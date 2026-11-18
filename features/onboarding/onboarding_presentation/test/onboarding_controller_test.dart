import 'dart:async';

import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onboarding_domain/onboarding_domain.dart';
import 'package:onboarding_presentation/onboarding_presentation.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/recording_onboarding_repository.dart';

void main() {
  late RecordingOnboardingRepository repository;

  ProviderContainer containerFor(RecordingOnboardingRepository repo) {
    repository = repo;
    final container = ProviderContainer.test(
      overrides: [onboardingRepositoryProvider.overrideWithValue(repo)],
    )..listen(onboardingControllerProvider, (_, _) {});
    return container;
  }

  /// The controller, once its first read is done.
  Future<OnboardingController> started(ProviderContainer container) => container
      .read(onboardingControllerProvider.future)
      .then((_) => container.read(onboardingControllerProvider.notifier));

  OnboardingFlowState flowOf(ProviderContainer container) =>
      container.read(onboardingControllerProvider).requireValue;

  group('build', () {
    test(
      'a first launch starts on the first stone, nothing answered',
      () async {
        final container = containerFor(RecordingOnboardingRepository());
        await started(container);
        final flow = flowOf(container);
        expect(flow.step, OnboardingStep.firstStone);
        expect(flow.aboutMe, AboutMe.empty);
        expect(flow.stones, isEmpty);
        expect(flow.cairn.first, OnboardingStone.pending);
      },
    );

    test('resumes on the saved step with the answers filled in', () async {
      const aboutMe = AboutMe(
        tracking: FoodTracking.calAi,
        hardParts: {HardPart.travel},
      );
      final container = containerFor(
        RecordingOnboardingRepository(
          const OnboardingRecord(step: OnboardingStep.voice, aboutMe: aboutMe),
        ),
      );
      await started(container);
      final flow = flowOf(container);
      expect(flow.step, OnboardingStep.voice);
      expect(flow.aboutMe, aboutMe);
      // Answered questions placed stones; the unanswered week a dimmer one;
      // the screens that store nothing a full one.
      expect(flow.cairn, [
        OnboardingStone.placed, // firstStone
        OnboardingStone.placed, // tracking
        OnboardingStone.placed, // source
        OnboardingStone.placed, // health
        OnboardingStone.dimmed, // week
        OnboardingStone.placed, // hardParts
        OnboardingStone.pending, // voice
        OnboardingStone.none,
        OnboardingStone.none,
      ]);
    });

    test('a failed read is an AsyncError carrying the Failure, '
        'without retrying', () async {
      final repo = RecordingOnboardingRepository();
      repo.store.failNextWith = const OnboardingStorageFailure('disk');
      final container = containerFor(repo);
      await expectLater(
        container.read(onboardingControllerProvider.future),
        throwsA(isA<OnboardingStorageFailure>()),
      );
      expect(
        container.read(onboardingControllerProvider).error,
        isA<OnboardingStorageFailure>(),
      );
      expect(repo.calls, ['read']);
    });
  });

  group('answers', () {
    test(
      'each answer moves on at once and saves About me and the step',
      () async {
        final container = containerFor(RecordingOnboardingRepository());
        final controller = await started(container);

        await controller.answerFoodTracking(FoodTracking.otherHealthApp);
        expect(flowOf(container).step, OnboardingStep.source);
        expect(repository.record.aboutMe.tracking, FoodTracking.otherHealthApp);
        expect(repository.record.step, OnboardingStep.source);

        await controller.answerYourWeek(
          activities: {OnboardingActivity.yoga},
          weekends: WeekendShape.mixed,
        );
        await controller.answerHardParts({HardPart.forgetting});
        await controller.chooseCoachVoice(CoachVoice.playful);
        await controller.meetCoach(consentGiven: true, note: '  Night shifts ');

        expect(
          repository.record.aboutMe,
          const AboutMe(
            tracking: FoodTracking.otherHealthApp,
            activities: {OnboardingActivity.yoga},
            weekends: WeekendShape.mixed,
            hardParts: {HardPart.forgetting},
            voice: CoachVoice.playful,
            note: 'Night shifts',
          ),
        );
        expect(repository.record.step, OnboardingStep.firstWeek);
        expect(repository.record.completed, isFalse);
      },
    );

    test('a skipped step places a dimmer stone and saves no answer', () async {
      final container = containerFor(RecordingOnboardingRepository());
      final controller = await started(container);

      await controller.skipOnboardingStep(OnboardingStep.firstStone);
      await controller.skipOnboardingStep(OnboardingStep.tracking);

      final flow = flowOf(container);
      expect(flow.step, OnboardingStep.source);
      expect(flow.stones, {
        OnboardingStep.firstStone: OnboardingStone.dimmed,
        OnboardingStep.tracking: OnboardingStone.dimmed,
      });
      expect(repository.record.aboutMe, AboutMe.empty);
      expect(repository.calls, isNot(contains('saveAboutMe')));
      expect(repository.record.step, OnboardingStep.source);
    });

    test('a second tap on the same screen does not skip a screen', () async {
      final container = containerFor(RecordingOnboardingRepository());
      final controller = await started(container);
      await Future.wait([
        controller.completeOnboardingStep(OnboardingStep.firstStone),
        controller.completeOnboardingStep(OnboardingStep.firstStone),
      ]);
      expect(flowOf(container).step, OnboardingStep.tracking);
    });

    test('meeting the coach: either answer moves on; the stone is dimmer '
        'only with no consent and no note', () async {
      final container = containerFor(
        RecordingOnboardingRepository(
          const OnboardingRecord(step: OnboardingStep.meetCoach),
        ),
      );
      final controller = await started(container);

      await controller.meetCoach(consentGiven: false, note: '   ');
      expect(flowOf(container).step, OnboardingStep.firstWeek);
      expect(
        flowOf(container).stones[OnboardingStep.meetCoach],
        OnboardingStone.dimmed,
      );
      expect(repository.record.aboutMe.note, isNull);

      await controller.meetCoach(consentGiven: false, note: 'Shift work');
      expect(
        flowOf(container).stones[OnboardingStep.meetCoach],
        OnboardingStone.placed,
      );

      await controller.meetCoach(consentGiven: true);
      expect(
        flowOf(container).stones[OnboardingStep.meetCoach],
        OnboardingStone.placed,
      );
    });

    test('a note longer than the limit is cut, not refused', () async {
      final container = containerFor(RecordingOnboardingRepository());
      final controller = await started(container);
      await controller.meetCoach(
        consentGiven: false,
        note: 'x' * (aboutMeNoteMaxChars + 20),
      );
      expect(repository.record.aboutMe.note, hasLength(aboutMeNoteMaxChars));
      expect(flowOf(container).saveFailure, isNull);
    });

    test('placing the first stone places it without saving', () async {
      final container = containerFor(RecordingOnboardingRepository());
      final controller = await started(container);
      controller.placeFirstStone();
      expect(
        flowOf(container).stones[OnboardingStep.firstStone],
        OnboardingStone.placed,
      );
      expect(flowOf(container).step, OnboardingStep.firstStone);
      expect(repository.calls, ['read']);
    });
  });

  group('moving and leaving', () {
    test('moving back saves the step and keeps the stones', () async {
      final container = containerFor(RecordingOnboardingRepository());
      final controller = await started(container);
      await controller.completeOnboardingStep(OnboardingStep.firstStone);
      await controller.answerFoodTracking(FoodTracking.calAi);

      await controller.moveToOnboardingStep(OnboardingStep.tracking);
      final flow = flowOf(container);
      expect(flow.step, OnboardingStep.tracking);
      expect(flow.stones.keys, [
        OnboardingStep.firstStone,
        OnboardingStep.tracking,
      ]);
      expect(repository.record.step, OnboardingStep.tracking);
    });

    test('leaving marks onboarding done and keeps the answers', () async {
      final container = containerFor(RecordingOnboardingRepository());
      final controller = await started(container);
      await controller.answerFoodTracking(FoodTracking.justStarting);
      await controller.leaveOnboarding();
      expect(repository.record.completed, isTrue);
      expect(repository.record.aboutMe.tracking, FoodTracking.justStarting);
    });

    test('leaving works after a failed read', () async {
      final repo = RecordingOnboardingRepository();
      repo.store.failNextWith = const OnboardingStorageFailure('disk');
      final container = containerFor(repo);
      await expectLater(
        container.read(onboardingControllerProvider.future),
        throwsA(isA<Failure>()),
      );
      await container
          .read(onboardingControllerProvider.notifier)
          .leaveOnboarding();
      expect(repo.record.completed, isTrue);
    });

    test('finishing waits for the saves before it, in order', () async {
      final container = containerFor(RecordingOnboardingRepository());
      final controller = await started(container);
      final hold = repository.holdWrites = Completer<void>();

      final answered = controller.chooseCoachVoice(CoachVoice.gentle);
      final finished = controller.finishOnboarding();
      // Shown at once, even while the save is held.
      expect(flowOf(container).step, OnboardingStep.meetCoach);
      await pumpEventQueue();
      expect(repository.calls, ['read', 'saveAboutMe']);

      hold.complete();
      await Future.wait([answered, finished]);
      expect(repository.calls, [
        'read',
        'saveAboutMe',
        'saveStep:meetCoach',
        'markCompleted',
      ]);
      expect(repository.record.completed, isTrue);
      expect(repository.record.aboutMe.voice, CoachVoice.gentle);
    });
  });

  group('a failed save never stops the flow', () {
    test(
      'the flow moves on and the failure is reported in the state',
      () async {
        final container = containerFor(RecordingOnboardingRepository());
        final controller = await started(container);
        repository.store.failNextWith = const OnboardingStorageFailure('disk');

        await controller.answerFoodTracking(FoodTracking.calAi);
        final flow = flowOf(container);
        expect(flow.step, OnboardingStep.source);
        expect(flow.aboutMe.tracking, FoodTracking.calAi);
        expect(flow.saveFailure, isA<OnboardingStorageFailure>());
        expect(container.read(onboardingControllerProvider).hasError, isFalse);

        // The next event clears it.
        await controller.completeOnboardingStep(OnboardingStep.source);
        expect(flowOf(container).saveFailure, isNull);
        expect(repository.record.step, OnboardingStep.health);
      },
    );

    test('a failed markCompleted still completes the call', () async {
      final container = containerFor(RecordingOnboardingRepository());
      final controller = await started(container);
      repository.store.failNextWith = const OnboardingStorageFailure('disk');
      await controller.leaveOnboarding();
      expect(flowOf(container).saveFailure, isA<OnboardingStorageFailure>());
      expect(repository.record.completed, isFalse);
    });
  });

  test(
    'a save that finishes after the screen is gone does not throw',
    () async {
      final repo = RecordingOnboardingRepository();
      final container = ProviderContainer.test(
        overrides: [onboardingRepositoryProvider.overrideWithValue(repo)],
      );
      final sub = container.listen(onboardingControllerProvider, (_, _) {});
      await container.read(onboardingControllerProvider.future);
      final controller = container.read(onboardingControllerProvider.notifier);
      final hold = repo.holdWrites = Completer<void>();

      final pending = controller.answerFoodTracking(FoodTracking.calAi);
      sub.close();
      await pumpEventQueue();

      hold.complete();
      await pending;
      expect(repo.record.aboutMe.tracking, FoodTracking.calAi);
    },
  );

  group('review fixes', () {
    test('an answered current screen resumes with its stone, '
        'one that stores nothing with its stone still to place', () async {
      final answered = containerFor(
        RecordingOnboardingRepository(
          const OnboardingRecord(
            step: OnboardingStep.voice,
            aboutMe: AboutMe(voice: CoachVoice.direct),
          ),
        ),
      );
      await started(answered);
      expect(
        flowOf(answered).stones[OnboardingStep.voice],
        OnboardingStone.placed,
      );
      expect(
        flowOf(answered).cairn[OnboardingStep.voice.index],
        OnboardingStone.placed,
      );

      final unanswered = containerFor(
        RecordingOnboardingRepository(
          const OnboardingRecord(step: OnboardingStep.health),
        ),
      );
      await started(unanswered);
      expect(flowOf(unanswered).stones, isNot(contains(OnboardingStep.health)));
      expect(
        flowOf(unanswered).cairn[OnboardingStep.health.index],
        OnboardingStone.pending,
      );
    });

    test('a failed About me save still saves the step', () async {
      final container = containerFor(RecordingOnboardingRepository());
      final controller = await started(container);
      repository.store.failNextWith = const OnboardingStorageFailure('disk');

      await controller.answerFoodTracking(FoodTracking.calAi);

      expect(repository.calls, ['read', 'saveAboutMe', 'saveStep:source']);
      // A relaunch resumes on the screen the person is on.
      expect(repository.record.step, OnboardingStep.source);
      expect(repository.record.aboutMe, AboutMe.empty);
      expect(flowOf(container).saveFailure, isA<OnboardingStorageFailure>());
    });

    test('an earlier failure finishing late does not outlive a later '
        'success', () async {
      final container = containerFor(RecordingOnboardingRepository());
      final controller = await started(container);
      final hold = repository.holdWrites = Completer<void>();
      repository.store.failNextWith = const OnboardingStorageFailure('disk');

      final first = controller.answerFoodTracking(FoodTracking.calAi);
      final second = controller.completeOnboardingStep(OnboardingStep.source);
      hold.complete();
      await first;
      // The first save failed after the second event cleared the error.
      expect(flowOf(container).saveFailure, isA<OnboardingStorageFailure>());
      await second;
      expect(flowOf(container).saveFailure, isNull);
      expect(repository.record.step, OnboardingStep.health);
    });

    test('the latest save failing keeps the error', () async {
      final container = containerFor(RecordingOnboardingRepository());
      final controller = await started(container);
      await controller.answerFoodTracking(FoodTracking.calAi);
      repository.store.failNextWith = const OnboardingStorageFailure('disk');
      await controller.completeOnboardingStep(OnboardingStep.source);
      expect(flowOf(container).saveFailure, isA<OnboardingStorageFailure>());
    });
  });
}
