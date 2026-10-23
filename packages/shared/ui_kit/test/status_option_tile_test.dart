import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/harness.dart';

void main() {
  Widget tile({
    required bool selected,
    VoidCallback? onPressed,
    LoggingStatus status = LoggingStatus.partial,
  }) => harness(
    SizedBox(
      width: 110,
      child: StatusOptionTile(
        status: status,
        label: 'Partial',
        selected: selected,
        onPressed: onPressed,
      ),
    ),
  );

  BoxDecoration surface(WidgetTester tester) {
    final clickable = tester.widget<Clickable>(find.byType(Clickable));
    return clickable.decoration!.resolve({})! as BoxDecoration;
  }

  group('StatusOptionTile', () {
    testWidgets('exposes button + selected semantics with its label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(tile(selected: true, onPressed: () {}));
      expect(
        tester.getSemantics(find.byType(StatusOptionTile)),
        isSemantics(
          label: 'Partial',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );

      await tester.pumpWidget(tile(selected: false, onPressed: () {}));
      expect(
        tester.getSemantics(find.byType(StatusOptionTile)),
        isSemantics(
          label: 'Partial',
          isButton: true,
          hasSelectedState: true,
          isSelected: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('selected uses the teal tint fill and border', (tester) async {
      await tester.pumpWidget(tile(selected: true, onPressed: () {}));
      final on = surface(tester);
      expect(on.color, SteadyColors.accentTealTint(0.16));
      expect(
        (on.border! as Border).top.color,
        SteadyColors.accentTealTint(0.65),
      );

      await tester.pumpWidget(tile(selected: false, onPressed: () {}));
      final off = surface(tester);
      expect(off.color, StatusOptionTile.unselectedFill);
      expect((off.border! as Border).top.color, SteadyColors.glassBorder);
    });

    testWidgets('is 72px tall and calls onPressed on tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(tile(selected: false, onPressed: () => taps++));
      expect(tester.getSize(find.byType(StatusOptionTile)).height, 72);
      await tester.tap(find.byType(StatusOptionTile));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('the swatch takes the status ladder colour', (tester) async {
      for (final (status, colour) in [
        (LoggingStatus.logged, SteadyColors.statusLogged),
        (LoggingStatus.partial, SteadyColors.statusPartial),
        (LoggingStatus.skipped, SteadyColors.statusSkipped),
      ]) {
        await tester.pumpWidget(tile(selected: false, status: status));
        final swatch = tester.widget<DecoratedBox>(
          find
              .ancestor(
                of: find.byWidgetPredicate(
                  (w) => w is SizedBox && w.width == 22 && w.height == 9,
                ),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect((swatch.decoration as BoxDecoration).color, colour);
      }
    });

    testWidgets('a null onPressed disables it', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(tile(selected: false));
      expect(
        tester.getSemantics(find.byType(StatusOptionTile)),
        isSemantics(isEnabled: false, hasTapAction: false),
      );
      handle.dispose();
    });
  });

  group('StatusOptionTile golden', skip: goldenSkip, () {
    testWidgets('three options, partial selected', (tester) async {
      await loadGoldenFonts();
      await tester.pumpWidget(
        goldenFrame(
          size: const Size(354, 104),
          child: Row(
            children: [
              for (final (i, (status, label)) in const [
                (LoggingStatus.logged, 'Logged fully'),
                (LoggingStatus.partial, 'Partial'),
                (LoggingStatus.skipped, 'Skipped'),
              ].indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: StatusOptionTile(
                    status: status,
                    label: label,
                    selected: status == LoggingStatus.partial,
                    onPressed: () {},
                  ),
                ),
              ],
            ],
          ),
        ),
      );
      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/status_option_tile.png'),
      );
    });
  });
}
