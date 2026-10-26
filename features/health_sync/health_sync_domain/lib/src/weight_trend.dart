import 'package:health_sync_domain/src/health_day_totals.dart';

/// How far each reading moves [weightTrendKg] toward itself: a tenth of
/// the way, so a single day's water or sodium swing barely shifts it.
const double weightTrendSmoothing = 0.1;

/// The smoothed weight trend as of the latest reading in [days], in
/// kilograms, or `null` when no day has a reading.
///
/// An exponentially weighted moving average over the days that have a
/// reading, oldest first, seeded with the first reading. Days without one
/// are skipped rather than filled in, so the trend is always built from
/// whatever readings exist (product overview §6, "Weight-trend trusted
/// number"). [days] may be in any order.
double? weightTrendKg(
  Iterable<HealthDayTotals> days, {
  double smoothing = weightTrendSmoothing,
}) {
  assert(smoothing > 0 && smoothing <= 1, 'smoothing is in (0, 1].');
  final readings = [
    for (final day in days)
      if (day.weightKg case final kg?) (date: day.date, kg: kg),
  ]..sort((a, b) => a.date.compareTo(b.date));
  double? trend;
  for (final reading in readings) {
    trend = trend == null
        ? reading.kg
        : trend + smoothing * (reading.kg - trend);
  }
  return trend;
}
