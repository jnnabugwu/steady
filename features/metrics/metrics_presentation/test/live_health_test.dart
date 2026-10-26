import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:metrics_presentation/src/live_health.dart' show mergeLiveHealth;

import 'helpers/fake_health_kit_repository.dart';

void main() {
  final day = DateTime(2026, 10, 22);

  group('healthHistoryWindow', () {
    test('is the last healthHistoryDays days, at local midnights', () {
      final window = healthHistoryWindow(DateTime(2026, 10, 23, 8, 15));
      expect(window.end, DateTime(2026, 10, 23));
      expect(window.start, DateTime(2026, 9, 24));
      expect(window.end.difference(window.start).inDays + 1, healthHistoryDays);
    });

    test('takes the local calendar day of a UTC now', () {
      final now = DateTime.utc(2026, 10, 23, 2);
      final local = now.toLocal();
      final window = healthHistoryWindow(now);
      expect(window.end, DateTime(local.year, local.month, local.day));
      expect(window.end.isUtc, isFalse);
      expect(window.start.isUtc, isFalse);
      expect(window.end.difference(window.start).inDays + 1, healthHistoryDays);
    });
  });

  group('healthDayTotalsProvider', () {
    test('is empty without a Health source (macOS)', () async {
      final container = ProviderContainer.test();
      final totals = await container.read(
        healthDayTotalsProvider(day, day).future,
      );
      expect(totals, isEmpty);
    });

    test('reads Health live and drops days with no samples', () async {
      final health = FakeHealthKitRepository(
        days: [HealthDayTotals(date: day, steps: 5)],
      );
      final container = ProviderContainer.test(
        overrides: [
          metricsHealthKitRepositoryProvider.overrideWithValue(health),
        ],
      );
      final start = DateTime(2026, 10, 20);
      final totals = await container.read(
        healthDayTotalsProvider(start, day).future,
      );
      expect(totals, {day: HealthDayTotals(date: day, steps: 5)});
      expect(health.dailyTotalsCalls, [(start, day)]);
    });

    test('re-reads Health when invalidated', () async {
      final health = FakeHealthKitRepository();
      final container = ProviderContainer.test(
        overrides: [
          metricsHealthKitRepositoryProvider.overrideWithValue(health),
        ],
      );
      final provider = healthDayTotalsProvider(day, day);
      container.listen(provider, (_, _) {});
      await container.read(provider.future);
      container.invalidate(healthDayTotalsProvider);
      await container.read(provider.future);
      expect(health.dailyTotalsCalls, hasLength(2));
    });
  });

  group('mergeLiveHealth', () {
    test('takes eaten and status from the row, Health from the map', () {
      final merged = mergeLiveHealth(
        [
          DailyMetric(
            date: day,
            caloriesEaten: 1800,
            loggingStatus: LoggingStatus.logged,
            steps: 1,
          ),
          DailyMetric(date: DateTime(2026, 10, 20), caloriesEaten: 2000),
        ],
        {
          day: HealthDayTotals(date: day, steps: 900, caloriesBurnedBasal: 10),
          DateTime(2026, 10, 21): HealthDayTotals(
            date: DateTime(2026, 10, 21),
            steps: 3,
          ),
        },
      );
      expect(merged, [
        DailyMetric(
          date: day,
          caloriesEaten: 1800,
          loggingStatus: LoggingStatus.logged,
          steps: 900,
          caloriesBurnedBasal: 10,
        ),
        DailyMetric(date: DateTime(2026, 10, 21), steps: 3),
        DailyMetric(date: DateTime(2026, 10, 20), caloriesEaten: 2000),
      ]);
    });

    test('a day with only a weight reading adds no row', () {
      final weighed = DateTime(2026, 10, 21);
      final merged = mergeLiveHealth(
        [DailyMetric(date: day, caloriesEaten: 1800)],
        {weighed: HealthDayTotals(date: weighed, weightKg: 80.4)},
      );
      expect(merged, [DailyMetric(date: day, caloriesEaten: 1800)]);
    });
  });

  group('healthWeightUnitProvider', () {
    test('is kilograms without a Health source (macOS)', () async {
      final container = ProviderContainer.test();
      expect(
        await container.read(healthWeightUnitProvider.future),
        WeightUnit.kilograms,
      );
    });

    test("is Health's preferred unit", () async {
      final health = FakeHealthKitRepository(weightUnit: WeightUnit.pounds);
      final container = ProviderContainer.test(
        overrides: [
          metricsHealthKitRepositoryProvider.overrideWithValue(health),
        ],
      );
      expect(
        await container.read(healthWeightUnitProvider.future),
        WeightUnit.pounds,
      );
    });
  });
}
