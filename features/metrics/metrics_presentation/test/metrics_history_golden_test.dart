import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_domain/metrics_domain.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fake_metrics_repository.dart';
import 'helpers/golden.dart';

/// Nine stored days on fixed dates, newest Thu Oct 22 2026, one of them
/// a logged zero and one with nothing logged. No Apple Health, as on the
/// Mac: Health is read relative to today, which would make the golden
/// change daily. The widget tests cover the Health tiles.
Widget historyScene() {
  const eaten = [1840, 2010, null, 0, 1950, 2230, 1610, 1780, 1905];
  return _scene(
    FakeMetricsRepository(
      onGetRange: (_, _) => Ok([
        for (var i = 0; i < eaten.length; i++)
          DailyMetric(
            date: DateTime(2026, 10, 22 - i),
            caloriesEaten: eaten[i],
          ),
      ]),
    ),
  );
}

/// No days stored and no Health: the empty state.
Widget emptyScene() => _scene(FakeMetricsRepository());

/// A failed read: the error state.
Widget errorScene() => _scene(
  FakeMetricsRepository(
    onGetRange: (_, _) => const Err(PlatformChannelFailure('channel down')),
  ),
);

Widget _scene(MetricsRepository repository) => ProviderScope(
  overrides: [metricsRepositoryProvider.overrideWithValue(repository)],
  child: ShadcnApp(
    theme: steadyTheme,
    home: MetricsHistoryModule(onImportRequested: () {}, onOpenSettings: () {}),
  ),
);

void main() {
  group('MetricsHistoryModule goldens', () {
    for (final (name, scene) in [
      ('metrics_history', historyScene),
      ('metrics_history_empty', emptyScene),
      ('metrics_history_error', errorScene),
    ]) {
      // A group per golden so its skip reason is reported (testWidgets'
      // `skip` is a bool).
      group(name, skip: goldenSkip(name), () {
        testWidgets('matches goldens/$name.png', (tester) async {
          await loadGoldenFonts();
          useGoldenSurface(tester);
          await tester.pumpWidget(scene());
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(MetricsHistoryModule),
            matchesGoldenFile('goldens/$name.png'),
          );
        });
      });
    }
  });
}
