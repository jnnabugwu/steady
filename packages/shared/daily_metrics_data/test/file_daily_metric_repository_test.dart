import 'dart:io';

import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:daily_metrics_data/testing/daily_metric_repository_contract.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late File file;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('file_daily_metrics_');
    file = File('${tempDir.path}/daily_metrics.json');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  // A fresh file per contract test: setUp runs before each one.
  runDailyMetricRepositoryContractTests(() => FileDailyMetricRepository(file));

  group('FileDailyMetricRepository persistence', () {
    test('a fresh instance reads back every field', () async {
      final a = FileDailyMetricRepository(file);
      await a.upsert(
        DateTime(2026, 8, 24, 15, 30),
        caloriesEaten: 2000,
        caloriesBurnedActive: 400,
        caloriesBurnedBasal: 1600,
        steps: 8000,
        loggingStatus: LoggingStatus.partial,
      );
      await a.upsert(DateTime(2026, 8, 25), caloriesEaten: 0);

      final b = FileDailyMetricRepository(file);
      final row = ((await b.getByDate(DateTime(2026, 8, 24))) as Ok).value;
      expect(
        row,
        DailyMetric(
          date: DateTime(2026, 8, 24),
          caloriesEaten: 2000,
          caloriesBurnedActive: 400,
          caloriesBurnedBasal: 1600,
          steps: 8000,
          loggingStatus: LoggingStatus.partial,
        ),
      );
      final zero = ((await b.getByDate(DateTime(2026, 8, 25))) as Ok).value;
      expect(zero, DailyMetric(date: DateTime(2026, 8, 25), caloriesEaten: 0));
    });

    test('partial-field merge survives a reload', () async {
      final a = FileDailyMetricRepository(file);
      await a.upsert(DateTime(2026, 8, 24), steps: 8000);

      final b = FileDailyMetricRepository(file);
      await b.upsert(
        DateTime(2026, 8, 24),
        loggingStatus: LoggingStatus.logged,
      );

      final c = FileDailyMetricRepository(file);
      final row = ((await c.getByDate(DateTime(2026, 8, 24))) as Ok).value;
      expect(
        row,
        DailyMetric(
          date: DateTime(2026, 8, 24),
          steps: 8000,
          loggingStatus: LoggingStatus.logged,
        ),
      );
    });

    test('delete survives a reload', () async {
      final a = FileDailyMetricRepository(file);
      await a.upsert(DateTime(2026, 8, 24), steps: 1);
      await a.upsert(DateTime(2026, 8, 25), steps: 2);
      await a.delete(DateTime(2026, 8, 24));

      final b = FileDailyMetricRepository(file);
      final rows = ((await b.getRange(
        DateTime(2026, 8),
        DateTime(2026, 8, 31),
      )) as Ok<List<DailyMetric>>).value;
      expect(rows.map((m) => m.steps), [2]);
    });

    test('dates are stored as yyyy-MM-dd in a version 1 envelope', () async {
      await FileDailyMetricRepository(file)
          .upsert(DateTime(2026, 3, 5, 23, 59), steps: 1);
      final text = file.readAsStringSync();
      expect(text, contains('"version":1'));
      expect(text, contains('"date":"2026-03-05"'));
      expect(File('${file.path}.tmp').existsSync(), isFalse);
    });
  });

  group('FileDailyMetricRepository missing file', () {
    test('reads as an empty store without creating the file', () async {
      final repo = FileDailyMetricRepository(file);
      final result = await repo.getRange(
        DateTime(2026),
        DateTime(2026, 12, 31),
      );
      expect((result as Ok<List<DailyMetric>>).value, isEmpty);
      expect(file.existsSync(), isFalse);
    });

    test('creates missing parent directories on first write', () async {
      final nested = File('${tempDir.path}/a/b/c/daily_metrics.json');
      final result = await FileDailyMetricRepository(nested)
          .upsert(DateTime(2026, 8, 24), steps: 10);
      expect(result, isA<Ok<DailyMetric>>());
      expect(nested.existsSync(), isTrue);
    });
  });

  group('FileDailyMetricRepository file format', () {
    test('duplicate dates in a hand-edited file merge on load', () async {
      file.writeAsStringSync(
        '{"version":1,"metrics":['
        '{"date":"2026-08-24","caloriesEaten":2000},'
        '{"date":"2026-08-24","steps":8000}]}',
      );

      final row = ((await FileDailyMetricRepository(
        file,
      ).getByDate(DateTime(2026, 8, 24))) as Ok).value;

      expect(
        row,
        DailyMetric(
          date: DateTime(2026, 8, 24),
          caloriesEaten: 2000,
          steps: 8000,
        ),
      );
    });

    test(
      'a year the file format cannot hold is rejected, not written',
      () async {
        final repo = FileDailyMetricRepository(file);

        final result = await repo.upsert(DateTime(10000), steps: 1);

        expect((result as Err).failure, isA<ValidationFailure>());
        expect(file.existsSync(), isFalse);
      },
    );

    test(
      'clearFields persists, and clearing every field drops the row',
      () async {
        final repo = FileDailyMetricRepository(file);
        final day = DateTime(2026, 8, 24);
        await repo.upsert(day, caloriesEaten: 2000, steps: 8000);
        await repo.clearFields(day, {DailyMetricField.steps});

        final reread = ((await FileDailyMetricRepository(
          file,
        ).getByDate(day)) as Ok).value;
        expect(reread, DailyMetric(date: day, caloriesEaten: 2000));

        await repo.clearFields(day, {DailyMetricField.caloriesEaten});
        expect(
          ((await FileDailyMetricRepository(file).getByDate(day)) as Ok).value,
          isNull,
        );
      },
    );
  });

  group('FileDailyMetricRepository write failure', () {
    // A read-only parent directory makes creating `<file>.tmp` fail.
    void makeReadOnly() {
      Process.runSync('chmod', ['555', tempDir.path]);
      addTearDown(() => Process.runSync('chmod', ['755', tempDir.path]));
    }

    test('a failed upsert returns Err and keeps the previous row', () async {
      final repo = FileDailyMetricRepository(file);
      final day = DateTime(2026, 8, 24);
      await repo.upsert(day, caloriesEaten: 2000);
      makeReadOnly();

      final result = await repo.upsert(day, caloriesEaten: 2500, steps: 10);

      expect((result as Err).failure, isA<UnknownFailure>());
      expect(
        ((await repo.getByDate(day)) as Ok).value,
        DailyMetric(date: day, caloriesEaten: 2000),
      );
    });

    test('a failed clearFields returns Err and keeps the field', () async {
      final repo = FileDailyMetricRepository(file);
      final day = DateTime(2026, 8, 24);
      await repo.upsert(day, caloriesEaten: 2000, steps: 8000);
      makeReadOnly();

      final result = await repo.clearFields(day, {DailyMetricField.steps});

      expect((result as Err).failure, isA<UnknownFailure>());
      expect(
        ((await repo.getByDate(day)) as Ok).value,
        DailyMetric(date: day, caloriesEaten: 2000, steps: 8000),
      );
    });

    test('a failed delete returns Err and keeps the row', () async {
      final repo = FileDailyMetricRepository(file);
      final day = DateTime(2026, 8, 24);
      await repo.upsert(day, caloriesEaten: 2000);
      makeReadOnly();

      final result = await repo.delete(day);

      expect((result as Err).failure, isA<UnknownFailure>());
      expect(
        ((await repo.getByDate(day)) as Ok).value,
        DailyMetric(date: day, caloriesEaten: 2000),
      );
    });
  });

  group('FileDailyMetricRepository corrupt file', () {
    for (final (label, contents) in [
      ('empty file', ''),
      ('invalid JSON', '{not json'),
      ('wrong version', '{"version":2,"metrics":[]}'),
      ('bad date', '{"version":1,"metrics":[{"date":"2026-02-31"}]}'),
      (
        'unknown status',
        '{"version":1,"metrics":[{"date":"2026-08-24",'
            '"loggingStatus":"maybe"}]}',
      ),
    ]) {
      test('$label: returns Err and leaves the file untouched', () async {
        file.writeAsStringSync(contents);
        final repo = FileDailyMetricRepository(file);

        final read = await repo.getByDate(DateTime(2026, 8, 24));
        expect((read as Err).failure, isA<UnknownFailure>());

        final write = await repo.upsert(DateTime(2026, 8, 24), steps: 1);
        expect((write as Err).failure, isA<UnknownFailure>());

        final delete = await repo.delete(DateTime(2026, 8, 24));
        expect((delete as Err).failure, isA<UnknownFailure>());

        final clear = await repo.clearFields(DateTime(2026, 8, 24), {
          DailyMetricField.steps,
        });
        expect((clear as Err).failure, isA<UnknownFailure>());

        expect(file.readAsStringSync(), contents);
      });
    }

    test('recovers once the file is removed', () async {
      file.writeAsStringSync('{not json');
      final repo = FileDailyMetricRepository(file);
      expect(await repo.getByDate(DateTime(2026, 8, 24)), isA<Err<Object?>>());

      file.deleteSync();
      expect(
        await repo.upsert(DateTime(2026, 8, 24), steps: 1),
        isA<Ok<DailyMetric>>(),
      );
    });
  });

  group('FileDailyMetricRepository concurrency', () {
    test('50 concurrent upserts on different days all persist', () async {
      final repo = FileDailyMetricRepository(file);
      final start = DateTime(2026);
      final results = await Future.wait([
        for (var i = 0; i < 50; i++)
          repo.upsert(DateTime(2026, 1, 1 + i), steps: i),
      ]);
      expect(results, everyElement(isA<Ok<DailyMetric>>()));

      final reloaded = FileDailyMetricRepository(file);
      final rows = ((await reloaded.getRange(
        start,
        DateTime(2026, 12, 31),
      )) as Ok<List<DailyMetric>>).value;
      expect(rows.map((m) => m.steps), [for (var i = 0; i < 50; i++) i]);
    });

    test('concurrent upserts on the same day merge, not clobber', () async {
      final repo = FileDailyMetricRepository(file);
      final day = DateTime(2026, 8, 24);
      await Future.wait([
        repo.upsert(day, caloriesEaten: 2000),
        repo.upsert(day, steps: 8000),
        repo.upsert(day, loggingStatus: LoggingStatus.skipped),
      ]);
      final row =
          ((await FileDailyMetricRepository(file).getByDate(day)) as Ok).value;
      expect(
        row,
        DailyMetric(
          date: day,
          caloriesEaten: 2000,
          steps: 8000,
          loggingStatus: LoggingStatus.skipped,
        ),
      );
    });
  });
}
