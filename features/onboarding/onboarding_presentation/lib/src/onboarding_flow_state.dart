import 'package:failures/failures.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:onboarding_domain/onboarding_domain.dart';
import 'package:ui_kit/ui_kit.dart';

part 'onboarding_flow_state.freezed.dart';

/// Where a step sits in the flow.
extension OnboardingStepFlow on OnboardingStep {
  /// The step after this one, or `null` on the last screen.
  OnboardingStep? get next => index + 1 < OnboardingStep.values.length
      ? OnboardingStep.values[index + 1]
      : null;

  /// The step before this one, or `null` on the first screen.
  OnboardingStep? get previous =>
      index > 0 ? OnboardingStep.values[index - 1] : null;

  /// Whether this step places a stone: screens 1–9 do, and screen 10 shows
  /// them.
  bool get placesStone => this != OnboardingStep.cairn;
}

/// The steps that place a stone, in flow order (screens 1–9).
final List<OnboardingStep> stoneSteps = [
  for (final step in OnboardingStep.values)
    if (step.placesStone) step,
];

/// The onboarding flow as the screens see it: the screen the person is on,
/// their answers so far and the stones placed.
///
/// Every change shows at once; the controller saves it behind the scenes.
/// A save that fails sets [saveFailure] and never stops the flow
/// (docs/design/onboarding.md, "Leaving early": nothing traps someone).
@freezed
abstract class OnboardingFlowState with _$OnboardingFlowState {
  /// Creates a flow state.
  const factory OnboardingFlowState({
    /// The screen the person is on.
    required OnboardingStep step,

    /// Their answers so far.
    @Default(AboutMe.empty) AboutMe aboutMe,

    /// The stone each passed step placed: [OnboardingStone.placed] for an
    /// answered step, [OnboardingStone.dimmed] for a skipped one. Steps not
    /// reached yet have none.
    @Default(<OnboardingStep, OnboardingStone>{})
    Map<OnboardingStep, OnboardingStone> stones,

    /// The last save that failed, if the latest one did. Shown as a quiet
    /// line; the answer is still kept in memory and the flow goes on.
    Failure? saveFailure,
  }) = _OnboardingFlowState;

  const OnboardingFlowState._();

  /// The flow as a stored [record] resumes it: on the saved screen (the
  /// first if none), with the answers filled in.
  ///
  /// The stones before that screen are inferred, since only answers are
  /// stored: a question with a stored answer placed a stone, one without
  /// placed a dimmer one, and a screen that stores nothing (the first
  /// stone, where you heard about Steady, Apple Health, meeting the coach,
  /// the first week) placed a full one.
  factory OnboardingFlowState.resumedFrom(OnboardingRecord record) {
    final step = record.step ?? OnboardingStep.firstStone;
    final aboutMe = record.aboutMe;
    return OnboardingFlowState(
      step: step,
      aboutMe: aboutMe,
      stones: {
        for (final passed in stoneSteps.take(step.index))
          passed: (answered(passed, aboutMe) ?? true)
              ? OnboardingStone.placed
              : OnboardingStone.dimmed,
      },
    );
  }

  /// Whether [step]'s question has an answer in [aboutMe], or `null` for a
  /// screen whose answer isn't stored.
  static bool? answered(OnboardingStep step, AboutMe aboutMe) => switch (step) {
    OnboardingStep.tracking => aboutMe.tracking != null,
    OnboardingStep.week =>
      aboutMe.activities.isNotEmpty || aboutMe.weekends != null,
    OnboardingStep.hardParts => aboutMe.hardParts.isNotEmpty,
    OnboardingStep.voice => aboutMe.voice != null,
    OnboardingStep.firstStone ||
    OnboardingStep.source ||
    OnboardingStep.health ||
    OnboardingStep.meetCoach ||
    OnboardingStep.firstWeek ||
    OnboardingStep.cairn => null,
  };

  /// The cairn to draw, bottom first: one slot per stone step, the current
  /// step's still to place if it has no stone yet. On the last screen a
  /// tenth, pending slot stands for tonight's check-in.
  List<OnboardingStone> get cairn => [
    for (final s in stoneSteps)
      stones[s] ?? (s == step ? OnboardingStone.pending : OnboardingStone.none),
    if (step == OnboardingStep.cairn) OnboardingStone.pending,
  ];
}
