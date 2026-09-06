import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:metrics_domain/src/weekly_bucket.dart';

/// Buckets [days] into `WeeklyBucket`s anchored on [anchorWeekday]
/// (`DateTime.friday` by default — the product doc's Friday→Thursday
/// window; §5 "any weekday start, not just Friday"). Ports the product
/// doc's already-validated `bucket_into_weeks()`. Assumes [days] is sorted
/// ascending by date.
List<WeeklyBucket> bucketIntoWeeks(
  List<DailyMetric> days, {
  int anchorWeekday = DateTime.friday,
}) {
  if (days.isEmpty) return [];

  final buckets = <WeeklyBucket>[];
  var currentWeekStart = _weekStartFor(days.first.date, anchorWeekday);
  var currentDays = <DailyMetric>[];

  for (final day in days) {
    final weekStart = _weekStartFor(day.date, anchorWeekday);
    if (weekStart != currentWeekStart) {
      buckets.add(WeeklyBucket(weekStart: currentWeekStart, days: currentDays));
      currentWeekStart = weekStart;
      currentDays = [];
    }
    currentDays.add(day);
  }
  buckets.add(WeeklyBucket(weekStart: currentWeekStart, days: currentDays));

  return buckets;
}

DateTime _weekStartFor(DateTime date, int anchorWeekday) {
  final daysSinceAnchor = (date.weekday - anchorWeekday) % 7;
  // Calendar-date arithmetic, not `Duration(days: n)`: subtracting a fixed
  // 24h duration across a DST transition lands on 23:00/01:00 of an
  // adjacent day, which would give a non-midnight `weekStart` and split one
  // week into two buckets. The DateTime constructor normalizes a negative
  // day-of-month and always yields local midnight.
  return DateTime(date.year, date.month, date.day - daysSinceAnchor);
}
