import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_data/health_sync_data.dart';
import 'package:health_sync_domain/health_sync_domain.dart';

void main() {
  test('requestAuthorization moves notDetermined to requested', () async {
    final repo = InMemoryHealthKitRepository();
    await repo.requestAuthorization();
    expect(
      (await repo.authorizationStatus() as Ok).value,
      HealthAuthorizationStatus.requested,
    );
    expect(repo.requestAuthorizationCalls, 1);
  });

  test('dailyTotals fills the range, one row per day', () async {
    final repo = InMemoryHealthKitRepository(
      days: [HealthDayTotals(date: DateTime(2026, 10, 22), steps: 5)],
    );
    final result = await repo.dailyTotals(
      DateTime(2026, 10, 21),
      DateTime(2026, 10, 23, 12),
    );
    expect((result as Ok<List<HealthDayTotals>>).value, [
      HealthDayTotals(date: DateTime(2026, 10, 21)),
      HealthDayTotals(date: DateTime(2026, 10, 22), steps: 5),
      HealthDayTotals(date: DateTime(2026, 10, 23)),
    ]);
  });

  test('days are keyed and dated by local calendar day', () async {
    final repo = InMemoryHealthKitRepository(
      days: [HealthDayTotals(date: DateTime(2026, 10, 22, 15), steps: 5)],
    );
    final result = await repo.dailyTotals(
      DateTime(2026, 10, 22),
      DateTime(2026, 10, 22),
    );
    expect((result as Ok<List<HealthDayTotals>>).value, [
      HealthDayTotals(date: DateTime(2026, 10, 22), steps: 5),
    ]);
  });

  test('dailyTotals converts UTC bounds to local days', () async {
    final repo = InMemoryHealthKitRepository();
    final start = DateTime.utc(2026, 10, 21, 12);
    final end = DateTime.utc(2026, 10, 22, 12);
    final result = await repo.dailyTotals(start, end);
    final startDay = start.toLocal();
    final endDay = end.toLocal();
    expect((result as Ok<List<HealthDayTotals>>).value, [
      for (
        var d = DateTime(startDay.year, startDay.month, startDay.day);
        !d.isAfter(DateTime(endDay.year, endDay.month, endDay.day));
        d = DateTime(d.year, d.month, d.day + 1)
      )
        HealthDayTotals(date: d),
    ]);
  });

  test('dailyTotals rejects start after end', () async {
    final repo = InMemoryHealthKitRepository();
    expect(
      await repo.dailyTotals(DateTime(2026, 10, 23), DateTime(2026, 10, 22)),
      isA<Err<List<HealthDayTotals>>>().having(
        (e) => e.failure,
        'failure',
        isA<ValidationFailure>(),
      ),
    );
  });

  test('dailyTotals rejects years outside 0000 to 9999', () async {
    final repo = InMemoryHealthKitRepository();
    for (final (start, end) in [
      (DateTime(-1, 12, 31), DateTime(2026)),
      (DateTime(2026), DateTime(10000)),
    ]) {
      expect(
        await repo.dailyTotals(start, end),
        isA<Err<List<HealthDayTotals>>>().having(
          (e) => e.failure,
          'failure',
          isA<ValidationFailure>(),
        ),
      );
    }
  });

  test('failure makes every method an Err', () async {
    final repo = InMemoryHealthKitRepository()
      ..failure = const UnknownFailure('nope');
    expect(await repo.isAvailable(), isA<Err<bool>>());
    expect(
      await repo.authorizationStatus(),
      isA<Err<HealthAuthorizationStatus>>(),
    );
    expect(await repo.requestAuthorization(), isA<Err<Unit>>());
    expect(
      await repo.dailyTotals(DateTime(2026), DateTime(2026)),
      isA<Err<List<HealthDayTotals>>>(),
    );
  });
}
