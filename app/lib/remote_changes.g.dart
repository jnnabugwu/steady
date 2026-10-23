// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_changes.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fires when the shared store changed through something other than this
/// app's writes: the plugin's stream for the SwiftData store, and empty for
/// the in-memory one (tests), which nothing else writes to. Tests override
/// it with their own stream.

@ProviderFor(dailyMetricsRemoteChangeSource)
final dailyMetricsRemoteChangeSourceProvider =
    DailyMetricsRemoteChangeSourceProvider._();

/// Fires when the shared store changed through something other than this
/// app's writes: the plugin's stream for the SwiftData store, and empty for
/// the in-memory one (tests), which nothing else writes to. Tests override
/// it with their own stream.

final class DailyMetricsRemoteChangeSourceProvider
    extends
        $FunctionalProvider<
          Stream<void> Function(),
          Stream<void> Function(),
          Stream<void> Function()
        >
    with $Provider<Stream<void> Function()> {
  /// Fires when the shared store changed through something other than this
  /// app's writes: the plugin's stream for the SwiftData store, and empty for
  /// the in-memory one (tests), which nothing else writes to. Tests override
  /// it with their own stream.
  DailyMetricsRemoteChangeSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyMetricsRemoteChangeSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyMetricsRemoteChangeSourceHash();

  @$internal
  @override
  $ProviderElement<Stream<void> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Stream<void> Function() create(Ref ref) {
    return dailyMetricsRemoteChangeSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Stream<void> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Stream<void> Function()>(value),
    );
  }
}

String _$dailyMetricsRemoteChangeSourceHash() =>
    r'22e6d2a57e9371dc891a879939d964cc82033a09';

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

@ProviderFor(DailyMetricsRemoteRefresh)
final dailyMetricsRemoteRefreshProvider = DailyMetricsRemoteRefreshProvider._();

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
final class DailyMetricsRemoteRefreshProvider
    extends $NotifierProvider<DailyMetricsRemoteRefresh, int> {
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
  DailyMetricsRemoteRefreshProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyMetricsRemoteRefreshProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyMetricsRemoteRefreshHash();

  @$internal
  @override
  DailyMetricsRemoteRefresh create() => DailyMetricsRemoteRefresh();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$dailyMetricsRemoteRefreshHash() =>
    r'8a03419c99ca3a3923f43d6bcf83e032ccfd0b4a';

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

abstract class _$DailyMetricsRemoteRefresh extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
