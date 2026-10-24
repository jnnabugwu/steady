import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fake_health_kit_repository.dart';
import 'helpers/fake_metrics_repository.dart';

void main() {
  // Thursday 2026-10-22; its seven days run Fri Oct 16 to Thu Oct 22.
  final today = DateTime(2026, 10, 22);
  late FakeMetricsRepository repository;

  setUp(() => repository = FakeMetricsRepository());

  Future<void> pump(
    WidgetTester tester, {
    HealthKitRepository? health,
    DateTime? date,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          metricsRepositoryProvider.overrideWithValue(repository),
          if (health != null)
            metricsHealthKitRepositoryProvider.overrideWithValue(health),
        ],
        child: ShadcnApp(
          theme: steadyTheme,
          home: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [TodayMetricTiles(date: date ?? today)],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  MetricTile tile(WidgetTester tester, String name) =>
      tester.widget(find.byKey(Key('todayTile_$name')));

  test('todayMetricsDates: the seven days ending on the day', () {
    expect(todayMetricsDates(today), [
      for (var d = 16; d <= 22; d++) DateTime(2026, 10, d),
    ]);
  });

  group('TodayMetricTiles', () {
    testWidgets("reads the seven days ending today; today's value over the "
        "week's sparkline", (tester) async {
      repository.onGetRange = (_, _) => Ok([
        DailyMetric(date: DateTime(2026, 10, 16), caloriesEaten: 1700),
        DailyMetric(date: DateTime(2026, 10, 20), caloriesEaten: 2100),
        DailyMetric(date: today, caloriesEaten: 1840),
      ]);
      // A time of day is normalized away.
      await pump(tester, date: DateTime(2026, 10, 22, 21, 15));

      expect(repository.getRangeCalls, [(DateTime(2026, 10, 16), today)]);
      final eaten = tile(tester, 'eaten');
      expect(eaten.label, 'Eaten');
      expect(eaten.value, '1,840');
      expect(eaten.unit, 'kcal');
      expect(eaten.dailyValues, [1700, null, null, null, 2100, null, 1840]);
    });

    testWidgets('without Health (the Mac) only eaten shows', (tester) async {
      repository.onGetRange = (_, _) =>
          Ok([DailyMetric(date: today, caloriesEaten: 1840)]);
      await pump(tester);

      expect(find.byKey(const Key('todayTile_eaten')), findsOneWidget);
      expect(find.byKey(const Key('todayTile_burned')), findsNothing);
      expect(find.byKey(const Key('todayTile_steps')), findsNothing);
    });

    testWidgets('on the iPhone, burned and steps come from live Health', (
      tester,
    ) async {
      repository.onGetRange = (_, _) =>
          Ok([DailyMetric(date: today, caloriesEaten: 1840)]);
      final health = FakeHealthKitRepository(
        days: [
          HealthDayTotals(
            date: today,
            steps: 8412,
            caloriesBurnedActive: 610,
            caloriesBurnedBasal: 1700,
          ),
          HealthDayTotals(date: DateTime(2026, 10, 21), steps: 5000),
        ],
      );
      await pump(tester, health: health);

      expect(tile(tester, 'burned').value, '2,310');
      expect(tile(tester, 'steps').value, '8,412');
      expect(tile(tester, 'steps').unit, isNull);
      expect(tile(tester, 'steps').dailyValues, [
        null, null, null, null, null, 5000, 8412, //
      ]);
      // The history's 30-day Health window, so the two share a read.
      final window = healthHistoryWindow(today);
      expect(health.dailyTotalsCalls, [(window.start, window.end)]);
    });

    testWidgets('a metric with values this week but none today shows "—"', (
      tester,
    ) async {
      repository.onGetRange = (_, _) =>
          Ok([DailyMetric(date: DateTime(2026, 10, 21), caloriesEaten: 1900)]);
      await pump(tester);

      final eaten = tile(tester, 'eaten');
      expect(eaten.value, '—');
      expect(eaten.unit, isNull);
      expect(eaten.semanticLabel, 'Eaten, nothing today');
    });

    testWidgets('an empty week says so instead of showing tiles', (
      tester,
    ) async {
      await pump(tester);

      expect(find.byType(MetricTile), findsNothing);
      expect(find.byKey(const Key('todayMetricsEmpty')), findsOneWidget);
    });

    testWidgets('a failed read shows the Failure', (tester) async {
      repository.onGetRange = (_, _) =>
          const Err(PlatformChannelFailure('store down'));
      await pump(tester);

      expect(find.byType(MetricTile), findsNothing);
      expect(
        find.text("Couldn't load today's metrics: store down"),
        findsOneWidget,
      );
    });
  });
}
