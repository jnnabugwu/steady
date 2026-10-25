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
import 'helpers/golden.dart';

/// Thursday Oct 22 2026, the artboard's day. Health is read for the window
/// ending on the date the tiles are given, not on the real today, so the
/// golden stays fixed.
final _today = DateTime(2026, 10, 22);

/// The artboard's three tiles: eaten from the store, burned and steps from
/// Health (the iPhone).
Widget iPhoneScene() {
  const eaten = [1700, 2300, 1100, 2100, 1500, 2500, 1840];
  const steps = [6500, 12500, 4000, 8500, 5500, 11500, 8412];
  return _scene(
    health: FakeHealthKitRepository(
      days: [
        for (var i = 0; i < 7; i++)
          HealthDayTotals(
            date: DateTime(2026, 10, 16 + i),
            steps: steps[i],
            caloriesBurnedActive: 500 + 10 * i,
            caloriesBurnedBasal: 1700,
          ),
      ],
    ),
    rows: [
      for (var i = 0; i < 7; i++)
        DailyMetric(date: DateTime(2026, 10, 16 + i), caloriesEaten: eaten[i]),
    ],
  );
}

/// The Mac: no Health, so eaten only, with a gap on Monday.
Widget macScene() => _scene(
  rows: [
    for (final (i, kcal) in [1700, 2300, 1100, null, 1500, 2500, 1840].indexed)
      DailyMetric(date: DateTime(2026, 10, 16 + i), caloriesEaten: kcal),
  ],
);

Widget _scene({required List<DailyMetric> rows, HealthKitRepository? health}) =>
    ProviderScope(
      overrides: [
        metricsRepositoryProvider.overrideWithValue(
          FakeMetricsRepository(onGetRange: (_, _) => Ok(rows)),
        ),
        if (health != null)
          metricsHealthKitRepositoryProvider.overrideWithValue(health),
      ],
      child: ShadcnApp(
        theme: steadyTheme,
        home: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [TodayMetricTiles(date: _today)],
          ),
        ),
      ),
    );

void main() {
  // Goldens: macOS only, and only once their PNGs exist (see goldenSkip).
  // Generate on a Mac with
  // `flutter test --update-goldens test/today_metrics_golden_test.dart`.
  group('TodayMetricTiles goldens', () {
    for (final (name, scene) in [
      ('today_metrics_iphone', iPhoneScene),
      ('today_metrics_mac', macScene),
    ]) {
      group(name, skip: goldenSkip(name), () {
        testWidgets('matches goldens/$name.png', (tester) async {
          await loadGoldenFonts();
          useGoldenSurface(tester);
          await tester.pumpWidget(scene());
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(TodayMetricTiles),
            matchesGoldenFile('goldens/$name.png'),
          );
        });
      });
    }
  });
}
