import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:metrics_presentation/src/metric_format.dart' show formatWeight;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fake_health_kit_repository.dart';
import 'helpers/fake_metrics_repository.dart';

void main() {
  final today = DateTime(2026, 10, 22);
  late FakeMetricsRepository repository;

  setUp(
    () => repository = FakeMetricsRepository(
      onGetRange: (_, _) => Ok([DailyMetric(date: today, caloriesEaten: 1840)]),
    ),
  );

  Future<void> pump(WidgetTester tester, {HealthKitRepository? health}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          metricsRepositoryProvider.overrideWithValue(repository),
          if (health != null)
            metricsHealthKitRepositoryProvider.overrideWithValue(health),
        ],
        child: ShadcnApp(
          theme: steadyTheme,
          home: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: TodayMetricTiles(date: today),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String text(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  group('formatWeight', () {
    test('kilograms and pounds, to one decimal', () {
      expect(formatWeight(82.44, WeightUnit.kilograms), (
        value: '82.4',
        unit: 'kg',
      ));
      expect(formatWeight(82.44, WeightUnit.pounds), (
        value: '181.7',
        unit: 'lb',
      ));
    });

    test('stones carry the remainder in pounds', () {
      // 82.44 kg = 181.75 lb = 12 st 13.7 lb (rounded to a tenth first).
      expect(formatWeight(82.44, WeightUnit.stones), (
        value: '12 st 13.7',
        unit: 'lb',
      ));
    });

    test('a remainder that rounds to 14 lb becomes the next stone', () {
      // 13.98 lb over 12 st rounds to 13.98 → 14.0, so 13 st 0.0.
      const kg = (12 * 14 + 13.98) / 2.20462262185;
      expect(formatWeight(kg, WeightUnit.stones), (
        value: '13 st 0.0',
        unit: 'lb',
      ));
    });
  });

  group('TodayMetricTiles weight card', () {
    testWidgets('shows the trend and today’s reading in Health’s unit', (
      tester,
    ) async {
      final health = FakeHealthKitRepository(
        weightUnit: WeightUnit.pounds,
        days: [
          HealthDayTotals(date: DateTime(2026, 10, 20), weightKg: 80),
          HealthDayTotals(date: today, weightKg: 82),
        ],
      );
      await pump(tester, health: health);

      // Trend: 80 + 0.1 × (82 − 80) = 80.2 kg = 176.8 lb.
      expect(text(tester, 'todayWeightTrend'), '176.8');
      expect(text(tester, 'todayWeightReading'), "Today's reading: 180.8 lb");
      // The eaten tile is still there, above it.
      expect(find.byKey(const Key('todayTile_eaten')), findsOneWidget);
    });

    testWidgets('says so when there is no reading today', (tester) async {
      final health = FakeHealthKitRepository(
        days: [HealthDayTotals(date: DateTime(2026, 10, 20), weightKg: 80)],
      );
      await pump(tester, health: health);

      expect(text(tester, 'todayWeightTrend'), '80.0');
      expect(text(tester, 'todayWeightReading'), 'No reading today');
    });

    testWidgets('no weight in the window: no card', (tester) async {
      final health = FakeHealthKitRepository(
        days: [HealthDayTotals(date: today, steps: 5000)],
      );
      await pump(tester, health: health);

      expect(find.byKey(const Key('todayWeightCard')), findsNothing);
      expect(find.byKey(const Key('todayTile_steps')), findsOneWidget);
    });

    testWidgets('without Health (the Mac): no card', (tester) async {
      await pump(tester);
      expect(find.byKey(const Key('todayWeightCard')), findsNothing);
    });

    testWidgets('a unit that fails to load falls back to kilograms', (
      tester,
    ) async {
      final health =
          FakeHealthKitRepository(
              weightUnit: WeightUnit.pounds,
              days: [HealthDayTotals(date: today, weightKg: 80)],
            )
            ..weightUnitFailure = const PlatformChannelFailure(
              'not determined',
              code: 'authorizationNotDetermined',
            );
      await pump(tester, health: health);

      expect(text(tester, 'todayWeightTrend'), '80.0');
      expect(text(tester, 'todayWeightReading'), "Today's reading: 80.0 kg");
    });
  });
}
