import 'dart:async';

import 'package:checkin_domain/checkin_domain.dart';
import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:cravings_domain/cravings_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/coach_container.dart';
import 'helpers/fake_coach_model.dart';
import 'helpers/fake_coach_repository.dart';
import 'helpers/fake_domains.dart';

/// The weekly session (#81): the 4-of-7 rule, separate topics, a summary.
/// "Now" is Sunday, Oct 25; the week is Fri Oct 16 → Thu Oct 22.
void main() {
  late FakeCoachModel model;
  late FakeCoachRepository repository;
  late FakeCheckIns checkIns;
  late FakeCravings cravings;
  final provider = coachSessionControllerProvider(
    CoachSessionKind.weekly,
    'session-1',
  );

  FakeCheckIns daysOfWeek(int count) => FakeCheckIns({
    for (var i = 0; i < count; i++)
      DateTime(2026, 10, 16 + i): CheckInStatus.logged,
  });

  setUp(() {
    model = FakeCoachModel();
    repository = FakeCoachRepository();
    checkIns = daysOfWeek(4);
    cravings = FakeCravings();
  });

  List<Override> overrides() => coachTestOverrides(
    model: model,
    repository: repository,
    checkIns: checkIns,
    cravings: cravings,
  );

  group('controller', () {
    late ProviderContainer container;

    Future<CoachSessionController> start() async {
      container = ProviderContainer.test(overrides: overrides())
        ..listen(provider, (_, _) {});
      await pumpEventQueue();
      // The lint takes the notifier for a Future; it isn't one.
      // ignore: async_return_with_no_await
      return container.read(provider.notifier);
    }

    CoachSessionState state() => container.read(provider);

    test('fewer than 4 of 7 days with a check-in: it never starts, and the '
        'model is never touched', () async {
      checkIns = daysOfWeek(3);
      final controller = await start();
      expect(state().phase, CoachSessionPhase.notEnoughCheckIns);
      expect(state().weekFirst, DateTime(2026, 10, 16));
      expect(model.availabilityChecks, 0);
      expect(model.instructions, isEmpty);

      await controller.startWeeklySession();
      expect(model.prompts, isEmpty);
      await controller.endCoachSession();
      expect(repository.sessions, isEmpty);
    });

    test('4 of 7: primed with the weekly instructions and the finished '
        "week's data, waiting to begin", () async {
      await start();
      expect(state().phase, CoachSessionPhase.awaitingStart);
      final instructions = model.instructions.single;
      expect(instructions, startsWith(CoachInstructions.weeklySession));
      expect(instructions, contains('a finished week'));
      expect(instructions, contains('Fri Oct 16: logged fully'));
      expect(instructions, contains('Thu Oct 22'));
      expect(instructions, isNot(contains('Fri Oct 23')));
      expect(state().topics, [
        WeeklyTopic.logging,
        WeeklyTopic.steps,
        WeeklyTopic.nextWeek,
      ]);
      expect(state().topicIndex, -1);
      expect(model.prompts, isEmpty);
    });

    test(
      'with cravings, a craving topic and their reasons in the data',
      () async {
        cravings.events.add(
          craving(
            'a',
            DateTime(2026, 10, 18, 21),
            reasons: {CravingReason.tired},
          ),
        );
        await start();
        expect(state().topics, contains(WeeklyTopic.cravings));
        expect(model.instructions.single, contains('What was behind them'));
      },
    );

    test(
      'Begin re-checks the rule, then the coach opens with logging',
      () async {
        final controller = await start();
        await controller.startWeeklySession();
        expect(state().topicIndex, 0);
        expect(state().topic, WeeklyTopic.logging);
        expect(
          model.prompts.single.prompt,
          weeklyTopicPrompt(WeeklyTopic.logging),
        );
        expect(state().phase, CoachSessionPhase.ready);
        // The coach spoke first; the app's prompt isn't in the transcript.
        expect(state().session.messages.single.role, CoachMessageRole.coach);
        // Nothing stored until the person says something.
        expect(repository.sessions, isEmpty);
      },
    );

    test('Begin after a new week began (the screen left open into a '
        "Friday) sets the coach up again with that week's data", () async {
      // Thursday night: the last finished week is Oct 9 – 15.
      var now = DateTime(2026, 10, 22, 23);
      checkIns = FakeCheckIns({
        for (var i = 0; i < 4; i++) ...{
          DateTime(2026, 10, 9 + i): CheckInStatus.logged,
          DateTime(2026, 10, 16 + i): CheckInStatus.logged,
        },
      });
      container = ProviderContainer.test(
        overrides: coachTestOverrides(
          model: model,
          repository: repository,
          checkIns: checkIns,
          cravings: cravings,
          now: () => now,
        ),
      )..listen(provider, (_, _) {});
      await pumpEventQueue();
      expect(state().weekFirst, DateTime(2026, 10, 9));
      expect(model.instructions.single, contains('Thu Oct 15'));

      // Friday morning, Begin: the finished week is now Oct 16 – 22.
      now = DateTime(2026, 10, 23, 9);
      await container.read(provider.notifier).startWeeklySession();
      expect(state().weekFirst, DateTime(2026, 10, 16));
      expect(model.instructions, hasLength(2));
      expect(model.instructions.last, contains('Thu Oct 22'));
      expect(model.instructions.last, isNot(contains('Thu Oct 15')));
      // The session primed with the old week is gone; the coach opened
      // logging in the new one.
      expect(model.ended, contains('s0'));
      expect(state().topic, WeeklyTopic.logging);
      expect(state().phase, CoachSessionPhase.ready);
    });

    test('Begin after the week lost check-ins does not start', () async {
      final controller = await start();
      checkIns.statuses.clear();
      await controller.startWeeklySession();
      expect(state().phase, CoachSessionPhase.notEnoughCheckIns);
      expect(model.prompts, isEmpty);
      expect(model.ended, ['s0']);
    });

    test('each next topic is its own thread, in the same session, until '
        'the last', () async {
      final controller = await start();
      await controller.startWeeklySession();
      await controller.sendCoachMessage('Mostly fine, Saturday slipped.');
      await controller.moveToNextWeeklyTopic();
      expect(state().topic, WeeklyTopic.steps);
      expect(model.prompts.last.prompt, weeklyTopicPrompt(WeeklyTopic.steps));
      expect(model.prompts.last.session, 's0');

      await controller.moveToNextWeeklyTopic();
      expect(state().topic, WeeklyTopic.nextWeek);
      expect(state().hasNextTopic, isFalse);
      final prompts = model.prompts.length;
      await controller.moveToNextWeeklyTopic();
      expect(model.prompts, hasLength(prompts));
    });

    test('ends with a stored summary of the whole session', () async {
      final controller = await start();
      await controller.startWeeklySession();
      await controller.sendCoachMessage('Weekends are hard.');
      await controller.endCoachSession();
      final stored = repository.sessions.single;
      expect(stored.kind, CoachSessionKind.weekly);
      expect(stored.summary, 'A short summary.');
      expect(stored.endedAt, coachTestNow);
    });

    test('a move is ignored while the coach replies', () async {
      model.manualReplies = true;
      final controller = await start();
      unawaited(controller.startWeeklySession());
      await pumpEventQueue();
      await controller.moveToNextWeeklyTopic();
      expect(model.prompts, hasLength(1));
    });
  });

  group('screen', () {
    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: ShadcnApp(
            theme: steadyTheme,
            home: CoachSessionModule(
              kind: CoachSessionKind.weekly,
              onClosed: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('shows the week and its topics, then Begin opens logging', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Weekly check-in'), findsOneWidget);
      expect(find.text('Oct 16 – 22 · about 5 minutes'), findsOneWidget);
      expect(find.text('Look back on Oct 16 – 22'), findsOneWidget);
      expect(
        find.textContaining('logging, steps and next week'),
        findsOneWidget,
      );
      expect(find.text(CoachCopy.notMedicalAdvice), findsOneWidget);

      await tester.tap(find.byKey(const Key('coachWeeklyBegin')));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('coachTopicRow')), findsOneWidget);
      expect(find.text('Coach reply.'), findsOneWidget);
      expect(find.text('Next: steps'), findsOneWidget);

      await tester.tap(find.byKey(const Key('coachNextTopic')));
      await tester.pump();
      await tester.pump();
      expect(find.text('Next: next week'), findsOneWidget);
    });

    testWidgets('the topic row says where you are, as a position only', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);
      await tester.tap(find.byKey(const Key('coachWeeklyBegin')));
      await tester.pump();
      await tester.pump();
      expect(find.bySemanticsLabel('Topic 1 of 3: Logging'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a thin week explains, kindly, and offers no Begin', (
      tester,
    ) async {
      checkIns = daysOfWeek(2);
      await pump(tester);
      expect(find.byKey(const Key('coachNotEnoughCheckIns')), findsOneWidget);
      expect(find.byKey(const Key('coachWeeklyBegin')), findsNothing);
      expect(find.textContaining('A chat works any time'), findsOneWidget);
    });
  });
}
