import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_import_data/pdf_import_data.dart';
import 'package:pdf_import_domain/pdf_import_domain.dart';

/// Removing the sample export's rows touches exactly the rows it wrote:
/// a sample date with the sample's own `caloriesEaten`.
void main() {
  late InMemoryDailyMetricRepository store;
  late PdfImportRepositoryImpl repo;

  setUp(() {
    store = InMemoryDailyMetricRepository();
    repo = PdfImportRepositoryImpl(parser: CalAIParser(), dailyMetrics: store);
  });

  Future<void> importSample() async {
    final result = await repo.commitDailyTotals([
      for (final MapEntry(key: date, value: kcal)
          in sampleExportDailyTotals.entries)
        ParsedDay(date: date, caloriesEaten: kcal, foodEntries: const []),
    ]);
    expect(result, isA<Ok<Unit>>());
  }

  Future<List<DailyMetric>> allRows() async => ((await store.getRange(
    DateTime(2000),
    DateTime(2100),
  )) as Ok<List<DailyMetric>>).value;

  int count(Result<int> result) => (result as Ok<int>).value;

  test('an empty store has no sample days, and removing is a no-op', () async {
    expect(count(await repo.countSampleDays()), 0);
    expect(count(await repo.removeSampleDays()), 0);
  });

  test(
    'removes all seven imported sample days, leaving the store empty',
    () async {
      await importSample();
      expect(count(await repo.countSampleDays()), 7);

      expect(count(await repo.removeSampleDays()), 7);

      expect(await allRows(), isEmpty);
      expect(count(await repo.countSampleDays()), 0);
    },
  );

  test('leaves a real day on a sample date with different calories', () async {
    await importSample();
    final jan9 = DateTime(2025, 1, 9);
    await store.upsert(jan9, caloriesEaten: 2100); // a real Jan 9

    expect(count(await repo.countSampleDays()), 6);
    expect(count(await repo.removeSampleDays()), 6);

    final rows = await allRows();
    expect(rows, [DailyMetric(date: jan9, caloriesEaten: 2100)]);
  });

  test(
    'keeps a check-in on a sample day, clearing only its calories',
    () async {
      await importSample();
      final jan6 = DateTime(2025, 1, 6);
      await store.upsert(jan6, loggingStatus: LoggingStatus.partial);

      expect(count(await repo.removeSampleDays()), 7);

      final rows = await allRows();
      expect(rows, [
        DailyMetric(date: jan6, loggingStatus: LoggingStatus.partial),
      ]);
    },
  );

  test('never touches rows outside the sample dates', () async {
    final outside = DateTime(2026, 10, 20);
    await store.upsert(outside, caloriesEaten: 1450); // a sample total
    await store.upsert(DateTime(2025, 1, 5), caloriesEaten: 1450);
    await importSample();

    expect(count(await repo.removeSampleDays()), 7);

    expect((await allRows()).map((r) => r.date), [
      DateTime(2025, 1, 5),
      outside,
    ]);
  });

  test('returns the store failure when it cannot read', () async {
    final failing = PdfImportRepositoryImpl(
      parser: CalAIParser(),
      dailyMetrics: _FailingRangeStore(),
    );
    expect(await failing.countSampleDays(), isA<Err<int>>());
    expect(await failing.removeSampleDays(), isA<Err<int>>());
  });
}

class _FailingRangeStore extends InMemoryDailyMetricRepository {
  @override
  ResultFuture<List<DailyMetric>> getRange(
    DateTime start,
    DateTime end,
  ) async => const Err(UnknownFailure('store unavailable'));
}
