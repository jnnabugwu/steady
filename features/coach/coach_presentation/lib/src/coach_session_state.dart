import 'package:coach_domain/coach_domain.dart';
import 'package:failures/failures.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'coach_session_state.freezed.dart';

/// Where a live coach session is.
enum CoachSessionPhase {
  /// Checking the model, reading the week and starting the model session.
  starting,

  /// The model can't run on this iPhone right now
  /// ([CoachSessionState.failure] is a [CoachModelUnavailableFailure]).
  unavailable,

  /// The model is available, but the session couldn't start
  /// ([CoachSessionState.failure] says why).
  failedToStart,

  /// Weekly only: fewer than `weeklySessionMinCheckInDays` of the week's
  /// days have a check-in, so the session doesn't start (#81).
  notEnoughCheckIns,

  /// Weekly only: everything is ready; waiting for the person to begin
  /// (`startWeeklySession`).
  awaitingStart,

  /// Waiting for the person's next message.
  ready,

  /// The coach is replying ([CoachSessionState.reply] is the reply so far).
  replying,

  /// Writing the summary and saving the session.
  ending,

  /// Over. [CoachSessionState.session] has its summary, if one could be
  /// written.
  ended,
}

/// A live coach session's state (`CoachSessionController`).
///
/// A hand-written state rather than an `AsyncValue` (CLAUDE.md §4's
/// exception for multi-step flows): a failed start shows a different
/// screen from a failed reply, which keeps the conversation on screen with
/// a line under it, and a failed save is shown without stopping the
/// conversation.
@freezed
abstract class CoachSessionState with _$CoachSessionState {
  /// Creates the state.
  const factory CoachSessionState({
    /// Where the session is.
    required CoachSessionPhase phase,

    /// The session as stored (`CoachRepository`): its id, kind, start, and
    /// the transcript so far.
    required CoachSession session,

    /// The coach's reply so far while [phase] is
    /// [CoachSessionPhase.replying]: the latest snapshot, the whole reply
    /// so far. `null` until the first snapshot arrives.
    String? reply,

    /// Why the session couldn't start ([CoachSessionPhase.unavailable],
    /// [CoachSessionPhase.failedToStart]), or why the last reply failed
    /// (while [CoachSessionPhase.ready]). `null` otherwise.
    Failure? failure,

    /// Whether the last save to the coach history failed. The conversation
    /// carries on; the next save writes the whole session again.
    @Default(false) bool saveFailed,

    /// Weekly only: the week it looks back on (its Friday), once known.
    DateTime? weekFirst,

    /// Weekly only: the week's Thursday, once known.
    DateTime? weekLast,

    /// Weekly only: the session's topics, in order (`weeklyTopicsFor`).
    @Default(<WeeklyTopic>[]) List<WeeklyTopic> topics,

    /// Weekly only: the index in [topics] of the topic under way, or `-1`
    /// before the session begins.
    @Default(-1) int topicIndex,
  }) = _CoachSessionState;

  const CoachSessionState._();

  /// Weekly only: the topic under way, or `null` before it begins.
  WeeklyTopic? get topic =>
      topicIndex >= 0 && topicIndex < topics.length ? topics[topicIndex] : null;

  /// Weekly only: whether there's a topic after the current one.
  bool get hasNextTopic => topicIndex >= 0 && topicIndex < topics.length - 1;

  /// Whether the person has said anything yet. A session with nothing
  /// from them is never stored.
  bool get hasUserMessages =>
      session.messages.any((m) => m.role == CoachMessageRole.user);

  /// Whether the last reply was stopped by Apple's safety guardrails, when
  /// the screen offers the help line (`CoachCopy.helpLine`).
  bool get guardrailTripped => switch (failure) {
    CoachInferenceFailure(
      reason: CoachInferenceFailureReason.guardrailViolation,
    ) =>
      true,
    _ => false,
  };
}
