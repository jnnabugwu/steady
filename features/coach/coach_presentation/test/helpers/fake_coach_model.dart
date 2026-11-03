import 'dart:async';

import 'package:coach_domain/coach_domain.dart';
import 'package:failures/failures.dart';

/// A scriptable [CoachModel] that records every request.
///
/// By default it's available and answers every request at once with
/// [replyFor]'s text, as two cumulative snapshots, the last with
/// [CoachStopReason.endTurn]. Set [manualReplies] to push snapshots
/// yourself through [say] / [finish] (a summary still answers at once), or
/// [failNext] to make the next reply fail.
class FakeCoachModel implements CoachModel {
  FakeCoachModel({
    this.availability = const Ok(unit),
    this.manualReplies = false,
  });

  /// What [checkAvailability] returns.
  Result<Unit> availability;

  /// How many times [checkAvailability] was called.
  int availabilityChecks = 0;

  /// When `true`, replies (not summaries) stay open until [finish].
  bool manualReplies;

  /// The next reply's failure (consumed by one reply).
  Failure? failNext;

  /// The stop reason the next automatic reply ends with (consumed by one
  /// reply).
  CoachStopReason stopReasonNext = CoachStopReason.endTurn;

  /// Awaited by every automatic reply before its first snapshot, when set:
  /// lets a test hold a reply (a summary, say) to interleave other calls.
  Future<void> Function()? beforeReply;

  /// The reply text for a request, when not [manualReplies].
  String Function(CoachRequest request) replyFor = (request) =>
      request.kind == CoachRequestKind.summary
      ? 'A short summary.'
      : 'Coach reply.';

  /// Every request, in order.
  final List<CoachRequest> requests = [];

  StreamController<Result<CoachReplySnapshot>>? _open;
  var _said = '';

  /// Whether a manual reply stream is open.
  bool get replying => _open != null;

  /// Whether the open stream's listener cancelled it.
  bool cancelled = false;

  /// The requests that weren't summaries.
  List<CoachRequest> get replyRequests =>
      requests.where((r) => r.kind != CoachRequestKind.summary).toList();

  /// The summary requests.
  List<CoachRequest> get summaryRequests =>
      requests.where((r) => r.kind == CoachRequestKind.summary).toList();

  @override
  ResultFuture<Unit> checkAvailability() async {
    availabilityChecks++;
    return availability;
  }

  @override
  Stream<Result<CoachReplySnapshot>> reply(CoachRequest request) {
    requests.add(request);
    if (failNext case final failure?) {
      failNext = null;
      return Stream.value(Err(failure));
    }
    final summary = request.kind == CoachRequestKind.summary;
    if (!manualReplies || summary) {
      final stop = summary ? CoachStopReason.endTurn : stopReasonNext;
      if (!summary) stopReasonNext = CoachStopReason.endTurn;
      return _auto(replyFor(request), stop);
    }
    cancelled = false;
    _said = '';
    final controller = StreamController<Result<CoachReplySnapshot>>(
      onCancel: () {
        cancelled = true;
        _open = null;
      },
    );
    _open = controller;
    return controller.stream;
  }

  Stream<Result<CoachReplySnapshot>> _auto(
    String text,
    CoachStopReason stop,
  ) async* {
    if (beforeReply case final hook?) await hook();
    yield Ok(CoachReplySnapshot(text: text.substring(0, text.length ~/ 2)));
    yield Ok(CoachReplySnapshot(text: text, stopReason: stop));
  }

  /// Pushes [snapshot] (the whole reply so far) on the open reply.
  void say(String snapshot) {
    _said = snapshot;
    _open!.add(Ok(CoachReplySnapshot(text: snapshot)));
  }

  /// Fails the open reply with [failure], and closes it: `CoachModel`
  /// says a reply's stream ends after one `Err`.
  void fail(Failure failure) {
    final open = _open!;
    _open = null;
    open.add(Err(failure));
    unawaited(open.close());
  }

  /// Finishes the open reply with [stopReason], and closes it.
  Future<void> finish({CoachStopReason stopReason = CoachStopReason.endTurn}) {
    final open = _open!;
    _open = null;
    open.add(Ok(CoachReplySnapshot(text: _said, stopReason: stopReason)));
    return open.close();
  }
}
