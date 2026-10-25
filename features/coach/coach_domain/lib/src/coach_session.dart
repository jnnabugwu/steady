import 'package:freezed_annotation/freezed_annotation.dart';

part 'coach_session.freezed.dart';

/// Which kind of coach session a [CoachSession] is.
enum CoachSessionKind {
  /// An open conversation, started whenever the person wants one.
  chat,

  /// The 5-minute weekly session (product overview §6).
  weekly,
}

/// Who wrote a [CoachMessage].
enum CoachMessageRole {
  /// The person using Steady.
  user,

  /// The on-device coach.
  coach,
}

/// One turn in a coach session's transcript.
@freezed
abstract class CoachMessage with _$CoachMessage {
  /// Creates a [CoachMessage].
  const factory CoachMessage({
    /// Who wrote it.
    required CoachMessageRole role,

    /// What was said.
    required String text,

    /// When it was said.
    required DateTime at,
  }) = _CoachMessage;
}

/// One coach session and its transcript, on the iPhone only.
///
/// **Device-only** (CLAUDE.md §11): a transcript can quote Health values and
/// cravings, so it is never stored in SwiftData/CloudKit (App Store
/// 5.1.3(ii)). The data export carries only [startedAt]'s date, [kind] and
/// [summary], never [messages].
@freezed
abstract class CoachSession with _$CoachSession {
  /// Creates a [CoachSession].
  const factory CoachSession({
    /// Identity, unique per session. Saving a session with an `id` that's
    /// already stored replaces it.
    required String id,

    /// Chat or the weekly session.
    required CoachSessionKind kind,

    /// When the session started. Sessions are listed newest first by it.
    required DateTime startedAt,

    /// The transcript, in the order it was said. Empty until the first
    /// message.
    @Default(<CoachMessage>[]) List<CoachMessage> messages,

    /// When the session ended; `null` while it's still going (or if it was
    /// left without ending).
    DateTime? endedAt,

    /// The coach's short summary of the session, once there is one.
    String? summary,
  }) = _CoachSession;
}
