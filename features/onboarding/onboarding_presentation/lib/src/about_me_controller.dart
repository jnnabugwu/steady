import 'dart:async';

import 'package:failures/failures.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:onboarding_domain/onboarding_domain.dart';
import 'package:onboarding_presentation/src/providers.dart';
import 'package:onboarding_presentation/src/retry_unless_failure.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'about_me_controller.freezed.dart';
part 'about_me_controller.g.dart';

/// Settings → About me as the editor sees it: the answers on screen, and
/// whether the latest save failed.
@freezed
abstract class AboutMeEditorState with _$AboutMeEditorState {
  /// Creates the editor's state.
  const factory AboutMeEditorState({
    /// The answers on screen: every edit, saved or not.
    required AboutMe aboutMe,

    /// Why the latest save failed, if it did. Shown as the quiet line;
    /// [aboutMe] keeps the edit, and the next edit saves it again.
    Failure? saveFailure,
  }) = _AboutMeEditorState;
}

/// Settings → About me (#172): every onboarding answer, each editable on
/// its own, over the stored `OnboardingRecord`.
///
/// `build` reads the record. An unreadable one (`OnboardingUnreadableFailure`)
/// opens with nothing answered, since the next save replaces it
/// (`OnboardingRepository`); any other failed read is an `AsyncError`
/// carrying the `Failure`, and the screen offers to try again.
///
/// **Every event shows at once and saves behind it**, through
/// `saveAboutMe`, which never changes whether onboarding is done. Clearing
/// an answer (`null`, or an empty set) puts it back to skipped. Saves
/// never overlap and always write the latest answers: an edit made while
/// one is being written is saved right after it, together with any other
/// edits made meanwhile (a note typed letter by letter is a few writes,
/// not one per letter). A failed save sets
/// [AboutMeEditorState.saveFailure] and keeps the edit on screen; the next
/// edit's save, if it works, clears it.
///
/// Each event's future completes once a save holding that edit has
/// finished, whether it worked or not, so the caller can refresh what
/// reads the record (Today's tracking).
///
/// Auto-dispose: screen-scoped. Saves still to run when the screen goes
/// run anyway (only the state updates are dropped), so leaving right after
/// an edit doesn't lose it.
@Riverpod(retry: retryUnlessFailure)
class AboutMeController extends _$AboutMeController {
  /// The repository the saves go through, kept so they can finish after
  /// the screen goes. Set by `build`, which has run before any event: the
  /// answers on screen come from it.
  late OnboardingRepository _repository;

  /// The latest answers not yet handed to a save, if any.
  AboutMe? _unsaved;

  /// The saves running now, or `null` when none are.
  Future<void>? _saving;

  @override
  Future<AboutMeEditorState> build() async {
    final repository = ref.watch(onboardingRepositoryProvider);
    _repository = repository;
    final result = await repository.read();
    return switch (result) {
      Ok(:final value) => AboutMeEditorState(aboutMe: value.aboutMe),
      // The next save replaces the unreadable record, starting from
      // nothing answered: say so by showing nothing answered.
      Err(failure: OnboardingUnreadableFailure()) => const AboutMeEditorState(
        aboutMe: AboutMe.empty,
      ),
      Err(:final failure) => throw failure,
    };
  }

  /// Domain event: FoodTrackingChanged.
  ///
  /// How the person tracks food (screen 2's question), or `null` to clear
  /// it. Today's import button, its Apple Health prompt and its empty text
  /// follow it.
  Future<void> changeFoodTracking(FoodTracking? tracking) =>
      _change((a) => a.copyWith(tracking: tracking));

  /// Domain event: ActivitiesChanged.
  ///
  /// The person's activities (screen 5); empty clears them.
  Future<void> changeActivities(Set<OnboardingActivity> activities) =>
      _change((a) => a.copyWith(activities: Set.of(activities)));

  /// Domain event: WeekendsChanged.
  ///
  /// What the person's weekends are like (screen 5), or `null` to clear it.
  Future<void> changeWeekends(WeekendShape? weekends) =>
      _change((a) => a.copyWith(weekends: weekends));

  /// Domain event: HardPartsChanged.
  ///
  /// What gets in the way (screen 6); empty clears it.
  Future<void> changeHardParts(Set<HardPart> hardParts) =>
      _change((a) => a.copyWith(hardParts: Set.of(hardParts)));

  /// Domain event: CoachVoiceChanged.
  ///
  /// The coach's voice (screen 7), or `null` to clear it.
  Future<void> changeCoachVoice(CoachVoice? voice) =>
      _change((a) => a.copyWith(voice: voice));

  /// Domain event: AboutMeNoteChanged.
  ///
  /// "Anything else the coach should know?" (screen 8), as typed: trimmed
  /// and cut to `aboutMeNoteMaxChars` code points (`clampAboutMeNote`), the
  /// way the store keeps it; blank clears it.
  Future<void> changeAboutMeNote(String? note) =>
      _change((a) => a.copyWith(note: clampAboutMeNote(note)));

  /// Applies [change] to the answers on screen and saves them.
  Future<void> _change(AboutMe Function(AboutMe) change) {
    final current = state.value;
    if (!ref.mounted || current == null) return Future<void>.value();
    final aboutMe = change(current.aboutMe);
    // Nothing new to save (a space typed after the note, say): wait for
    // whatever is being saved, which already holds these answers.
    if (aboutMe == current.aboutMe) return _saving ?? Future<void>.value();
    state = AsyncData(current.copyWith(aboutMe: aboutMe));
    _unsaved = aboutMe;
    return _saving ??= _saveAll();
  }

  /// Saves [_unsaved] until there's nothing left to save, one write at a
  /// time, each with the latest answers.
  Future<void> _saveAll() async {
    final repository = _repository;
    try {
      while (_unsaved != null) {
        final aboutMe = _unsaved!;
        _unsaved = null;
        final result = await repository.saveAboutMe(aboutMe);
        // A newer edit is about to be saved: that save speaks for what's
        // stored, not this one.
        if (_unsaved != null || !ref.mounted) continue;
        final current = state.value;
        if (current == null) continue;
        state = AsyncData(
          current.copyWith(
            saveFailure: switch (result) {
              Ok() => null,
              Err(:final failure) => failure,
            },
          ),
        );
      }
    } finally {
      _saving = null;
    }
  }
}
