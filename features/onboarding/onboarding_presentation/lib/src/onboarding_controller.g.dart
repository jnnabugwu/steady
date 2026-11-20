// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(OnboardingController)
final onboardingControllerProvider = OnboardingControllerProvider._();

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
final class OnboardingControllerProvider
    extends $AsyncNotifierProvider<OnboardingController, OnboardingFlowState> {
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
  OnboardingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: retryUnlessFailure,
        name: r'onboardingControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingControllerHash();

  @$internal
  @override
  OnboardingController create() => OnboardingController();
}

String _$onboardingControllerHash() =>
    r'60c800ac38906394c386fa14e6e3228609f11af9';

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

abstract class _$OnboardingController
    extends $AsyncNotifier<OnboardingFlowState> {
  FutureOr<OnboardingFlowState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<OnboardingFlowState>, OnboardingFlowState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OnboardingFlowState>, OnboardingFlowState>,
              AsyncValue<OnboardingFlowState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
