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
/// **Asking for permission once.** There's no flag of Steady's own:
/// HealthKit already remembers whether its permission sheet was shown
/// (`authorizationStatus`, from `getRequestStatusForAuthorization`), and
/// iOS never shows it twice for the same types anyway. The first refresh
/// asks; every later one finds `requested` and goes straight to re-reading.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:failures/failures.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:steady/providers.dart';

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
  Future<void>? _inFlight;

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
  /// Shows Health's read-permission sheet if it has never been shown, then
  /// invalidates `healthDayTotalsProvider` and `healthWeightUnitProvider`,
  /// so every screen showing Health values reads them from Health again
  /// (today's steps keep counting).
  /// Writes nothing anywhere.
  ///
  /// Never throws: a failure becomes an `AsyncError` carrying the
  /// [Failure], and is logged. A no-op where Health isn't bound (macOS). A
  /// call while one is running returns that one.
  Future<void> refreshHealthData() =>
      _inFlight ??= _refresh().whenComplete(() => _inFlight = null);

  Future<void> _refresh() async {
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
    if (status == HealthAuthorizationStatus.notDetermined) {
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
