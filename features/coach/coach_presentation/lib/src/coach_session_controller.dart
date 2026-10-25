import 'dart:async';

import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/src/coach_history_providers.dart';
import 'package:coach_presentation/src/coach_session_state.dart';
import 'package:coach_presentation/src/coach_week_context.dart';
import 'package:coach_presentation/src/coach_weekly_readiness.dart';
import 'package:coach_presentation/src/providers.dart';
import 'package:failures/failures.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'coach_session_controller.g.dart';

/// A live coach session on the iPhone: a chat or the weekly session, from
/// opening the screen to its stored summary.
///
/// **The weekly session** (#81) looks back on the last completed
/// Friday→Thursday week ([coachWeeklyWindow]). It doesn't start if fewer
/// than 4 of its 7 days have a check-in ([CheckWeeklyReadiness], checked
/// before the model is touched and again in [startWeeklySession]). Its
/// topics are separate threads ([weeklyTopicsFor]: logging, steps, the
/// cravings when there were any, next week), each opened by an app prompt
/// ([weeklyTopicPrompt]) and moved on by [moveToNextWeeklyTopic]. It ends
/// like a chat, with a stored summary.
///
/// A family keyed by the session's [kind] and a fresh `sessionId` per
/// opening of the screen, so a session still writing its summary after its
/// screen closed is never handed to the next one. Auto-dispose; while
/// [endCoachSession] runs it holds a `KeepAliveLink` (closed in `finally`),
/// so closing the screen doesn't lose the summary (CLAUDE.md §4).
///
/// **Context budget.** The model sees the instructions for [kind] with a
/// compact summary of the person's last seven days
/// ([BuildCoachWeekContext], [formatCoachWeek]). Before every message,
/// [CoachConversation] checks the turn fits the device's context window
/// (`CoachModelInfo.contextSize`) with room for a full reply; when it
/// doesn't, the older turns are summarised in a separate model session and
/// the conversation moves to a fresh one, carrying that summary and the
/// last few messages. A reply that still overflows (`contextExceeded`) or
/// finds its native session gone moves on once more, without the summary,
/// and is retried once.
///
/// **Saving.** The transcript is saved through `CoachRepository` after the
/// person's message and after each reply (an upsert by id), and once more
/// with the summary when the session ends. Nothing is stored until the
/// person has said something.
@riverpod
class CoachSessionController extends _$CoachSessionController {
  late CoachModel _api;
  CoachModelSession? _model;
  CoachConversation? _conversation;
  late CoachContextBudget _budget;

  /// The reply on screen, which [stopCoachReply] can stop.
  StreamSubscription<Result<String>>? _reply;

  /// Whichever model stream is running (the reply on screen, or a summary
  /// asked in a separate session), and its completion: cancelled on
  /// dispose.
  StreamSubscription<Result<String>>? _active;
  Completer<void>? _activeDone;

  @override
  CoachSessionState build(CoachSessionKind kind, String sessionId) {
    ref.onDispose(_dispose);
    _api = ref.read(coachModelProvider);
    final now = ref.read(coachClockProvider)();
    unawaited(_start());
    return CoachSessionState(
      phase: CoachSessionPhase.starting,
      session: CoachSession(id: sessionId, kind: kind, startedAt: now),
    );
  }

  /// The base instructions for [kind].
  static String instructionsFor(CoachSessionKind kind) => switch (kind) {
    CoachSessionKind.chat => CoachInstructions.chat,
    CoachSessionKind.weekly => CoachInstructions.weeklySession,
  };

  Future<void> _start() async {
    final api = _api;
    final weekly = kind == CoachSessionKind.weekly;
    if (weekly) {
      // The rule comes first: below it, the model is never touched.
      final ready = await _checkWeek();
      if (!ref.mounted || ready == null || !ready.allowed) return;
    }
    final availability = await api.checkAvailability();
    if (!ref.mounted) return;
    final CoachModelInfo info;
    switch (availability) {
      case Ok(:final value):
        info = value;
      case Err(:final CoachModelUnavailableFailure failure):
        state = state.copyWith(
          phase: CoachSessionPhase.unavailable,
          failure: failure,
        );
        return;
      case Err(:final failure):
        state = state.copyWith(
          phase: CoachSessionPhase.failedToStart,
          failure: failure,
        );
        return;
    }
    _budget = CoachContextBudget(contextSize: info.contextSize);

    final now = ref.read(coachClockProvider)();
    final window = weekly
        ? (first: state.weekFirst!, last: state.weekLast!)
        : coachChatWindow(now);
    final data = await ref
        .read(coachWeekContextProvider)
        .call(first: window.first, last: window.last, now: now);
    if (!ref.mounted) return;
    final instructions = CoachInstructions.forSession(
      instructionsFor(kind),
      formatCoachWeek(data, includeCravingReasons: weekly),
    );
    if (weekly) {
      state = state.copyWith(
        topics: weeklyTopicsFor(cravingCount: data.cravingCount),
      );
    }

    final started = await api.startSession(instructions: instructions);
    if (!ref.mounted) {
      if (started case Ok(:final value)) unawaited(api.endSession(value));
      return;
    }
    switch (started) {
      case Ok(:final value):
        _model = value;
        _conversation = CoachConversation.start(instructions: instructions);
        state = state.copyWith(
          phase: weekly
              ? CoachSessionPhase.awaitingStart
              : CoachSessionPhase.ready,
        );
      case Err(:final failure):
        state = state.copyWith(
          phase: failure is CoachModelUnavailableFailure
              ? CoachSessionPhase.unavailable
              : CoachSessionPhase.failedToStart,
          failure: failure,
        );
    }
  }

  /// Domain event: CoachMessageSent.
  ///
  /// Adds the person's [text] (trimmed, at most [coachMaxMessageChars]) to
  /// the transcript, saves it, and streams the coach's reply into
  /// [CoachSessionState.reply], snapshot by snapshot. Ignored unless the
  /// session is ready, for an empty message, or once disposed.
  Future<void> sendCoachMessage(String text) async {
    if (!ref.mounted || state.phase != CoachSessionPhase.ready) return;
    final message = CoachConversation.clampMessage(text);
    if (message.isEmpty) return;
    final said = CoachMessage(
      role: CoachMessageRole.user,
      text: message,
      at: ref.read(coachClockProvider)(),
    );
    state = state.copyWith(
      phase: CoachSessionPhase.replying,
      session: state.session.copyWith(
        messages: [...state.session.messages, said],
      ),
      reply: null,
      failure: null,
    );
    await _save();
    if (!ref.mounted) return;
    await _turn(message, said: said);
  }

  /// Domain event: WeeklySessionStarted.
  ///
  /// Begins the weekly session: checks the 4-of-7 rule again
  /// ([CheckWeeklyReadiness], the week may have changed since the screen
  /// opened), then has the coach open the first topic (logging). Ignored
  /// unless the session is waiting to begin.
  Future<void> startWeeklySession() async {
    if (!ref.mounted || state.phase != CoachSessionPhase.awaitingStart) {
      return;
    }
    state = state.copyWith(phase: CoachSessionPhase.starting);
    final ready = await _checkWeek();
    if (!ref.mounted || ready == null) return;
    if (!ready.allowed) {
      _endModel();
      return;
    }
    await _openTopic(0);
  }

  /// Domain event: WeeklyTopicAdvanced.
  ///
  /// Moves the weekly session to its next topic (logging → steps →
  /// cravings, when there were any → next week), as a new thread: the
  /// coach is told to leave the last one behind. Ignored unless the
  /// session is ready and has a next topic.
  Future<void> moveToNextWeeklyTopic() async {
    if (!ref.mounted ||
        state.phase != CoachSessionPhase.ready ||
        !state.hasNextTopic) {
      return;
    }
    await _openTopic(state.topicIndex + 1);
  }

  Future<void> _openTopic(int index) async {
    state = state.copyWith(
      phase: CoachSessionPhase.replying,
      topicIndex: index,
      reply: null,
      failure: null,
    );
    await _turn(weeklyTopicPrompt(state.topics[index]));
  }

  /// Reads the weekly session's week and its readiness. Sets the phase
  /// for a failure or a week that's too thin; returns `null` on failure.
  Future<WeeklyReadiness?> _checkWeek() async {
    final result = await ref.read(coachWeeklyReadinessProvider)(
      ref.read(coachClockProvider)(),
    );
    if (!ref.mounted) return null;
    switch (result) {
      case Ok(:final value):
        state = state.copyWith(
          weekFirst: value.first,
          weekLast: value.last,
          phase: value.allowed
              ? state.phase
              : CoachSessionPhase.notEnoughCheckIns,
        );
        return value;
      case Err(:final failure):
        state = state.copyWith(
          phase: CoachSessionPhase.failedToStart,
          failure: failure,
        );
        return null;
    }
  }

  /// One exchange: [text] is the person's message ([said] its transcript
  /// entry) or, with [said] `null`, the app's own prompt (a weekly topic).
  /// Makes room first (a fresh model session when the turn wouldn't fit),
  /// then streams the reply into the transcript.
  Future<void> _turn(String text, {CoachMessage? said}) async {
    final fromApp = said == null;
    if (_conversation!.needsFreshSession(text, _budget, fromApp: fromApp)) {
      final moved = await _moveToFreshSession(summarise: true);
      if (!ref.mounted) return;
      if (moved != null) return _replyFailed(moved);
      if (_conversation!.needsFreshSession(text, _budget, fromApp: fromApp)) {
        // Even the carried context doesn't fit (a very small window): go
        // on with the message alone.
        _conversation = _conversation!.withoutCarry();
      }
    }
    await _replyTo(text, said, retried: false);
  }

  Future<void> _replyTo(
    String message,
    CoachMessage? said, {
    required bool retried,
  }) async {
    final prompt = _conversation!.promptFor(message, fromApp: said == null);
    final (text, failure) = await _stream(_model!, prompt, show: true);
    if (!ref.mounted) return;

    if (failure case CoachInferenceFailure(:final reason)
        when !retried &&
            (reason == CoachInferenceFailureReason.contextExceeded ||
                reason == CoachInferenceFailureReason.sessionEnded)) {
      final moved = await _moveToFreshSession(summarise: false);
      if (!ref.mounted) return;
      if (moved != null) return _replyFailed(moved);
      _conversation = _conversation!.withoutCarry();
      return await _replyTo(message, said, retried: true);
    }

    final reply = text.trim().isEmpty || failure != null
        ? null
        : CoachMessage(
            role: CoachMessageRole.coach,
            text: text.trim(),
            at: ref.read(coachClockProvider)(),
          );
    _conversation = said == null
        ? _conversation!.afterAppPrompt(prompt: prompt, reply: reply)
        : _conversation!.afterTurn(prompt: prompt, message: said, reply: reply);
    if (failure != null) return _replyFailed(failure);
    state = state.copyWith(
      phase: CoachSessionPhase.ready,
      reply: null,
      session: state.session.copyWith(
        messages: [...state.session.messages, ?reply],
      ),
    );
    if (reply != null) await _save();
  }

  void _replyFailed(Failure failure) {
    state = state.copyWith(
      phase: CoachSessionPhase.ready,
      reply: null,
      failure: failure,
    );
  }

  /// Streams the reply to [prompt] in [session]. Returns the last snapshot
  /// (what was said before a stop, too) and the failure, if any. With
  /// [show], each snapshot goes to [CoachSessionState.reply].
  Future<(String, Failure?)> _stream(
    CoachModelSession session,
    String prompt, {
    required bool show,
  }) async {
    var latest = '';
    Failure? failure;
    final done = Completer<void>();
    void finish() {
      if (!done.isCompleted) done.complete();
    }

    final subscription = _api
        .streamResponse(session, prompt)
        .listen(
          (result) {
            switch (result) {
              case Ok(:final value):
                latest = value;
                if (show && ref.mounted) {
                  state = state.copyWith(reply: value);
                }
              case Err(failure: final f):
                // The stream ends after one Err (`CoachModel`); don't wait
                // for it to close.
                failure = f;
                finish();
            }
          },
          onError: (Object e) {
            failure = e is Failure
                ? e
                : UnknownFailure('The coach could not reply', cause: e);
            finish();
          },
          onDone: finish,
        );
    _active = subscription;
    _activeDone = done;
    if (show) _reply = subscription;
    await done.future;
    // Already finished or cancelled; this only releases it. Not awaited:
    // nothing depends on it, and a finished subscription's cancel future
    // completes outside the caller's zone.
    unawaited(subscription.cancel());
    if (identical(_active, subscription)) {
      _active = null;
      _activeDone = null;
    }
    if (show) _reply = null;
    return (latest, failure);
  }

  /// Domain event: CoachReplyStopped.
  ///
  /// Stops the reply in flight. What the coach had said so far stays in the
  /// transcript (the model's own transcript keeps it too). Ignored unless
  /// the coach is replying.
  Future<void> stopCoachReply() async {
    if (!ref.mounted || state.phase != CoachSessionPhase.replying) return;
    final subscription = _reply;
    final done = _activeDone;
    if (subscription == null || done == null) return;
    _reply = null;
    // Cancelling stops the model (the channel cancels the native task).
    // The reply ends here either way, so don't wait for the native side.
    unawaited(subscription.cancel());
    if (!done.isCompleted) done.complete();
  }

  /// Summarises the window (unless not [summarise]), ends the current
  /// model session and starts a fresh one with the same instructions.
  /// Returns the failure if the fresh session couldn't start.
  Future<Failure?> _moveToFreshSession({required bool summarise}) async {
    final conversation = _conversation!;
    String? summary;
    if (summarise) {
      summary = await _askAlone(
        coachSummaryPrompt(
          request: CoachInstructions.summaryRequest,
          messages: conversation.toSummarise,
          earlierSummary: conversation.earlierSummary,
          budget: _budget,
          instructionTokens: estimateCoachTokens(conversation.instructions),
        ),
      );
      if (!ref.mounted) return null;
    }
    final api = _api;
    if (_model case final old?) unawaited(api.endSession(old));
    _model = null;
    final started = await api.startSession(
      instructions: conversation.instructions,
    );
    if (!ref.mounted) {
      if (started case Ok(:final value)) unawaited(api.endSession(value));
      return null;
    }
    switch (started) {
      case Ok(:final value):
        _model = value;
        _conversation = conversation.afterFreshSession(summary);
        return null;
      case Err(:final failure):
        return failure;
    }
  }

  /// Asks [prompt] in a separate model session primed with this session's
  /// instructions, and returns the reply, or `null` if anything fails.
  Future<String?> _askAlone(String? prompt) async {
    if (prompt == null) return null;
    final api = _api;
    final started = await api.startSession(
      instructions: _conversation!.instructions,
    );
    if (started case Ok(:final value)) {
      try {
        final (text, failure) = await _stream(value, prompt, show: false);
        final trimmed = text.trim();
        return failure == null && trimmed.isNotEmpty ? trimmed : null;
      } finally {
        unawaited(api.endSession(value));
      }
    }
    return null;
  }

  /// Domain event: CoachSessionEnded.
  ///
  /// Stops any reply in flight, asks the coach for a short, neutral summary
  /// (`CoachInstructions.summaryRequest`, under the session's own
  /// instructions), and saves the session with it and its end time. A
  /// session where the person said nothing is not stored. Keeps itself
  /// alive until done, so the screen may close at once. Ignored while
  /// starting, ending or ended.
  Future<void> endCoachSession() async {
    if (!ref.mounted) return;
    switch (state.phase) {
      case CoachSessionPhase.starting ||
          CoachSessionPhase.ending ||
          CoachSessionPhase.ended:
        return;
      case CoachSessionPhase.replying:
        await stopCoachReply();
        if (!ref.mounted) return;
        // Let the stopped reply land in the transcript first.
        await Future<void>.delayed(Duration.zero);
        if (!ref.mounted) return;
      case CoachSessionPhase.unavailable ||
          CoachSessionPhase.failedToStart ||
          CoachSessionPhase.notEnoughCheckIns ||
          CoachSessionPhase.awaitingStart ||
          CoachSessionPhase.ready:
        break;
    }
    if (state.phase == CoachSessionPhase.ending ||
        state.phase == CoachSessionPhase.ended) {
      return;
    }
    final link = ref.keepAlive();
    try {
      if (!state.hasUserMessages || _conversation == null) {
        _endModel();
        state = state.copyWith(phase: CoachSessionPhase.ended, reply: null);
        return;
      }
      state = state.copyWith(
        phase: CoachSessionPhase.ending,
        reply: null,
        failure: null,
      );
      final summary = await _askAlone(
        _conversation!.summaryPromptFor(
          state.session.messages,
          request: CoachInstructions.summaryRequest,
          budget: _budget,
        ),
      );
      if (!ref.mounted) return;
      _endModel();
      state = state.copyWith(
        phase: CoachSessionPhase.ended,
        session: state.session.copyWith(
          endedAt: ref.read(coachClockProvider)(),
          summary: summary,
        ),
      );
      await _save();
    } finally {
      link.close();
    }
  }

  /// Domain event: CoachSessionSaveRetried.
  ///
  /// Saves the session again after a failed save. Ignored unless the last
  /// save failed, or once disposed.
  Future<void> retryCoachSave() async {
    if (!ref.mounted || !state.saveFailed) return;
    await _save();
  }

  void _endModel() {
    if (_model case final model?) unawaited(_api.endSession(model));
    _model = null;
  }

  /// Saves the session as it stands. Never throws; a failure sets
  /// [CoachSessionState.saveFailed].
  Future<void> _save() async {
    if (!state.hasUserMessages) return;
    final session = state.session;
    Result<Unit> result;
    try {
      result = await ref.read(coachRepositoryProvider).saveSession(session);
    } on Object catch (e) {
      result = Err(UnknownFailure('Saving the coach session failed', cause: e));
    }
    if (!ref.mounted) return;
    state = state.copyWith(saveFailed: result is Err);
    if (result is Ok) ref.invalidate(coachSessionListProvider);
  }

  void _dispose() {
    unawaited(_active?.cancel());
    _active = null;
    _reply = null;
    if (_activeDone case final done? when !done.isCompleted) done.complete();
    _endModel();
  }
}
