import 'dart:io';

import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:daily_metrics_data/testing/daily_metric_repository_contract.dart';
import 'package:daily_metrics_data/testing/daily_metrics_store_test_control.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// `SwiftDataDailyMetricRepository` against real SwiftData through the real
/// `daily_metrics_store` plugin. Runs on a separate local `integration_test`
/// store (never CloudKit, never the user's data), emptied before each test.
///
/// `flutter test integration_test/daily_metrics_store_test.dart -d macos`
/// (or an iOS simulator id).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await DailyMetricsStoreTestControl.useStore('integration_test');
    await DailyMetricsStoreTestControl.reset();
  });

  tearDownAll(() => DailyMetricsStoreTestControl.useStore(null));

  runDailyMetricRepositoryContractTests(SwiftDataDailyMetricRepository.new);

  final day = DateTime(2026, 8, 24);

  Future<DailyMetric?> read(DailyMetricRepository repo, DateTime date) async =>
      ((await repo.getByDate(date)) as Ok<DailyMetric?>).value;

  testWidgets('a row survives reopening the store from disk', (_) async {
    final written = DailyMetric(
      date: day,
      caloriesEaten: 0,
      caloriesBurnedActive: 400,
      caloriesBurnedBasal: 1600,
      steps: 8000,
      loggingStatus: LoggingStatus.partial,
    );
    await SwiftDataDailyMetricRepository().upsert(
      DateTime(2026, 8, 24, 21, 45),
      caloriesEaten: 0,
      caloriesBurnedActive: 400,
      caloriesBurnedBasal: 1600,
      steps: 8000,
      loggingStatus: LoggingStatus.partial,
    );

    // A new ModelContainer over the same file, then a new repository.
    await DailyMetricsStoreTestControl.useStore('integration_test');
    final reopened = SwiftDataDailyMetricRepository();

    expect(await read(reopened, day), written);
  });

  group('same-day duplicates (two devices, before CloudKit syncs)', () {
    Map<String, Object?> row({
      int? caloriesEaten,
      int? steps,
      String? loggingStatus,
    }) => {
      'date': '2026-08-24',
      'caloriesEaten': caloriesEaten,
      'caloriesBurnedActive': null,
      'caloriesBurnedBasal': null,
      'steps': steps,
      'loggingStatus': loggingStatus,
    };

    Future<void> insertDuplicates() async {
      await DailyMetricsStoreTestControl.insertRecord(
        row(caloriesEaten: 1500, steps: 6000, loggingStatus: 'logged'),
        modifiedAt: DateTime(2026, 8, 24, 9),
      );
      await DailyMetricsStoreTestControl.insertRecord(
        row(caloriesEaten: 1850, loggingStatus: 'partial'),
        modifiedAt: DateTime(2026, 8, 24, 21),
      );
    }

    final merged = DailyMetric(
      date: day,
      caloriesEaten: 1850,
      steps: 6000,
      loggingStatus: LoggingStatus.partial,
    );

    testWidgets('getByDate merges them, newest non-null field wins', (_) async {
      await insertDuplicates();

      expect(await read(SwiftDataDailyMetricRepository(), day), merged);
    });

    testWidgets('getRange merges them into one row', (_) async {
      await insertDuplicates();
      await DailyMetricsStoreTestControl.insertRecord({
        ...row(steps: 3000),
        'date': '2026-08-25',
      }, modifiedAt: DateTime(2026, 8, 25));

      final result = await SwiftDataDailyMetricRepository().getRange(
        DateTime(2026, 8, 20),
        DateTime(2026, 8, 30),
      );

      expect((result as Ok<List<DailyMetric>>).value, [
        merged,
        DailyMetric(date: DateTime(2026, 8, 25), steps: 3000),
      ]);
    });

    testWidgets('the merge is saved: the extras are gone from disk', (_) async {
      await insertDuplicates();
      await SwiftDataDailyMetricRepository().getByDate(day);

      // Reopen, then delete: if an extra record had survived, the day
      // would come back after removing the merged one.
      await DailyMetricsStoreTestControl.useStore('integration_test');
      final reopened = SwiftDataDailyMetricRepository();
      expect(await read(reopened, day), merged);
      await reopened.delete(day);
      expect(await read(reopened, day), isNull);
    });

    testWidgets('equal modifiedAt: the same merge whatever the insertion '
        'order', (_) async {
      // Same instant, conflicting fields: only the value tie-breaker
      // decides. 1850 > 1500 in the first differing field, so the second
      // row ranks higher on every device.
      final sameInstant = DateTime(2026, 8, 24, 12);
      final first = row(
        caloriesEaten: 1500,
        steps: 6000,
        loggingStatus: 'logged',
      );
      final second = row(caloriesEaten: 1850, loggingStatus: 'partial');

      Future<DailyMetric?> mergeInOrder(List<Map<String, Object?>> rows) async {
        await DailyMetricsStoreTestControl.reset();
        for (final r in rows) {
          await DailyMetricsStoreTestControl.insertRecord(
            r,
            modifiedAt: sameInstant,
          );
        }
        // Reopened, so the fetch order comes from disk, not the context.
        await DailyMetricsStoreTestControl.useStore('integration_test');
        return await read(SwiftDataDailyMetricRepository(), day);
      }

      expect(await mergeInOrder([first, second]), merged);
      expect(await mergeInOrder([second, first]), merged);
    });

    testWidgets('an upsert over duplicates leaves one merged row', (_) async {
      await insertDuplicates();
      final repo = SwiftDataDailyMetricRepository();

      await repo.upsert(day, caloriesBurnedActive: 400);
      await repo.clearFields(day, {DailyMetricField.steps});

      expect(
        await read(repo, day),
        merged.copyWith(caloriesBurnedActive: 400, steps: null),
      );
    });
  });

  group('remote changes (#73)', () {
    Map<String, Object?> row(String date, int caloriesEaten) => {
      'date': date,
      'caloriesEaten': caloriesEaten,
      'caloriesBurnedActive': null,
      'caloriesBurnedBasal': null,
      'steps': null,
      'loggingStatus': null,
    };

    /// Collects change events until the returned function is called.
    (List<void>, Future<void> Function()) listen() {
      final events = <void>[];
      final subscription = dailyMetricsRemoteChanges().listen(events.add);
      return (events, subscription.cancel);
    }

    // Longer than the native 400 ms debounce plus the history check.
    const settle = Duration(milliseconds: 1500);

    testWidgets('a write through another context (how a CloudKit import '
        'lands) emits one event, and the row reads back', (_) async {
      final (events, cancel) = listen();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await DailyMetricsStoreTestControl.simulateImport(
        row('2026-08-24', 1850),
        modifiedAt: DateTime(2026, 8, 24, 9),
      );
      await Future<void>.delayed(settle);
      await cancel();

      expect(events, hasLength(1));
      expect(
        (await read(SwiftDataDailyMetricRepository(), day))?.caloriesEaten,
        1850,
      );
    });

    testWidgets('a burst of imports emits a single event', (_) async {
      final (events, cancel) = listen();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      for (var i = 1; i <= 5; i++) {
        await DailyMetricsStoreTestControl.simulateImport(
          row('2026-08-2$i', 1000 + i),
          modifiedAt: DateTime(2026, 8, 20 + i),
        );
      }
      await Future<void>.delayed(settle);
      await cancel();

      expect(events, hasLength(1));
    });

    testWidgets("the app's own writes emit nothing", (_) async {
      if (!await DailyMetricsStoreTestControl.filtersOwnWrites()) {
        // iOS 17 / macOS 14: no persistent history, so own writes emit too.
        markTestSkipped(
          'No persistent-history filtering here (needs iOS 18 / macOS 15): '
          "the app's own writes emit by design",
        );
        return;
      }
      final (events, cancel) = listen();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final repo = SwiftDataDailyMetricRepository();
      await repo.upsert(day, caloriesEaten: 1850, steps: 8000);
      await repo.clearFields(day, {DailyMetricField.steps});
      await repo.delete(day);
      await Future<void>.delayed(settle);
      await cancel();

      expect(events, isEmpty);
    });
  });

  testWidgets('test-only calls are refused on the real store, which is '
      'never opened', (_) async {
    // Where DailyMetricsStore puts the real store: path_provider's support
    // directory (which already includes the bundle id on macOS).
    final support = await getApplicationSupportDirectory();
    final realStore = File('${support.path}/DailyMetrics/steady.store');
    if (realStore.existsSync()) {
      // Real data may be there; a regression in the guard would wipe it.
      markTestSkipped('The real store exists on this device; not risking it');
      return;
    }
    final refused = throwsA(
      isA<PlatformException>().having((e) => e.code, 'code', 'not_test_store'),
    );

    await DailyMetricsStoreTestControl.useStore(null);
    await expectLater(DailyMetricsStoreTestControl.reset(), refused);
    await expectLater(
      DailyMetricsStoreTestControl.insertRecord({
        'date': '2026-08-24',
        for (final field in const [
          'caloriesEaten',
          'caloriesBurnedActive',
          'caloriesBurnedBasal',
          'steps',
          'loggingStatus',
        ])
          field: null,
      }, modifiedAt: DateTime(2026, 8, 24)),
      refused,
    );
    await expectLater(
      DailyMetricsStoreTestControl.simulateImport({
        'date': '2026-08-24',
        for (final field in const [
          'caloriesEaten',
          'caloriesBurnedActive',
          'caloriesBurnedBasal',
          'steps',
          'loggingStatus',
        ])
          field: null,
      }, modifiedAt: DateTime(2026, 8, 24)),
      refused,
    );

    expect(realStore.existsSync(), isFalse, reason: 'opened the real store');
  });
}
