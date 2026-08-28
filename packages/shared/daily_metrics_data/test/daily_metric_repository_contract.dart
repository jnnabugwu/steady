import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs the shared `DailyMetricRepository` contract against whatever
/// implementation [build] constructs. Used against the in-memory fake today
/// and the real SwiftData-backed implementation later, so behavioral parity
/// between the two is enforced by construction rather than hand-copied
/// assertions across two test files.
void runDailyMetricRepositoryContractTests(
  DailyMetricRepository Function() build,
) {
  group('DailyMetricRepository contract', () {
    test('getByDate returns Ok(null) when nothing stored', () async {
      final repo = build();
      final result = await repo.getByDate(DateTime(2026, 8, 24));
      expect(result, isA<Ok<DailyMetric?>>());
      expect((result as Ok<DailyMetric?>).value, isNull);
    });

    test('upsert on empty store sets only given fields', () async {
      final repo = build();
      final result = await repo.upsert(
        DateTime(2026, 8, 24),
        caloriesEaten: 2000,
      );
      final metric = (result as Ok<DailyMetric>).value;
      expect(metric.caloriesEaten, 2000);
      expect(metric.steps, isNull);
      expect(metric.loggingStatus, isNull);
    });

    test(
      'upsert on existing row overwrites only given fields, preserves rest',
      () async {
        final repo = build();
        await repo.upsert(
          DateTime(2026, 8, 24),
          caloriesBurnedActive: 400,
          steps: 8000,
        );
        final result = await repo.upsert(
          DateTime(2026, 8, 24),
          caloriesEaten: 2000,
        );
        final metric = (result as Ok<DailyMetric>).value;
        expect(metric.caloriesEaten, 2000);
        expect(metric.caloriesBurnedActive, 400);
        expect(metric.steps, 8000);
      },
    );

    test('getRange returns sorted, inclusive-bounded results', () async {
      final repo = build();
      await repo.upsert(DateTime(2026, 8, 20), caloriesEaten: 1);
      await repo.upsert(DateTime(2026, 8, 22), caloriesEaten: 2);
      await repo.upsert(DateTime(2026, 8, 24), caloriesEaten: 3);
      await repo.upsert(DateTime(2026, 8, 26), caloriesEaten: 4);

      final result = await repo.getRange(
        DateTime(2026, 8, 22),
        DateTime(2026, 8, 24),
      );
      final rows = (result as Ok<List<DailyMetric>>).value;
      expect(rows.map((m) => m.caloriesEaten), [2, 3]);
    });

    test(
      'getRange with start after end returns Err(ValidationFailure)',
      () async {
        final repo = build();
        final result = await repo.getRange(
          DateTime(2026, 8, 24),
          DateTime(2026, 8, 20),
        );
        expect(result, isA<Err<List<DailyMetric>>>());
        expect(
          (result as Err<List<DailyMetric>>).failure,
          isA<ValidationFailure>(),
        );
      },
    );

    test('delete removes a row', () async {
      final repo = build();
      await repo.upsert(DateTime(2026, 8, 24), caloriesEaten: 2000);
      await repo.delete(DateTime(2026, 8, 24));
      final result = await repo.getByDate(DateTime(2026, 8, 24));
      expect((result as Ok<DailyMetric?>).value, isNull);
    });
  });
}
