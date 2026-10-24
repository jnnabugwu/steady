import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/goldens.dart';

void main() {
  final weekStart = DateTime(2026, 8, 21);

  WeekCardData week(List<LoggingStatus?> statuses) => WeekCardData(
    weekStart: weekStart,
    days: [
      for (final (i, date) in weekCardDates(weekStart).indexed)
        WeekCardDay(
          date: date,
          status: statuses[i],
          caloriesEaten: i == 0 ? 1850 : null,
          steps: i == 0 ? 8204 : null,
        ),
    ],
  );

  // Fri logged, Sat partial, Sun skipped, Mon-Thu nothing.
  final data = week([
    LoggingStatus.logged,
    LoggingStatus.partial,
    LoggingStatus.skipped,
    null,
    null,
    null,
    null,
  ]);

  Widget cardApp(WeekCardData data, {bool showNumbers = false}) => ShadcnApp(
    theme: steadyTheme,
    home: Align(
      alignment: Alignment.topLeft,
      child: RepaintBoundary(
        key: const ValueKey('golden'),
        child: SizedBox.fromSize(
          size: WeekCard.logicalSize,
          child: WeekCard(data: data, showNumbers: showNumbers),
        ),
      ),
    ),
  );

  Future<void> pumpCard(WidgetTester tester, {bool showNumbers = false}) =>
      tester.pumpWidget(cardApp(data, showNumbers: showNumbers));

  group('WeekCard', () {
    testWidgets('shows the wordmark, the dates and the summary', (
      tester,
    ) async {
      await pumpCard(tester);

      expect(find.text('STEADY'), findsOneWidget);
      expect(find.text('Fri Aug 21 – Thu Aug 27'), findsOneWidget);
      // Logged and partial have food; skipped is checked in, not a miss.
      expect(find.text('2 of 3 days logged'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('stacks the 7 days as a cairn, first day at the bottom', (
      tester,
    ) async {
      await pumpCard(tester);

      final cairn = tester.widget<CairnWeek>(
        find.byKey(const Key('weekCardCairn')),
      );
      expect(
        [for (final d in cairn.days) d.label],
        ['F', 'S', 'S', 'M', 'T', 'W', 'T'],
      );
      expect(
        [for (final d in cairn.days) d.status],
        [
          LoggingStatus.logged,
          LoggingStatus.partial,
          LoggingStatus.skipped,
          null,
          null,
          null,
          null,
        ],
      );
      // No day is "today" on a share image, so no day is drawn as still to
      // come: every day keeps its stone.
      expect(cairn.days.where((d) => d.isToday), isEmpty);
      expect(cairn.semanticsLabel, contains('Friday at the bottom'));
      expect(find.byType(CairnStone), findsNWidgets(7));
      expect(find.byType(CairnLegend), findsOneWidget);
    });

    testWidgets('renders settled: every stone fully shown', (tester) async {
      await pumpCard(tester);

      final fades = tester.widgetList<FadeTransition>(
        find.descendant(
          of: find.byType(CairnWeek),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fades, hasLength(7));
      for (final fade in fades) {
        expect(fade.opacity.value, 1);
      }
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('summarises a week with nothing checked in yet', (
      tester,
    ) async {
      await tester.pumpWidget(cardApp(week(List.filled(7, null))));

      expect(find.text('A fresh week'), findsOneWidget);
    });

    testWidgets('hides calories and steps by default', (tester) async {
      await pumpCard(tester);

      expect(find.text('1,850 cal'), findsNothing);
      expect(find.text('8,204 steps'), findsNothing);
      expect(find.byKey(const Key('weekCardNumbers_0')), findsNothing);
    });

    testWidgets('shows calories and steps beside their day when opted in', (
      tester,
    ) async {
      await pumpCard(tester, showNumbers: true);

      Finder inDay(int i, Finder finder) => find.descendant(
        of: find.byKey(Key('weekCardNumbers_$i')),
        matching: finder,
      );
      expect(inDay(0, find.text('1,850 cal')), findsOneWidget);
      expect(inDay(0, find.text('8,204 steps')), findsOneWidget);
      // Nothing is invented for days with no numbers.
      expect(find.textContaining(' cal'), findsOneWidget);
      expect(find.textContaining(' steps'), findsOneWidget);

      // Each day's numbers sit level with that day's stone (the bottom
      // stone is the first day).
      final row = tester.getCenter(find.byKey(const Key('weekCardNumbers_0')));
      final stones = find.byType(CairnStone);
      final bottomStone = tester.getCenter(stones.last);
      expect(row.dy, moreOrLessEquals(bottomStone.dy, epsilon: 0.5));
      expect(tester.takeException(), isNull);
    });
  });

  // Goldens: macOS only, and only once their PNGs exist (see goldenSkip in
  // helpers/goldens.dart). They draw with shadcn_flutter's bundled Geist
  // standing in for SF Pro. Each golden is the card's 360×450 logical
  // layout at 1x; the share flow renders that same layout at
  // WeekCard.pixelRatio (1080×1350). Regenerate on a Mac with
  // `flutter test --update-goldens test/week_card_test.dart`.
  group('WeekCard goldens', () {
    setUp(loadGoldenFonts);

    testGolden('statuses only', 'goldens/week_card.png', (tester) async {
      await tester.pumpWidget(cardApp(data));
      await expectLater(
        find.byKey(const ValueKey('golden')),
        matchesGoldenFile('goldens/week_card.png'),
      );
    });

    testGolden('with numbers', 'goldens/week_card_numbers.png', (tester) async {
      await tester.pumpWidget(cardApp(data, showNumbers: true));
      await expectLater(
        find.byKey(const ValueKey('golden')),
        matchesGoldenFile('goldens/week_card_numbers.png'),
      );
    });
  });
}
