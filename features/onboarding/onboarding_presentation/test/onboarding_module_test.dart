import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onboarding_domain/onboarding_domain.dart';
import 'package:onboarding_presentation/onboarding_presentation.dart';
import 'package:onboarding_presentation/src/onboarding_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/recording_onboarding_repository.dart';

late RecordingOnboardingRepository repository;
late ProviderContainer container;
late List<OnboardingStep> leftAt;
late int finished;
late List<String> sources;
late int healthAsks;
late List<bool> consentAnswers;

/// What the consent callback returns next.
bool consentResult = true;

Future<void> pumpModule(
  WidgetTester tester, {
  OnboardingRecord record = OnboardingRecord.initial,
  bool reducedMotion = false,
  double textScale = 1,
  void Function(RecordingOnboardingRepository)? arrange,
}) async {
  tester.view
    ..physicalSize = const Size(390 * 3, 844 * 3)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  repository = RecordingOnboardingRepository(record);
  arrange?.call(repository);
  container = ProviderContainer.test(
    overrides: [onboardingRepositoryProvider.overrideWithValue(repository)],
  );
  leftAt = [];
  finished = 0;
  sources = [];
  healthAsks = 0;
  consentAnswers = [];
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: ShadcnApp(
        theme: steadyTheme,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reducedMotion,
              textScaler: TextScaler.linear(textScale),
            ),
            child: OnboardingModule(
              onFinished: () => finished++,
              onLeft: leftAt.add,
              onSourceChosen: sources.add,
              onHealthRequested: () async => healthAsks++,
              onConsentRequested: () async {
                consentAnswers.add(consentResult);
                return consentResult;
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder byKey(String key) => find.byKey(Key(key));

/// Whether the main button can be pressed.
bool continueEnabled(WidgetTester tester) =>
    tester.widget<PrimaryButton>(byKey('onboardingContinue')).onPressed != null;

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(byKey(key));
  await tester.tap(byKey(key));
  await tester.pumpAndSettle();
}

Future<void> tapOption(WidgetTester tester, String code) =>
    tapKey(tester, 'onboardingOption_$code');

Future<void> tapContinue(WidgetTester tester) =>
    tapKey(tester, 'onboardingContinue');

Future<void> tapSkip(WidgetTester tester) => tapKey(tester, 'onboardingSkip');

/// The header cairn's slots, bottom first.
List<OnboardingStone> headerCairn(WidgetTester tester) => tester
    .widget<OnboardingCairn>(
      find.descendant(
        of: byKey('onboardingHeaderCairn'),
        matching: find.byType(OnboardingCairn),
      ),
    )
    .stones;

bool optionSelected(WidgetTester tester, String code) {
  final widget = tester.widget(byKey('onboardingOption_$code'));
  return switch (widget) {
    OnboardingChip(:final selected) => selected,
    OnboardingChoiceRow(:final selected) => selected,
    _ => throw StateError('Not an answer: $widget'),
  };
}

void main() {
  setUp(() => consentResult = true);

  group('resuming', () {
    testWidgets('opens on the saved screen with the answers filled in', (
      tester,
    ) async {
      await pumpModule(
        tester,
        record: const OnboardingRecord(
          step: OnboardingStep.hardParts,
          aboutMe: AboutMe(
            tracking: FoodTracking.calAi,
            hardParts: {HardPart.travel, HardPart.lateNights},
          ),
        ),
      );
      expect(find.text(OnboardingCopy.hardPartsTitle), findsOneWidget);
      expect(optionSelected(tester, 'travel'), isTrue);
      expect(optionSelected(tester, 'lateNights'), isTrue);
      expect(optionSelected(tester, 'eatingOut'), isFalse);
      expect(continueEnabled(tester), isTrue);
      expect(headerCairn(tester).take(6), [
        OnboardingStone.placed,
        OnboardingStone.placed,
        OnboardingStone.placed,
        OnboardingStone.placed,
        OnboardingStone.dimmed, // the week wasn't answered
        // The screen it resumed on is answered, so its stone is there.
        OnboardingStone.placed,
      ]);

      // Going back shows the earlier answer too.
      await tapKey(tester, 'onboardingBack');
      await tapKey(tester, 'onboardingBack');
      await tapKey(tester, 'onboardingBack');
      await tapKey(tester, 'onboardingBack');
      expect(find.text(OnboardingCopy.trackingTitle), findsOneWidget);
      expect(optionSelected(tester, 'calAi'), isTrue);
      expect(repository.record.step, OnboardingStep.tracking);
    });
  });

  group('answering', () {
    testWidgets('Continue is disabled until the screen is answered', (
      tester,
    ) async {
      await pumpModule(
        tester,
        record: const OnboardingRecord(step: OnboardingStep.tracking),
      );
      expect(continueEnabled(tester), isFalse);
      await tapOption(tester, 'justStarting');
      expect(continueEnabled(tester), isTrue);
    });

    testWidgets('the first stone must be placed before Continue', (
      tester,
    ) async {
      await pumpModule(tester);
      expect(continueEnabled(tester), isFalse);
      expect(headerCairn(tester).first, OnboardingStone.pending);

      await tester.tap(byKey('onboardingFirstStone'));
      await tester.pump();
      // Falling and wobbling.
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();

      expect(continueEnabled(tester), isTrue);
      expect(find.text(OnboardingCopy.firstStonePlaced), findsOneWidget);
      expect(headerCairn(tester).first, OnboardingStone.placed);
    });

    testWidgets('the first stone can be dragged to the ground', (tester) async {
      await pumpModule(tester);
      await tester.drag(byKey('onboardingFirstStone'), const Offset(0, 160));
      await tester.pumpAndSettle();
      expect(continueEnabled(tester), isTrue);
    });

    testWidgets('a short drag springs back and places nothing', (tester) async {
      await pumpModule(tester);
      await tester.timedDrag(
        byKey('onboardingFirstStone'),
        const Offset(0, 20),
        const Duration(milliseconds: 400),
      );
      await tester.pumpAndSettle();
      expect(continueEnabled(tester), isFalse);
    });

    testWidgets('a skip places a dimmer stone and saves nothing for it', (
      tester,
    ) async {
      await pumpModule(
        tester,
        record: const OnboardingRecord(step: OnboardingStep.tracking),
      );
      await tapOption(tester, 'calAi');
      await tapSkip(tester);

      expect(find.text(OnboardingCopy.sourceTitle), findsOneWidget);
      expect(headerCairn(tester)[1], OnboardingStone.dimmed);
      expect(repository.record.aboutMe, AboutMe.empty);
      expect(repository.calls, isNot(contains('saveAboutMe')));
      expect(repository.record.step, OnboardingStep.source);
    });

    testWidgets('every answer reaches the repository with the right codes', (
      tester,
    ) async {
      await pumpModule(tester);

      // 1. The first stone.
      await tester.tap(byKey('onboardingFirstStone'));
      await tester.pumpAndSettle();
      await tapContinue(tester);

      // 2. Tracking.
      await tapOption(tester, 'calAi');
      await tapContinue(tester);
      expect(repository.record.aboutMe.tracking, FoodTracking.calAi);

      // 3. Where you heard about Steady: sent, never stored.
      await tapOption(tester, 'tiktok');
      await tapContinue(tester);
      expect(sources, ['tiktok']);

      // 4. Apple Health.
      expect(find.byType(MetricTile), findsNWidgets(3));
      await tapContinue(tester);
      expect(healthAsks, 1);

      // 5. Your week.
      await tapOption(tester, 'tennis');
      await tapOption(tester, 'walks');
      await tapOption(tester, 'busier');
      await tapContinue(tester);

      // 6. What gets in the way.
      await tapOption(tester, 'eatingOut');
      await tapOption(tester, 'lateNights');
      await tapContinue(tester);

      // 7. Voice, marked paid, with the sample reply in that voice.
      expect(find.byType(PaidBadge), findsOneWidget);
      expect(byKey('onboardingSampleReply'), findsNothing);
      await tapOption(tester, 'direct');
      expect(
        find.text(OnboardingCopy.sampleReply(CoachVoice.direct)),
        findsOneWidget,
      );
      await tapContinue(tester);

      // 8. Meet the coach, marked paid; the note, then consent.
      expect(find.byType(PaidBadge), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: byKey('onboardingNote'),
          matching: find.byType(EditableText),
        ),
        'I work nights twice a month',
      );
      await tapContinue(tester);
      expect(consentAnswers, [true]);

      // 9. Your first week, built from the answers.
      expect(
        find.text('When you eat out, log a rough guess. Close enough counts.'),
        findsOneWidget,
      );
      expect(
        find.text('On tennis days, log lunch before you head out.'),
        findsOneWidget,
      );
      await tapContinue(tester);

      // 10. The cairn, then Today.
      expect(find.text(OnboardingCopy.cairnNext), findsOneWidget);
      final cairn = tester.widget<OnboardingCairn>(
        byKey('onboardingFinalCairn'),
      );
      expect(cairn.stones, [
        ...List.filled(9, OnboardingStone.placed),
        OnboardingStone.pending,
      ]);
      expect(byKey('onboardingNotNow'), findsNothing);
      await tapContinue(tester);

      expect(finished, 1);
      expect(leftAt, isEmpty);
      expect(
        repository.record,
        const OnboardingRecord(
          completed: true,
          aboutMe: AboutMe(
            tracking: FoodTracking.calAi,
            activities: {OnboardingActivity.tennis, OnboardingActivity.walks},
            weekends: WeekendShape.busier,
            hardParts: {HardPart.eatingOut, HardPart.lateNights},
            voice: CoachVoice.direct,
            note: 'I work nights twice a month',
          ),
        ),
      );
    });

    testWidgets('a skipped step shows as a dimmer stone at the end', (
      tester,
    ) async {
      await pumpModule(
        tester,
        record: const OnboardingRecord(step: OnboardingStep.firstWeek),
      );
      await tapContinue(tester);
      final cairn = tester.widget<OnboardingCairn>(
        byKey('onboardingFinalCairn'),
      );
      // Every unanswered question resumed as a dimmer stone, never a gap.
      expect(cairn.stones, hasLength(10));
      expect(cairn.stones, contains(OnboardingStone.dimmed));
      expect(cairn.stones, isNot(contains(OnboardingStone.none)));
      expect(find.text(OnboardingCopy.cairnSkipped), findsOneWidget);
    });
  });

  group('screen 3', () {
    testWidgets('sends the source only when one is chosen', (tester) async {
      await pumpModule(
        tester,
        record: const OnboardingRecord(step: OnboardingStep.source),
      );
      await tapSkip(tester);
      expect(sources, isEmpty);
      expect(find.text(OnboardingCopy.healthTitle), findsOneWidget);

      // Back to it: nothing is filled in, since nothing was stored.
      await tapKey(tester, 'onboardingBack');
      expect(continueEnabled(tester), isFalse);
      await tapOption(tester, 'friend');
      expect(sources, isEmpty);
      await tapContinue(tester);
      expect(sources, ['friend']);
      expect(repository.record.aboutMe, AboutMe.empty);
    });

    testWidgets('leaving from it sends nothing', (tester) async {
      await pumpModule(
        tester,
        record: const OnboardingRecord(step: OnboardingStep.source),
      );
      await tapOption(tester, 'reddit');
      await tapKey(tester, 'onboardingNotNow');
      expect(sources, isEmpty);
      expect(leftAt, [OnboardingStep.source]);
    });
  });

  group('"Not now"', () {
    for (final step in [
      OnboardingStep.firstStone,
      OnboardingStep.health,
      OnboardingStep.week,
      OnboardingStep.voice,
      OnboardingStep.meetCoach,
      OnboardingStep.firstWeek,
    ]) {
      testWidgets('on ${step.name} marks onboarding done and reports where', (
        tester,
      ) async {
        await pumpModule(
          tester,
          record: OnboardingRecord(
            step: step,
            aboutMe: const AboutMe(tracking: FoodTracking.calAi),
          ),
        );
        await tapKey(tester, 'onboardingNotNow');
        expect(repository.calls, contains('markCompleted'));
        expect(repository.record.completed, isTrue);
        // The answers given so far are kept.
        expect(repository.record.aboutMe.tracking, FoodTracking.calAi);
        expect(leftAt, [step]);
        expect(finished, 0);
      });
    }
  });

  group('screen 8', () {
    for (final given in [true, false]) {
      testWidgets('consent ${given ? 'given' : 'declined'} moves on', (
        tester,
      ) async {
        consentResult = given;
        await pumpModule(
          tester,
          record: const OnboardingRecord(step: OnboardingStep.meetCoach),
        );
        await tapContinue(tester);
        expect(consentAnswers, [given]);
        expect(find.text(OnboardingCopy.firstWeekTitle), findsOneWidget);
        expect(
          headerCairn(tester)[OnboardingStep.meetCoach.index],
          given ? OnboardingStone.placed : OnboardingStone.dimmed,
        );
      });
    }

    testWidgets('skip asks for no consent and saves no note', (tester) async {
      await pumpModule(
        tester,
        record: const OnboardingRecord(step: OnboardingStep.meetCoach),
      );
      await tester.enterText(
        find.descendant(
          of: byKey('onboardingNote'),
          matching: find.byType(EditableText),
        ),
        'Not this',
      );
      await tapSkip(tester);
      expect(consentAnswers, isEmpty);
      expect(repository.record.aboutMe.note, isNull);
    });

    testWidgets('a consent callback that throws still moves on', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(390 * 3, 844 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      repository = RecordingOnboardingRepository(
        const OnboardingRecord(step: OnboardingStep.meetCoach),
      );
      container = ProviderContainer.test(
        overrides: [onboardingRepositoryProvider.overrideWithValue(repository)],
      );
      final reported = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = previous);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: ShadcnApp(
            theme: steadyTheme,
            home: OnboardingModule(
              onFinished: () {},
              onLeft: (_) {},
              onSourceChosen: (_) {},
              onHealthRequested: () async {},
              onConsentRequested: () async => throw StateError('no route'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tapContinue(tester);
      expect(find.text(OnboardingCopy.firstWeekTitle), findsOneWidget);
      expect(reported, hasLength(1));
    });
  });

  group('reduced motion', () {
    // shadcn_flutter's Clickable cross-fades a button's colours over its
    // own 150 ms (kDefaultDuration) whatever the motion setting, e.g. when
    // Continue becomes enabled. That's a colour fade, not movement, and not
    // ours; so each check lets 150 ms pass, which is shorter than every
    // onboarding animation (the fall alone is 380 ms, the stone's drop into
    // the cairn 350 ms, a screen change 280 ms).
    Future<void> pastShadcnFade(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 151));
    }

    testWidgets('the stone and the screens just appear', (tester) async {
      await pumpModule(tester, reducedMotion: true);
      await tester.tap(byKey('onboardingFirstStone'));
      await tester.pump();
      // On the ground and in the cairn at once.
      expect(find.text(OnboardingCopy.firstStonePlaced), findsOneWidget);
      expect(headerCairn(tester).first, OnboardingStone.placed);
      await pastShadcnFade(tester);
      expect(tester.hasRunningAnimations, isFalse);
      expect(continueEnabled(tester), isTrue);

      await tester.tap(byKey('onboardingContinue'));
      await tester.pump();
      // The next screen replaces the last with no cross-fade.
      expect(find.text(OnboardingCopy.trackingTitle), findsOneWidget);
      expect(find.text(OnboardingCopy.firstStoneTitle), findsNothing);
      await pastShadcnFade(tester);
      expect(tester.hasRunningAnimations, isFalse);

      await tester.tap(byKey('onboardingSkip'));
      await pastShadcnFade(tester);
      expect(tester.hasRunningAnimations, isFalse);
      expect(headerCairn(tester)[1], OnboardingStone.dimmed);
    });

    testWidgets('with motion, a screen change animates', (tester) async {
      await pumpModule(
        tester,
        record: const OnboardingRecord(step: OnboardingStep.tracking),
      );
      await tester.tap(byKey('onboardingSkip'));
      await tester.pump();
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
    });
  });

  group('a repository failure never traps anyone', () {
    testWidgets('a failed save shows a quiet line and the flow goes on', (
      tester,
    ) async {
      await pumpModule(
        tester,
        record: const OnboardingRecord(step: OnboardingStep.tracking),
      );
      repository.store.failNextWith = const OnboardingStorageFailure('disk');
      await tapOption(tester, 'calAi');
      await tapContinue(tester);

      expect(find.text(OnboardingCopy.sourceTitle), findsOneWidget);
      expect(byKey('onboardingSaveFailed'), findsOneWidget);

      // Still free to go on, or to leave.
      await tapSkip(tester);
      expect(find.text(OnboardingCopy.healthTitle), findsOneWidget);
      expect(byKey('onboardingSaveFailed'), findsNothing);
      await tapKey(tester, 'onboardingNotNow');
      expect(leftAt, [OnboardingStep.health]);
    });

    testWidgets('a failed "Not now" save still leaves', (tester) async {
      await pumpModule(
        tester,
        record: const OnboardingRecord(step: OnboardingStep.voice),
      );
      repository.store.failNextWith = const OnboardingStorageFailure('disk');
      await tapKey(tester, 'onboardingNotNow');
      expect(leftAt, [OnboardingStep.voice]);
    });

    testWidgets('a failed read offers to try again or leave', (tester) async {
      await pumpModule(
        tester,
        arrange: (repo) =>
            repo.store.failNextWith = const OnboardingStorageFailure('disk'),
      );
      expect(byKey('onboardingReadFailed'), findsOneWidget);
      expect(find.text(OnboardingCopy.readFailed), findsOneWidget);

      await tapContinue(tester);
      expect(find.text(OnboardingCopy.firstStoneTitle), findsOneWidget);
    });

    testWidgets('leaving after a failed read marks onboarding done', (
      tester,
    ) async {
      await pumpModule(
        tester,
        arrange: (repo) =>
            repo.store.failNextWith = const OnboardingStorageFailure('disk'),
      );
      await tapKey(tester, 'onboardingNotNow');
      expect(leftAt, [OnboardingStep.firstStone]);
      expect(repository.record.completed, isTrue);
    });
  });

  group('accessibility', () {
    testWidgets('the stone and the cairn have labels', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpModule(tester);
      expect(
        find.bySemanticsLabel(OnboardingCopy.stoneToPlace),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Your cairn: no stones yet. The next stone is still to place.',
        ),
        findsOneWidget,
      );

      await tester.tap(byKey('onboardingFirstStone'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(OnboardingCopy.stonePlaced), findsOneWidget);
      expect(
        find.bySemanticsLabel('Your cairn: 1 stone. ', skipOffstage: false),
        findsNothing,
      );
      expect(find.bySemanticsLabel('Your cairn: 1 stone.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('answers are buttons a screen reader can select', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpModule(
        tester,
        record: const OnboardingRecord(step: OnboardingStep.week),
      );
      for (final code in ['tennis', 'quieter']) {
        final node = tester.getSemantics(byKey('onboardingOption_$code'));
        expect(
          node,
          isSemantics(isButton: true, isSelected: false, hasTapAction: true),
        );
        node.owner!.performAction(node.id, SemanticsAction.tap);
        await tester.pumpAndSettle();
        expect(optionSelected(tester, code), isTrue);
      }
      expect(
        tester.getSemantics(byKey('onboardingOption_quieter')),
        isSemantics(label: 'Quieter', isSelected: true),
      );
      handle.dispose();
    });

    for (final step in OnboardingStep.values) {
      testWidgets('${step.name} reads at twice the text size', (tester) async {
        await pumpModule(
          tester,
          textScale: 2,
          record: OnboardingRecord(
            step: step,
            aboutMe: const AboutMe(
              voice: CoachVoice.playful,
              hardParts: {HardPart.feelingJudged},
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(byKey('onboardingContinue'), findsOneWidget);
      });
    }
  });

  group('review fixes', () {
    testWidgets('the header keeps its height on the last screen', (
      tester,
    ) async {
      await pumpModule(
        tester,
        record: const OnboardingRecord(step: OnboardingStep.firstWeek),
      );
      final before = tester.getSize(find.byType(OnboardingHeader)).height;
      final titleBefore = tester.getTopLeft(
        find.text(OnboardingCopy.firstWeekTitle),
      );
      await tapContinue(tester);
      expect(find.text(OnboardingCopy.cairnTitle), findsOneWidget);
      expect(tester.getSize(find.byType(OnboardingHeader)).height, before);
      expect(
        tester.getTopLeft(find.text(OnboardingCopy.cairnTitle)).dy,
        titleBefore.dy,
      );
    });

    testWidgets('"Not now" after a failed read runs once on a double tap', (
      tester,
    ) async {
      late Completer<void> hold;
      await pumpModule(
        tester,
        arrange: (repo) {
          repo.store.failNextWith = const OnboardingStorageFailure('disk');
          hold = repo.holdWrites = Completer<void>();
        },
      );
      expect(byKey('onboardingReadFailed'), findsOneWidget);

      await tester.tap(byKey('onboardingNotNow'));
      await tester.tap(byKey('onboardingNotNow'), warnIfMissed: false);
      await tester.pump();
      // Hidden while it runs.
      expect(byKey('onboardingNotNow'), findsNothing);
      hold.complete();
      await tester.pumpAndSettle();

      expect(repository.calls.where((c) => c == 'markCompleted'), hasLength(1));
      expect(leftAt, [OnboardingStep.firstStone]);
    });
  });
}
