import 'package:failures/failures.dart';

/// The coach's consent screen: its copy and the version of it the person
/// agrees to (App Store 5.1.2: disclose what's shared with a third-party AI,
/// and ask first). Kept in one place, so it's easy to edit, and so the
/// version sits next to the words it numbers.
///
/// **Bump [currentVersion] when what's sent changes materially** (journal
/// notes, #85; a different model provider; a new kind of data), and change
/// [items] to match. Everyone who agreed to an earlier version is then asked
/// again: their stored agreement no longer counts
/// (`CoachConsentRepository`). A wording fix that doesn't change what's
/// sent, to whom or why doesn't need a bump.
abstract final class CoachConsent {
  /// The version of the consent text below. Agreement is stored as this
  /// number.
  static const int currentVersion = 1;

  /// The screen's title.
  static const String title = 'Talk with the coach';

  static const String _healthItem =
      'steps, energy burned and calories eaten (from Apple Health or your '
      'Cal AI import)';

  /// The paragraph above the list of what's sent.
  static const String intro =
      'The coach is powered by Claude, an AI model made by Anthropic. To '
      'coach you, Steady sends Anthropic what the conversation needs:';

  /// What's sent, one line each. Matches `BuildCoachWeekContext` /
  /// `formatCoachWeek` and the conversation itself; weight isn't sent.
  static const List<String> items = [
    "this week's check-ins",
    _healthItem,
    'your craving check-ins',
    'what you type to the coach',
  ];

  /// What it's used for, how long Anthropic keeps it, and where
  /// conversations are saved. The retention line follows Anthropic's API
  /// terms (`docs/PRIVACY.md`, "Coach").
  static const String use =
      "It's used only to write the coach's replies. Anthropic deletes it "
      "within 30 days and doesn't use it to train its models. Steady's "
      "server doesn't keep it, and your conversations are saved only on "
      'this iPhone.';

  /// The closing line: not medical advice, and how to turn it off.
  static const String closing =
      "The coach isn't medical advice. You can turn it off any time in "
      'Settings → Coach.';

  /// The button that gives consent.
  static const String allow = 'Allow and continue';

  /// The button that leaves the coach off.
  static const String notNow = 'Not now';

  /// The one line under Settings → Coach's switch: what it sends, and to
  /// whom.
  static const String settingsLine =
      'When it’s on, a conversation sends the week’s check-ins, Apple Health '
      'totals, craving check-ins and what you type to Anthropic, only to '
      'write the replies.';
}

/// Where the person's agreement to [CoachConsent] is kept: on this iPhone
/// only, never synced or put in iCloud storage (CLAUDE.md §7, like craving
/// check-ins). Only the agreed [CoachConsent.currentVersion]'s number is
/// stored; whether that's the current one is the caller's question.
abstract interface class CoachConsentRepository {
  /// The version of the consent text the person agreed to, or `null` if
  /// they haven't, or withdrew. A missing or unreadable store reads as
  /// `null` (not given), never as an error.
  ResultFuture<int?> readAgreedVersion();

  /// Records that the person agreed to [version] of the consent text,
  /// replacing any earlier agreement.
  ResultFuture<Unit> giveConsent(int version);

  /// Forgets any agreement: the coach is off until the person agrees again.
  ResultFuture<Unit> withdrawConsent();
}

/// The consent store couldn't be found, written or deleted (a file-system
/// error). What's stored didn't change; trying again may work.
class CoachConsentStorageFailure extends Failure {
  /// Creates a [CoachConsentStorageFailure].
  const CoachConsentStorageFailure(super.message, {super.cause});
}
