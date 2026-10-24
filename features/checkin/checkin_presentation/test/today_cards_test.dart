// The two cards the app's Today screen composes on their own, outside
// CheckInModule: CheckInCard and CairnWeekCard.
import 'package:checkin_domain/checkin_domain.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fake_check_in_repository.dart';
import 'helpers/fake_metrics_repository.dart';

void main() {
  // Thursday 2026-10-22, the artboard's day; its week starts Fri Oct 16.
  final today = DateTime(2026, 10, 22);
  late FakeCheckInRepository repository;
  late FakeMetricsRepository metrics;

  setUp(() {
    repository = FakeCheckInRepository();
    metrics = FakeMetricsRepository(
      onGetRange: (_, _) => Ok([
        for (final (i, s) in [
          LoggingStatus.logged,
          LoggingStatus.partial,
          LoggingStatus.skipped,
          LoggingStatus.logged,
          LoggingStatus.partial,
          LoggingStatus.logged,
        ].indexed)
          DailyMetric(date: DateTime(2026, 10, 16 + i), loggingStatus: s),
      ]),
    );
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checkInRepositoryProvider.overrideWithValue(repository),
          weekMetricsRepositoryProvider.overrideWithValue(metrics),
          checkInClockProvider.overrideWithValue(
            () => DateTime(2026, 10, 22, 21),
          ),
        ],
        child: ShadcnApp(
          theme: steadyTheme,
          home: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [child],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String title(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('checkInTitle'))).data!;

  StatusOptionTile tile(WidgetTester tester, CheckInStatus status) =>
      tester.widget(find.byKey(Key('checkInButton_${status.name}')));

  CairnWeek cairn(WidgetTester tester) =>
      tester.widget(find.byKey(const Key('checkInCairn')));

  group('CheckInCard', () {
    testWidgets("today: Tonight's check-in, then Added to this week's stack", (
      tester,
    ) async {
      var completed = 0;
      await pump(
        tester,
        CheckInCard(
          // Any time of day: the card normalizes to midnight.
          date: DateTime(2026, 10, 22, 7, 30),
          onCheckInCompleted: () => completed++,
        ),
      );

      expect(find.text("TONIGHT'S CHECK-IN"), findsOneWidget);
      expect(title(tester), 'How did tracking go today?');
      expect(find.byType(StatusOptionTile), findsNWidgets(3));

      await tester.tap(find.byKey(const Key('checkInButton_logged')));
      await tester.pumpAndSettle();

      expect(repository.logCheckInCalls, [(today, CheckInStatus.logged)]);
      expect(tile(tester, CheckInStatus.logged).selected, isTrue);
      expect(title(tester), 'Added to this week’s stack');
      expect(completed, 1);
    });

    testWidgets('works without an onCheckInCompleted callback', (tester) async {
      await pump(tester, CheckInCard(date: today));

      await tester.tap(find.byKey(const Key('checkInButton_skipped')));
      await tester.pumpAndSettle();

      expect(repository.logCheckInCalls, [(today, CheckInStatus.skipped)]);
      expect(title(tester), 'Added to this week’s stack');
    });

    testWidgets('a failed log shows the Failure and does not complete', (
      tester,
    ) async {
      var completed = 0;
      repository.onLogCheckIn = (_, _) =>
          const Err(UnknownFailure('write failed'));
      await pump(
        tester,
        CheckInCard(date: today, onCheckInCompleted: () => completed++),
      );

      await tester.tap(find.byKey(const Key('checkInButton_partial')));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong: write failed'), findsOneWidget);
      expect(completed, 0);
    });

    testWidgets('another day names the day', (tester) async {
      await pump(tester, CheckInCard(date: DateTime(2026, 10, 20)));

      expect(find.text('CHECK-IN · TUE, OCT 20'), findsOneWidget);
      expect(title(tester), 'How did tracking go on Tuesday?');
    });
  });

  group('CairnWeekCard', () {
    testWidgets('stacks the week with its headline and legend', (tester) async {
      await pump(tester, CairnWeekCard(date: today));

      expect(metrics.getRangeCalls, [
        (DateTime(2026, 10, 16), DateTime(2026, 10, 22)),
      ]);
      expect(find.text('THIS WEEK · FRI–THU'), findsOneWidget);
      expect(find.text('5 of 6 days logged'), findsOneWidget);
      expect(find.byType(CairnLegend), findsOneWidget);
      final days = cairn(tester).days;
      expect(
        [for (final d in days) d.isToday],
        [
          false, false, false, false, false, false, true, //
        ],
      );
      expect(days.last.status, isNull);
    });

    testWidgets('a failed week read shows the Failure', (tester) async {
      metrics.onGetRange = (_, _) =>
          const Err(PlatformChannelFailure('store down'));
      await pump(tester, CairnWeekCard(date: today));

      expect(find.text("Couldn't load this week: store down"), findsOneWidget);
      expect(find.byKey(const Key('checkInCairn')), findsNothing);
    });

    testWidgets('a log on a CheckInCard lands on its stack, and the week '
        're-reads', (tester) async {
      await pump(
        tester,
        Column(
          children: [
            CheckInCard(date: today),
            CairnWeekCard(date: today),
          ],
        ),
      );
      expect(metrics.getRangeCalls, hasLength(1));

      await tester.tap(find.byKey(const Key('checkInButton_logged')));
      await tester.pumpAndSettle();

      expect(cairn(tester).days.last.status, LoggingStatus.logged);
      expect(find.text('6 of 7 days logged'), findsOneWidget);
      expect(metrics.getRangeCalls, hasLength(2));
    });
  });
}
