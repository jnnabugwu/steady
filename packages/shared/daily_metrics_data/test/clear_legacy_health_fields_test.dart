import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = DateTime(2026, 10, 20);
  final healthOnlyDay = DateTime(2026, 10, 21);
  final cleanDay = DateTime(2026, 10, 22);

  Future<List<DailyMetric>> all(DailyMetricRepository repo) async =>
      ((await repo.getRange(
        DateTime(0),
        DateTime(9999, 12, 31),
      )) as Ok<List<DailyMetric>>).value;

  test('clears only Health fields, keeps the rest, drops empty rows', () async {
    final repo = InMemoryDailyMetricRepository();
    await repo.upsert(
      day,
      caloriesEaten: 1800,
      steps: 8000,
      caloriesBurnedActive: 400,
      caloriesBurnedBasal: 1600,
      loggingStatus: LoggingStatus.logged,
    );
    await repo.upsert(healthOnlyDay, steps: 42);
    await repo.upsert(cleanDay, caloriesEaten: 2000);

    final result = await clearLegacyHealthFields(repo);

    expect((result as Ok<int>).value, 2);
    expect(await all(repo), [
      DailyMetric(
        date: day,
        caloriesEaten: 1800,
        loggingStatus: LoggingStatus.logged,
      ),
      DailyMetric(date: cleanDay, caloriesEaten: 2000),
    ]);
  });

  test('is idempotent: a clean store is Ok(0) and writes nothing', () async {
    final inner = InMemoryDailyMetricRepository();
    await inner.upsert(day, caloriesEaten: 1800, steps: 1);
    expect(((await clearLegacyHealthFields(inner)) as Ok<int>).value, 1);

    final spy = _SpyRepository(inner);
    expect(((await clearLegacyHealthFields(spy)) as Ok<int>).value, 0);
    expect(spy.clears, isEmpty);
  });

  test('clears exactly the Health fields a row has', () async {
    final inner = InMemoryDailyMetricRepository();
    await inner.upsert(day, caloriesEaten: 1800, caloriesBurnedBasal: 1600);
    final spy = _SpyRepository(inner);

    await clearLegacyHealthFields(spy);

    expect(spy.clears, hasLength(1));
    expect(spy.clears.single.$1, day);
    expect(spy.clears.single.$2, {DailyMetricField.caloriesBurnedBasal});
  });

  test('a failed read is that Err', () async {
    final spy = _SpyRepository(InMemoryDailyMetricRepository())
      ..rangeFailure = const UnknownFailure('locked');
    expect(
      await clearLegacyHealthFields(spy),
      isA<Err<int>>().having(
        (e) => e.failure,
        'failure',
        const UnknownFailure('locked'),
      ),
    );
  });

  test('a failed clear stops and is that Err', () async {
    final inner = InMemoryDailyMetricRepository();
    await inner.upsert(day, steps: 1);
    await inner.upsert(healthOnlyDay, steps: 2);
    final spy = _SpyRepository(inner)
      ..clearFailure = const UnknownFailure('nope');

    expect(
      await clearLegacyHealthFields(spy),
      isA<Err<int>>().having(
        (e) => e.failure,
        'failure',
        const UnknownFailure('nope'),
      ),
    );
    expect(spy.clears, hasLength(1));
  });
}

/// Forwards to [_inner], recording every `clearFields` and failing on
/// demand. No other write is expected from the cleanup.
class _SpyRepository implements DailyMetricRepository {
  _SpyRepository(this._inner);

  final DailyMetricRepository _inner;
  final List<(DateTime, Set<DailyMetricField>)> clears = [];
  Failure? rangeFailure;
  Failure? clearFailure;

  @override
  ResultFuture<DailyMetric?> getByDate(DateTime date) => _inner.getByDate(date);

  @override
  ResultFuture<List<DailyMetric>> getRange(DateTime start, DateTime end) {
    final failure = rangeFailure;
    if (failure != null) return Future.value(Err(failure));
    return _inner.getRange(start, end);
  }

  @override
  ResultFuture<DailyMetric> upsert(
    DateTime date, {
    int? caloriesEaten,
    int? caloriesBurnedActive,
    int? caloriesBurnedBasal,
    int? steps,
    LoggingStatus? loggingStatus,
  }) => fail('the cleanup must never upsert');

  @override
  ResultFuture<Unit> clearFields(DateTime date, Set<DailyMetricField> fields) {
    clears.add((date, fields));
    final failure = clearFailure;
    if (failure != null) return Future.value(Err(failure));
    return _inner.clearFields(date, fields);
  }

  @override
  ResultFuture<Unit> delete(DateTime date) =>
      fail('the cleanup must never delete');
}
