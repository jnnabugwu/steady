import 'dart:async';

import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:metrics_domain/metrics_domain.dart';

/// Hand-written fake for `MetricsRepository`.
///
/// Each method returns whatever its handler returns. Every `getRange` call
/// is recorded so tests can assert on the arguments and call counts.
class FakeMetricsRepository implements MetricsRepository {
  FakeMetricsRepository({
    FutureOr<Result<List<DailyMetric>>> Function(DateTime start, DateTime end)?
    onGetRange,
  }) : onGetRange = onGetRange ?? ((_, _) => const Ok([]));

  FutureOr<Result<List<DailyMetric>>> Function(DateTime start, DateTime end)
  onGetRange;

  final List<(DateTime, DateTime)> getRangeCalls = [];

  @override
  ResultFuture<List<DailyMetric>> getRange(DateTime start, DateTime end) async {
    getRangeCalls.add((start, end));
    return await onGetRange(start, end);
  }

  @override
  ResultFuture<List<WeeklyBucket>> getWeeks(
    DateTime start,
    DateTime end, {
    int anchorWeekday = DateTime.friday,
  }) => throw UnimplementedError('getWeeks is not used by these tests');
}
