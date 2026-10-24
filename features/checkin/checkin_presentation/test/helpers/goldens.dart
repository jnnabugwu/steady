import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

/// Why a golden test comparing against [golden] skips here, or null to run.
///
/// [golden] is the path `matchesGoldenFile` gets, relative to `test/` (the
/// test files sit directly in it); `flutter test` runs from the package
/// root, so the file is looked up under `test/`.
///
/// Goldens follow `ui_kit`'s convention (its `test/helpers/harness.dart`):
/// made and compared on macOS only, because anti-aliased edges rasterise
/// slightly differently elsewhere, so they skip on CI's ubuntu runner. They
/// also skip until their PNG has been generated: a plain run before then
/// has nothing to compare against, while `flutter test --update-goldens` on
/// a Mac still runs them and writes the file.
Object? goldenSkip(String golden) {
  if (!Platform.isMacOS) {
    return 'Goldens are macOS-only: pixel output differs on '
        '${Platform.operatingSystem}.';
  }
  if (!autoUpdateGoldenFiles && !File('test/$golden').existsSync()) {
    return 'Golden test/$golden not generated yet: run '
        'flutter test --update-goldens on macOS.';
  }
  return null;
}

/// A [testWidgets] whose [body] compares against [golden], skipped (with
/// the reason) as [goldenSkip] decides.
///
/// `testWidgets` only takes a `bool` skip, so the test sits in a one-test
/// group that carries the reason.
void testGolden(String description, String golden, WidgetTesterCallback body) {
  group(description, skip: goldenSkip(golden), () {
    testWidgets('matches $golden', body);
  });
}

/// Registers shadcn_flutter's bundled Geist under the app's system font
/// names, plus the Lucide icon font, so goldens show real glyphs rather
/// than boxes (the same stand-in as `ui_kit`'s `loadGoldenFonts`).
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
