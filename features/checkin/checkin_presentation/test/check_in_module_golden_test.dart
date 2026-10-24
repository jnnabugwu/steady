import 'dart:io';

import 'package:checkin_domain/checkin_domain.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fake_check_in_repository.dart';
import 'helpers/fake_metrics_repository.dart';

/// Golden tests run on macOS only, as in `ui_kit` (see its
/// `test/helpers/harness.dart`): anti-aliased output differs between macOS
/// and Linux, so these skip on CI's ubuntu runner. After an intentional
/// visual change, regenerate on a Mac with
/// `flutter test --update-goldens test/check_in_module_golden_test.dart`.
final Object? _goldenSkip = Platform.isMacOS
    ? null
    : 'Goldens are macOS-only: pixel output differs on '
          '${Platform.operatingSystem}.';

/// Registers shadcn_flutter's bundled Geist under the app's system font
/// names, plus the Lucide icon font, so goldens show real glyphs (same
/// stand-in as `ui_kit`'s `loadGoldenFonts`).
Future<void> _loadGoldenFonts() async {
  const fonts = 'packages/shadcn_flutter/lib/fonts';
  FontLoader geistAs(String family) {
    final loader = FontLoader(family);
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('$fonts/Geist-$weight.otf'));
    }
    return loader;
  }

  final lucide = FontLoader('packages/shadcn_flutter/LucideIcons')
    ..addFont(
      rootBundle.load('packages/shadcn_flutter/lib/icons/LucideIcons.ttf'),
    );
  await Future.wait([
    geistAs(SteadyType.fontFamily).load(),
    geistAs(SteadyType.displayFontFamily).load(),
    lucide.load(),
  ]);
}

void main() {
  // Thursday 2026-10-22, the artboard's day; its week starts Fri Oct 16.
  final day = DateTime(2026, 10, 22);

  Future<void> pumpScreen(WidgetTester tester, CheckInStatus? status) async {
    await _loadGoldenFonts();
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

  group('CheckInModule goldens', skip: _goldenSkip, () {
    testWidgets('not checked in yet', (tester) async {
      await pumpScreen(tester, null);
      await expectLater(
        find.byType(CheckInModule),
        matchesGoldenFile('goldens/check_in_module_pending.png'),
      );
    });

    testWidgets('logged', (tester) async {
      await pumpScreen(tester, CheckInStatus.logged);
      await expectLater(
        find.byType(CheckInModule),
        matchesGoldenFile('goldens/check_in_module_logged.png'),
      );
    });
  });
}
