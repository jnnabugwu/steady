import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:data_export_presentation/data_export_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fakes.dart';
import 'helpers/golden.dart';

/// Each golden: its name, and how to get there from the idle screen.
final goldenSteps = <(String, Future<void> Function(WidgetTester))>[
  ('data_export_idle', (_) async {}),
  (
    'data_export_exported',
    (tester) async {
      await tester.tap(find.byKey(const Key('exportButton_csv')));
      await tester.pumpAndSettle();
      // The export ran: the golden shows the receipt, not the idle screen.
      expect(
        find.text('Exported 2 days to steady-export-2026-10-22.csv.'),
        findsOneWidget,
      );
    },
  ),
];

/// Pumps the settings screen at the golden size, with two days to export
/// and a fixed clock, so the receipt's file name never changes.
Future<void> pumpGoldenScreen(WidgetTester tester) async {
  await loadGoldenFonts();
  useGoldenSurface(tester);
  final repository = FakeDailyMetricRepository(
    onGetRange: () => Ok([
      DailyMetric(date: DateTime(2026, 10, 19), caloriesEaten: 1850),
      DailyMetric(date: DateTime(2026, 10, 20), caloriesEaten: 2010),
    ]),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        exportDailyMetricRepositoryProvider.overrideWithValue(repository),
        exportFileSharerProvider.overrideWithValue(FakeExportSharer().call),
        exportClockProvider.overrideWithValue(
          () => DateTime(2026, 10, 22, 9, 30),
        ),
      ],
      child: ShadcnApp(
        theme: steadyTheme,
        home: DataExportModule(onBack: () {}),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('DataExportModule goldens', () {
    for (final (name, step) in goldenSteps) {
      // A group per golden so its skip reason is reported (testWidgets'
      // `skip` is a bool).
      group(name, skip: goldenSkip(name), () {
        testWidgets('matches goldens/$name.png', (tester) async {
          await pumpGoldenScreen(tester);
          await step(tester);
          await expectLater(
            find.byType(DataExportModule),
            matchesGoldenFile('goldens/$name.png'),
          );
        });
      });
    }
  });
}
