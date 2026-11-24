/// Two weeks free for people who used the coach on Steady 1.0 (#188,
/// docs/technical_decisions.md, "The coach is paid", Consequences).
///
/// 1.0 had a free on-device coach; 1.1.0 puts the coach behind the
/// subscription. Steady has no accounts, so it goes by what's on the
/// phone: on the first 1.1.0 launch, [recordEarlyCoachUser] decides once
/// whether `coach_sessions.json` holds any session, and the paywall offers
/// the offer code to the phones where it did. The decision is kept in a
/// device-only file next to `coach_consent.json` and never changes, so a
/// new install never gets the offer by using the coach later.
///
/// Accepted (decision record): a code can be passed on, and someone who
/// installed 1.0 but never used the coach doesn't get it.
library;

import 'package:coach_domain/coach_domain.dart';
import 'package:failures/failures.dart';
import 'package:subscription_domain/subscription_domain.dart';

/// What a read of the coach's sessions says about using the coach on 1.0:
/// `true` for any session that started before [launchedAt], `false` for
/// none (an empty or missing file, or only sessions from this launch), and
/// `null` when it can't be told this launch (a storage error; the next
/// launch tries again).
///
/// Only sessions from before [launchedAt] count, so a check that finishes
/// after the app has started (`main.dart`'s timeout lets the first frame
/// go ahead without it) never counts a session 1.1.0 made meanwhile.
///
/// A file that can't be decoded counts as `true`: something wrote it
/// before this check ran, and that was 1.0's coach.
bool? usedCoachFrom(
  Result<List<CoachSession>> sessions, {
  required DateTime launchedAt,
}) => switch (sessions) {
  Ok(:final value) => value.any((s) => s.startedAt.isBefore(launchedAt)),
  Err(failure: CoachHistoryUnreadableFailure()) => true,
  Err() => null,
};

/// Decides, once, whether the person on this iPhone used the coach on 1.0
/// and stores it in [flag]. Does nothing once decided, and reads [coach]
/// only until then. Returns what's stored, or `null` if nothing could be
/// decided this launch.
///
/// [launchedAt] is when this launch began, taken before the first frame:
/// only sessions that started before it count ([usedCoachFrom]).
/// `main.dart` awaits this before the first frame, but with a short
/// timeout that doesn't cancel it, so it can finish after 1.1.0 has added
/// a session of its own; [launchedAt] keeps that session out.
Future<bool?> recordEarlyCoachUser({
  required EarlyCoachUserRepository flag,
  required CoachRepository coach,
  required DateTime launchedAt,
}) async {
  switch (await flag.read()) {
    case Ok(value: final bool decided):
      return decided;
    case Err():
      return null;
    case Ok():
      break;
  }
  final usedCoach = usedCoachFrom(
    await coach.listSessions(),
    launchedAt: launchedAt,
  );
  if (usedCoach == null) return null;
  return switch (await flag.decideOnce(usedCoach: usedCoach)) {
    Ok(:final value) => value,
    Err() => null,
  };
}
