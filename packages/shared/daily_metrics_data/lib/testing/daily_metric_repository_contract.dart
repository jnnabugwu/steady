import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs the shared `DailyMetricRepository` contract against whatever
/// implementation [build] constructs: the in-memory and file repositories,
/// `SwiftDataDailyMetricRepository` over a fake channel (unit tests here),
/// and the same over real SwiftData (`app/integration_test/`). Behavioral
/// parity is enforced by construction rather than hand-copied assertions.
///
/// Lives under `lib/testing/` rather than `test/` so `app/` can import it.
/// Test-only: never import it from `lib/src/`.
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

    group('clearFields', () {
      final day = DateTime(2026, 8, 24);

      Future<void> upsertEveryField(DailyMetricRepository repo) => repo.upsert(
        day,
        caloriesEaten: 2000,
        caloriesBurnedActive: 400,
        caloriesBurnedBasal: 1600,
        steps: 8000,
        loggingStatus: LoggingStatus.logged,
      );

      Future<DailyMetric?> read(
        DailyMetricRepository repo, [
        DateTime? date,
      ]) async =>
          ((await repo.getByDate(date ?? day)) as Ok<DailyMetric?>).value;

      for (final field in DailyMetricField.values) {
        test('clearing ${field.name} sets only that field to null', () async {
          final repo = build();
          await upsertEveryField(repo);

          final result = await repo.clearFields(day, {field});
          expect(result, isA<Ok<Unit>>());

          final metric = (await read(repo))!;
          for (final other in DailyMetricField.values) {
            if (other == field) {
              expect(_valueOf(metric, other), isNull, reason: other.name);
            } else {
              expect(_valueOf(metric, other), isNotNull, reason: other.name);
            }
          }
        });
      }

      test('clears several named fields at once, preserves the rest', () async {
        final repo = build();
        await upsertEveryField(repo);

        await repo.clearFields(day, {
          DailyMetricField.caloriesBurnedActive,
          DailyMetricField.steps,
        });

        expect(
          await read(repo),
          DailyMetric(
            date: day,
            caloriesEaten: 2000,
            caloriesBurnedBasal: 1600,
            loggingStatus: LoggingStatus.logged,
          ),
        );
      });

      test("clearing one feature's field leaves another feature's", () async {
        final repo = build();
        // checkin writes loggingStatus, pdf_import writes caloriesEaten.
        await repo.upsert(day, loggingStatus: LoggingStatus.partial);
        await repo.upsert(day, caloriesEaten: 1800);

        await repo.clearFields(day, {DailyMetricField.loggingStatus});

        final metric = (await read(repo))!;
        expect(metric.loggingStatus, isNull);
        expect(metric.caloriesEaten, 1800);
      });

      test('clearing caloriesEaten gives null, not 0', () async {
        final repo = build();
        await repo.upsert(day, caloriesEaten: 2000, steps: 8000);

        await repo.clearFields(day, {DailyMetricField.caloriesEaten});

        final metric = (await read(repo))!;
        expect(metric.caloriesEaten, isNull);
        expect(metric.caloriesEaten, isNot(0));
      });

      test('a stored 0 survives clearing a different field', () async {
        final repo = build();
        await repo.upsert(day, caloriesEaten: 0, steps: 8000);

        await repo.clearFields(day, {DailyMetricField.steps});

        expect((await read(repo))!.caloriesEaten, 0);
      });

      test('normalizes date to midnight, same as upsert', () async {
        final repo = build();
        await repo.upsert(day, caloriesEaten: 2000, steps: 8000);

        await repo.clearFields(DateTime(2026, 8, 24, 21, 45), {
          DailyMetricField.caloriesEaten,
        });

        final metric = (await read(repo))!;
        expect(metric.caloriesEaten, isNull);
        expect(metric.steps, 8000);
      });

      test('on a day with no row is a no-op Ok and creates no row', () async {
        final repo = build();
        await repo.upsert(DateTime(2026, 8, 23), steps: 5000);

        final result = await repo.clearFields(
          day,
          DailyMetricField.values.toSet(),
        );

        expect(result, isA<Ok<Unit>>());
        expect(await read(repo), isNull);
        final range = await repo.getRange(
          DateTime(2026, 8, 20),
          DateTime(2026, 8, 30),
        );
        expect((range as Ok<List<DailyMetric>>).value.map((m) => m.date), [
          DateTime(2026, 8, 23),
        ]);
      });

      test('is idempotent', () async {
        final repo = build();
        await repo.upsert(day, caloriesEaten: 2000, steps: 8000);

        final first = await repo.clearFields(day, {
          DailyMetricField.caloriesEaten,
        });
        final afterFirst = await read(repo);
        final second = await repo.clearFields(day, {
          DailyMetricField.caloriesEaten,
        });

        expect(first, isA<Ok<Unit>>());
        expect(second, isA<Ok<Unit>>());
        expect(await read(repo), afterFirst);
        expect(afterFirst, DailyMetric(date: day, steps: 8000));
      });

      test('an empty set leaves the row unchanged', () async {
        final repo = build();
        await upsertEveryField(repo);
        final before = await read(repo);

        final result = await repo.clearFields(day, {});

        expect(result, isA<Ok<Unit>>());
        expect(await read(repo), before);
      });

      test('leaves other days untouched', () async {
        final repo = build();
        await repo.upsert(DateTime(2026, 8, 23), caloriesEaten: 1500);
        await repo.upsert(day, caloriesEaten: 2000, steps: 8000);

        await repo.clearFields(day, {DailyMetricField.caloriesEaten});

        expect((await read(repo, DateTime(2026, 8, 23)))!.caloriesEaten, 1500);
      });

      test('removes the row once every field is null', () async {
        final repo = build();
        await repo.upsert(day, caloriesEaten: 2000, steps: 8000);

        await repo.clearFields(day, {DailyMetricField.caloriesEaten});
        expect(await read(repo), isNotNull);

        await repo.clearFields(day, {DailyMetricField.steps});
        expect(await read(repo), isNull);
        final range = await repo.getRange(day, day);
        expect((range as Ok<List<DailyMetric>>).value, isEmpty);
      });

      test('a later upsert writes the cleared field again', () async {
        final repo = build();
        await repo.upsert(day, caloriesEaten: 2000, steps: 8000);
        await repo.clearFields(day, DailyMetricField.values.toSet());

        await repo.upsert(day, caloriesEaten: 1700);

        expect(await read(repo), DailyMetric(date: day, caloriesEaten: 1700));
      });
    });
  });
}

/// Reads [field] off [metric]. Exhaustive, so adding a `DailyMetricField`
/// member fails to compile here until the contract covers it.
Object? _valueOf(DailyMetric metric, DailyMetricField field) => switch (field) {
  DailyMetricField.caloriesEaten => metric.caloriesEaten,
  DailyMetricField.caloriesBurnedActive => metric.caloriesBurnedActive,
  DailyMetricField.caloriesBurnedBasal => metric.caloriesBurnedBasal,
  DailyMetricField.steps => metric.steps,
  DailyMetricField.loggingStatus => metric.loggingStatus,
};
