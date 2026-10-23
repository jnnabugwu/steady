/// Apple Health sync, iOS only (#75): copies the last 30 days of steps and
/// burned calories from Health into the shared `DailyMetric` store, at
/// launch and whenever the app returns to the foreground.
///
/// Lives in the app layer because `health_sync` is headless (no
/// `*_presentation` package): the use case is `syncHealthDays` in
/// `health_sync_domain`, and this file is the Notifier that runs it and
/// that Settings shows. On macOS [healthKitRepositoryProvider] is `null`,
/// so every call here is a no-op.
///
/// **Asking for permission once.** There's no flag of Steady's own:
/// HealthKit already remembers whether its permission sheet was shown
/// (`authorizationStatus`, from `getRequestStatusForAuthorization`), and
/// iOS never shows it twice for the same types anyway. The first sync asks;
/// every later one finds `requested` and goes straight to reading.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:failures/failures.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:steady/providers.dart';
import 'package:steady/remote_changes.dart';

part 'health_sync.g.dart';

/// The current time, which decides what "today" is for a sync. A provider
/// so tests can pin the date.
typedef HealthSyncClock = DateTime Function();

/// The clock [HealthSyncController] reads "now" from. Defaults to
/// [DateTime.now].
///
/// `keepAlive`: cheap and stateless (D6).
@Riverpod(keepAlive: true)
HealthSyncClock healthSyncClock(Ref ref) => DateTime.now;

/// What Settings shows about Apple Health.
class HealthSyncState {
  /// Creates the state.
  const HealthSyncState({required this.authorization, this.lastSync});

  /// Whether Health is available and whether its permission sheet has been
  /// shown. Never "allowed" or "denied": HealthKit doesn't say.
  final HealthAuthorizationStatus authorization;

  /// The latest sync this launch, or `null` before the first one finishes.
  final HealthSyncReport? lastSync;
}

/// Retry policy for [HealthSyncController], as for the account status: a
/// [Failure] was already mapped at the `_data` boundary, so it surfaces at
/// once instead of Riverpod 3's default retry holding the provider in
/// `AsyncLoading` (which would also stall a sync waiting on `build`). The
/// next resume, or "Sync now", is the retry.
Duration? _retryUnlessFailure(int retryCount, Object error) =>
    error is Failure ? null : ProviderContainer.defaultRetry(retryCount, error);

/// Runs the Health sync and holds its latest outcome.
///
/// `keepAlive`: app-scoped, not screen-scoped. It's driven from the app
/// root at launch and on resume, and it holds the in-flight sync, so a
/// resume while a sync (or the permission sheet) is still open joins it
/// instead of starting a second one. Not a family, so nothing piles up.
@Riverpod(keepAlive: true, retry: _retryUnlessFailure)
class HealthSyncController extends _$HealthSyncController {
  Future<void>? _inFlight;

  @override
  Future<HealthSyncState> build() async {
    final health = ref.watch(healthKitRepositoryProvider);
    if (health == null) {
      return const HealthSyncState(
        authorization: HealthAuthorizationStatus.unavailable,
      );
    }
    return switch (await health.authorizationStatus()) {
      Ok(:final value) => HealthSyncState(authorization: value),
      Err(:final failure) => throw failure,
    };
  }

  /// Domain event: HealthDataSynced.
  ///
  /// Shows Health's read-permission sheet if it has never been shown, then
  /// copies the last [healthSyncWindowDays] days into the shared store
  /// (only the three Health fields, only where they changed). When any day
  /// changed, re-reads every daily-metric screen (history, check-in, week
  /// card) through `invalidateDailyMetricReaders`, the same refresh a
  /// CloudKit remote change triggers.
  ///
  /// Never throws: a failure becomes an `AsyncError` carrying the
  /// [Failure], and is logged. A no-op where Health isn't bound (macOS). A
  /// call while a sync is running returns that sync.
  Future<void> syncHealthData() =>
      _inFlight ??= _sync().whenComplete(() => _inFlight = null);

  Future<void> _sync() async {
    final health = ref.read(healthKitRepositoryProvider);
    if (health == null) return;
    // Let build() settle first, so its result can't land on top of ours.
    try {
      await future;
    } on Object {
      // A failed status read; the sync below reads it again.
    }
    if (!ref.mounted) return;
    state = const AsyncLoading<HealthSyncState>();

    final HealthAuthorizationStatus status;
    switch (await health.authorizationStatus()) {
      case Ok(:final value):
        status = value;
      case Err(:final failure):
        return _fail(failure);
    }
    if (status == HealthAuthorizationStatus.unavailable) {
      state = AsyncData(HealthSyncState(authorization: status));
      return;
    }
    if (status == HealthAuthorizationStatus.notDetermined) {
      if (await health.requestAuthorization() case Err(:final failure)) {
        return _fail(failure);
      }
    }

    final result = await syncHealthDays(
      health: health,
      dailyMetrics: ref.read(dailyMetricRepositoryProvider),
      today: ref.read(healthSyncClockProvider)(),
    );
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        state = AsyncData(
          HealthSyncState(
            authorization: HealthAuthorizationStatus.requested,
            lastSync: value,
          ),
        );
        if (value.daysUpdated > 0) {
          developer.log(
            'Health sync updated ${value.daysUpdated} days',
            name: 'steady.health',
          );
          invalidateDailyMetricReaders(ref);
        }
      case Err(:final failure):
        _fail(failure);
    }
  }

  void _fail(Failure failure) {
    developer.log(
      'Health sync failed: ${failure.message}',
      name: 'steady.health',
      error: failure.cause ?? failure,
    );
    if (ref.mounted) state = AsyncError(failure, StackTrace.current);
  }
}
