import 'package:failures/failures.dart';
import 'package:onboarding_domain/src/about_me.dart';
import 'package:onboarding_domain/src/onboarding_record.dart';
import 'package:onboarding_domain/src/onboarding_step.dart';

/// Stores whether onboarding is done, the screen the person was last on and
/// their About me, **on this iPhone only** (CLAUDE.md §7): never SwiftData
/// or CloudKit, never synced.
///
/// Small on purpose: one read and three writes, each changing one thing.
/// [saveAboutMe] never touches `completed` or `step`, [saveStep] never
/// touches `completed` or `aboutMe`, and [markCompleted] never touches
/// `aboutMe`, so Settings → About me can edit the answers after onboarding
/// without bringing it back.
///
/// Failures:
///
/// - `Err(OnboardingUnreadableFailure)`: something is stored but it isn't
///   in the format Steady writes. [read] reports it, and the app treats it
///   as onboarding done. A write **replaces** it, starting from
///   [OnboardingRecord.whenUnreadable] (completed, nothing answered, no
///   step) so the replacement agrees with what the person saw; keeping it
///   would mean About me could never be saved again.
/// - `Err(OnboardingStorageFailure)`: the store couldn't be found, read or
///   written. Nothing changed; trying again may work.
/// - `Err(ValidationFailure)`: [saveAboutMe] with a note longer than
///   `aboutMeNoteMaxChars` code points once trimmed. Nothing is written.
///
/// Whether onboarding shows after a failed [read] is the app's call, not
/// the repository's (onboarding never blocks the app).
abstract class OnboardingRepository {
  /// What's stored, or [OnboardingRecord.initial] if nothing is.
  ResultFuture<OnboardingRecord> read();

  /// Replaces the stored About me with [aboutMe], keeping `completed` and
  /// `step` as they are. The note is stored trimmed, and a blank one as
  /// `null` (`trimAboutMeNote`); one still over `aboutMeNoteMaxChars` code
  /// points is refused. Over an unreadable store it starts from
  /// [OnboardingRecord.whenUnreadable] instead, so `completed` becomes
  /// `true` and `step` `null`. Returns the record now stored.
  ResultFuture<OnboardingRecord> saveAboutMe(AboutMe aboutMe);

  /// Records [step] as the screen the person is on, so a relaunch resumes
  /// there. Keeps `completed` and `aboutMe` as they are. Over an
  /// unreadable store it starts from [OnboardingRecord.whenUnreadable]
  /// instead, so `completed` becomes `true` and `aboutMe` empty. Returns
  /// the record now stored.
  ResultFuture<OnboardingRecord> saveStep(OnboardingStep step);

  /// Marks onboarding done, for good, keeping the About me as it is and
  /// clearing `step` (there's nothing left to resume). Calling it again
  /// changes nothing. Over an unreadable store the result is
  /// [OnboardingRecord.whenUnreadable] (the About me there can't be read).
  /// Returns the record now stored.
  ResultFuture<OnboardingRecord> markCompleted();
}
