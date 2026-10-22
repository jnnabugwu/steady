import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:daily_metrics_data/testing/daily_metric_repository_contract.dart';
import 'package:daily_metrics_data/testing/daily_metrics_store_test_control.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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
}
