import 'package:coach_domain/src/coach_model_failures.dart';
import 'package:coach_domain/src/coach_weekly.dart';
import 'package:failures/failures.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'coach_model.freezed.dart';

/// The model the coach talks through: Claude, behind Steady's own stateless
/// proxy (`jnnabugwu/steady-backend`), on the iPhone only (CLAUDE.md §11).
/// Nothing on the Mac implements this, and the app binds it only on iOS.
///
/// **Stateless.** There is no model session to start or end: every
/// [reply] carries the session's kind, the week's context and the whole
/// conversation so far ([CoachRequest]). The proxy owns the instructions
/// and the guardrails, so the app never sends instruction or prompt text.
///
/// Every failure is a typed [CoachModelFailure]: one class per thing the
/// coach screens have to say plainly (offline, rate limited, the coach
/// turned off, this iPhone can't be verified, no consent yet, a refusal, a
/// server error). The UI never sees an HTTP or platform exception.
abstract interface class CoachModel {
  /// `Ok` if this build and this iPhone can reach the coach at all, else
  /// `Err(CoachUnavailableFailure)` saying why: no proxy configured, or this
  /// iPhone can't be verified (CLAUDE.md §11).
  ///
  /// **Local and cheap: no network call.** It doesn't know whether the
  /// proxy is up; a reply finds that out. Safe to call before offering a
  /// session and on every return to the foreground. Consent is checked by
  /// the coach screens (`coachConsentGivenProvider`) and again by [reply].
  ResultFuture<Unit> checkAvailability();

  /// Streams the reply to [request].
  ///
  /// Each `Ok` is a [CoachReplySnapshot]: the whole reply so far, not just
  /// the new text, so show the latest one and replace the previous. The last
  /// one carries the [CoachStopReason], and then the stream closes. On
  /// failure it emits one `Err(CoachModelFailure)` and closes; a refusal
  /// ([CoachRefusalFailure]) can arrive after snapshots, and the text shown
  /// so far is then discarded.
  ///
  /// Cancelling the subscription stops the request (and so the reply); the
  /// stream then emits nothing more.
  ///
  /// One reply in flight at a time: a second call waits for the first to
  /// finish or be cancelled before it sends anything.
  Stream<Result<CoachReplySnapshot>> reply(CoachRequest request);
}

/// What a [CoachRequest] asks the coach for.
enum CoachRequestKind {
  /// A reply in a chat (`CoachSessionKind.chat`).
  chat,

  /// A reply in the weekly session (`CoachSessionKind.weekly`).
  weekly,

  /// The short, neutral summary a session ends with: the one stored and
  /// exported. The proxy builds the summary prompt itself (tracking habits
  /// and next week's plan; no cravings, no exact numbers, CLAUDE.md §7).
  summary,
}

/// One turn of the conversation a [CoachRequest] carries, oldest first.
///
/// [toString] is redacted, like `CoachSession`'s: a turn holds what the
/// person typed or the coach said, which can quote Health values and
/// cravings.
@Freezed(toStringOverride: false)
sealed class CoachTurn with _$CoachTurn {
  /// What the person said (at most `coachMaxMessageChars`).
  const factory CoachTurn.person(String text) = CoachPersonTurn;

  /// What the coach said: a whole reply, or what it had said when the
  /// person stopped it.
  const factory CoachTurn.coach(String text) = CoachReplyTurn;

  /// The app opening a weekly [topic] (weekly only). The proxy expands it
  /// into that topic's prompt; the person never sees it, but it stays in
  /// place in every later request, so the conversation is the same each
  /// time.
  const factory CoachTurn.app(WeeklyTopic topic) = CoachTopicTurn;

  const CoachTurn._();

  /// Shape only, never the text.
  @override
  String toString() => switch (this) {
    CoachPersonTurn(:final text) => 'CoachTurn.person(${text.length} chars)',
    CoachReplyTurn(:final text) => 'CoachTurn.coach(${text.length} chars)',
    CoachTopicTurn(:final topic) => 'CoachTurn.app(${topic.name})',
  };
}

/// Everything one reply needs: the proxy keeps nothing between requests.
///
/// [toString] is redacted: see [CoachTurn].
@Freezed(toStringOverride: false)
abstract class CoachRequest with _$CoachRequest {
  /// Creates a request.
  const factory CoachRequest({
    /// What's asked for.
    required CoachRequestKind kind,

    /// The whole conversation so far, oldest first. For chat and weekly the
    /// last turn is the person's or the app's (the coach replies to it);
    /// a summary may end with the coach's, and leaves out app turns.
    required List<CoachTurn> turns,

    /// The week's compact context (`formatCoachWeek`, at most 1,200
    /// characters): required for chat and weekly, `null` for a summary.
    String? weekContext,
  }) = _CoachRequest;

  const CoachRequest._();

  /// Shape only, never the turns' text or the week's data.
  @override
  String toString() =>
      'CoachRequest(kind: ${kind.name}, turns: ${turns.length}, '
      'weekContext: ${weekContext == null ? 'null' : '${weekContext!.length} '
                'chars'})';
}

/// Why a reply finished.
enum CoachStopReason {
  /// The coach finished what it had to say.
  endTurn,

  /// The reply was cut off at the proxy's token limit. The coach screens
  /// show it as it came and offer "Keep going" (`CoachKeepGoing`).
  maxTokens,
}

/// One snapshot of a reply as it streams ([CoachModel.reply]).
///
/// [toString] is redacted: see [CoachTurn].
@Freezed(toStringOverride: false)
abstract class CoachReplySnapshot with _$CoachReplySnapshot {
  /// Creates a snapshot of the reply so far.
  const factory CoachReplySnapshot({
    /// The whole reply so far.
    required String text,

    /// Why the reply finished, on the last snapshot only; `null` while it
    /// streams.
    CoachStopReason? stopReason,
  }) = _CoachReplySnapshot;

  const CoachReplySnapshot._();

  /// Shape only, never the text.
  @override
  String toString() =>
      'CoachReplySnapshot(text: ${text.length} chars, '
      'stopReason: ${stopReason?.name})';
}
