// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_metrics.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The stored `DailyMetric` rows for the seven days ending on [day]: the
/// Today screen's metric tiles (today's value plus the week's sparkline).
///
/// An auto-dispose family keyed on [day] (CLAUDE.md §4); callers pass local
/// midnight. One `getRange` read. A repository error arrives as a typed
/// [Failure] in `AsyncError`, without retrying. To reload (e.g. after a Cal
/// AI import), `ref.invalidate(todayMetricsProvider)`.
///
/// Stored rows only: Apple Health is merged in by [TodayMetricTiles], live
/// and in memory (`live_health.dart`).

@ProviderFor(todayMetrics)
final todayMetricsProvider = TodayMetricsFamily._();

/// The stored `DailyMetric` rows for the seven days ending on [day]: the
/// Today screen's metric tiles (today's value plus the week's sparkline).
///
/// An auto-dispose family keyed on [day] (CLAUDE.md §4); callers pass local
/// midnight. One `getRange` read. A repository error arrives as a typed
/// [Failure] in `AsyncError`, without retrying. To reload (e.g. after a Cal
/// AI import), `ref.invalidate(todayMetricsProvider)`.
///
/// Stored rows only: Apple Health is merged in by [TodayMetricTiles], live
/// and in memory (`live_health.dart`).

final class TodayMetricsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DailyMetric>>,
          List<DailyMetric>,
          FutureOr<List<DailyMetric>>
        >
    with
        $FutureModifier<List<DailyMetric>>,
        $FutureProvider<List<DailyMetric>> {
  /// The stored `DailyMetric` rows for the seven days ending on [day]: the
  /// Today screen's metric tiles (today's value plus the week's sparkline).
  ///
  /// An auto-dispose family keyed on [day] (CLAUDE.md §4); callers pass local
  /// midnight. One `getRange` read. A repository error arrives as a typed
  /// [Failure] in `AsyncError`, without retrying. To reload (e.g. after a Cal
  /// AI import), `ref.invalidate(todayMetricsProvider)`.
  ///
  /// Stored rows only: Apple Health is merged in by [TodayMetricTiles], live
  /// and in memory (`live_health.dart`).
  TodayMetricsProvider._({
    required TodayMetricsFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: _retryUnlessFailure,
         name: r'todayMetricsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$todayMetricsHash();

  @override
  String toString() {
    return r'todayMetricsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<DailyMetric>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DailyMetric>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return todayMetrics(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TodayMetricsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$todayMetricsHash() => r'bf9d37c9e60fae37759564b7ac568905ebe10c46';

/// The stored `DailyMetric` rows for the seven days ending on [day]: the
/// Today screen's metric tiles (today's value plus the week's sparkline).
///
/// An auto-dispose family keyed on [day] (CLAUDE.md §4); callers pass local
/// midnight. One `getRange` read. A repository error arrives as a typed
/// [Failure] in `AsyncError`, without retrying. To reload (e.g. after a Cal
/// AI import), `ref.invalidate(todayMetricsProvider)`.
///
/// Stored rows only: Apple Health is merged in by [TodayMetricTiles], live
/// and in memory (`live_health.dart`).

final class TodayMetricsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<DailyMetric>>, DateTime> {
  TodayMetricsFamily._()
    : super(
        retry: _retryUnlessFailure,
        name: r'todayMetricsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The stored `DailyMetric` rows for the seven days ending on [day]: the
  /// Today screen's metric tiles (today's value plus the week's sparkline).
  ///
  /// An auto-dispose family keyed on [day] (CLAUDE.md §4); callers pass local
  /// midnight. One `getRange` read. A repository error arrives as a typed
  /// [Failure] in `AsyncError`, without retrying. To reload (e.g. after a Cal
  /// AI import), `ref.invalidate(todayMetricsProvider)`.
  ///
  /// Stored rows only: Apple Health is merged in by [TodayMetricTiles], live
  /// and in memory (`live_health.dart`).

  TodayMetricsProvider call(DateTime day) =>
      TodayMetricsProvider._(argument: day, from: this);

  @override
  String toString() => r'todayMetricsProvider';
}
