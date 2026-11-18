/// Apple Health access, iOS only (#75): asking for read permission, and
/// re-reading Health live at launch, on every return to the foreground and
/// from Settings' "Refresh".
///
/// **Nothing here stores Health data.** Steps, burned calories and weight
/// are read live by `healthDayTotalsProvider` (`metrics_presentation`) while
/// a screen shows them, and are never written to the shared `DailyMetric`
/// store, which is mirrored to iCloud: App Store guideline 5.1.3(ii) forbids
/// storing personal health information there. "Refreshing" is only
/// invalidating the Health providers, so they read Health again. The Mac and
/// the coach have no Health data. `test/health_access_test.dart` guards that
/// no Health path writes the store.
///
/// Lives in the app layer because `health_sync` is headless (no
/// `*_presentation` package). On macOS [healthKitRepositoryProvider] is
/// `null`, so every call here is a no-op.
///
/// **Asked only from a screen that says why** (docs/design/onboarding.md,
/// "Leaving early"): onboarding's Apple Health screen, Settings → Apple
/// Health, Today's "Connect Apple Health" under the metric tiles and the
/// Cal AI card's "Allow Apple Health", each through
/// [HealthAccessController.requestHealthAccess]. Launch and resume call
/// [HealthAccessController.refreshHealthData], which never asks: it
/// re-reads Health only once the sheet has been shown. There's no flag of
/// Steady's own: HealthKit already remembers whether its sheet was shown
/// (`authorizationStatus`, from `getRequestStatusForAuthorization`), and
/// iOS never shows it twice for the same types anyway.
///
/// **Usage sharing** (TestFlight only, `usage_sharing.dart`): once per
/// launch, after the first refresh or request that finds Health asked, the
/// controller reads the last seven days and records `health_connected`
/// with two yes/nos, any steps and any calories eaten, never the numbers.
/// HealthKit never says whether access was allowed, so data coming back is
/// the only sign it was. Skipped, Health unread, unless sharing is on.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:analytics/analytics.dart' show AnalyticsEvent;
import 'package:failures/failures.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:steady/providers.dart';
import 'package:steady/usage_sharing.dart';

part 'health_access.g.dart';

/// Retry policy for [HealthAccessController], as for the account status: a
/// [Failure] was already mapped at the `_data` boundary, so it surfaces at
/// once instead of Riverpod 3's default retry holding the provider in
/// `AsyncLoading`. The next resume, or "Refresh", is the retry.
Duration? _retryUnlessFailure(int retryCount, Object error) =>
    error is Failure ? null : ProviderContainer.defaultRetry(retryCount, error);

/// Whether Health is available and whether its permission sheet has been
/// shown (never "allowed" or "denied": HealthKit doesn't say), for
/// Settings.
///
/// `keepAlive`: app-scoped, not screen-scoped. It's driven from the app
/// root at launch and on resume, and it holds the in-flight refresh, so a
/// resume while the permission sheet is still open joins it instead of
/// asking twice. Not a family, so nothing piles up.
@Riverpod(keepAlive: true, retry: _retryUnlessFailure)
class HealthAccessController extends _$HealthAccessController {
  Future<void>? _refreshing;
  Future<void>? _requesting;
  var _reportedThisLaunch = false;

  @override
  Future<HealthAuthorizationStatus> build() async {
    final health = ref.watch(healthKitRepositoryProvider);
    if (health == null) return HealthAuthorizationStatus.unavailable;
    return switch (await health.authorizationStatus()) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  /// Domain event: HealthDataRefreshed.
  ///
  /// Reads whether Health's permission sheet has been shown and, once it
  /// has (`requested`), invalidates `healthDayTotalsProvider` and
  /// `healthWeightUnitProvider`, so every screen showing Health values
  /// reads them from Health again (today's steps keep counting). **Never
  /// shows the sheet**: launch and resume call this, and asking is
  /// [requestHealthAccess]'s job. Writes nothing anywhere.
  ///
  /// Never throws: a failure becomes an `AsyncError` carrying the
  /// [Failure], and is logged. A no-op where Health isn't bound (macOS). A
  /// call while a refresh or a request is running returns that one.
  Future<void> refreshHealthData() =>
      _requesting ??
      (_refreshing ??= _refresh(ask: false)
          .whenComplete(() => _refreshing = null));

  /// Domain event: HealthAccessRequested.
  ///
  /// Shows Health's read-permission sheet if it has never been shown, then
  /// refreshes as [refreshHealthData] does. Called only from a screen that
  /// says why Steady reads Health (see the library comment). Completes once
  /// the sheet is answered.
  ///
  /// Never throws, like [refreshHealthData]. A refresh already running is
  /// waited for first, since it never asks; a request already running is
  /// joined.
  Future<void> requestHealthAccess() => _requesting ??= () async {
    if (_refreshing case final running?) await running;
    await _refresh(ask: true);
  }().whenComplete(() => _requesting = null);

  Future<void> _refresh({required bool ask}) async {
    final health = ref.read(healthKitRepositoryProvider);
    if (health == null) return;
    // Let build() settle first, so its result can't land on top of ours.
    try {
      await future;
    } on Object {
      // A failed status read; it's read again below.
    }
    if (!ref.mounted) return;

    var status = HealthAuthorizationStatus.unavailable;
    switch (await health.authorizationStatus()) {
      case Ok(:final value):
        status = value;
      case Err(:final failure):
        return _fail(failure);
    }
    if (ask && status == HealthAuthorizationStatus.notDetermined) {
      state = const AsyncLoading<HealthAuthorizationStatus>();
      if (await health.requestAuthorization() case Err(:final failure)) {
        return _fail(failure);
      }
      status = HealthAuthorizationStatus.requested;
    }
    if (!ref.mounted) return;
    state = AsyncData(status);
    if (status == HealthAuthorizationStatus.requested) {
      ref
        ..invalidate(healthDayTotalsProvider)
        ..invalidate(healthWeightUnitProvider);
      await _reportHealthConnected(health);
    }
  }

  /// Records `health_connected` once per launch (see the library comment).
  /// A failed read records nothing; there's no next try until relaunch.
  Future<void> _reportHealthConnected(HealthKitRepository health) async {
    final analytics = ref.read(postHogAnalyticsProvider);
    if (_reportedThisLaunch || analytics == null) return;
    _reportedThisLaunch = true;
    if (await analytics.status != UsageSharingStatus.on) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final week = await health.dailyTotals(
      today.subtract(const Duration(days: 6)),
      today,
    );
    if (week case Ok(value: final days)) {
      analytics.record(
        AnalyticsEvent.healthConnected(
          steps: days.any((day) => day.steps != null),
          caloriesEaten: days.any((day) => day.caloriesEaten != null),
        ),
      );
    }
  }

  void _fail(Failure failure) {
    developer.log(
      'Apple Health access failed: ${failure.message}',
      name: 'steady.health',
      error: failure.cause ?? failure,
    );
    if (ref.mounted) state = AsyncError(failure, StackTrace.current);
  }
}
