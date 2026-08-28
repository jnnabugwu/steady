import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_data/metrics_data.dart';
import 'package:metrics_domain/metrics_domain.dart';

void main() {
  group('MetricsRepositoryImpl', () {
    test('getWeeks buckets and sums seeded data correctly', () async {
      final dailyMetrics = InMemoryDailyMetricRepository();
      final repo = MetricsRepositoryImpl(dailyMetrics);

      // 2026-08-17 is a Monday. Seed 10 days across two weeks.
      for (var i = 0; i < 10; i++) {
        await dailyMetrics.upsert(
          DateTime(2026, 8, 17 + i),
          caloriesEaten: 100,
          steps: 1000,
        );
      }

      final result = await repo.getWeeks(
        DateTime(2026, 8, 17),
        DateTime(2026, 8, 26),
      );

      final weeks = (result as Ok<List<WeeklyBucket>>).value;
      expect(weeks, hasLength(2));
      expect(weeks[0].days, hasLength(7));
      expect(weeks[0].totalCaloriesEaten, 700);
      expect(weeks[0].totalSteps, 7000);
      expect(weeks[1].days, hasLength(3));
      expect(weeks[1].totalCaloriesEaten, 300);
    });
  });
}
