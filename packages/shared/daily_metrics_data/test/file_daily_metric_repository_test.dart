import 'dart:io';

import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'daily_metric_repository_contract.dart';

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

  group('FileDailyMetricRepository corrupt file', () {
    for (final (label, contents) in [
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
        expect(delete, isA<Err<Unit>>());

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
