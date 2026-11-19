import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/harness.dart';

Widget _host(Widget child, {bool disableAnimations = false}) => ShadcnApp(
  theme: steadyTheme,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Center(child: child),
  ),
);

/// The tortoise's own painted box.
RenderObject _paint(WidgetTester tester) => tester.renderObject(
  find.descendant(
    of: find.byType(SteadyTortoise),
    matching: find.byType(CustomPaint),
  ),
);

/// Matches a `drawOval` filled with exactly [color] (so not one still
/// fading in).
PaintPatternPredicate _oval(Color color) =>
    (method, arguments) =>
        method == #drawOval &&
        (arguments[1] as Paint).color.toARGB32() == color.toARGB32();

/// [goldenSkip], and also skipped until the golden files exist (#176:
/// they're generated on a Mac with `flutter test --update-goldens`, which
/// runs these). Without this, a plain `flutter test` on a Mac fails on the
/// missing references.
final Object? _tortoiseGoldenSkip =
    goldenSkip ??
    (autoUpdateGoldenFiles ||
            [
              'test/goldens/steady_tortoise_large.png',
              'test/goldens/steady_tortoise_small.png',
            ].every((path) => File(path).existsSync())
        ? null
        : 'SteadyTortoise goldens not generated yet: run '
              '`flutter test --update-goldens test/steady_tortoise_test.dart` '
              'on a Mac.');

/// The three stones' colours, bottom first.
const List<Color> _stoneColors = [
  SteadyColors.caloriesEaten,
  SteadyColors.caloriesBurned,
  SteadyColors.steps,
];

/// The ovals every form draws besides stones: the ground shadow, the rim
/// and the shell's highlight.
const _bodyOvals = 3;

void main() {
  group('SteadyTortoise', () {
    testWidgets('carries the stones it is given, bottom first, fully drawn', (
      tester,
    ) async {
      for (final count in [0, 1, 2, 3]) {
        await tester.pumpWidget(
          _host(SteadyTortoise(key: ValueKey(count), stones: count)),
        );
        expect(
          _paint(tester),
          paintsExactlyCountTimes(#drawOval, _bodyOvals + count),
          reason: '$count stones',
        );
        if (count == 0) continue;
        final pattern = paints;
        for (final color in _stoneColors.take(count)) {
          pattern.something(_oval(color));
        }
        expect(_paint(tester), pattern, reason: '$count stones');
      }
    });

    testWidgets('carries three by default', (tester) async {
      await tester.pumpWidget(_host(const SteadyTortoise()));
      expect(
        _paint(tester),
        paintsExactlyCountTimes(#drawOval, _bodyOvals + 3),
      );
    });

    testWidgets('its width follows its height', (tester) async {
      await tester.pumpWidget(_host(const SteadyTortoise(size: 200)));
      final size = tester.getSize(find.byType(SteadyTortoise));
      expect(size.height, 200);
      expect(size.width, SteadyTortoise.widthFor(200));
      expect(size.width, greaterThan(size.height));
    });

    group('small form', () {
      test('is chosen below 48 px tall', () {
        expect(SteadyTortoise.smallFormBelow, 48);
        expect(SteadyTortoise.isSmallForm(47.9), isTrue);
        expect(SteadyTortoise.isSmallForm(48), isFalse);
        // Without the stones' headroom it's wider for its height.
        expect(
          SteadyTortoise.widthFor(47.9) / 47.9,
          greaterThan(SteadyTortoise.widthFor(48) / 48),
        );
      });

      testWidgets('drops the stones and keeps the shell and head', (
        tester,
      ) async {
        await tester.pumpWidget(_host(const SteadyTortoise(size: 40)));
        expect(_paint(tester), paintsExactlyCountTimes(#drawOval, _bodyOvals));
        expect(
          _paint(tester),
          paints
            ..path() // the tail
            ..path() // the dome
            ..circle(color: SteadyColors.mascotSage), // the head
        );
      });

      testWidgets('draws the stones at 48 px', (tester) async {
        await tester.pumpWidget(_host(const SteadyTortoise(size: 48)));
        expect(
          _paint(tester),
          paintsExactlyCountTimes(#drawOval, _bodyOvals + 3),
        );
      });

      testWidgets('a stone added in the small form appears at once', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(const SteadyTortoise(size: 40, stones: 1)),
        );
        await tester.pumpWidget(
          _host(const SteadyTortoise(size: 40, stones: 2)),
        );
        expect(tester.hasRunningAnimations, isFalse);
      });
    });

    group('a stone added', () {
      testWidgets('drops onto the stack and settles', (tester) async {
        await tester.pumpWidget(_host(const SteadyTortoise(stones: 1)));
        await tester.pumpWidget(_host(const SteadyTortoise(stones: 2)));
        await tester.pump(const Duration(milliseconds: 40));

        expect(tester.hasRunningAnimations, isTrue);
        // Two stones drawn, the new one still fading in as it falls.
        expect(
          _paint(tester),
          paintsExactlyCountTimes(#drawOval, _bodyOvals + 2),
        );
        expect(
          _paint(tester),
          isNot(
            paints
              ..something(_oval(SteadyColors.caloriesEaten))
              ..something(_oval(SteadyColors.caloriesBurned)),
          ),
        );
        // The stone already there doesn't move.
        expect(
          _paint(tester),
          paints..something(_oval(SteadyColors.caloriesEaten)),
        );

        await tester.pump(SteadyTortoise.dropDuration);
        expect(tester.hasRunningAnimations, isFalse);
        expect(
          _paint(tester),
          paints
            ..something(_oval(SteadyColors.caloriesEaten))
            ..something(_oval(SteadyColors.caloriesBurned)),
        );
      });

      testWidgets('with reduced motion, just appears', (tester) async {
        await tester.pumpWidget(
          _host(const SteadyTortoise(stones: 1), disableAnimations: true),
        );
        await tester.pumpWidget(
          _host(const SteadyTortoise(stones: 2), disableAnimations: true),
        );

        expect(tester.hasRunningAnimations, isFalse);
        expect(
          _paint(tester),
          paints
            ..something(_oval(SteadyColors.caloriesEaten))
            ..something(_oval(SteadyColors.caloriesBurned)),
        );
      });

      testWidgets('with animateStones false, just appears', (tester) async {
        await tester.pumpWidget(
          _host(const SteadyTortoise(stones: 0, animateStones: false)),
        );
        await tester.pumpWidget(
          _host(const SteadyTortoise(stones: 1, animateStones: false)),
        );
        expect(tester.hasRunningAnimations, isFalse);
      });

      testWidgets('stones there on the first build do not drop', (
        tester,
      ) async {
        await tester.pumpWidget(_host(const SteadyTortoise()));
        expect(tester.hasRunningAnimations, isFalse);
      });

      testWidgets('a stone taken away never falls: it is just gone', (
        tester,
      ) async {
        await tester.pumpWidget(_host(const SteadyTortoise()));
        await tester.pumpWidget(_host(const SteadyTortoise(stones: 1)));
        expect(tester.hasRunningAnimations, isFalse);
        expect(
          _paint(tester),
          paintsExactlyCountTimes(#drawOval, _bodyOvals + 1),
        );
      });
    });

    group('semantics', () {
      testWidgets('one label, counting the stones', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_host(const SteadyTortoise(stones: 2)));
        expect(
          find.bySemanticsLabel('A tortoise carrying two stones on its back'),
          findsOneWidget,
        );
        expect(
          tester.getSemantics(find.byType(SteadyTortoise)),
          matchesSemantics(
            label: 'A tortoise carrying two stones on its back',
            isImage: true,
          ),
        );
        handle.dispose();
      });

      testWidgets('the small form is just a tortoise', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_host(const SteadyTortoise(size: 32)));
        expect(find.bySemanticsLabel('A tortoise'), findsOneWidget);
        handle.dispose();
      });

      testWidgets('a given label replaces the default', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(const SteadyTortoise(semanticsLabel: 'Steady')),
        );
        expect(find.bySemanticsLabel('Steady'), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('tortoise')), findsNothing);
        handle.dispose();
      });

      test('the default label for each count', () {
        expect(SteadyTortoise.defaultSemanticsLabel(stones: 0), 'A tortoise');
        expect(
          SteadyTortoise.defaultSemanticsLabel(stones: 1),
          'A tortoise carrying one stone on its back',
        );
        expect(
          SteadyTortoise.defaultSemanticsLabel(stones: 3),
          'A tortoise carrying three stones on its back',
        );
        expect(
          SteadyTortoise.defaultSemanticsLabel(stones: 3, small: true),
          'A tortoise',
        );
      });
    });

    group('stoneRect', () {
      test('stacks the stones bottom first, each narrower', () {
        final rects = [
          for (var i = 0; i < SteadyTortoise.maxStones; i++)
            SteadyTortoise.stoneRect(i, 120),
        ];
        for (var i = 1; i < rects.length; i++) {
          expect(rects[i].center.dy, lessThan(rects[i - 1].center.dy));
          expect(rects[i].width, lessThan(rects[i - 1].width));
          // Each overlaps the one under it, so it sits rather than floats.
          expect(rects[i].bottom, greaterThan(rects[i - 1].top));
        }
        // Inside the widget's box.
        final box = Offset.zero & Size(SteadyTortoise.widthFor(120), 120);
        for (final rect in rects) {
          expect(box.contains(rect.topLeft), isTrue);
          expect(box.contains(rect.bottomRight), isTrue);
        }
      });

      test('scales with the size', () {
        expect(
          SteadyTortoise.stoneRect(0, 240).width,
          closeTo(SteadyTortoise.stoneRect(0, 120).width * 2, 1e-9),
        );
      });

      test('rejects an index past the third stone', () {
        expect(() => SteadyTortoise.stoneRect(3, 120), throwsRangeError);
      });
    });

    testWidgets('TortoiseStone is the stone at the tortoise scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const TortoiseStone(index: 1, tortoiseSize: 200)),
      );
      expect(
        tester.getSize(find.byType(TortoiseStone)),
        SteadyTortoise.stoneRect(1, 200).size,
      );
      expect(
        tester.renderObject(
          find.descendant(
            of: find.byType(TortoiseStone),
            matching: find.byType(CustomPaint),
          ),
        ),
        paints..something(_oval(SteadyColors.caloriesBurned)),
      );
    });
  });

  group('SteadyTortoise golden', skip: _tortoiseGoldenSkip, () {
    testWidgets('large, carrying three', (tester) async {
      await loadGoldenFonts();
      await tester.pumpWidget(
        goldenFrame(
          size: const Size(260, 152),
          child: const Center(child: SteadyTortoise()),
        ),
      );
      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/steady_tortoise_large.png'),
      );
    });

    testWidgets('small form', (tester) async {
      await loadGoldenFonts();
      await tester.pumpWidget(
        goldenFrame(
          size: const Size(120, 72),
          child: const Center(child: SteadyTortoise(size: 40)),
        ),
      );
      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/steady_tortoise_small.png'),
      );
    });
  });
}
