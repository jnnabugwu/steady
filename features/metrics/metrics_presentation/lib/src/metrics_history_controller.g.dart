// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metrics_history_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every imported day, newest first, for the metrics history screen.
///
/// Auto-dispose (CLAUDE.md §4: screen controllers are screen-scoped). Reads
/// `metricsRepositoryProvider.getRange` from 2000-01-01 to today, inclusive.
/// Repository errors arrive as a typed [Failure] and are surfaced without
/// retrying.
///
/// No public methods: to reload (e.g. after a Cal AI import), callers
/// `ref.invalidate(metricsHistoryControllerProvider)`.

@ProviderFor(MetricsHistoryController)
final metricsHistoryControllerProvider = MetricsHistoryControllerProvider._();

/// Every imported day, newest first, for the metrics history screen.
///
/// Auto-dispose (CLAUDE.md §4: screen controllers are screen-scoped). Reads
/// `metricsRepositoryProvider.getRange` from 2000-01-01 to today, inclusive.
/// Repository errors arrive as a typed [Failure] and are surfaced without
/// retrying.
///
/// No public methods: to reload (e.g. after a Cal AI import), callers
/// `ref.invalidate(metricsHistoryControllerProvider)`.
final class MetricsHistoryControllerProvider
    extends
        $AsyncNotifierProvider<MetricsHistoryController, List<DailyMetric>> {
  /// Every imported day, newest first, for the metrics history screen.
  ///
  /// Auto-dispose (CLAUDE.md §4: screen controllers are screen-scoped). Reads
  /// `metricsRepositoryProvider.getRange` from 2000-01-01 to today, inclusive.
  /// Repository errors arrive as a typed [Failure] and are surfaced without
  /// retrying.
  ///
  /// No public methods: to reload (e.g. after a Cal AI import), callers
  /// `ref.invalidate(metricsHistoryControllerProvider)`.
  MetricsHistoryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: _retryUnlessFailure,
        name: r'metricsHistoryControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$metricsHistoryControllerHash();

  @$internal
  @override
  MetricsHistoryController create() => MetricsHistoryController();
}

String _$metricsHistoryControllerHash() =>
    r'3b8b1d46f3243bf28d5ec222747b18d2f52063f5';

/// Every imported day, newest first, for the metrics history screen.
///
/// Auto-dispose (CLAUDE.md §4: screen controllers are screen-scoped). Reads
/// `metricsRepositoryProvider.getRange` from 2000-01-01 to today, inclusive.
/// Repository errors arrive as a typed [Failure] and are surfaced without
/// retrying.
///
/// No public methods: to reload (e.g. after a Cal AI import), callers
/// `ref.invalidate(metricsHistoryControllerProvider)`.

abstract class _$MetricsHistoryController
    extends $AsyncNotifier<List<DailyMetric>> {
  FutureOr<List<DailyMetric>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<DailyMetric>>, List<DailyMetric>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<DailyMetric>>, List<DailyMetric>>,
              AsyncValue<List<DailyMetric>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
