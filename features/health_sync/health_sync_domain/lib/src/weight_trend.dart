import 'dart:math' as math;

import 'package:health_sync_domain/src/health_day_totals.dart';

/// How far one day's reading moves [weightTrendKg] toward itself: a tenth
/// of the way, so a single day's water or sodium swing barely shifts it.
const double weightTrendSmoothing = 0.1;

/// The smoothed weight trend as of the latest reading in [days], in
/// kilograms, or `null` when no day has a reading.
///
/// An exponentially weighted moving average over the days that have a
/// reading, oldest first, seeded with the first reading. Days without one
/// are never counted as a reading, never zero and never filled in, so the
/// trend is built only from readings that exist (product overview §6,
/// "Weight-trend trusted number"). [days] may be in any order.
///
/// **A gap counts for its length.** A reading after `n` calendar days moves
/// the trend `1 − (1 − smoothing)ⁿ` of the way toward itself: as far as `n`
/// daily readings at that weight would have. With daily weigh-ins that is
/// [smoothing] each day, as before. Someone who weighs in once a month gets
/// a trend that catches up instead of staying near their oldest reading:
/// 190 lb, then 180 lb 29 days later, gives about 180.5, not 189.
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
  DateTime? previous;
  for (final reading in readings) {
    if (trend == null || previous == null) {
      trend = reading.kg;
    } else {
      final gap = math.max(1, _calendarDaysBetween(previous, reading.date));
      final step = 1 - math.pow(1 - smoothing, gap);
      trend += step * (reading.kg - trend);
    }
    previous = reading.date;
  }
  return trend;
}

/// Whole calendar days from [from] to [to], by their local dates, so a
/// daylight-saving change (a 23- or 25-hour day) never shifts the count.
int _calendarDaysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
