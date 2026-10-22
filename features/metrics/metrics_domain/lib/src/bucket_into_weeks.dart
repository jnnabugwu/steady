import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:metrics_domain/src/week_start.dart';
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
  var currentWeekStart = weekStartFor(
    days.first.date,
    anchorWeekday: anchorWeekday,
  );
  var currentDays = <DailyMetric>[];

  for (final day in days) {
    final weekStart = weekStartFor(day.date, anchorWeekday: anchorWeekday);
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
