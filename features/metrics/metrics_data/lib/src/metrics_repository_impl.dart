import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:metrics_domain/metrics_domain.dart';

/// Implements `MetricsRepository` by composing over an injected
/// `DailyMetricRepository` and the pure `bucketIntoWeeks` function.
class MetricsRepositoryImpl implements MetricsRepository {
  MetricsRepositoryImpl(this._dailyMetrics);

  final DailyMetricRepository _dailyMetrics;

  @override
  ResultFuture<List<DailyMetric>> getRange(DateTime start, DateTime end) =>
      _dailyMetrics.getRange(start, end);

  @override
  ResultFuture<List<WeeklyBucket>> getWeeks(
    DateTime start,
    DateTime end, {
    int anchorWeekday = DateTime.friday,
  }) async {
    final result = await _dailyMetrics.getRange(start, end);
    return result.fold(
      Err.new,
      (days) => Ok(bucketIntoWeeks(days, anchorWeekday: anchorWeekday)),
    );
  }
}
