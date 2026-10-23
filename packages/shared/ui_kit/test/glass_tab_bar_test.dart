import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/harness.dart';

const _items = [
  GlassTabItem(icon: LucideIcons.sun, label: 'Today'),
  GlassTabItem(icon: LucideIcons.chartColumn, label: 'Week'),
  GlassTabItem(icon: LucideIcons.messageCircle, label: 'Coach'),
  GlassTabItem(icon: LucideIcons.settings, label: 'Settings'),
];

void main() {
  Widget bar({int selected = 0, ValueChanged<int>? onSelected}) => harness(
    SizedBox(
      width: 390,
      child: GlassTabBar(
        items: _items,
        selectedIndex: selected,
        onSelected: onSelected ?? (_) {},
      ),
    ),
  );

  group('GlassTabBar', () {
    testWidgets('is 64 tall, inset 18, and blurs behind itself', (
      tester,
    ) async {
      await tester.pumpWidget(bar());
      expect(find.byType(BackdropFilter), findsOneWidget);
      final pill = tester.getSize(find.byType(BackdropFilter));
      expect(pill, const Size(390 - 36, GlassTabBar.height));
    });

    testWidgets('each tab is a button with selected state', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(bar(selected: 1));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Week')),
        isSemantics(
          label: 'Week',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      for (final label in ['Today', 'Coach', 'Settings']) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(label)),
          isSemantics(
            label: label,
            isButton: true,
            hasSelectedState: true,
            isSelected: false,
          ),
        );
      }
      expect(find.bySemanticsLabel('Main'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('tapping a tab reports its index', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(bar(onSelected: taps.add));
      await tester.tap(find.text('Coach'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(taps, [2, 0]);
    });

    testWidgets('every tab meets the 44pt touch target', (tester) async {
      await tester.pumpWidget(bar());
      for (final item in _items) {
        final size = tester.getSize(
          find
              .ancestor(
                of: find.text(item.label),
                matching: find.byType(Clickable),
              )
              .first,
        );
        expect(size.height, greaterThanOrEqualTo(44));
        expect(size.width, greaterThanOrEqualTo(44));
      }
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    });

    testWidgets('only the selected tab gets the teal pill', (tester) async {
      await tester.pumpWidget(bar(selected: 2));
      final fills = [
        for (final item in _items)
          (tester
                      .widget<Clickable>(
                        find
                            .ancestor(
                              of: find.text(item.label),
                              matching: find.byType(Clickable),
                            )
                            .first,
                      )
                      .decoration!
                      .resolve({})!
                  as BoxDecoration)
              .color,
      ];
      expect(fills[2], SteadyColors.accentTealTint(0.18));
      expect(fills.where((c) => c == SteadyColors.accentTealTint(0.18)), [
        SteadyColors.accentTealTint(0.18),
      ]);
    });
  });

  group('GlassTabBar golden', skip: goldenSkip, () {
    testWidgets('over content, Today selected', (tester) async {
      await loadGoldenFonts();
      await tester.pumpWidget(
        goldenFrame(
          size: const Size(390, 140),
          padding: EdgeInsets.zero,
          child: const Stack(
            children: [
              // Something behind the bar for the blur to soften.
              Positioned(
                left: 40,
                top: 30,
                child: SizedBox(
                  width: 120,
                  height: 90,
                  child: ColoredBox(color: SteadyColors.caloriesEaten),
                ),
              ),
              Positioned(
                right: 50,
                top: 50,
                child: SizedBox(
                  width: 90,
                  height: 70,
                  child: ColoredBox(color: SteadyColors.steps),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: GlassTabBar(
                  items: _items,
                  selectedIndex: 0,
                  onSelected: _ignore,
                ),
              ),
            ],
          ),
        ),
      );
      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/glass_tab_bar.png'),
      );
    });
  });
}

void _ignore(int _) {}
