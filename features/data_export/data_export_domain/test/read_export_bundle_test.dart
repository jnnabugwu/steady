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
  ResultFuture<Unit> clearFields(
    DateTime date,
    Set<DailyMetricField> fields,
  ) => throw UnimplementedError();

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

  group("the range is pinned to DateTime's representable limit", () {
    // 100,000,000 days either side of the epoch, in milliseconds.
    const limitMs = 8640000000000000;
    // Longest a local day can be (DST), so "within a day" holds in any zone.
    final longestDayMs = const Duration(hours: 25).inMilliseconds;

    bool isLocalMidnight(DateTime d) =>
        !d.isUtc &&
        d.hour == 0 &&
        d.minute == 0 &&
        d.second == 0 &&
        d.millisecond == 0 &&
        d.microsecond == 0;

    test('start is the earliest representable local midnight', () {
      final start = exportRangeStart;
      expect(isLocalMidnight(start), isTrue);
      expect(start.year, -271821);
      expect(start.millisecondsSinceEpoch, greaterThanOrEqualTo(-limitMs));
      // The previous midnight would be past the limit.
      expect(start.millisecondsSinceEpoch - longestDayMs, lessThan(-limitMs));
    });

    test('end is the latest representable local midnight', () {
      final end = exportRangeEnd;
      expect(isLocalMidnight(end), isTrue);
      expect(end.year, 275760);
      expect(end.millisecondsSinceEpoch, lessThanOrEqualTo(limitMs));
      // The next midnight would be past the limit.
      expect(end.millisecondsSinceEpoch + longestDayMs, greaterThan(limitMs));
    });

    test('both bounds survive the DateTime(y, m, d) normalization a '
        'repository applies to them', () {
      for (final bound in [exportRangeStart, exportRangeEnd]) {
        expect(DateTime(bound.year, bound.month, bound.day), bound);
      }
    });

    test('rows before 1970 and after 9999 are inside the range', () {
      for (final date in [
        DateTime(-5000, 6, 15),
        DateTime(1),
        DateTime(1969, 12, 31),
        DateTime(10000),
        DateTime(275000),
      ]) {
        expect(date.isBefore(exportRangeStart), isFalse, reason: '$date');
        expect(date.isAfter(exportRangeEnd), isFalse, reason: '$date');
      }
    });
  });

  test('an Err passes its Failure through, with no bundle', () async {
    const failure = PlatformChannelFailure('store unavailable');
    final repository = _FakeDailyMetricRepository(const Err(failure));

    final result = await readExportBundle(repository, exportedAt: exportedAt);

    expect(result, isA<Err<ExportBundle>>());
    expect((result as Err<ExportBundle>).failure, same(failure));
  });
}
