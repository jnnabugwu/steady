import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:onboarding_domain/src/about_me.dart';
import 'package:onboarding_domain/src/onboarding_step.dart';

part 'onboarding_record.freezed.dart';

/// What's stored about onboarding on this iPhone: whether it's done, the
/// screen the person was last on, and their About me.
///
/// [completed] and [aboutMe] are independent on purpose. Finishing, or
/// skipping to the end, marks onboarding [completed] for good (it never
/// comes back on its own, docs/design/onboarding.md, "Who sees it"), and
/// editing About me in Settings afterwards changes [aboutMe] only.
@freezed
abstract class OnboardingRecord with _$OnboardingRecord {
  /// Creates an [OnboardingRecord].
  const factory OnboardingRecord({
    /// Whether the person has finished (or skipped to the end of)
    /// onboarding.
    @Default(false) bool completed,

    /// The screen the person was last on, to resume from; `null` if they
    /// haven't started, and once onboarding is completed.
    OnboardingStep? step,

    /// Their answers so far; [AboutMe.empty] if none.
    @Default(AboutMe.empty) AboutMe aboutMe,
  }) = _OnboardingRecord;

  /// A first launch: not completed, not started, nothing answered. What a
  /// missing store reads as.
  static const initial = OnboardingRecord();

  /// What an unreadable store counts as: done, nothing answered, no step.
  /// The app treats a failed read as onboarding done (it never blocks),
  /// and a write over an unreadable store starts from this, so the
  /// replacement agrees with what the person saw.
  static const whenUnreadable = OnboardingRecord(completed: true);
}
