import 'dart:async';

import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/src/coach_consent_controller.dart';
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
/// before the coach is touched and again in [startWeeklySession]). Its
/// topics are separate threads ([weeklyTopicsFor]: logging, steps, the
/// cravings when there were any, next week), each opened by an app turn
/// (`CoachTurn.app`, which the proxy expands into the topic's prompt) and
/// moved on by [moveToNextWeeklyTopic]. It ends like a chat, with a stored
/// summary.
///
/// A family keyed by the session's [kind] and a fresh `sessionId` per
/// opening of the screen, so a session still writing its summary after its
/// screen closed is never handed to the next one. Auto-dispose; from its
/// first line to its last, [endCoachSession] holds a `KeepAliveLink`
/// (closed in `finally`), so closing the screen doesn't lose the summary
/// (CLAUDE.md §4).
///
/// **One operation at a time.** A turn (the person's message: save, the
/// reply, save) and a retried start are each one in-flight operation
/// ([_operation]). The phase isn't the lock: `replying` covers a save as
/// well as the reply. Ending marks the session as ending at once, stops
/// whatever is streaming, and waits for the operation to finish before it
/// summarises; an operation that resumes after that point stops without
/// touching the coach or the transcript further.
///
/// **Stateless model.** Nothing is started or ended on the model's side:
/// every reply sends the session's kind, the week's compact context
/// ([BuildCoachWeekContext], [formatCoachWeek]) and the whole conversation
/// so far ([_turns]), app turns in place. The summary is one request of its
/// own kind (`CoachRequestKind.summary`) over the transcript.
///
/// **Nothing is sent without consent** ([coachConsentGivenProvider]):
/// checked through [checkCoachAvailable] at the start and before a retry,
/// again at the weekly session's Begin, and before every request, the
/// summary's included ([isCoachConsentGiven]); the hosted model checks it
/// once more. **Turning the coach off** (Settings → Coach,
/// `withdrawCoachConsent`) stops whatever is streaming at once, drops that
/// reply's partial text, and leaves the session unavailable with
/// [CoachConsentNotGivenFailure]; a session that was ending saves without
/// a summary. **Turning it on** while the session says it's off starts it
/// again ([retryCoachStart]).
///
/// **Saving.** The transcript is saved through `CoachRepository` after the
/// person's message and after each reply (an upsert by id), and once more
/// with the summary when the session ends. Nothing is stored until the
/// person has said something, and never again for a session that was
/// still open when "Delete coach history" ran ([coachHistoryEpochProvider]).
@riverpod
class CoachSessionController extends _$CoachSessionController {
  late CoachModel _api;

  /// The week's compact context, once the session has started.
  String? _weekContext;

  /// The conversation as the coach is sent it: the transcript's turns, plus
  /// the app's weekly topic turns in place, and "Keep going" as the prompt
  /// it sends rather than the label the transcript stores.
  final List<CoachTurn> _turns = [];

  /// The reply on screen, which [stopCoachReply] can stop.
  StreamSubscription<Result<CoachReplySnapshot>>? _reply;

  /// Whichever reply stream is running (the reply on screen, or the
  /// summary), and its completion: cancelled on dispose.
  StreamSubscription<Result<CoachReplySnapshot>>? _active;
  Completer<void>? _activeDone;

  /// The turn or retried start in flight, which [endCoachSession] waits
  /// for. `null` when nothing is running.
  Future<void>? _operation;

  /// Set when [endCoachSession] starts: an operation that resumes after it
  /// stops there, and no new one starts.
  var _ending = false;

  /// [coachHistoryEpochProvider]'s value when this session opened.
  late int _historyEpoch;

  /// The stream [_stopStreaming] stopped because consent was withdrawn,
  /// and the failure [_stream] returns for it.
  (StreamSubscription<Result<CoachReplySnapshot>>, Failure)? _stoppedBy;

  @override
  CoachSessionState build(CoachSessionKind kind, String sessionId) {
    ref.onDispose(_dispose);
    _api = ref.read(coachModelProvider);
    _historyEpoch = ref.read(coachHistoryEpochProvider).value;
    ref.listen(coachConsentGivenProvider, _consentChanged);
    final now = ref.read(coachClockProvider)();
    unawaited(_start());
    return CoachSessionState(
      phase: CoachSessionPhase.starting,
      session: CoachSession(id: sessionId, kind: kind, startedAt: now),
    );
  }

  /// The request kind for this session's replies.
  CoachRequestKind get _replyKind => switch (kind) {
    CoachSessionKind.chat => CoachRequestKind.chat,
    CoachSessionKind.weekly => CoachRequestKind.weekly,
  };

  Future<void> _start() async {
    final weekly = kind == CoachSessionKind.weekly;
    if (weekly) {
      // The rule comes first: below it, the coach is never touched.
      final ready = await _checkWeek();
      if (!ref.mounted || ready == null || !ready.allowed) return;
    }
    if (!await _available()) return;

    final now = ref.read(coachClockProvider)();
    final window = weekly
        ? (first: state.weekFirst!, last: state.weekLast!)
        : coachChatWindow(now);
    final data = await ref
        .read(coachWeekContextProvider)
        .call(first: window.first, last: window.last, now: now);
    if (!ref.mounted) return;
    // Turned off while the week was read: say so rather than offer it.
    if (!_consentGiven) return _withdrawnWhileIdle();
    _weekContext = formatCoachWeek(data, includeCravingReasons: weekly);
    state = state.copyWith(
      topics: weekly ? weeklyTopicsFor(cravingCount: data.cravingCount) : [],
      phase: weekly ? CoachSessionPhase.awaitingStart : CoachSessionPhase.ready,
    );
  }

  /// Whether consent is a settled yes right now ([isCoachConsentGiven]).
  bool get _consentGiven =>
      isCoachConsentGiven(ref.read(coachConsentGivenProvider));

  /// Consent was given or withdrawn ([coachConsentGivenProvider]).
  void _consentChanged(AsyncValue<bool>? previous, AsyncValue<bool> next) {
    if (!ref.mounted) return;
    final was = previous != null && isCoachConsentGiven(previous);
    final now = isCoachConsentGiven(next);
    if (was && !now) {
      _consentWithdrawn();
    } else if (!was &&
        now &&
        !_ending &&
        state.phase == CoachSessionPhase.unavailable &&
        state.failure is CoachConsentNotGivenFailure) {
      unawaited(retryCoachStart());
    }
  }

  /// The coach was turned off: stop whatever streams (its operation then
  /// lands [CoachConsentNotGivenFailure]: the turn goes unavailable, the
  /// summary is dropped), or, with nothing streaming, say it's off.
  void _consentWithdrawn() {
    if (_active != null) {
      _stopStreaming(because: const CoachConsentNotGivenFailure());
      return;
    }
    _withdrawnWhileIdle();
  }

  /// Unavailable for want of consent, unless the session is past offering
  /// anything (ending, ended, or stopped for another reason) or mid-way
  /// through an operation, whose next request refuses by itself.
  void _withdrawnWhileIdle() {
    if (_ending) return;
    switch (state.phase) {
      case CoachSessionPhase.ready || CoachSessionPhase.awaitingStart:
        state = state.copyWith(
          phase: CoachSessionPhase.unavailable,
          reply: null,
          replyCutOff: false,
          failure: const CoachConsentNotGivenFailure(),
        );
      case CoachSessionPhase.starting ||
          CoachSessionPhase.replying ||
          CoachSessionPhase.unavailable ||
          CoachSessionPhase.failedToStart ||
          CoachSessionPhase.notEnoughCheckIns ||
          CoachSessionPhase.ending ||
          CoachSessionPhase.ended:
        break;
    }
  }

  /// Whether the coach may send anything ([checkCoachAvailable]). Sets the
  /// phase and failure when not.
  Future<bool> _available() async {
    final result = await checkCoachAvailable(
      consentGiven: await readCoachConsent(
        ref.read(coachConsentGivenProvider.future),
      ),
      model: _api,
    );
    if (!ref.mounted) return false;
    if (result case Err(:final failure)) {
      state = state.copyWith(
        phase: failure is CoachUnavailableFailure
            ? CoachSessionPhase.unavailable
            : CoachSessionPhase.failedToStart,
        failure: failure,
      );
      return false;
    }
    return true;
  }

  /// Domain event: CoachMessageSent.
  ///
  /// Adds the person's [text] (trimmed, at most [coachMaxMessageChars]) to
  /// the transcript, saves it, and streams the coach's reply into
  /// [CoachSessionState.reply], snapshot by snapshot. Ignored unless the
  /// session is ready, for an empty message, once ending, or once disposed.
  Future<void> sendCoachMessage(String text) async {
    if (!ref.mounted || _ending || state.phase != CoachSessionPhase.ready) {
      return;
    }
    final message = clampCoachMessage(text);
    if (message.isEmpty) return;
    await _run(() => _send(message));
  }

  /// Runs [operation] as the one in flight ([_operation]).
  Future<void> _run(Future<void> Function() operation) async {
    final running = operation();
    _operation = running;
    try {
      await running;
    } finally {
      if (identical(_operation, running)) _operation = null;
    }
  }

  /// Domain event: CoachKeepGoing.
  ///
  /// "Keep going" under a reply cut off at the proxy's token limit
  /// ([CoachSessionState.replyCutOff]): the person's turn reads "Keep
  /// going", and the coach is asked to carry on ([CoachKeepGoing]). Ignored
  /// unless the session is ready after a cut-off reply, once ending, or once
  /// disposed.
  Future<void> keepGoing() async {
    if (!ref.mounted ||
        _ending ||
        state.phase != CoachSessionPhase.ready ||
        !state.replyCutOff) {
      return;
    }
    await _run(
      () => _send(CoachKeepGoing.message, prompt: CoachKeepGoing.prompt),
    );
  }

  /// The person's [message]: added to the transcript and saved, then the
  /// reply, with [prompt] sent as their turn instead when given ("Keep
  /// going" stores its label but asks for more).
  Future<void> _send(String message, {String? prompt}) async {
    final said = CoachMessage(
      role: CoachMessageRole.user,
      text: message,
      at: ref.read(coachClockProvider)(),
    );
    _turns.add(CoachTurn.person(prompt ?? message));
    state = state.copyWith(
      phase: CoachSessionPhase.replying,
      session: state.session.copyWith(
        messages: [...state.session.messages, said],
      ),
      reply: null,
      failure: null,
      replyCutOff: false,
    );
    await _save();
    if (!ref.mounted || _ending) return;
    await _replyTo();
  }

  /// Domain event: WeeklySessionStarted.
  ///
  /// Begins the weekly session: checks the 4-of-7 rule again
  /// ([CheckWeeklyReadiness], the week may have changed since the screen
  /// opened), then has the coach open the first topic (logging). If a new
  /// week began meanwhile (the screen was left open into a Friday), the
  /// session is set up again with that week's data first. Without consent
  /// it sends nothing and says the coach is off. Ignored unless the session
  /// is waiting to begin, or once ending.
  Future<void> startWeeklySession() async {
    if (!ref.mounted ||
        _ending ||
        state.phase != CoachSessionPhase.awaitingStart) {
      return;
    }
    if (!_consentGiven) return _withdrawnWhileIdle();
    state = state.copyWith(phase: CoachSessionPhase.starting);
    await _run(() async {
      final readFor = state.weekFirst;
      final ready = await _checkWeek();
      if (!ref.mounted || _ending || ready == null || !ready.allowed) return;
      if (ready.first != readFor) {
        _weekContext = null;
        await _start();
        if (!ref.mounted ||
            _ending ||
            state.phase != CoachSessionPhase.awaitingStart) {
          return;
        }
      }
      await _openTopic(0);
    });
  }

  /// Domain event: WeeklyTopicAdvanced.
  ///
  /// Moves the weekly session to its next topic (logging → steps →
  /// cravings, when there were any → next week), as a new thread: the
  /// proxy's topic prompt tells the coach to leave the last one behind.
  /// Ignored unless the session is ready and has a next topic, or once
  /// ending.
  Future<void> moveToNextWeeklyTopic() async {
    if (!ref.mounted ||
        _ending ||
        state.phase != CoachSessionPhase.ready ||
        !state.hasNextTopic) {
      return;
    }
    await _run(() => _openTopic(state.topicIndex + 1));
  }

  Future<void> _openTopic(int index) async {
    _turns.add(CoachTurn.app(state.topics[index]));
    state = state.copyWith(
      phase: CoachSessionPhase.replying,
      topicIndex: index,
      reply: null,
      failure: null,
      replyCutOff: false,
    );
    await _replyTo();
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

  /// Streams the coach's reply to the conversation so far ([_turns], whose
  /// last turn is the person's or the app's) into the transcript.
  Future<void> _replyTo() async {
    // Ending stops what streams; nothing new starts after it.
    if (_ending) return;
    final (:text, :stopReason, :failure) = await _stream(
      // A copy: the request is read when it's sent, and [_turns] moves on.
      CoachRequest(
        kind: _replyKind,
        weekContext: _weekContext,
        turns: List.unmodifiable(_turns),
      ),
      show: true,
    );
    if (!ref.mounted) return;

    // A failed reply is dropped, partial text included: a refusal's must
    // never be shown. A reply the person stopped keeps what was said.
    final kept = text.trim();
    final reply = kept.isEmpty || failure != null
        ? null
        : CoachMessage(
            role: CoachMessageRole.coach,
            text: kept,
            at: ref.read(coachClockProvider)(),
          );
    if (reply != null) _turns.add(CoachTurn.coach(reply.text));
    if (failure != null) return _replyFailed(failure);
    state = state.copyWith(
      phase: CoachSessionPhase.ready,
      reply: null,
      replyCutOff: reply != null && stopReason == CoachStopReason.maxTokens,
      session: state.session.copyWith(
        messages: [...state.session.messages, ?reply],
      ),
    );
    if (reply != null) await _save();
  }

  void _replyFailed(Failure failure) {
    // The coach can't run here any more (the kill switch, say): the way
    // back is "Check again". Anything else leaves the conversation ready,
    // with a line saying the reply failed.
    state = state.copyWith(
      phase: failure is CoachUnavailableFailure
          ? CoachSessionPhase.unavailable
          : CoachSessionPhase.ready,
      reply: null,
      replyCutOff: false,
      failure: failure,
    );
  }

  /// Streams the reply to [request]. Returns the last snapshot's text (what
  /// was said before a stop, too), the stop reason if it finished, and the
  /// failure, if any. With [show], each snapshot goes to
  /// [CoachSessionState.reply].
  Future<({String text, CoachStopReason? stopReason, Failure? failure})>
  _stream(CoachRequest request, {required bool show}) async {
    // Nothing leaves the phone without a settled yes.
    if (!_consentGiven) {
      return (
        text: '',
        stopReason: null,
        failure: const CoachConsentNotGivenFailure(),
      );
    }
    var latest = '';
    CoachStopReason? stopReason;
    Failure? failure;
    final done = Completer<void>();
    void finish() {
      if (!done.isCompleted) done.complete();
    }

    final subscription = _api
        .reply(request)
        .listen(
          (result) {
            switch (result) {
              case Ok(:final value):
                latest = value.text;
                stopReason = value.stopReason;
                if (show && ref.mounted) {
                  state = state.copyWith(reply: value.text);
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
    if (_stoppedBy case (final stopped, final because)
        when identical(stopped, subscription)) {
      _stoppedBy = null;
      // Stopped because the coach was turned off: what came in is dropped.
      return (text: '', stopReason: null, failure: because);
    }
    return (text: latest, stopReason: stopReason, failure: failure);
  }

  /// Domain event: CoachReplyStopped.
  ///
  /// Stops the reply in flight. What the coach had said so far stays in the
  /// transcript, and in what the coach is sent next. Ignored unless the
  /// coach is replying.
  Future<void> stopCoachReply() async {
    if (!ref.mounted || state.phase != CoachSessionPhase.replying) return;
    final subscription = _reply;
    final done = _activeDone;
    if (subscription == null || done == null) return;
    _reply = null;
    // Cancelling aborts the request, and the proxy stops the model. The
    // reply ends here either way, so don't wait for that.
    unawaited(subscription.cancel());
    if (!done.isCompleted) done.complete();
  }

  /// Cancels whichever reply stream is running, so the operation awaiting
  /// it moves on with what was said so far, or, stopped [because] of a
  /// failure (consent withdrawn), with that failure and nothing said.
  void _stopStreaming({Failure? because}) {
    final subscription = _active;
    final done = _activeDone;
    if (subscription != null && because != null) {
      _stoppedBy = (subscription, because);
    }
    _reply = null;
    if (subscription != null) unawaited(subscription.cancel());
    if (done != null && !done.isCompleted) done.complete();
  }

  /// The session's summary: one `summary` request over the transcript
  /// (the person's and the coach's turns, never the app's). `null` if it
  /// fails or comes back empty.
  Future<String?> _summary() async {
    final (:text, :failure, stopReason: _) = await _stream(
      CoachRequest(
        kind: CoachRequestKind.summary,
        turns: [
          for (final message in state.session.messages)
            switch (message.role) {
              CoachMessageRole.user => CoachTurn.person(message.text),
              CoachMessageRole.coach => CoachTurn.coach(message.text),
            },
        ],
      ),
      show: false,
    );
    final trimmed = text.trim();
    return failure == null && trimmed.isNotEmpty ? trimmed : null;
  }

  /// Domain event: CoachSessionEnded.
  ///
  /// Stops any reply in flight and waits for the turn it belongs to, asks
  /// the coach for a short, neutral summary (`CoachRequestKind.summary`:
  /// tracking habits and next week's plan, no cravings, no exact numbers),
  /// and saves the session with it and its end time. A session where the
  /// person said nothing is not stored. Keeps itself alive from the first
  /// line, so the screen may close at once. Ignored once ending or ended,
  /// and while starting before the person has said anything.
  Future<void> endCoachSession() async {
    if (!ref.mounted || _ending) return;
    switch (state.phase) {
      case CoachSessionPhase.ending || CoachSessionPhase.ended:
        return;
      case CoachSessionPhase.starting when !state.hasUserMessages:
        return;
      case CoachSessionPhase.starting ||
          CoachSessionPhase.unavailable ||
          CoachSessionPhase.failedToStart ||
          CoachSessionPhase.notEnoughCheckIns ||
          CoachSessionPhase.awaitingStart ||
          CoachSessionPhase.ready ||
          CoachSessionPhase.replying:
        break;
    }
    _ending = true;
    final link = ref.keepAlive();
    try {
      if (_operation case final operation?) {
        // Stop whatever streams; the turn then lands what was said and
        // stops.
        _stopStreaming();
        // Its own caller sees any error; ending goes on regardless.
        await operation.then((_) {}, onError: (Object _) {});
        if (!ref.mounted) return;
      }
      if (!state.hasUserMessages) {
        state = state.copyWith(phase: CoachSessionPhase.ended, reply: null);
        return;
      }
      state = state.copyWith(
        phase: CoachSessionPhase.ending,
        reply: null,
        failure: null,
      );
      final summary = await _summary();
      if (!ref.mounted) return;
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

  /// Domain event: CoachStartRetried.
  ///
  /// Tries again after the coach couldn't start or stopped being available
  /// ("Check again"): checks again and starts afresh (before the person has
  /// said anything, including a weekly session that failed at Begin), or,
  /// mid-way through a conversation, sends the last turn again if the coach
  /// hadn't answered it. Ignored unless unavailable or failed to start,
  /// once ending, or once disposed.
  Future<void> retryCoachStart() async {
    if (!ref.mounted || _ending) return;
    if (state.phase != CoachSessionPhase.unavailable &&
        state.phase != CoachSessionPhase.failedToStart) {
      return;
    }
    state = state.copyWith(phase: CoachSessionPhase.starting, failure: null);
    // Until the person has said something there's nothing to carry over:
    // start again from the top, which for the weekly session also
    // re-checks the week and waits for Begin.
    if (_weekContext == null || !state.hasUserMessages) {
      _weekContext = null;
      _turns.clear();
      state = state.copyWith(
        topicIndex: -1,
        session: state.session.copyWith(messages: const []),
      );
      return await _run(_start);
    }
    await _run(() async {
      if (!await _available() || _ending) return;
      if (_turns.lastOrNull is CoachReplyTurn) {
        state = state.copyWith(phase: CoachSessionPhase.ready);
        return;
      }
      state = state.copyWith(phase: CoachSessionPhase.replying);
      await _replyTo();
    });
  }

  /// Domain event: CoachSessionSaveRetried.
  ///
  /// Saves the session again after a failed save. Ignored unless the last
  /// save failed, or once disposed.
  Future<void> retryCoachSave() async {
    if (!ref.mounted || !state.saveFailed) return;
    await _save();
  }

  /// Saves the session as it stands. Never throws; a failure sets
  /// [CoachSessionState.saveFailed]. Saves nothing once "Delete coach
  /// history" has run since the session opened: a session still finishing
  /// its summary in the background mustn't bring itself back.
  Future<void> _save() async {
    if (!state.hasUserMessages) return;
    final epoch = ref.read(coachHistoryEpochProvider);
    await epoch.idle;
    if (!ref.mounted || epoch.value != _historyEpoch) return;
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
  }
}
