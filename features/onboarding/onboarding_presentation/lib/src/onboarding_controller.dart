import 'dart:async';

import 'package:failures/failures.dart';
import 'package:onboarding_domain/onboarding_domain.dart';
import 'package:onboarding_presentation/src/onboarding_flow_state.dart';
import 'package:onboarding_presentation/src/providers.dart';
import 'package:onboarding_presentation/src/retry_unless_failure.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ui_kit/ui_kit.dart';

part 'onboarding_controller.g.dart';

/// The onboarding flow: which screen the person is on, their answers and
/// the stones placed, over the stored `OnboardingRecord`.
///
/// `build` reads the record and resumes on its step with the answers filled
/// in ([OnboardingFlowState.resumedFrom]); a failed read is an `AsyncError`
/// carrying the `Failure`, and the screen offers to try again or leave.
///
/// **Every event shows at once and saves behind it.** Each answer is saved
/// as it's given, with the screen the person moves to, so closing the app
/// mid-flow resumes there. Saves run one at a time, in order. A failed save
/// sets [OnboardingFlowState.saveFailure] and never holds the person back:
/// nothing in onboarding traps anyone (docs/design/onboarding.md, "Leaving
/// early"). That's why the events don't pass through `AsyncLoading`, unlike
/// `CheckInController`: a write never replaces the screen.
///
/// The events that move on name the step they belong to, so a second tap
/// on the same screen's button repeats the same move instead of skipping a
/// screen.
///
/// Auto-dispose: screen-scoped. A save still running when the screen goes
/// finishes in the repository; only the state update is dropped.
@Riverpod(retry: retryUnlessFailure)
class OnboardingController extends _$OnboardingController {
  /// The last save queued, so the next waits for it.
  Future<void> _lastSave = Future<void>.value();

  /// How many saves have been queued, so a save can tell whether it's the
  /// latest.
  int _savesQueued = 0;

  @override
  Future<OnboardingFlowState> build() async {
    final result = await ref.watch(onboardingRepositoryProvider).read();
    return switch (result) {
      Ok(:final value) => OnboardingFlowState.resumedFrom(value),
      Err(:final failure) => throw failure,
    };
  }

  /// Domain event: FirstStonePlaced.
  ///
  /// Screen 1: the person put the first stone on the ground. Places it in
  /// the cairn; nothing is saved (Continue moves on).
  void placeFirstStone() {
    final current = state.value;
    if (!ref.mounted || current == null) return;
    state = AsyncData(
      current.copyWith(
        stones: {
          ...current.stones,
          OnboardingStep.firstStone: OnboardingStone.placed,
        },
      ),
    );
  }

  /// Domain event: OnboardingStepCompleted.
  ///
  /// A screen whose answer isn't stored was done (the first stone, where
  /// the person heard about Steady, Apple Health, the first week): places
  /// [step]'s stone and moves to the next screen.
  Future<void> completeOnboardingStep(OnboardingStep step) =>
      _advance(step, OnboardingStone.placed);

  /// Domain event: OnboardingStepSkipped.
  ///
  /// [step] was skipped: places a dimmer stone, never none, and moves on.
  /// Saves nothing for that answer; one stored earlier stays.
  Future<void> skipOnboardingStep(OnboardingStep step) =>
      _advance(step, OnboardingStone.dimmed);

  /// Domain event: FoodTrackingAnswered.
  ///
  /// Screen 2: how the person tracks food. Saved to About me.
  Future<void> answerFoodTracking(FoodTracking tracking) => _advance(
    OnboardingStep.tracking,
    OnboardingStone.placed,
    change: (a) => a.copyWith(tracking: tracking),
  );

  /// Domain event: YourWeekAnswered.
  ///
  /// Screen 5: the person's activities and what their weekends are like
  /// (either may be left out). Saved to About me.
  Future<void> answerYourWeek({
    required Set<OnboardingActivity> activities,
    WeekendShape? weekends,
  }) => _advance(
    OnboardingStep.week,
    OnboardingStone.placed,
    change: (a) =>
        a.copyWith(activities: Set.of(activities), weekends: weekends),
  );

  /// Domain event: HardPartsAnswered.
  ///
  /// Screen 6: what gets in the way. Saved to About me.
  Future<void> answerHardParts(Set<HardPart> hardParts) => _advance(
    OnboardingStep.hardParts,
    OnboardingStone.placed,
    change: (a) => a.copyWith(hardParts: Set.of(hardParts)),
  );

  /// Domain event: CoachVoiceChosen.
  ///
  /// Screen 7: the coach's voice. Saved to About me.
  Future<void> chooseCoachVoice(CoachVoice voice) => _advance(
    OnboardingStep.voice,
    OnboardingStone.placed,
    change: (a) => a.copyWith(voice: voice),
  );

  /// Domain event: CoachMet.
  ///
  /// Screen 8, after the consent screen answered: [consentGiven] is what
  /// it returned, and [note] the optional "Anything else the coach should
  /// know?" (cut to `aboutMeNoteMaxChars`; blank saves none, clearing an
  /// earlier note). Either answer moves on. The stone is full when the
  /// coach was turned on or a note was left, dimmer otherwise.
  Future<void> meetCoach({required bool consentGiven, String? note}) {
    final clamped = clampAboutMeNote(note);
    return _advance(
      OnboardingStep.meetCoach,
      consentGiven || clamped != null
          ? OnboardingStone.placed
          : OnboardingStone.dimmed,
      change: (a) => a.copyWith(note: clamped),
    );
  }

  /// Domain event: OnboardingStepChanged.
  ///
  /// The person moved to [step] without answering (the back arrow). Saved,
  /// so a relaunch resumes there. Stones already placed stay.
  Future<void> moveToOnboardingStep(OnboardingStep step) async {
    final current = state.value;
    if (!ref.mounted || current == null) return;
    state = AsyncData(current.copyWith(step: step, saveFailure: null));
    await _save(
      (repository) async => _failureOf(await repository.saveStep(step)),
    );
  }

  /// Domain event: OnboardingCompleted.
  ///
  /// Screen 10's "Go to Today": marks onboarding done for good, after any
  /// save still running. A failed save is reported in the state; the
  /// person goes on to Today either way.
  Future<void> finishOnboarding() => _markCompleted();

  /// Domain event: OnboardingLeft.
  ///
  /// "Not now", on any screen: marks onboarding done, keeping the answers
  /// given so far (Settings → About me has every question). Works whatever
  /// the state, a failed read included, so leaving is always one tap.
  Future<void> leaveOnboarding() => _markCompleted();

  Future<void> _markCompleted() async {
    if (!ref.mounted) return;
    await _save(
      (repository) async => _failureOf(await repository.markCompleted()),
    );
  }

  /// Places [step]'s [stone], applies [change] to About me, moves to the
  /// next screen, then saves the About me (when changed) and the new step.
  /// The step is saved even if the About me save fails, so a relaunch
  /// resumes on the screen the person is on; the About me failure is the
  /// one reported.
  Future<void> _advance(
    OnboardingStep step,
    OnboardingStone stone, {
    AboutMe Function(AboutMe)? change,
  }) async {
    final current = state.value;
    if (!ref.mounted || current == null) return;
    final next = step.next ?? step;
    final aboutMe = change?.call(current.aboutMe);
    state = AsyncData(
      current.copyWith(
        step: next,
        aboutMe: aboutMe ?? current.aboutMe,
        stones: {...current.stones, step: stone},
        saveFailure: null,
      ),
    );
    await _save((repository) async {
      final aboutMeFailure = aboutMe == null
          ? null
          : _failureOf(await repository.saveAboutMe(aboutMe));
      final stepFailure = _failureOf(await repository.saveStep(next));
      return aboutMeFailure ?? stepFailure;
    });
  }

  /// Runs [write] after every save queued before it, then records the
  /// outcome in [OnboardingFlowState.saveFailure]: a failure is shown, and
  /// the latest save queued succeeding clears it. An earlier save's failure
  /// finishing after a later event can't outlive that later save's
  /// success.
  Future<void> _save(
    Future<Failure?> Function(OnboardingRepository repository) write,
  ) async {
    final repository = ref.read(onboardingRepositoryProvider);
    final queued = ++_savesQueued;
    final previous = _lastSave;
    final done = Completer<void>();
    _lastSave = done.future;
    Failure? failure;
    try {
      await previous;
      failure = await write(repository);
    } finally {
      done.complete();
    }
    if (!ref.mounted) return;
    final current = state.value;
    if (current == null) return;
    if (failure == null) {
      // Only the latest save's success speaks for what's stored now.
      if (queued != _savesQueued || current.saveFailure == null) return;
    }
    state = AsyncData(current.copyWith(saveFailure: failure));
  }

  static Failure? _failureOf(Result<Object?> result) => switch (result) {
    Ok() => null,
    Err(:final failure) => failure,
  };
}
