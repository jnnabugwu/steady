import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

/// Pass as a golden test's `skip:`. Goldens run on macOS only, like
/// ui_kit's (packages/shared/ui_kit/test/helpers/harness.dart): rasterising
/// differs between macOS and Linux, so CI's ubuntu runner skips them.
/// After an intentional visual change, regenerate them on a Mac with
/// `flutter test --update-goldens` and commit the PNGs.
final Object? goldenSkip = Platform.isMacOS
    ? null
    : 'Goldens are macOS-only: pixel output differs on '
          '${Platform.operatingSystem} (see test/helpers/golden.dart).';

/// The phone-sized surface goldens render at (the Pass 02 artboard).
const goldenSize = Size(390, 844);

/// Loads the fonts goldens draw with: shadcn_flutter's Geist registered
/// under Steady's system-font names (SF Pro doesn't resolve under
/// flutter_test), plus the Lucide icon font. Same as ui_kit's
/// `loadGoldenFonts`; call it before the first pump.
Future<void> loadGoldenFonts() async {
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

/// Sets the test surface to [goldenSize] at 1x for the rest of the test.
void useGoldenSurface(WidgetTester tester) {
  tester.view
    ..physicalSize = goldenSize
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
