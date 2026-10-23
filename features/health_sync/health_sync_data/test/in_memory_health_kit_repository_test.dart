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

  test('failure makes every method an Err', () async {
    final repo = InMemoryHealthKitRepository()
      ..failure = const UnknownFailure('nope');
    expect(await repo.isAvailable(), isA<Err<bool>>());
    expect(await repo.requestAuthorization(), isA<Err<Unit>>());
    expect(
      await repo.dailyTotals(DateTime(2026), DateTime(2026)),
      isA<Err<List<HealthDayTotals>>>(),
    );
  });
}
