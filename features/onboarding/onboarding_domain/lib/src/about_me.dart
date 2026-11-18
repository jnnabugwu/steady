import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:onboarding_domain/src/about_me_answers.dart';

part 'about_me.freezed.dart';

/// The longest About me note, in characters (Unicode code points), counted
/// the way the coach counts a message (`coachMaxMessageChars`): `runes`, so
/// an emoji is one character, not two UTF-16 units. "About 200 characters"
/// in docs/design/onboarding.md, screen 8.
const int aboutMeNoteMaxChars = 200;

/// [note], trimmed and cut to [aboutMeNoteMaxChars] code points, or `null`
/// if nothing is left (a blank note is a skipped one). For the note field,
/// the way `clampCoachMessage` serves the coach's message box.
String? clampAboutMeNote(String? note) {
  final trimmed = note?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed.runes.length <= aboutMeNoteMaxChars
      ? trimmed
      : String.fromCharCodes(trimmed.runes.take(aboutMeNoteMaxChars));
}

/// [note] as a repository stores it: trimmed, and `null` if nothing is
/// left (a blank note is a skipped one, so `AboutMe.isEmpty` holds). It
/// never cuts: a note over [aboutMeNoteMaxChars] is refused, not shortened.
String? trimAboutMeNote(String? note) {
  final trimmed = note?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// Whether [note] fits: `null`, or at most [aboutMeNoteMaxChars] code
/// points. A repository refuses to save an [AboutMe] whose note, after
/// [trimAboutMeNote], doesn't.
bool isValidAboutMeNote(String? note) =>
    note == null || note.runes.length <= aboutMeNoteMaxChars;

/// What the person told Steady about themselves in onboarding, and can
/// change any time in Settings → About me. It becomes the coach's About me
/// (docs/design/onboarding.md).
///
/// **Every answer can be skipped:** a skipped single answer is `null`, a
/// skipped multi-select is an empty set. No body or goal fields, ever (no
/// weight, height, age, sex or calorie target): they invite the targets the
/// coach refuses to give.
///
/// Stored only on the iPhone, never synced (CLAUDE.md §7). Where screen 3's
/// "Where did you hear about Steady?" goes is deliberately not here: it's
/// one anonymous analytics event, never stored and never sent to the coach.
@freezed
abstract class AboutMe with _$AboutMe {
  /// Creates an [AboutMe]. Every answer defaults to skipped.
  const factory AboutMe({
    /// The coach's voice (screen 7), or `null` if skipped.
    CoachVoice? voice,

    /// How the person tracks food (screen 2), or `null` if skipped.
    FoodTracking? tracking,

    /// The person's activities (screen 5). Empty if skipped.
    @Default(<OnboardingActivity>{}) Set<OnboardingActivity> activities,

    /// What the person's weekends are like (screen 5), or `null` if
    /// skipped.
    WeekendShape? weekends,

    /// What gets in the way (screen 6). Empty if skipped.
    @Default(<HardPart>{}) Set<HardPart> hardParts,

    /// "Anything else the coach should know?" (screen 8), at most
    /// [aboutMeNoteMaxChars] code points, or `null` if skipped. The only
    /// free text in About me. A repository stores it trimmed, and a blank
    /// note as `null` ([trimAboutMeNote]).
    String? note,
  }) = _AboutMe;

  const AboutMe._();

  /// Every answer skipped: what a person who hasn't answered anything has.
  static const empty = AboutMe();

  /// Whether every answer is skipped.
  bool get isEmpty => this == empty;
}
