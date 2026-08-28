import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_import_data/pdf_import_data.dart';
import 'package:pdf_import_domain/pdf_import_domain.dart';

void main() {
  group('PdfImportRepositoryImpl', () {
    test(
      'commitDailyTotals sets caloriesEaten without clobbering existing '
      'HealthKit-sourced fields',
      () async {
        final dailyMetrics = InMemoryDailyMetricRepository();
        final repo = PdfImportRepositoryImpl(
          parser: CalAIParser(),
          dailyMetrics: dailyMetrics,
        );
        final date = DateTime(2026, 8, 24);

        // A HealthKit-shaped row already exists for this date.
        await dailyMetrics.upsert(
          date,
          caloriesBurnedActive: 400,
          steps: 8000,
        );

        final result = await repo.commitDailyTotals([
          ParsedDay(date: date, caloriesEaten: 1874, foodEntries: const []),
        ]);
        expect(result, isA<Ok<Unit>>());

        final rowResult = await dailyMetrics.getByDate(date);
        final row = (rowResult as Ok<DailyMetric?>).value!;
        expect(row.caloriesEaten, 1874);
        expect(row.caloriesBurnedActive, 400);
        expect(row.steps, 8000);
      },
    );
  });
}
