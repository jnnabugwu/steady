import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/harness.dart';

void main() {
  group('GlassIconButton', () {
    testWidgets('is a 44×44 labelled button that calls onPressed', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        harness(
          GlassIconButton(
            icon: LucideIcons.download,
            semanticLabel: 'Import Cal AI PDF',
            onPressed: () => taps++,
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(GlassIconButton)),
        const Size.square(44),
      );
      expect(
        tester.getSemantics(find.byType(GlassIconButton)),
        isSemantics(
          label: 'Import Cal AI PDF',
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );

      await tester.tap(find.byType(GlassIconButton));
      await tester.pumpAndSettle();
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('a null onPressed disables it', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        harness(
          const GlassIconButton(
            icon: LucideIcons.download,
            semanticLabel: 'Import Cal AI PDF',
            onPressed: null,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(GlassIconButton)),
        isSemantics(
          label: 'Import Cal AI PDF',
          isButton: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      handle.dispose();
    });
  });

  group('GlassIconButton golden', skip: goldenSkip, () {
    testWidgets('enabled and disabled', (tester) async {
      await loadGoldenFonts();
      await tester.pumpWidget(
        goldenFrame(
          size: const Size(140, 76),
          child: Row(
            children: [
              GlassIconButton(
                icon: LucideIcons.download,
                semanticLabel: 'Import Cal AI PDF',
                onPressed: () {},
              ),
              const SizedBox(width: 16),
              const GlassIconButton(
                icon: LucideIcons.download,
                semanticLabel: 'Import Cal AI PDF',
                onPressed: null,
              ),
            ],
          ),
        ),
      );
      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/glass_icon_button.png'),
      );
    });
  });
}
