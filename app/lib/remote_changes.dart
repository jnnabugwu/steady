/// Refreshing screens when CloudKit syncs in rows from another device (#73).
///
/// On a second device, CloudKit imports rows into the local SwiftData store
/// in the background, after screens have already read it. The
/// `daily_metrics_store` plugin reports those imports (and not this app's
/// own writes) as events; [DailyMetricsRemoteRefresh] turns each one into
/// a re-read of every screen that shows daily metrics.
///
/// This lives in `app/` because it touches several features' providers at
/// once, which only the app layer may know about (CLAUDE.md §3, §5).
library;

import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:steady/providers.dart';

part 'remote_changes.g.dart';

/// Fires when the shared store changed through something other than this
/// app's writes: the plugin's stream for the SwiftData store, and empty for
/// the in-memory one (tests), which nothing else writes to. Tests override
/// it with their own stream.
@Riverpod(keepAlive: true)
Stream<void> Function() dailyMetricsRemoteChangeSource(Ref ref) =>
    switch (ref.watch(dailyMetricStoreProvider)) {
      DailyMetricStore.inMemory => Stream<void>.empty,
      DailyMetricStore.swiftData => dailyMetricsRemoteChanges,
    };

/// Listens to [dailyMetricsRemoteChangeSource] for as long as the app runs
/// and, on each event, invalidates every provider that holds data read
/// from the shared `DailyMetric` store:
///
/// - `metricsHistoryControllerProvider` (the home screen's history),
/// - every `checkInControllerProvider(date)` (check-in screens),
/// - every `weekCardControllerProvider(weekStart)` (the share card).
///
/// Providers nobody is watching are already disposed, so invalidating them
/// costs nothing. A watched one re-reads, and keeps showing its previous
/// data meanwhile (an invalidated `AsyncNotifier` refreshes as `AsyncData`
/// with `isLoading`, not `AsyncLoading`), so the screen doesn't flash a
/// spinner.
///
/// Not invalidated, on purpose: `pdfImportControllerProvider` and
/// `dataExportControllerProvider` hold no store data in their state (they
/// read at the moment of an action), and invalidating them would throw away
/// an import or export in progress.
///
/// State: how many refreshes it has triggered, for tests and debugging.
/// `keepAlive`: it must outlive every screen. `SteadyApp` starts it.
///
/// Add a provider here when a new screen caches daily-metric reads.
@Riverpod(keepAlive: true)
class DailyMetricsRemoteRefresh extends _$DailyMetricsRemoteRefresh {
  @override
  int build() {
    final subscription = ref
        .watch(dailyMetricsRemoteChangeSourceProvider)()
        .listen((_) => refreshDailyMetricReaders());
    ref.onDispose(subscription.cancel);
    return 0;
  }

  /// Domain event: DailyMetricsSyncedIn.
  ///
  /// Re-reads every screen showing daily metrics (see the class comment).
  void refreshDailyMetricReaders() {
    ref
      ..invalidate(metricsHistoryControllerProvider)
      ..invalidate(checkInControllerProvider)
      ..invalidate(weekCardControllerProvider);
    state++;
  }
}
