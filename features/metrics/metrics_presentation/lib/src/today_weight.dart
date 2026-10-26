import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_presentation/src/live_health.dart';
import 'package:metrics_presentation/src/metric_format.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// Today's weight card (#128), under `TodayMetricTiles`' tiles on the
/// iPhone: the smoothed trend as the headline, and today's raw reading
/// beneath it.
///
/// The trend ([weightTrendKg]) is the number to trust, not the morning's
/// scale reading (product overview §6), so it's the big one. Both come
/// from Apple Health, read live and never stored (App Store 5.1.3(ii)).
///
/// Neutral colours only: a weight going up or down gets no red, green or
/// praise (product overview, "Explicit non-goals").
///
/// Callers show it only when [trendKg] exists; the Mac never does, since it
/// has no Health data.
class TodayWeightCard extends StatelessWidget {
  /// Creates the card.
  const TodayWeightCard({
    required this.trendKg,
    required this.todayKg,
    required this.unit,
    super.key,
  });

  /// The smoothed trend, in kilograms.
  final double trendKg;

  /// Today's latest reading in kilograms, or `null` with none yet today.
  final double? todayKg;

  /// The unit the Health app shows weight in.
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final trend = formatWeight(trendKg, unit);
    final today = switch (todayKg) {
      final kg? => formatWeight(kg, unit),
      null => null,
    };
    final todayLine = today == null
        ? 'No reading today'
        : "Today's reading: ${today.value} ${today.unit}";
    return Semantics(
      container: true,
      label: 'Weight trend, ${trend.value} ${trend.unit}. $todayLine.',
      child: ExcludeSemantics(
        child: GlassCard(
          key: const Key('todayWeightCard'),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Weight trend', style: _labelStyle),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                spacing: 4,
                children: [
                  Text(
                    trend.value,
                    key: const Key('todayWeightTrend'),
                    style: SteadyType.metricValue,
                  ),
                  Text(trend.unit, style: _unitStyle),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                todayLine,
                key: const Key('todayWeightReading'),
                style: SteadyType.body,
              ),
              const SizedBox(height: 4),
              const Text(
                'Smoothed over your last $healthHistoryDays days of '
                'weigh-ins, so one day’s swing barely moves it.',
                style: _captionStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `MetricTile`'s label style, so the card reads as one of the metrics.
  static const _labelStyle = TextStyle(
    fontFamilyFallback: SteadyType.fontFamilyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: SteadyColors.textSecondary,
  );

  static const _unitStyle = TextStyle(
    fontFamilyFallback: SteadyType.fontFamilyFallback,
    fontSize: 11,
    color: SteadyColors.textMuted,
  );

  static const _captionStyle = TextStyle(
    fontFamilyFallback: SteadyType.fontFamilyFallback,
    fontSize: 12,
    color: SteadyColors.textMuted,
  );
}
