import 'package:coach_domain/src/coach_history_failures.dart';
import 'package:coach_domain/src/coach_session.dart';
import 'package:failures/failures.dart';

/// Stores coach sessions and their transcripts **on this iPhone only**.
///
/// Implementations must never sync sessions or put them in iCloud storage:
/// transcripts quote Health values and cravings, which App Store 5.1.3(ii)
/// keeps out of iCloud (CLAUDE.md §11). Like craving check-ins, they're
/// part of the phone's own iOS device backup, as any app data is.
///
/// A store that can't be read returns [CoachHistoryUnreadableFailure]; one
/// that can't be reached or written returns [CoachHistoryStorageFailure].
abstract class CoachRepository {
  /// Every stored session, newest first by `startedAt` (ties by `id`, so
  /// the order is stable). Each carries its full transcript.
  ResultFuture<List<CoachSession>> listSessions();

  /// The session with [id], or `Ok(null)` if there's none.
  ResultFuture<CoachSession?> getSession(String id);

  /// Saves [session], replacing any stored session with the same `id`
  /// (so a session in progress is saved again as it grows).
  ///
  /// Returns `Err(ValidationFailure)` for an empty `id`, or an `endedAt`
  /// before `startedAt`, and stores nothing.
  ResultFuture<Unit> saveSession(CoachSession session);

  /// Deletes every stored session ("Delete coach history" in Settings).
  ResultFuture<Unit> deleteAll();
}

/// Why [CoachRepository.saveSession] would reject [session], or `null` if
/// it's valid. Shared by every implementation, so they reject the same
/// sessions.
ValidationFailure? validateCoachSession(CoachSession session) {
  if (session.id.isEmpty) {
    return const ValidationFailure('A coach session needs an id');
  }
  if (session.endedAt case final endedAt?
      when endedAt.isBefore(session.startedAt)) {
    return const ValidationFailure(
      "A coach session can't end before it starts",
    );
  }
  return null;
}

/// Orders sessions newest first by `startedAt`, then by `id`: the order
/// [CoachRepository.listSessions] returns.
int compareCoachSessionsNewestFirst(CoachSession a, CoachSession b) {
  final byStart = b.startedAt.compareTo(a.startedAt);
  return byStart != 0 ? byStart : a.id.compareTo(b.id);
}
