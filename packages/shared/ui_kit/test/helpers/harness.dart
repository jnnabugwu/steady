import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// Pass as a golden `group`'s `skip:`. Golden tests run on macOS only;
/// on every other host, CI's ubuntu runner included, they're skipped with
/// this reason (scripts/test.sh lists it in its "Skipped tests" summary).
///
/// Goldens draw with real fonts ([loadGoldenFonts]) and include rounded
/// rects, a backdrop blur and icon glyphs, all anti-aliased. Rasterisation
/// differs slightly between macOS and Linux, so a golden made on a Mac
/// fails a pixel-exact compare on ubuntu. The goldens are a local visual
/// check: after an intentional visual change, regenerate them on a Mac
/// with `flutter test --update-goldens` and commit the PNGs. The
/// non-golden widget tests (semantics, selection, callbacks, null
/// handling) run everywhere.
final Object? goldenSkip = Platform.isMacOS
    ? null
    : 'Goldens are macOS-only: pixel output differs on '
          '${Platform.operatingSystem} (see test/helpers/harness.dart).';

/// Puts [child] in a dark-themed `ShadcnApp`, centred on the screen
/// background, as the feature screens see it.
Widget harness(Widget child) => ShadcnApp(
  theme: steadyTheme,
  home: ColoredBox(
    color: SteadyColors.bgScreen,
    child: Center(child: child),
  ),
);

/// A fixed-size, screen-coloured frame for a golden, keyed [goldenKey].
Widget goldenFrame({
  required Widget child,
  required Size size,
  EdgeInsets padding = const EdgeInsets.all(16),
}) => ShadcnApp(
  theme: steadyTheme,
  home: Align(
    alignment: Alignment.topLeft,
    child: RepaintBoundary(
      key: goldenKey,
      child: SizedBox.fromSize(
        size: size,
        child: ColoredBox(
          color: SteadyColors.bgScreen,
          child: Padding(padding: padding, child: child),
        ),
      ),
    ),
  ),
);

/// The key [goldenFrame] puts on the boundary a golden captures.
const ValueKey<String> goldenKey = ValueKey('golden');

/// Loads the fonts goldens draw with, so they show real glyphs rather
/// than flutter_test's placeholder boxes. Call it at the start of every
/// golden test, before the first pump.
///
/// - Text: the app names Apple's system font explicitly
///   ([SteadyType.fontFamily], [SteadyType.displayFontFamily]); on iOS and
///   macOS the engine maps those names to SF Pro. SF Pro isn't
///   redistributable and doesn't resolve under flutter_test, so goldens
///   register shadcn_flutter's bundled Geist under both names as a
///   stand-in. Geist is close enough in width that values and labels lay
///   out as they will on device, but the goldens show Geist, not SF.
/// - Icons: shadcn_flutter's Lucide icon font.
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
