import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  final weekStart = DateTime(2026, 8, 21);
  final data = WeekCardData(
    weekStart: weekStart,
    days: [
      for (final (i, date) in weekCardDates(weekStart).indexed)
        WeekCardDay(
          date: date,
          // Fri logged, Sat partial, Sun skipped, Mon-Thu nothing.
          status: switch (i) {
            0 => LoggingStatus.logged,
            1 => LoggingStatus.partial,
            2 => LoggingStatus.skipped,
            _ => null,
          },
          caloriesEaten: i == 0 ? 1850 : null,
          steps: i == 0 ? 8204 : null,
        ),
    ],
  );

  Future<void> pumpCard(WidgetTester tester, {bool showNumbers = false}) =>
      tester.pumpWidget(
        ShadcnApp(
          theme: steadyTheme,
          home: Center(
            child: SizedBox.fromSize(
              size: WeekCard.logicalSize,
              child: WeekCard(data: data, showNumbers: showNumbers),
            ),
          ),
        ),
      );

  Finder inDay(int i, Finder finder) =>
      find.descendant(of: find.byKey(Key('weekCardDay_$i')), matching: finder);

  group('WeekCard', () {
    testWidgets('renders all 7 days with their labels and statuses', (
      tester,
    ) async {
      await pumpCard(tester);

      expect(find.text('STEADY'), findsOneWidget);
      expect(find.text('Fri Aug 21 – Thu Aug 27'), findsOneWidget);

      const labels = ['FRI', 'SAT', 'SUN', 'MON', 'TUE', 'WED', 'THU'];
      const statuses = [
        'Logged',
        'Partial',
        'Skipped',
        'No check-in',
        'No check-in',
        'No check-in',
        'No check-in',
      ];
      for (var i = 0; i < 7; i++) {
        expect(inDay(i, find.text(labels[i])), findsOneWidget);
        expect(inDay(i, find.text('${21 + i}')), findsOneWidget);
        expect(inDay(i, find.text(statuses[i])), findsOneWidget);
      }
    });

    testWidgets('uses the single-hue indicator for checked-in days only', (
      tester,
    ) async {
      await pumpCard(tester);

      for (final (i, status) in [
        LoggingStatus.logged,
        LoggingStatus.partial,
        LoggingStatus.skipped,
      ].indexed) {
        final indicator = tester.widget<LoggingStatusIndicator>(
          inDay(i, find.byType(LoggingStatusIndicator)),
        );
        expect(indicator.status, status);
      }
      for (var i = 3; i < 7; i++) {
        expect(inDay(i, find.byType(LoggingStatusIndicator)), findsNothing);
      }
    });

    testWidgets('hides calories and steps by default', (tester) async {
      await pumpCard(tester);

      expect(find.text('1,850 cal'), findsNothing);
      expect(find.text('8,204 steps'), findsNothing);
    });

    testWidgets('shows calories and steps when opted in', (tester) async {
      await pumpCard(tester, showNumbers: true);

      expect(inDay(0, find.text('1,850 cal')), findsOneWidget);
      expect(inDay(0, find.text('8,204 steps')), findsOneWidget);
      // Nothing is invented for days with no numbers.
      expect(find.textContaining(' cal'), findsOneWidget);
      expect(find.textContaining(' steps'), findsOneWidget);
    });
  });
}
