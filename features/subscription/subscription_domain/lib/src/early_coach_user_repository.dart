import 'package:failures/failures.dart';

/// Whether the person on this iPhone used the coach on Steady 1.0, when it
/// was free, **decided once** on the first 1.1.0 launch (#188,
/// docs/technical_decisions.md, "The coach is paid", Consequences). People
/// who did get two weeks free through an offer code.
///
/// Steady has no accounts, so it goes by what's on the phone: the app
/// decides from whether `coach_sessions.json` holds any session, before
/// anything in 1.1.0 can add one. Once decided it never changes, so a new
/// install (decided `false`) never gets it by using the coach later.
///
/// **Device-only** (CLAUDE.md §7): next to `coach_consent.json`, never
/// synced, in the person's own device backup.
///
/// Failures: `Err(EarlyCoachUserStorageFailure)` when the store can't be
/// reached or written; nothing changed, and the app tries again on the
/// next launch.
abstract class EarlyCoachUserRepository {
  /// What was decided: `true` (used the coach on 1.0), `false`, or `null`
  /// if nothing has been decided yet.
  ResultFuture<bool?> read();

  /// Stores [usedCoach] if nothing has been decided yet. Returns what's
  /// stored afterwards, which is the earlier decision if there was one.
  ResultFuture<bool> decideOnce({required bool usedCoach});
}

/// The early-coach-user store couldn't be reached or written. Nothing
/// changed; the next launch tries again.
class EarlyCoachUserStorageFailure extends Failure {
  /// Creates an [EarlyCoachUserStorageFailure].
  const EarlyCoachUserStorageFailure(super.message, {super.cause});
}
