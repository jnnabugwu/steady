import 'package:failures/failures.dart';
import 'package:onboarding_domain/src/about_me.dart';
import 'package:onboarding_domain/src/onboarding_state.dart';

/// Stores whether onboarding is done and the person's About me, **on this
/// iPhone only** (CLAUDE.md §7): never SwiftData or CloudKit, never synced.
///
/// Small on purpose: one read and two writes, each changing one thing.
/// [saveAboutMe] never touches `completed` and [markCompleted] never
/// touches `aboutMe`, so Settings → About me can edit the answers after
/// onboarding without bringing it back.
///
/// Failures:
///
/// - `Err(OnboardingUnreadableFailure)`: something is stored but it isn't
///   in the format Steady writes. [read] reports it; a write **replaces**
///   it, starting from [OnboardingState.initial] (nothing in it can be
///   read, and keeping it would mean the person could never finish
///   onboarding or save About me again).
/// - `Err(OnboardingStorageFailure)`: the store couldn't be found, read or
///   written. Nothing changed; trying again may work.
/// - `Err(ValidationFailure)`: [saveAboutMe] with a note longer than
///   `aboutMeNoteMaxChars` code points. Nothing is written.
///
/// Whether onboarding shows after a failed [read] is the app's call, not
/// the repository's (onboarding never blocks the app).
abstract class OnboardingRepository {
  /// What's stored, or [OnboardingState.initial] if nothing is.
  ResultFuture<OnboardingState> read();

  /// Replaces the stored About me with [aboutMe], keeping `completed` as
  /// it is. Returns the state now stored.
  ResultFuture<OnboardingState> saveAboutMe(AboutMe aboutMe);

  /// Marks onboarding done, for good, keeping the About me as it is.
  /// Calling it again changes nothing. Returns the state now stored.
  ResultFuture<OnboardingState> markCompleted();
}
