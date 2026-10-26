import 'dart:async';

import 'package:coach_domain/coach_domain.dart';
import 'package:failures/failures.dart';

/// One prompt the coach was sent, in which model session.
typedef SentPrompt = ({String session, String prompt});

/// A scriptable [CoachModel] that records every call.
///
/// By default it's available (4,096 tokens) and answers every prompt at
/// once with [replyFor]'s text, as two cumulative snapshots. Set
/// [manualReplies] to push snapshots yourself through [reply] / [finish],
/// or [failNext] to make the next reply fail.
class FakeCoachModel implements CoachModel {
  FakeCoachModel({
    this.availability = const Ok(CoachModelInfo(contextSize: 4096)),
    this.manualReplies = false,
  });

  /// What [checkAvailability] returns.
  Result<CoachModelInfo> availability;

  /// What [startSession] returns, or `null` for a new session.
  Result<CoachModelSession>? startResult;

  /// Awaited by [startSession] before it answers, when set: lets a test
  /// hold a model session's start to interleave other calls.
  Future<void> Function()? beforeStart;

  /// When `true`, replies stay open until [finish].
  bool manualReplies;

  /// The next reply's failure (consumed by one reply).
  Failure? failNext;

  /// The reply text for a prompt, when not [manualReplies].
  String Function(String prompt) replyFor = (prompt) =>
      prompt.startsWith(CoachInstructions.summaryRequest)
      ? 'A short summary.'
      : 'Coach reply.';

  /// Every session's instructions, in start order.
  final List<String> instructions = [];

  /// Every prompt, with its session id.
  final List<SentPrompt> prompts = [];

  /// Session ids ended.
  final List<String> ended = [];

  int availabilityChecks = 0;
  var _next = 0;
  StreamController<Result<CoachReplySnapshot>>? _open;

  /// The token count the next automatic reply reports (iOS 27's
  /// `Snapshot.usage`), or `null` for none, as on iOS 26. Consumed by one
  /// reply.
  int? outputTokensNext;

  /// Whether a reply stream is open.
  bool get replying => _open != null;

  /// Whether the open stream's listener cancelled it.
  bool cancelled = false;

  @override
  ResultFuture<CoachModelInfo> checkAvailability() async {
    availabilityChecks++;
    return availability;
  }

  @override
  ResultFuture<CoachModelSession> startSession({
    required String instructions,
  }) async {
    this.instructions.add(instructions);
    if (beforeStart case final hook?) await hook();
    if (startResult case final result?) return result;
    return Ok(CoachModelSession(id: 's${_next++}'));
  }

  @override
  Stream<Result<CoachReplySnapshot>> streamResponse(
    CoachModelSession session,
    String prompt,
  ) {
    prompts.add((session: session.id, prompt: prompt));
    if (failNext case final failure?) {
      failNext = null;
      return Stream.value(Err(failure));
    }
    final summary = prompt.startsWith(CoachInstructions.summaryRequest);
    if (!manualReplies || summary) {
      final text = replyFor(prompt);
      final half = text.substring(0, text.length ~/ 2);
      final tokens = summary ? null : outputTokensNext;
      if (!summary) outputTokensNext = null;
      return Stream.fromIterable([
        Ok(CoachReplySnapshot(text: half)),
        Ok(CoachReplySnapshot(text: text, outputTokens: tokens)),
      ]);
    }
    cancelled = false;
    final controller = StreamController<Result<CoachReplySnapshot>>(
      onCancel: () {
        cancelled = true;
        _open = null;
      },
    );
    _open = controller;
    return controller.stream;
  }

  /// Pushes [snapshot] (the whole reply so far, with [outputTokens] if the
  /// model reports them) on the open reply.
  void reply(String snapshot, {int? outputTokens}) => _open!.add(
    Ok(CoachReplySnapshot(text: snapshot, outputTokens: outputTokens)),
  );

  /// Fails the open reply with [failure], and closes it: `CoachModel`
  /// says a reply's stream ends after one `Err`.
  void fail(Failure failure) {
    final open = _open!;
    _open = null;
    open.add(Err(failure));
    unawaited(open.close());
  }

  /// Closes the open reply.
  Future<void> finish() async {
    final open = _open!;
    _open = null;
    await open.close();
  }

  @override
  ResultFuture<Unit> cancelResponse(CoachModelSession session) async {
    // `CoachModel.cancelResponse` says the reply's stream closes; in
    // production that's the native task ending. Leaving it open here let
    // tests pass on a stream a real caller would still be waiting on.
    final open = _open;
    if (open != null) {
      _open = null;
      cancelled = true;
      await open.close();
    }
    return const Ok(unit);
  }

  @override
  ResultFuture<Unit> endSession(CoachModelSession session) async {
    ended.add(session.id);
    return const Ok(unit);
  }
}
