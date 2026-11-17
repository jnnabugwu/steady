import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

Widget _host(Widget child, {bool disableAnimations = false}) => ShadcnApp(
  theme: steadyTheme,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Center(child: child),
  ),
);

/// The stones drawn, bottom of the stack first.
List<CairnStone> _stones(WidgetTester tester) => tester
    .widgetList<CairnStone>(find.byType(CairnStone))
    .toList()
    .reversed
    .toList();

/// The opacity of the drop wrapper around the topmost drawn stone.
double _topStoneOpacity(WidgetTester tester) {
  final fade = tester.widget<FadeTransition>(
    find
        .ancestor(
          of: find.byType(CairnStone).first,
          matching: find.byType(FadeTransition),
        )
        .first,
  );
  return fade.opacity.value;
}

void main() {
  group('OnboardingCairn', () {
    testWidgets('draws placed and dimmed stones with the cairn stone, '
        'a pending one dashed, and keeps empty slots', (tester) async {
      await tester.pumpWidget(
        _host(
          const OnboardingCairn(
            stones: [
              OnboardingStone.placed,
              OnboardingStone.dimmed,
              OnboardingStone.placed,
              OnboardingStone.pending,
              OnboardingStone.none,
            ],
          ),
        ),
      );

      expect(_stones(tester).map((s) => s.status), [
        LoggingStatus.logged,
        LoggingStatus.skipped,
        LoggingStatus.logged,
        null,
      ]);
      // CairnWeek's widths for the first slots.
      expect(_stones(tester).map((s) => s.width), [100, 90, 84, 88]);
      // The empty slot still takes its height.
      expect(
        tester.getSize(find.byType(OnboardingCairn)).height,
        OnboardingCairn.heightFor(5),
      );
    });

    testWidgets('a skipped step is still a stone, never a gap', (tester) async {
      await tester.pumpWidget(
        _host(OnboardingCairn(stones: List.filled(9, OnboardingStone.dimmed))),
      );
      expect(find.byType(CairnStone), findsNWidgets(9));
    });

    testWidgets('holds up to ten stones, tapering', (tester) async {
      expect(OnboardingCairn.shapes, hasLength(OnboardingCairn.maxStones));
      await tester.pumpWidget(
        _host(
          OnboardingCairn(
            stones: List.filled(
              OnboardingCairn.maxStones,
              OnboardingStone.placed,
            ),
          ),
        ),
      );
      final widths = _stones(tester).map((s) => s.width).toList();
      expect(widths.last, lessThan(widths.first));
      expect(tester.takeException(), isNull);
    });

    testWidgets('one label for the whole stack', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const OnboardingCairn(
            stones: [
              OnboardingStone.placed,
              OnboardingStone.dimmed,
              OnboardingStone.pending,
            ],
          ),
        ),
      );
      expect(
        find.bySemanticsLabel(
          'Your cairn: 2 stones, 1 of them dimmer for a skipped step. '
          'The next stone is still to place.',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    test('the default label counts stones', () {
      expect(
        OnboardingCairn.defaultSemanticsLabel(const [OnboardingStone.pending]),
        'Your cairn: no stones yet. The next stone is still to place.',
      );
      expect(
        OnboardingCairn.defaultSemanticsLabel(const [OnboardingStone.placed]),
        'Your cairn: 1 stone.',
      );
      expect(
        OnboardingCairn.defaultSemanticsLabel(const [
          OnboardingStone.dimmed,
          OnboardingStone.dimmed,
          OnboardingStone.placed,
        ]),
        'Your cairn: 3 stones, 2 of them dimmer for skipped steps.',
      );
    });

    testWidgets('a newly placed stone drops in', (tester) async {
      await tester.pumpWidget(
        _host(
          const OnboardingCairn(
            stones: [OnboardingStone.placed, OnboardingStone.pending],
          ),
        ),
      );
      await tester.pumpWidget(
        _host(
          const OnboardingCairn(
            stones: [OnboardingStone.placed, OnboardingStone.placed],
          ),
        ),
      );
      expect(tester.hasRunningAnimations, isTrue);
      expect(_topStoneOpacity(tester), lessThan(1));
      await tester.pumpAndSettle();
      expect(_topStoneOpacity(tester), 1);
    });

    testWidgets('stones there on the first build do not drop', (tester) async {
      await tester.pumpWidget(
        _host(
          const OnboardingCairn(
            stones: [OnboardingStone.placed, OnboardingStone.dimmed],
          ),
        ),
      );
      expect(tester.hasRunningAnimations, isFalse);
      expect(_topStoneOpacity(tester), 1);
    });

    testWidgets('each slot keeps its own state when the stack grows', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const OnboardingCairn(
            stones: [OnboardingStone.placed, OnboardingStone.pending],
          ),
        ),
      );
      // A slot added on top, already placed, isn't a stone being dropped;
      // matched by position instead of by slot, the pending slot's state
      // would take the new stone and drop it.
      await tester.pumpWidget(
        _host(
          const OnboardingCairn(
            stones: [
              OnboardingStone.placed,
              OnboardingStone.pending,
              OnboardingStone.placed,
            ],
          ),
        ),
      );
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('with reduced motion a new stone just appears', (tester) async {
      await tester.pumpWidget(
        _host(
          const OnboardingCairn(stones: [OnboardingStone.pending]),
          disableAnimations: true,
        ),
      );
      await tester.pumpWidget(
        _host(
          const OnboardingCairn(stones: [OnboardingStone.dimmed]),
          disableAnimations: true,
        ),
      );
      expect(tester.hasRunningAnimations, isFalse);
      expect(_topStoneOpacity(tester), 1);
    });
  });

  group('PaidBadge', () {
    testWidgets('shows and reads its one wording', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const PaidBadge()));
      expect(PaidBadge.text, 'Paid');
      expect(find.text(PaidBadge.text), findsOneWidget);
      expect(find.bySemanticsLabel(PaidBadge.text), findsOneWidget);
      handle.dispose();
    });

    testWidgets('never says Plus or upgrade', (tester) async {
      expect(PaidBadge.text.toLowerCase(), isNot(contains('plus')));
      expect(PaidBadge.text.toLowerCase(), isNot(contains('upgrade')));
    });
  });
}
