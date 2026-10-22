import 'dart:io';

import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late File file;
  late File migrated;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('migrate_file_store_');
    file = File('${tempDir.path}/daily_metrics.json');
    migrated = File('${tempDir.path}/daily_metrics.json.migrated');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<DailyMetric?> read(DailyMetricRepository repo, DateTime day) async =>
      ((await repo.getByDate(day)) as Ok<DailyMetric?>).value;

  test('a missing file is Ok(0) and writes nothing', () async {
    final target = InMemoryDailyMetricRepository();

    final result = await migrateFileStore(file, target);

    expect((result as Ok<int>).value, 0);
    final all = await target.getRange(DateTime(2000), DateTime(2100));
    expect((all as Ok<List<DailyMetric>>).value, isEmpty);
    expect(migrated.existsSync(), isFalse);
  });

  test('copies every row, then renames the file', () async {
    final source = FileDailyMetricRepository(file);
    await source.upsert(
      DateTime(2026, 8, 24),
      caloriesEaten: 2000,
      caloriesBurnedActive: 400,
      caloriesBurnedBasal: 1600,
      steps: 8000,
      loggingStatus: LoggingStatus.partial,
    );
    await source.upsert(DateTime(2026, 8, 25), caloriesEaten: 0);
    final target = InMemoryDailyMetricRepository();

    final result = await migrateFileStore(file, target);

    expect((result as Ok<int>).value, 2);
    expect(
      await read(target, DateTime(2026, 8, 24)),
      DailyMetric(
        date: DateTime(2026, 8, 24),
        caloriesEaten: 2000,
        caloriesBurnedActive: 400,
        caloriesBurnedBasal: 1600,
        steps: 8000,
        loggingStatus: LoggingStatus.partial,
      ),
    );
    expect(
      await read(target, DateTime(2026, 8, 25)),
      DailyMetric(date: DateTime(2026, 8, 25), caloriesEaten: 0),
    );
    expect(file.existsSync(), isFalse);
    expect(migrated.existsSync(), isTrue);
  });

  test('merges: fields the file lacks keep their target values', () async {
    await FileDailyMetricRepository(file)
        .upsert(DateTime(2026, 8, 24), caloriesEaten: 1850);
    final target = InMemoryDailyMetricRepository();
    await target.upsert(
      DateTime(2026, 8, 24),
      steps: 8000,
      loggingStatus: LoggingStatus.logged,
    );

    await migrateFileStore(file, target);

    expect(
      await read(target, DateTime(2026, 8, 24)),
      DailyMetric(
        date: DateTime(2026, 8, 24),
        caloriesEaten: 1850,
        steps: 8000,
        loggingStatus: LoggingStatus.logged,
      ),
    );
  });

  test('runs once: a second launch finds nothing to migrate', () async {
    await FileDailyMetricRepository(file)
        .upsert(DateTime(2026, 8, 24), caloriesEaten: 1850);
    final target = InMemoryDailyMetricRepository();

    await migrateFileStore(file, target);
    final second = await migrateFileStore(file, target);

    expect((second as Ok<int>).value, 0);
  });

  test('a corrupt file is Err and is left untouched', () async {
    file.writeAsStringSync('{not json');
    final target = InMemoryDailyMetricRepository();

    final result = await migrateFileStore(file, target);

    expect((result as Err<int>).failure, isA<UnknownFailure>());
    expect(file.readAsStringSync(), '{not json');
    expect(migrated.existsSync(), isFalse);
  });

  test('a failing target is Err and the file stays for a retry', () async {
    await FileDailyMetricRepository(file)
        .upsert(DateTime(2026, 8, 24), caloriesEaten: 1850);

    final result = await migrateFileStore(file, _FailingRepository());

    expect((result as Err<int>).failure, isA<PlatformChannelFailure>());
    expect(file.existsSync(), isTrue);
    expect(migrated.existsSync(), isFalse);
  });
}

class _FailingRepository extends InMemoryDailyMetricRepository {
  @override
  ResultFuture<DailyMetric> upsert(
    DateTime date, {
    int? caloriesEaten,
    int? caloriesBurnedActive,
    int? caloriesBurnedBasal,
    int? steps,
    LoggingStatus? loggingStatus,
  }) async => const Err(PlatformChannelFailure('boom', code: 'save_failed'));
}
