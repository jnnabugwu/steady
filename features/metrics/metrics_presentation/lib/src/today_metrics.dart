import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_presentation/src/live_health.dart';
import 'package:metrics_presentation/src/metric_format.dart';
import 'package:metrics_presentation/src/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

part 'today_metrics.g.dart';

/// A [Failure] was already mapped at the `_data` boundary (CLAUDE.md §9):
/// surface it at once instead of retrying.
Duration? _retryUnlessFailure(int retryCount, Object error) =>
    error is Failure ? null : ProviderContainer.defaultRetry(retryCount, error);

/// The seven calendar days ending on [day], oldest first, each at local
/// midnight. Calendar arithmetic, so a DST change can't shift a day.
List<DateTime> todayMetricsDates(DateTime day) => [
  for (var i = 6; i >= 0; i--) DateTime(day.year, day.month, day.day - i),
];

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
@Riverpod(retry: _retryUnlessFailure)
Future<List<DailyMetric>> todayMetrics(Ref ref, DateTime day) async {
  assert(
    day == DateTime(day.year, day.month, day.day),
    'Key todayMetricsProvider on local midnight, not on $day.',
  );
  final dates = todayMetricsDates(day);
  final result = await ref
      .watch(metricsRepositoryProvider)
      .getRange(dates.first, dates.last);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
}

/// The Today screen's metrics (Pass 02 "Native Glass", artboard A2): one
/// [MetricTile] per metric, its value for [date] over a sparkline of the
/// seven days ending on [date].
///
/// Eaten comes from the stored rows (Cal AI PDFs); burned and steps from
/// Apple Health, read live on the iPhone ([healthDayTotalsProvider], the
/// same window the history reads) and never stored (App Store 5.1.3(ii)).
/// Like the history's tiles, a metric with no value anywhere in the seven
/// days gets no tile, so the Mac, which has no Health, shows only what it
/// has. A metric with values this week but none on [date] shows "—".
///
/// With no metric at all this week, a short glass card says so. Lays
/// itself out at full width with no outer padding; the app's Today screen
/// places it.
class TodayMetricTiles extends ConsumerWidget {
  /// Creates the tiles for [date] (normalized to midnight).
  const TodayMetricTiles({required this.date, super.key});

  /// The day the tiles' values are for, normally today.
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = DateTime(date.year, date.month, date.day);
    final stored = ref.watch(todayMetricsProvider(day));
    final window = healthHistoryWindow(day);
    // `.value` is null while loading and on error: the stored values show
    // without Health rather than waiting on, or failing with, it.
    final health =
        ref.watch(healthDayTotalsProvider(window.start, window.end)).value ??
        const <DateTime, HealthDayTotals>{};

    return switch (stored) {
      AsyncValue(:final error?) => _Message(
        key: const Key('todayMetricsError'),
        text: error is Failure
            ? "Couldn't load today's metrics: ${error.message}"
            : "Couldn't load today's metrics.",
        // A Failure isn't retried automatically, so a transient store
        // error would otherwise stay up until something else invalidates.
        onRetry: () => ref.invalidate(todayMetricsProvider(day)),
      ),
      AsyncValue(:final value?) => _tiles(day, mergeLiveHealth(value, health)),
      _ => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(key: Key('todayMetricsProgress')),
        ),
      ),
    };
  }

  Widget _tiles(DateTime day, List<DailyMetric> merged) {
    final byDay = {
      for (final d in merged)
        DateTime(d.date.year, d.date.month, d.date.day): d,
    };
    final week = [for (final d in todayMetricsDates(day)) byDay[d]];
    final tiles = [
      for (final metric in _TodayMetric.values)
        if (week.any((d) => d != null && metric.read(d) != null))
          _tile(metric, week),
    ];
    if (tiles.isEmpty) {
      return const _Message(
        key: Key('todayMetricsEmpty'),
        text:
            'No metrics this week yet. Import a Cal AI PDF to see '
            'what you’ve eaten.',
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        // Three slots whatever shows, so a tile keeps its width.
        for (var i = 0; i < 3; i++)
          Expanded(child: i < tiles.length ? tiles[i] : const SizedBox()),
      ],
    );
  }

  Widget _tile(_TodayMetric metric, List<DailyMetric?> week) {
    final values = [
      for (final d in week)
        if (d == null) null else metric.read(d),
    ];
    final today = values.last;
    return MetricTile(
      key: Key('todayTile_${metric.name}'),
      label: metric.label,
      value: today == null ? '—' : formatThousands(today),
      unit: today == null ? null : metric.unit,
      accent: metric.accent,
      dailyValues: values,
      semanticLabel: today == null ? '${metric.label}, nothing today' : null,
    );
  }
}

/// The Today tiles' metrics, in the artboard's order.
enum _TodayMetric {
  eaten('Eaten', 'kcal', MetricAccent.caloriesEaten),
  burned('Burned', 'kcal', MetricAccent.caloriesBurned),
  steps('Steps', null, MetricAccent.steps);

  _TodayMetric(this.label, this.unit, this.accent);

  final String label;
  final String? unit;
  final MetricAccent accent;

  int? read(DailyMetric day) => switch (this) {
    _TodayMetric.eaten => day.caloriesEaten,
    _TodayMetric.burned => caloriesBurned(day),
    _TodayMetric.steps => day.steps,
  };
}

/// A short glass card in place of the tiles, with a Retry pill when
/// [onRetry] is given.
class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry, super.key});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        Text(text, style: SteadyType.body),
        if (onRetry case final onRetry?)
          SizedBox(
            height: 44,
            child: Button(
              key: const Key('todayMetricsRetry'),
              style: _glassPillStyle,
              alignment: Alignment.center,
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    ),
  );

  /// The Pass 02 secondary pill, as on the history's error state.
  static final AbstractButtonStyle _glassPillStyle =
      const ButtonStyle.secondary()
          .withBackgroundColor(
            color: SteadyColors.glassControlFill,
            hoverColor: SteadyColors.glassControlBorder,
          )
          .withBorder(
            border: Border.all(color: SteadyColors.glassControlBorder),
          );
}
