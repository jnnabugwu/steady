import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:onboarding_domain/src/about_me.dart';

part 'onboarding_state.freezed.dart';

/// What's stored about onboarding on this iPhone: whether it's done, and
/// the person's About me.
///
/// The two are independent on purpose. Finishing, or skipping to the end,
/// marks onboarding [completed] for good (it never comes back on its own,
/// docs/design/onboarding.md, "Who sees it"), and editing About me in
/// Settings afterwards changes [aboutMe] only.
@freezed
abstract class OnboardingState with _$OnboardingState {
  /// Creates an [OnboardingState].
  const factory OnboardingState({
    /// Whether the person has finished (or skipped to the end of)
    /// onboarding.
    @Default(false) bool completed,

    /// Their answers so far; [AboutMe.empty] if none.
    @Default(AboutMe.empty) AboutMe aboutMe,
  }) = _OnboardingState;

  /// A first launch: not completed, nothing answered. What a missing store
  /// reads as.
  static const initial = OnboardingState();
}
