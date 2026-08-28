import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:metrics_domain/src/weekly_bucket.dart';

/// Reads metrics data, bucketed for the weekly view.
abstract class MetricsRepository {
  /// Every `DailyMetric` row between [start] and [end], inclusive.
  ResultFuture<List<DailyMetric>> getRange(DateTime start, DateTime end);

  /// The `DailyMetric` rows between [start] and [end], bucketed into
  /// `WeeklyBucket`s anchored on [anchorWeekday].
  ResultFuture<List<WeeklyBucket>> getWeeks(
    DateTime start,
    DateTime end, {
    int anchorWeekday = DateTime.monday,
  });
}
