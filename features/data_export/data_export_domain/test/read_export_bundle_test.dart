import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:data_export_domain/data_export_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers `getRange` with [rangeResult] and records each call's bounds.
class _FakeDailyMetricRepository implements DailyMetricRepository {
  _FakeDailyMetricRepository(this.rangeResult);

  final Result<List<DailyMetric>> rangeResult;
  final List<(DateTime, DateTime)> rangeCalls = [];

  @override
  ResultFuture<List<DailyMetric>> getRange(DateTime start, DateTime end) async {
    rangeCalls.add((start, end));
    return rangeResult;
  }

  @override
  ResultFuture<DailyMetric?> getByDate(DateTime date) =>
      throw UnimplementedError();

  @override
  ResultFuture<DailyMetric> upsert(
    DateTime date, {
    int? caloriesEaten,
    int? caloriesBurnedActive,
    int? caloriesBurnedBasal,
    int? steps,
    LoggingStatus? loggingStatus,
  }) => throw UnimplementedError();

  @override
  ResultFuture<Unit> delete(DateTime date) => throw UnimplementedError();
}

void main() {
  final exportedAt = DateTime(2026, 10, 22, 9, 30);

  test('reads the all-time range and bundles every row', () async {
    final rows = [
      DailyMetric(date: DateTime(2026, 10, 19), steps: 1),
      DailyMetric(date: DateTime(2026, 10, 20), caloriesEaten: 0),
    ];
    final repository = _FakeDailyMetricRepository(Ok(rows));

    final result = await readExportBundle(repository, exportedAt: exportedAt);

    expect(repository.rangeCalls, [(exportRangeStart, exportRangeEnd)]);
    final bundle = (result as Ok<ExportBundle>).value;
    expect(bundle.exportedAt, exportedAt);
    expect(bundle.dailyMetrics, rows);
  });

  test('the range covers the past and any future-dated row', () {
    expect(exportRangeStart.isBefore(DateTime(2000)), isTrue);
    expect(
      exportRangeEnd.isAfter(DateTime.now().add(const Duration(days: 3650))),
      isTrue,
    );
  });

  test('an Err passes its Failure through, with no bundle', () async {
    const failure = PlatformChannelFailure('store unavailable');
    final repository = _FakeDailyMetricRepository(const Err(failure));

    final result = await readExportBundle(repository, exportedAt: exportedAt);

    expect(result, isA<Err<ExportBundle>>());
    expect((result as Err<ExportBundle>).failure, same(failure));
  });
}
