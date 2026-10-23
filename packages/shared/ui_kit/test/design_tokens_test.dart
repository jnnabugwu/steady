import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// WCAG 2.x relative luminance of an opaque colour.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('SteadyColors', () {
    // A glass card as it actually renders: the translucent fill over the
    // screen background.
    final glassOnScreen = Color.alphaBlend(
      SteadyColors.glassFill,
      SteadyColors.bgScreen,
    );

    test('textMuted meets WCAG AA (4.5:1) on the screen and on cards', () {
      expect(
        _contrast(SteadyColors.textMuted, SteadyColors.bgScreen),
        closeTo(5.37, 0.01),
      );
      expect(
        _contrast(SteadyColors.textMuted, glassOnScreen),
        closeTo(4.93, 0.01),
      );
      expect(
        _contrast(SteadyColors.textMuted, SteadyColors.bgCard),
        closeTo(4.91, 0.01),
      );
    });

    test('the coach card tokens are the teal tint at 0.10 and 0.28', () {
      expect(SteadyColors.coachCardFill, SteadyColors.accentTealTint(0.10));
      expect(SteadyColors.coachCardBorder, SteadyColors.accentTealTint(0.28));
    });
  });

  test('metricValue uses tabular figures', () {
    expect(
      SteadyType.metricValue.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test("steadyTheme's radius multiplier makes shadcn buttons pills", () {
    expect(steadyTheme.radiusMd, closeTo(SteadyRadii.pill, 1e-9));
  });

  testWidgets('SteadyCard renders its child', (tester) async {
    await tester.pumpWidget(
      const ShadcnApp(
        theme: steadyTheme,
        home: Center(child: SteadyCard(child: Text('Tonight'))),
      ),
    );
    expect(find.text('Tonight'), findsOneWidget);
  });

  test('Pass 02 is set in SF Pro: Display for the screen title, Text '
      'elsewhere, and the theme default is SF Pro Text', () {
    expect(SteadyType.headline.fontFamily, 'CupertinoSystemDisplay');
    for (final style in [
      SteadyType.cardTitle,
      SteadyType.metricValue,
      SteadyType.body,
      SteadyType.eyebrow,
    ]) {
      expect(style.fontFamily, 'CupertinoSystemText');
    }
    expect(steadyTheme.typography.sans.fontFamily, 'CupertinoSystemText');
  });
}
