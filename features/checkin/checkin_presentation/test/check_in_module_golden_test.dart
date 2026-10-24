import 'package:checkin_domain/checkin_domain.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fake_check_in_repository.dart';
import 'helpers/fake_metrics_repository.dart';
import 'helpers/goldens.dart';

void main() {
  // Thursday 2026-10-22, the artboard's day; its week starts Fri Oct 16.
  final day = DateTime(2026, 10, 22);

  Future<void> pumpScreen(WidgetTester tester, CheckInStatus? status) async {
    await loadGoldenFonts();
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checkInRepositoryProvider.overrideWithValue(
            FakeCheckInRepository(onGetStatus: (_) => Ok(status)),
          ),
          weekMetricsRepositoryProvider.overrideWithValue(
            FakeMetricsRepository(
              onGetRange: (_, _) => Ok([
                for (final (i, s) in [
                  LoggingStatus.logged,
                  LoggingStatus.partial,
                  LoggingStatus.skipped,
                  LoggingStatus.logged,
                  LoggingStatus.partial,
                  LoggingStatus.logged,
                ].indexed)
                  DailyMetric(
                    date: DateTime(2026, 10, 16 + i),
                    loggingStatus: s,
                  ),
              ]),
            ),
          ),
          checkInClockProvider.overrideWithValue(
            () => DateTime(2026, 10, 22, 21),
          ),
        ],
        child: ShadcnApp(
          theme: steadyTheme,
          home: CheckInModule(date: day, onCheckInCompleted: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Goldens: macOS only, and only once their PNGs exist (see goldenSkip).
  // After an intentional visual change, regenerate on a Mac with
  // `flutter test --update-goldens test/check_in_module_golden_test.dart`.
  group('CheckInModule goldens', () {
    testGolden('not checked in yet', 'goldens/check_in_module_pending.png', (
      tester,
    ) async {
      await pumpScreen(tester, null);
      await expectLater(
        find.byType(CheckInModule),
        matchesGoldenFile('goldens/check_in_module_pending.png'),
      );
    });

    testGolden('logged', 'goldens/check_in_module_logged.png', (tester) async {
      await pumpScreen(tester, CheckInStatus.logged);
      await expectLater(
        find.byType(CheckInModule),
        matchesGoldenFile('goldens/check_in_module_logged.png'),
      );
    });
  });
}
