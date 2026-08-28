import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:metrics_domain/src/weekly_bucket.dart';

/// Buckets [days] into `WeeklyBucket`s anchored on [anchorWeekday]
/// (`DateTime.monday` by default). Ports the product doc's already-validated
/// `bucket_into_weeks()`. Assumes [days] is sorted ascending by date.
List<WeeklyBucket> bucketIntoWeeks(
  List<DailyMetric> days, {
  int anchorWeekday = DateTime.monday,
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
  final normalized = DateTime(date.year, date.month, date.day);
  final daysSinceAnchor = (normalized.weekday - anchorWeekday) % 7;
  return normalized.subtract(Duration(days: daysSinceAnchor));
}
