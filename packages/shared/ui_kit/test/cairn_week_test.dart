import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

const _fridayWeek = [
  ('F', 'Friday'),
  ('S', 'Saturday'),
  ('S', 'Sunday'),
  ('M', 'Monday'),
  ('T', 'Tuesday'),
  ('W', 'Wednesday'),
  ('T', 'Thursday'),
];

/// A Fri–Thu window with [statuses] in order and [today] as today's index
/// (null: no day is today).
List<CairnDay> _week(List<LoggingStatus?> statuses, {int? today = 6}) => [
  for (final (i, (label, name)) in _fridayWeek.indexed)
    CairnDay(
      label: label,
      fullName: name,
      status: statuses[i],
      isToday: i == today,
    ),
];

/// The artboard's week: Thursday is today, [todayStatus] its status.
List<CairnDay> _artboardWeek([LoggingStatus? todayStatus]) => _week([
  LoggingStatus.logged,
  LoggingStatus.partial,
  LoggingStatus.skipped,
  LoggingStatus.logged,
  LoggingStatus.partial,
  LoggingStatus.logged,
  todayStatus,
]);

Widget _host(Widget child, {bool disableAnimations = false}) => ShadcnApp(
  theme: steadyTheme,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Center(child: child),
  ),
);

/// The stones on screen, bottom of the stack first.
List<CairnStone> _stones(WidgetTester tester) {
  final stones = tester.widgetList<CairnStone>(find.byType(CairnStone));
  return stones.toList().reversed.toList();
}

/// Letters on screen, bottom of the stack first.
List<String> _letters(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(of: find.byType(CairnWeek), matching: find.byType(Text)),
    )
    .map((t) => t.data!)
    .toList()
    .reversed
    .toList();

Color? _letterColor(WidgetTester tester, int fromBottom) => tester
    .widgetList<Text>(
      find.descendant(of: find.byType(CairnWeek), matching: find.byType(Text)),
    )
    .toList()
    .reversed
    .elementAt(fromBottom)
    .style
    ?.color;

/// The opacity of the drop-in wrapper around the stone at [fromBottom].
double _stoneOpacity(WidgetTester tester, int fromBottom) {
  final stone = find.byType(CairnStone).at(6 - fromBottom);
  final fade = tester.widget<FadeTransition>(
    find.ancestor(of: stone, matching: find.byType(FadeTransition)).first,
  );
  return fade.opacity.value;
}

void main() {
  group('CairnWeek', () {
    testWidgets('draws one stone per day, first day at the bottom', (
      tester,
    ) async {
      await tester.pumpWidget(_host(CairnWeek(days: _artboardWeek())));

      expect(_letters(tester), ['F', 'S', 'S', 'M', 'T', 'W', 'T']);
      expect(_stones(tester).map((s) => s.status), [
        LoggingStatus.logged,
        LoggingStatus.partial,
        LoggingStatus.skipped,
        LoggingStatus.logged,
        LoggingStatus.partial,
        LoggingStatus.logged,
        null,
      ]);
      // The artboard's widths, bottom to top (the 4th is wider than the
      // 3rd on purpose).
      expect(_stones(tester).map((s) => s.width), [
        100,
        90,
        84,
        88,
        76,
        68,
        58,
      ]);
      // The bottom stone sits physically below the top one.
      expect(
        tester.getCenter(find.byType(CairnStone).last).dy,
        greaterThan(tester.getCenter(find.byType(CairnStone).first).dy),
      );
      expect(tester.getSize(find.byType(CairnWeek)), const Size(150, 123));
    });

    testWidgets('fills logged and partial stones from the status ladder', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const CairnStone(status: LoggingStatus.logged, width: 100)),
      );
      expect(
        find.byType(CairnStone),
        paints..rrect(color: SteadyColors.statusLogged),
      );

      await tester.pumpWidget(
        _host(const CairnStone(status: LoggingStatus.partial, width: 100)),
      );
      expect(
        find.byType(CairnStone),
        paints..rrect(color: SteadyColors.statusPartial),
      );
    });

    testWidgets('a skipped day is still a stone, with a faint border', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(CairnWeek(days: _week(List.filled(7, LoggingStatus.skipped)))),
      );
      // Never removed: a whole week of skips is still seven stones.
      expect(find.byType(CairnStone), findsNWidgets(7));

      await tester.pumpWidget(
        _host(const CairnStone(status: LoggingStatus.skipped, width: 100)),
      );
      expect(
        find.byType(CairnStone),
        paints
          ..rrect(color: SteadyColors.statusSkipped)
          ..rrect(
            style: PaintingStyle.stroke,
            strokeWidth: 1,
            color: const Color.fromRGBO(255, 255, 255, 0.14),
          ),
      );
    });

    testWidgets('a pending today is a dashed teal outline, no fill', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const CairnStone(status: null, width: 58)));
      expect(
        find.byType(CairnStone),
        paints..path(
          style: PaintingStyle.stroke,
          strokeWidth: 1.5,
          color: SteadyColors.accentTealTint(0.75),
        ),
      );
      expect(find.byType(CairnStone), isNot(paints..rrect()));
    });

    testWidgets("today's letter is teal, the others muted", (tester) async {
      await tester.pumpWidget(_host(CairnWeek(days: _artboardWeek())));

      expect(_letterColor(tester, 6), SteadyColors.accentTealHover);
      for (var i = 0; i < 6; i++) {
        expect(_letterColor(tester, i), SteadyColors.textMuted);
      }
    });

    testWidgets('days after today have no stone yet, and a faint letter', (
      tester,
    ) async {
      // Monday is today; Tuesday to Thursday haven't happened.
      final days = _week([
        LoggingStatus.logged,
        LoggingStatus.partial,
        LoggingStatus.skipped,
        null,
        null,
        null,
        null,
      ], today: 3);
      await tester.pumpWidget(_host(CairnWeek(days: days)));

      expect(_stones(tester).map((s) => s.status), [
        LoggingStatus.logged,
        LoggingStatus.partial,
        LoggingStatus.skipped,
        null,
      ]);
      expect(_letters(tester), hasLength(7));
      expect(_letterColor(tester, 3), SteadyColors.accentTealHover);
      expect(_letterColor(tester, 4), SteadyColors.textDisabled);
      // The stack keeps its height while the week fills.
      expect(tester.getSize(find.byType(CairnWeek)), const Size(150, 123));
    });

    testWidgets('works for a non-Friday anchor', (tester) async {
      const monday = [
        ('M', 'Monday'),
        ('T', 'Tuesday'),
        ('W', 'Wednesday'),
        ('T', 'Thursday'),
        ('F', 'Friday'),
        ('S', 'Saturday'),
        ('S', 'Sunday'),
      ];
      final days = [
        for (final (i, (label, name)) in monday.indexed)
          CairnDay(
            label: label,
            fullName: name,
            status: i == 6 ? null : LoggingStatus.logged,
            isToday: i == 6,
          ),
      ];
      await tester.pumpWidget(_host(CairnWeek(days: days)));

      expect(_letters(tester), ['M', 'T', 'W', 'T', 'F', 'S', 'S']);
      expect(_stones(tester).last.status, isNull);
      expect(
        find.bySemanticsLabel(
          RegExp('^This week as a stack of days, Monday at the bottom: '),
        ),
        findsOneWidget,
      );
    });

    testWidgets('has one semantics label for the whole stack', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(CairnWeek(days: _artboardWeek())));

      const label =
          'This week as a stack of days, Friday at the bottom: '
          'Friday logged fully, Saturday partial, Sunday skipped, '
          'Monday logged fully, Tuesday partial, Wednesday logged fully, '
          'Thursday not checked in yet';
      expect(CairnWeek(days: _artboardWeek()).semanticsLabel, label);
      expect(find.bySemanticsLabel(label), findsOneWidget);
      // The letters are excluded: no separate node per day.
      expect(find.bySemanticsLabel('F'), findsNothing);
      expect(find.bySemanticsLabel('T'), findsNothing);
      handle.dispose();
    });

    test('names days after today as still to come', () {
      final days = _week([
        LoggingStatus.logged,
        null,
        null,
        null,
        null,
        null,
        null,
      ], today: 1);
      expect(
        CairnWeek(days: days).semanticsLabel,
        'This week as a stack of days, Friday at the bottom: '
        'Friday logged fully, Saturday not checked in yet, '
        'Sunday still to come, Monday still to come, Tuesday still to come, '
        'Wednesday still to come, Thursday still to come',
      );
    });

    test('asserts on anything but 7 days', () {
      expect(
        () => CairnWeek(days: _artboardWeek().sublist(0, 6)),
        throwsAssertionError,
      );
      expect(
        () => CairnWeek(days: [..._artboardWeek(), _artboardWeek().first]),
        throwsAssertionError,
      );
    });

    testWidgets("today's stone drops into place when checked in", (
      tester,
    ) async {
      await tester.pumpWidget(_host(CairnWeek(days: _artboardWeek())));
      expect(_stoneOpacity(tester, 6), 1);

      await tester.pumpWidget(
        _host(CairnWeek(days: _artboardWeek(LoggingStatus.logged))),
      );
      expect(_stoneOpacity(tester, 6), 0);
      double topY() => tester.getCenter(find.byType(CairnStone).first).dy;
      final start = topY();

      await tester.pump(const Duration(milliseconds: 100));
      expect(_stoneOpacity(tester, 6), inExclusiveRange(0, 1));
      final falling = topY();

      await tester.pump(CairnWeek.dropDuration);
      expect(_stoneOpacity(tester, 6), 1);
      expect(tester.hasRunningAnimations, isFalse);
      final resting = topY();
      // Falls from above: start < falling < resting (y grows downwards),
      // 1.6 stone heights in all.
      expect(start, lessThan(falling));
      expect(falling, lessThan(resting));
      expect(resting - start, closeTo(1.6 * CairnStone.height, 0.01));
      expect(_stones(tester).last.status, LoggingStatus.logged);
      // Other stones never animate.
      expect(_stoneOpacity(tester, 0), 1);
    });

    testWidgets('reduced motion places the stone without animating', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(CairnWeek(days: _artboardWeek()), disableAnimations: true),
      );
      await tester.pumpWidget(
        _host(
          CairnWeek(days: _artboardWeek(LoggingStatus.partial)),
          disableAnimations: true,
        ),
      );

      expect(_stoneOpacity(tester, 6), 1);
      expect(tester.hasRunningAnimations, isFalse);
      expect(_stones(tester).last.status, LoggingStatus.partial);
    });

    testWidgets('changing an already-logged status does not drop again', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(CairnWeek(days: _artboardWeek(LoggingStatus.partial))),
      );
      await tester.pumpWidget(
        _host(CairnWeek(days: _artboardWeek(LoggingStatus.logged))),
      );
      expect(_stoneOpacity(tester, 6), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('CairnLegend', () {
    testWidgets('counts each status, zeros included', (tester) async {
      await tester.pumpWidget(
        _host(SizedBox(width: 160, child: CairnLegend(days: _artboardWeek()))),
      );
      expect(find.text('Logged fully'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Partial'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Skipped'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 160,
            child: CairnLegend(days: _week(List.filled(7, null))),
          ),
        ),
      );
      expect(find.text('0'), findsNWidgets(3));
    });
  });

  // Goldens are generated on macOS (`flutter test --update-goldens`) and
  // only compared there: Linux CI rasterizes anti-aliased, rotated edges a
  // few pixels differently, which would fail the comparison for no real
  // change. Text uses the test font (Ahem-style boxes), so the images don't
  // depend on installed fonts. Run them locally on a Mac; regenerate after a
  // Flutter upgrade or a deliberate visual change.
  group(
    'CairnWeek goldens',
    skip: Platform.isMacOS
        ? false
        : 'Goldens are generated on and compared against macOS only.',
    () {
      // The artboard's card: the cairn and its legend inside a glass card.
      Widget card(List<CairnDay> days) => ShadcnApp(
        theme: steadyTheme,
        home: ColoredBox(
          color: SteadyColors.bgScreen,
          child: Center(
            child: RepaintBoundary(
              key: const ValueKey('golden'),
              child: ColoredBox(
                color: SteadyColors.bgScreen,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: 340,
                    child: SteadyCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Row(
                        spacing: 14,
                        children: [
                          CairnWeek(days: days),
                          Expanded(child: CairnLegend(days: days)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      testWidgets('full week', (tester) async {
        await tester.pumpWidget(card(_artboardWeek(LoggingStatus.logged)));
        await expectLater(
          find.byKey(const ValueKey('golden')),
          matchesGoldenFile('goldens/cairn_week_full.png'),
        );
      });

      testWidgets('artboard, today not checked in yet', (tester) async {
        await tester.pumpWidget(card(_artboardWeek()));
        await expectLater(
          find.byKey(const ValueKey('golden')),
          matchesGoldenFile('goldens/cairn_week_pending_today.png'),
        );
      });

      testWidgets('mid-week, Monday not checked in yet', (tester) async {
        final days = _week([
          LoggingStatus.logged,
          LoggingStatus.partial,
          LoggingStatus.skipped,
          null,
          null,
          null,
          null,
        ], today: 3);
        await tester.pumpWidget(card(days));
        await expectLater(
          find.byKey(const ValueKey('golden')),
          matchesGoldenFile('goldens/cairn_week_mid_week.png'),
        );
      });
    },
  );
}
