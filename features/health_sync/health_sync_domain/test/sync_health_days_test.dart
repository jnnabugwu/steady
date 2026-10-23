import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_domain/health_sync_domain.dart';

import 'helpers/fake_health_kit_repository.dart';

/// The real in-memory shared store, counting writes and optionally failing.
class _CountingStore extends InMemoryDailyMetricRepository {
  int upserts = 0;
  Failure? rangeFailure;
  Failure? upsertFailure;

  @override
  ResultFuture<List<DailyMetric>> getRange(DateTime start, DateTime end) {
    final failure = rangeFailure;
    if (failure != null) return Future.value(Err(failure));
    return super.getRange(start, end);
  }

  @override
  ResultFuture<DailyMetric> upsert(
    DateTime date, {
    int? caloriesEaten,
    int? caloriesBurnedActive,
    int? caloriesBurnedBasal,
    int? steps,
    LoggingStatus? loggingStatus,
  }) {
    upserts++;
    final failure = upsertFailure;
    if (failure != null) return Future.value(Err(failure));
    return super.upsert(
      date,
      caloriesEaten: caloriesEaten,
      caloriesBurnedActive: caloriesBurnedActive,
      caloriesBurnedBasal: caloriesBurnedBasal,
      steps: steps,
      loggingStatus: loggingStatus,
    );
  }
}

void main() {
  final today = DateTime(2026, 10, 23, 14, 5);
  final day = DateTime(2026, 10, 22);
  late _CountingStore store;

  setUp(() => store = _CountingStore());

  Future<Result<HealthSyncReport>> sync(
    FakeHealthKitRepository health, {
    int days = healthSyncWindowDays,
  }) => syncHealthDays(
    health: health,
    dailyMetrics: store,
    today: today,
    days: days,
  );

  Future<DailyMetric?> row(DateTime date) async =>
      ((await store.getByDate(date)) as Ok<DailyMetric?>).value;

  HealthSyncReport report(Result<HealthSyncReport> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => fail('Expected Ok, got $failure'),
  };

  test('asks Health for the 30 local days ending today', () async {
    final health = FakeHealthKitRepository();
    await sync(health);
    expect(health.ranges.single, (
      DateTime(2026, 9, 24),
      DateTime(2026, 10, 23),
    ));
  });

  test('writes the three Health fields onto a new row', () async {
    final health = FakeHealthKitRepository([
      HealthDayTotals(
        date: day,
        steps: 8123,
        caloriesBurnedActive: 412,
        caloriesBurnedBasal: 1650,
      ),
    ]);

    final result = report(await sync(health));

    expect(result, const HealthSyncReport(daysUpdated: 1, daysWithData: 1));
    expect(
      await row(day),
      DailyMetric(
        date: day,
        steps: 8123,
        caloriesBurnedActive: 412,
        caloriesBurnedBasal: 1650,
      ),
    );
  });

  test('preserves caloriesEaten and loggingStatus', () async {
    await store.upsert(
      day,
      caloriesEaten: 1850,
      loggingStatus: LoggingStatus.partial,
      steps: 100,
    );
    final health = FakeHealthKitRepository([
      HealthDayTotals(date: day, steps: 9000, caloriesBurnedActive: 500),
    ]);

    await sync(health);

    expect(
      await row(day),
      DailyMetric(
        date: day,
        caloriesEaten: 1850,
        loggingStatus: LoggingStatus.partial,
        steps: 9000,
        caloriesBurnedActive: 500,
      ),
    );
  });

  test('skips days whose Health values are unchanged', () async {
    final health = FakeHealthKitRepository([
      HealthDayTotals(
        date: day,
        steps: 8123,
        caloriesBurnedActive: 412,
        caloriesBurnedBasal: 1650,
      ),
    ]);
    await sync(health);
    store.upserts = 0;

    final again = report(await sync(health));

    expect(again, const HealthSyncReport(daysUpdated: 0, daysWithData: 1));
    expect(store.upserts, 0);
  });

  test('writes only the field that changed', () async {
    await store.upsert(day, steps: 5000, caloriesBurnedActive: 300);
    final health = FakeHealthKitRepository([
      HealthDayTotals(date: day, steps: 5000, caloriesBurnedActive: 320),
    ]);

    expect(report(await sync(health)).daysUpdated, 1);
    expect(
      await row(day),
      DailyMetric(date: day, steps: 5000, caloriesBurnedActive: 320),
    );
  });

  test('a day with no Health data creates no row', () async {
    final result = report(await sync(FakeHealthKitRepository()));

    expect(result, const HealthSyncReport(daysUpdated: 0, daysWithData: 0));
    expect(store.upserts, 0);
    final all = await store.getRange(DateTime(2026), DateTime(2027));
    expect((all as Ok<List<DailyMetric>>).value, isEmpty);
  });

  test('a Health null never clears a stored value', () async {
    await store.upsert(
      day,
      steps: 7000,
      caloriesBurnedActive: 400,
      caloriesBurnedBasal: 1600,
    );
    // Steps unknown now (e.g. read access to steps was turned off).
    final health = FakeHealthKitRepository([
      HealthDayTotals(
        date: day,
        caloriesBurnedActive: 400,
        caloriesBurnedBasal: 1600,
      ),
    ]);

    expect(report(await sync(health)).daysUpdated, 0);
    expect((await row(day))?.steps, 7000);
  });

  test('a recorded zero is a value, written like any other', () async {
    final health = FakeHealthKitRepository([
      HealthDayTotals(date: day, steps: 0),
    ]);

    await sync(health);

    expect((await row(day))?.steps, 0);
  });

  test('days below 1 is a ValidationFailure, without reading Health', () async {
    final health = FakeHealthKitRepository();
    final result = await sync(health, days: 0);
    expect((result as Err).failure, isA<ValidationFailure>());
    expect(health.ranges, isEmpty);
  });

  group('propagates Failures', () {
    const failure = PlatformChannelFailure('Health said no', code: 'x');

    test('from reading Health, writing nothing', () async {
      final health = FakeHealthKitRepository([
        HealthDayTotals(date: day, steps: 1),
      ])..totalsFailure = failure;

      final result = await sync(health);

      expect((result as Err).failure, failure);
      expect(store.upserts, 0);
    });

    test('from reading the store, writing nothing', () async {
      store.rangeFailure = const UnknownFailure('store unreadable');
      final health = FakeHealthKitRepository([
        HealthDayTotals(date: day, steps: 1),
      ]);

      final result = await sync(health);

      expect((result as Err).failure, const UnknownFailure('store unreadable'));
      expect(store.upserts, 0);
    });

    test('from a write, stopping there', () async {
      store.upsertFailure = const UnknownFailure('write failed');
      final health = FakeHealthKitRepository([
        HealthDayTotals(date: day, steps: 1),
        HealthDayTotals(date: DateTime(2026, 10, 23), steps: 2),
      ]);

      final result = await sync(health);

      expect((result as Err).failure, const UnknownFailure('write failed'));
      expect(store.upserts, 1);
    });
  });
}
