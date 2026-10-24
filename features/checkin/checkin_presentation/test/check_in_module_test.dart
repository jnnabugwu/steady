import 'dart:async';

import 'package:checkin_domain/checkin_domain.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fake_check_in_repository.dart';
import 'helpers/fake_metrics_repository.dart';

void main() {
  // Monday; its Friday-Thursday week runs Fri 2026-08-21 to Thu 2026-08-27.
  final midnight = DateTime(2026, 8, 24);
  late FakeCheckInRepository repository;
  late FakeMetricsRepository metrics;
  late DateTime now;
  late int completedCount;

  setUp(() {
    repository = FakeCheckInRepository();
    metrics = FakeMetricsRepository();
    now = DateTime(2026, 8, 24, 21);
    completedCount = 0;
  });

  List<Override> overrides() => [
    checkInRepositoryProvider.overrideWithValue(repository),
    weekMetricsRepositoryProvider.overrideWithValue(metrics),
    checkInClockProvider.overrideWithValue(() => now),
  ];

  StatusOptionTile tile(WidgetTester tester, CheckInStatus status) =>
      tester.widget(find.byKey(Key('checkInButton_${status.name}')));

  /// The one status tile shown as selected, or null.
  CheckInStatus? selected(WidgetTester tester) {
    final chosen = [
      for (final status in CheckInStatus.values)
        if (tile(tester, status).selected) status,
    ];
    expect(chosen.length, lessThanOrEqualTo(1));
    return chosen.firstOrNull;
  }

  String title(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('checkInTitle'))).data!;

  CairnWeek cairn(WidgetTester tester) =>
      tester.widget(find.byKey(const Key('checkInCairn')));

  Widget module(DateTime date) => ShadcnApp(
    theme: steadyTheme,
    home: CheckInModule(date: date, onCheckInCompleted: () => completedCount++),
  );

  Future<void> pumpInScope(WidgetTester tester, DateTime date) => tester
      .pumpWidget(ProviderScope(overrides: overrides(), child: module(date)));

  group('CheckInModule', () {
    testWidgets('shows a spinner while loading, then the stored status', (
      tester,
    ) async {
      final completer = Completer<Result<CheckInStatus?>>();
      repository.onGetStatus = (_) => completer.future;

      await pumpInScope(tester, midnight);
      expect(find.byKey(const Key('checkInProgress')), findsOneWidget);
      expect(tile(tester, CheckInStatus.logged).onPressed, isNull);

      completer.complete(const Ok(CheckInStatus.logged));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(selected(tester), CheckInStatus.logged);
      expect(title(tester), 'Added to this week’s stack');
    });

    testWidgets('tapping a button logs it and fires onCheckInCompleted once', (
      tester,
    ) async {
      await pumpInScope(tester, midnight);
      await tester.pumpAndSettle();
      expect(selected(tester), isNull);
      expect(title(tester), 'How did tracking go today?');

      await tester.tap(find.byKey(const Key('checkInButton_partial')));
      await tester.pumpAndSettle();

      expect(repository.logCheckInCalls, [(midnight, CheckInStatus.partial)]);
      expect(selected(tester), CheckInStatus.partial);
      expect(title(tester), 'Added to this week’s stack');
      expect(completedCount, 1);
    });

    testWidgets('renders the Failure when loading fails', (tester) async {
      repository.onGetStatus = (_) =>
          const Err(PlatformChannelFailure('channel down'));

      await pumpInScope(tester, midnight);
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong: channel down'), findsOneWidget);
    });

    testWidgets('a failed log renders the Failure and does not complete', (
      tester,
    ) async {
      repository.onLogCheckIn = (_, _) =>
          const Err(UnknownFailure('write failed'));

      await pumpInScope(tester, midnight);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('checkInButton_skipped')));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong: write failed'), findsOneWidget);
      expect(completedCount, 0);
    });

    testWidgets('a failed change keeps the previous selection', (tester) async {
      repository.onGetStatus = (_) => const Ok(CheckInStatus.logged);
      metrics.onGetRange = (_, _) => Ok([
        DailyMetric(date: midnight, loggingStatus: LoggingStatus.logged),
      ]);
      final write = Completer<Result<Unit>>();
      repository.onLogCheckIn = (_, _) => write.future;

      await pumpInScope(tester, midnight);
      await tester.pumpAndSettle();
      expect(selected(tester), CheckInStatus.logged);

      await tester.tap(find.byKey(const Key('checkInButton_skipped')));
      await tester.pump();

      // While the write is in flight, the saved status stays selected.
      expect(find.byKey(const Key('checkInProgress')), findsOneWidget);
      expect(selected(tester), CheckInStatus.logged);
      expect(title(tester), 'Added to this week’s stack');

      write.complete(const Err(UnknownFailure('write failed')));
      await tester.pumpAndSettle();

      // After it fails: the error shows, and the tile, the title and the
      // cairn all still show the last saved status.
      expect(find.text('Something went wrong: write failed'), findsOneWidget);
      expect(selected(tester), CheckInStatus.logged);
      expect(title(tester), 'Added to this week’s stack');
      final monday = cairn(tester).days.singleWhere((d) => d.label == 'M');
      expect(monday.status, LoggingStatus.logged);
      expect(completedCount, 0);
      // The tiles are enabled again, so the change can be retried.
      expect(tile(tester, CheckInStatus.skipped).onPressed, isNotNull);
    });

    testWidgets(
      'rapid taps while a write is in flight log once and complete once',
      (tester) async {
        final write = Completer<Result<Unit>>();
        repository.onLogCheckIn = (_, _) => write.future;

        await pumpInScope(tester, midnight);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('checkInButton_partial')));
        await tester.tap(find.byKey(const Key('checkInButton_skipped')));
        await tester.pump();

        // Tiles are disabled while the write is in flight.
        for (final status in CheckInStatus.values) {
          expect(tile(tester, status).onPressed, isNull);
        }
        await tester.tap(
          find.byKey(const Key('checkInButton_logged')),
          warnIfMissed: false,
        );

        write.complete(const Ok(unit));
        await tester.pumpAndSettle();

        expect(repository.logCheckInCalls, [(midnight, CheckInStatus.partial)]);
        expect(selected(tester), CheckInStatus.partial);
        expect(completedCount, 1);
      },
    );
  });

  group('week cairn', () {
    setUp(() {
      metrics.onGetRange = (_, _) => Ok([
        DailyMetric(
          date: DateTime(2026, 8, 21),
          loggingStatus: LoggingStatus.logged,
        ),
        DailyMetric(
          date: DateTime(2026, 8, 22),
          loggingStatus: LoggingStatus.partial,
        ),
        DailyMetric(
          date: DateTime(2026, 8, 23),
          loggingStatus: LoggingStatus.skipped,
        ),
      ]);
    });

    testWidgets('stacks the Friday-Thursday week the date falls in', (
      tester,
    ) async {
      await pumpInScope(tester, midnight);
      await tester.pumpAndSettle();

      expect(metrics.getRangeCalls, [
        (DateTime(2026, 8, 21), DateTime(2026, 8, 27)),
      ]);
      final days = cairn(tester).days;
      expect(
        [for (final d in days) d.label],
        [
          'F', 'S', 'S', 'M', 'T', 'W', 'T', //
        ],
      );
      expect(
        [for (final d in days) d.status],
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
      expect(
        [for (final d in days) d.isToday],
        [
          false, false, false, true, false, false, false, //
        ],
      );
      expect(find.text('THIS WEEK · FRI–THU'), findsOneWidget);
      expect(find.text("TONIGHT'S CHECK-IN"), findsOneWidget);
      // Logged fully and partial count as logged; skipped doesn't.
      expect(find.text('2 of 3 days logged'), findsOneWidget);
      expect(find.byType(CairnLegend), findsOneWidget);
      expect(
        cairn(tester).semanticsLabel,
        startsWith('This week as a stack of days, Friday at the bottom'),
      );
    });

    testWidgets('a logged status lands on the stack and the week re-reads', (
      tester,
    ) async {
      await pumpInScope(tester, midnight);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('checkInButton_logged')));
      await tester.pumpAndSettle();

      expect(cairn(tester).days[3].status, LoggingStatus.logged);
      expect(find.text('3 of 4 days logged'), findsOneWidget);
      expect(metrics.getRangeCalls, hasLength(2));
    });

    testWidgets('a past day names the day and stacks its week', (tester) async {
      now = DateTime(2026, 9, 2, 9);
      await pumpInScope(tester, midnight);
      await tester.pumpAndSettle();

      expect(find.text('CHECK-IN · MON, AUG 24'), findsOneWidget);
      expect(title(tester), 'How did tracking go on Monday?');
      expect(find.text('WEEK OF FRI, AUG 21 · FRI–THU'), findsOneWidget);
      // No day is today, so none is still to come.
      expect(cairn(tester).days.where((d) => d.isToday), isEmpty);
    });

    testWidgets('a later day this week still gets its stone', (tester) async {
      now = DateTime(2026, 8, 22, 9);
      await pumpInScope(tester, midnight);
      await tester.pumpAndSettle();

      expect(cairn(tester).days[3].isToday, isTrue);
    });

    testWidgets('a failed week read shows the Failure, not an empty week', (
      tester,
    ) async {
      metrics.onGetRange = (_, _) =>
          const Err(PlatformChannelFailure('store down'));

      await pumpInScope(tester, midnight);
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load this week: store down"), findsOneWidget);
      expect(find.byType(CairnWeek), findsNothing);
      // Checking in doesn't depend on the week.
      expect(tile(tester, CheckInStatus.logged).onPressed, isNotNull);
    });
  });

  group('date normalization', () {
    testWidgets('09:00 and 18:00 on the same day share one provider', (
      tester,
    ) async {
      final container = ProviderContainer.test(overrides: overrides());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: module(DateTime(2026, 8, 24, 9)),
        ),
      );
      await tester.pumpAndSettle();
      final morning = container.read(checkInControllerProvider(midnight));

      await tester.tap(find.byKey(const Key('checkInButton_logged')));
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: module(DateTime(2026, 8, 24, 18)),
        ),
      );
      await tester.pumpAndSettle();

      // One provider, keyed on midnight, built once: the 18:00 module sees
      // the status logged from the 09:00 module without re-reading.
      expect(morning, isA<AsyncData<CheckInStatus?>>());
      expect(container.exists(checkInControllerProvider(midnight)), isTrue);
      expect(
        container.exists(checkInControllerProvider(DateTime(2026, 8, 24, 9))),
        isFalse,
      );
      expect(
        container.exists(checkInControllerProvider(DateTime(2026, 8, 24, 18))),
        isFalse,
      );
      expect(repository.getStatusCalls, [midnight]);
      expect(selected(tester), CheckInStatus.logged);
    });
  });

  group('auto-dispose', () {
    testWidgets('the provider is disposed once the module leaves the tree', (
      tester,
    ) async {
      final container = ProviderContainer.test(overrides: overrides());
      Widget scoped(Widget child) =>
          UncontrolledProviderScope(container: container, child: child);

      await tester.pumpWidget(scoped(module(midnight)));
      await tester.pumpAndSettle();
      expect(container.exists(checkInControllerProvider(midnight)), isTrue);

      // Simulate the screen popping: replace the module with another widget.
      await tester.pumpWidget(
        scoped(const ShadcnApp(theme: steadyTheme, home: SizedBox())),
      );
      await tester.pumpAndSettle();

      expect(container.exists(checkInControllerProvider(midnight)), isFalse);

      // Returning to the screen builds a fresh provider that re-reads.
      await tester.pumpWidget(scoped(module(midnight)));
      await tester.pumpAndSettle();
      expect(repository.getStatusCalls, [midnight, midnight]);
    });
  });
}
