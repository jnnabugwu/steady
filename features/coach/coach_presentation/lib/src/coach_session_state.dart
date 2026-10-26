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
  }) = _CoachSessionState;

  const CoachSessionState._();

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
