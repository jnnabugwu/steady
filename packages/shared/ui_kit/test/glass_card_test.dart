import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/harness.dart';

void main() {
  group('GlassCard', () {
    testWidgets('renders its child with no backdrop blur', (tester) async {
      await tester.pumpWidget(harness(const GlassCard(child: Text('Tonight'))));
      expect(find.text('Tonight'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('defaults to 18px padding; padding is configurable', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(const GlassCard(child: SizedBox(width: 10, height: 10))),
      );
      // 10 + 2 × 18 padding + 2 × 1px border.
      expect(tester.getSize(find.byType(Card)), const Size(48, 48));

      await tester.pumpWidget(
        harness(
          const GlassCard(
            padding: EdgeInsets.all(4),
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      );
      expect(tester.getSize(find.byType(Card)), const Size(20, 20));
    });

    testWidgets('SteadyCard forwards to GlassCard with 16px padding', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(const SteadyCard(child: SizedBox(width: 10, height: 10))),
      );
      final glass = tester.widget<GlassCard>(find.byType(GlassCard));
      expect(glass.tint, GlassCardTint.glass);
      expect(glass.padding, const EdgeInsets.all(16));
      expect(tester.getSize(find.byType(Card)), const Size(44, 44));
    });
  });

  group('GlassCard golden', skip: goldenSkip, () {
    testWidgets('glass and coach tints', (tester) async {
      await loadGoldenFonts();
      await tester.pumpWidget(
        goldenFrame(
          size: const Size(320, 280),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(child: SizedBox(height: 80)),
              SizedBox(height: 12),
              GlassCard(
                tint: GlassCardTint.coach,
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ),
      );
      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/glass_card.png'),
      );
    });
  });
}
