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
///
/// [toString] is redacted: see [CoachSession].
@Freezed(toStringOverride: false)
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

  const CoachMessage._();

  /// Shape only, never [text] — see [CoachSession.toString].
  @override
  String toString() =>
      'CoachMessage(role: $role, text: ${text.length} chars, at: $at)';
}

/// One coach session and its transcript, on the iPhone only.
///
/// **Device-only** (CLAUDE.md §11): a transcript can quote Health values and
/// cravings, so it is never stored in SwiftData/CloudKit (App Store
/// 5.1.3(ii)). The data export carries only [startedAt]'s date, [kind] and
/// [summary], never [messages].
///
/// For the same reason [toString] gives the session's shape and never what
/// was said: freezed's generated one would print the whole transcript, and
/// a `ProviderObserver` (CLAUDE.md §4) or a Flutter error dump prints state
/// through `toString`. [messages] and [summary] are reachable only by
/// reading the fields on purpose.
@Freezed(toStringOverride: false)
abstract class CoachSession with _$CoachSession {
  /// Creates a [CoachSession].
  const factory CoachSession({
    /// Identity, unique per session. Saving a session with an `id` that's
    /// already stored replaces it.
    ///
    /// Opaque (e.g. a UUID): never built from what was said, the summary,
    /// or a Health value. [toString] prints it, so a log line or error dump
    /// can say which session it's about without saying anything about it.
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

  const CoachSession._();

  /// Shape only, never [messages] or [summary] — see the class doc. [id]
  /// is printed because it's opaque (see its doc).
  @override
  String toString() =>
      'CoachSession(id: $id, kind: $kind, startedAt: $startedAt, '
      'messages: ${messages.length}, endedAt: $endedAt, '
      'summary: ${summary == null ? 'null' : '${summary!.length} chars'})';
}
