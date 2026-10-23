import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/harness.dart';

void main() {
  Widget tile(List<num?> values, {int? futureFrom, String? unit = 'kcal'}) =>
      harness(
        SizedBox(
          width: 112,
          child: MetricTile(
            label: 'Eaten',
            value: '1,840',
            unit: unit,
            accent: MetricAccent.caloriesEaten,
            dailyValues: values,
            futureFrom: futureFrom,
          ),
        ),
      );

  Container bar(WidgetTester tester, int i) =>
      tester.widget<Container>(find.byKey(ValueKey('metric-bar-$i')));
  double barHeight(WidgetTester tester, int i) =>
      tester.getSize(find.byKey(ValueKey('metric-bar-$i'))).height;
  Color? barColour(WidgetTester tester, int i) =>
      (bar(tester, i).decoration! as BoxDecoration).color;

  group('MetricTile', () {
    testWidgets('reads as one label: name, value, unit', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(tile(const [1, 2, 3, 4, 5, 6, 7]));
      expect(
        tester.getSemantics(find.byType(MetricTile)),
        matchesSemantics(label: 'Eaten, 1,840 kcal'),
      );

      await tester.pumpWidget(tile(const [1, 2, 3, 4, 5, 6, 7], unit: null));
      expect(
        tester.getSemantics(find.byType(MetricTile)),
        matchesSemantics(label: 'Eaten, 1,840'),
      );
      handle.dispose();
    });

    testWidgets('scales bars to the week peak, in the accent colour', (
      tester,
    ) async {
      await tester.pumpWidget(tile(const [10, 20, 5, 0, 15, 25, 20]));
      expect(barHeight(tester, 5), MetricTile.sparklineHeight);
      expect(barHeight(tester, 1), closeTo(20.8, 0.01));
      // A logged zero is a full-colour stub.
      expect(barHeight(tester, 3), MetricTile.minBarHeight);
      expect(barColour(tester, 3), SteadyColors.caloriesEaten);
      for (var i = 0; i < 7; i++) {
        expect(barColour(tester, i), SteadyColors.caloriesEaten);
      }
    });

    testWidgets('a null value is a dimmed stub, not a gap', (tester) async {
      await tester.pumpWidget(tile(const [10, null, 20, null, 5, 10, 20]));
      expect(find.byKey(const ValueKey('metric-bar-1')), findsOneWidget);
      expect(barHeight(tester, 1), MetricTile.minBarHeight);
      expect(barColour(tester, 1), SteadyColors.caloriesEatenDimmed);
      expect(barColour(tester, 2), SteadyColors.caloriesEaten);
    });

    testWidgets('an all-null week renders seven stubs', (tester) async {
      await tester.pumpWidget(tile(List<num?>.filled(7, null)));
      for (var i = 0; i < 7; i++) {
        expect(barHeight(tester, i), MetricTile.minBarHeight);
        expect(barColour(tester, i), SteadyColors.caloriesEatenDimmed);
      }
    });

    testWidgets('days from futureFrom on use the dimmed colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        tile(const [10, 20, 15, 18, 12, null, null], futureFrom: 5),
      );
      expect(barColour(tester, 4), SteadyColors.caloriesEaten);
      expect(barColour(tester, 5), SteadyColors.caloriesEatenDimmed);
      expect(barColour(tester, 6), SteadyColors.caloriesEatenDimmed);
    });
  });

  group('MetricTile golden', skip: goldenSkip, () {
    testWidgets('three accents, gaps and future days', (tester) async {
      await loadGoldenFonts();
      await tester.pumpWidget(
        goldenFrame(
          size: const Size(372, 128),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MetricTile(
                  label: 'Eaten',
                  value: '1,840',
                  unit: 'kcal',
                  accent: MetricAccent.caloriesEaten,
                  dailyValues: [17, 23, 11, 21, 15, 25, 20],
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: MetricTile(
                  label: 'Burned',
                  value: '2,310',
                  unit: 'kcal',
                  accent: MetricAccent.caloriesBurned,
                  dailyValues: [21, null, 19, 22, 23, null, null],
                  futureFrom: 5,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: MetricTile(
                  label: 'Steps',
                  value: '8,412',
                  accent: MetricAccent.steps,
                  dailyValues: [13, 25, 8, 17, 11, 23, 19],
                ),
              ),
            ],
          ),
        ),
      );
      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/metric_tile.png'),
      );
    });
  });
}
