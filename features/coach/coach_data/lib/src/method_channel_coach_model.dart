import 'dart:async';

import 'package:coach_data/src/coach_model_wire.dart';
import 'package:coach_domain/coach_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter/services.dart';

/// [CoachModel] backed by the `steady/coach` platform channels
/// ([CoachModelChannel]): Apple Foundation Models, on the iPhone only.
///
/// The native side lives runner-adjacent, like the HealthKit channel
/// (CLAUDE.md §8): `app/ios/Runner/CoachChannel.swift`. macOS has no
/// handler and the app doesn't bind this there at all (§11).
///
/// Every platform error becomes a typed [Failure] here, so the UI never
/// sees a raw [PlatformException] (§9): an unavailable model is a
/// [CoachModelUnavailableFailure] subtype, a failed reply a
/// [CoachInferenceFailure], an empty prompt or empty instructions a
/// [ValidationFailure] (without calling native), a missing handler or an
/// unknown error code outside a reply a [PlatformChannelFailure], and a
/// reply in the wrong shape an [UnknownFailure].
class MethodChannelCoachModel implements CoachModel {
  /// Creates the model. [channel] and [responses] are for tests; the
  /// defaults are the real `steady/coach` channels.
  MethodChannelCoachModel({MethodChannel? channel, EventChannel? responses})
    : _channel = channel ?? const MethodChannel(CoachModelChannel.name),
      _responses =
          responses ?? const EventChannel(CoachModelChannel.responsesName);

  final MethodChannel _channel;
  final EventChannel _responses;

  /// The reply stream currently owning the `steady/coach/responses`
  /// handler, if any.
  ///
  /// The native side has one `FlutterEventSink`, so only one reply streams
  /// at a time; the binary messenger likewise has one message handler per
  /// channel name. Without an owner, a second `listen` would silently take
  /// the handler over and the first stream would hang forever — never
  /// emitting, never closing — and that first stream's `cancel` would then
  /// clear the second's handler. So each `_listen` takes ownership, closes
  /// the stream it displaces (which cancels it natively, stopping a reply
  /// nobody is listening to), and clears the handler on cancel only while
  /// it still owns it.
  ///
  /// **Residual, and why it isn't fixed here:** events on
  /// `steady/coach/responses` carry no session id, so an event the
  /// displaced native stream had already queued before its `cancel`
  /// arrived is indistinguishable from the live stream's own, and an
  /// end-of-stream among them would close the live stream early. Telling
  /// them apart needs the session id on the wire, which is a change to
  /// `CoachChannel.swift`. Cancelling the displaced stream immediately
  /// keeps the window small.
  _ResponseListen? _owner;

  @override
  ResultFuture<CoachModelInfo> checkAvailability() async {
    final result = await _call(
      'Could not check whether the coach is available',
      () async => coachAvailabilityFromWire(
        await _channel.invokeMethod<Object?>(
          CoachModelChannel.availabilityMethod,
        ),
      ),
    );
    return switch (result) {
      Ok(value: (info: final info?, failure: _)) => Ok(info),
      Ok(value: (info: _, failure: final failure?)) => Err(failure),
      Ok() => const Err(UnknownFailure('Empty availability reply')),
      Err(:final failure) => Err(failure),
    };
  }

  @override
  ResultFuture<CoachModelSession> startSession({
    required String instructions,
  }) async {
    if (instructions.trim().isEmpty) {
      return const Err(ValidationFailure('instructions must not be empty'));
    }
    return await _call('Could not start a coach session', () async {
      final id = await _channel.invokeMethod<Object?>(
        CoachModelChannel.startSessionMethod,
        {'instructions': instructions},
      );
      if (id is! String || id.isEmpty) {
        throw FormatException('Expected a session id', id);
      }
      return CoachModelSession(id: id);
    });
  }

  @override
  Stream<Result<String>> streamResponse(
    CoachModelSession session,
    String prompt,
  ) async* {
    if (prompt.trim().isEmpty) {
      yield const Err(ValidationFailure('prompt must not be empty'));
      return;
    }
    try {
      // Cancelling this generator's subscription cancels the `await for`,
      // which cancels the native stream and stops the model.
      await for (final event in _listen({
        'sessionId': session.id,
        'prompt': prompt,
        'maximumResponseTokens': CoachModelChannel.maximumResponseTokens,
      })) {
        if (event is! String) {
          yield Err(
            UnknownFailure(
              'The coach sent a reply in an unexpected shape',
              cause: FormatException('Expected a String snapshot', event),
            ),
          );
          return;
        }
        yield Ok(event);
      }
    } on PlatformException catch (e) {
      yield Err(_responseFailure(e));
    } on MissingPluginException catch (e) {
      yield Err(_missingPlugin(e));
    } on Object catch (e) {
      yield Err(UnknownFailure('The coach could not reply', cause: e));
    }
  }

  /// The [_responses] event stream for [arguments], like
  /// `EventChannel.receiveBroadcastStream` but with one difference: a
  /// failed `listen` call (no native handler, as on macOS) is delivered as
  /// the stream's error and closes it. `receiveBroadcastStream` only
  /// reports that through `FlutterError.reportError`, so the stream would
  /// never emit or close and the coach UI would wait forever.
  Stream<Object?> _listen(Map<String, Object?> arguments) {
    final name = _responses.name;
    final codec = _responses.codec;
    final messenger = _responses.binaryMessenger;
    final control = MethodChannel(name, codec, messenger);
    late final StreamController<Object?> controller;
    late final _ResponseListen me;
    controller = StreamController<Object?>(
      onListen: () async {
        // Whatever was listening can no longer be reached by the native
        // side: close it rather than leave it waiting forever.
        // Not awaited: this listen must not wait on the displaced stream's
        // listener to drain, and nothing here depends on it being closed.
        final displaced = _owner;
        _owner = me;
        if (displaced != null) unawaited(displaced.close());

        messenger.setMessageHandler(name, (reply) async {
          // A late event from a stream that has lost ownership belongs to
          // nobody: dropping it is what keeps it from closing this one.
          if (_owner != me) return null;
          if (reply == null) {
            unawaited(controller.close());
          } else {
            try {
              controller.add(codec.decodeEnvelope(reply));
            } on PlatformException catch (e) {
              controller.addError(e);
            }
          }
          return null;
        });
        try {
          await control.invokeMethod<void>('listen', arguments);
        } on Object catch (e, stack) {
          if (_owner == me) {
            messenger.setMessageHandler(name, null);
            _owner = null;
          }
          controller.addError(e, stack);
          unawaited(controller.close());
        }
      },
      onCancel: () async {
        // Only clear the handler if it's still ours; a newer listen may
        // own it by now.
        if (_owner == me) {
          messenger.setMessageHandler(name, null);
          _owner = null;
        }
        try {
          await control.invokeMethod<void>('cancel', arguments);
        } on Object {
          // Nothing to stop: the native stream already ended or never
          // started.
        }
      },
    );
    me = _ResponseListen(controller);
    return controller.stream;
  }

  @override
  ResultFuture<Unit> cancelResponse(CoachModelSession session) =>
      _call('Could not stop the coach reply', () async {
        await _channel.invokeMethod<void>(
          CoachModelChannel.cancelResponseMethod,
          {'sessionId': session.id},
        );
        return unit;
      });

  @override
  ResultFuture<Unit> endSession(CoachModelSession session) =>
      _call('Could not end the coach session', () async {
        await _channel.invokeMethod<void>(CoachModelChannel.endSessionMethod, {
          'sessionId': session.id,
        });
        return unit;
      });

  /// The failure for an error event on the reply stream.
  static Failure _responseFailure(PlatformException e) {
    if (e.code == CoachModelChannel.unavailableCode) {
      return coachUnavailableFailureFromWire(e.details);
    }
    final message = e.message ?? 'The coach could not reply';
    if (e.code == CoachModelChannel.sessionNotFoundCode) {
      return CoachInferenceFailure(
        message,
        reason: CoachInferenceFailureReason.sessionEnded,
        cause: e,
      );
    }
    return CoachInferenceFailure(
      message,
      reason:
          CoachModelChannel.inferenceCodes[e.code] ??
          CoachInferenceFailureReason.other,
      cause: e,
    );
  }

  static PlatformChannelFailure _missingPlugin(MissingPluginException e) =>
      PlatformChannelFailure(
        'The coach is not available on this platform',
        code: 'missingPlugin',
        cause: e,
      );

  /// Runs [body], mapping every exception to a [Failure] described by
  /// [what].
  Future<Result<T>> _call<T>(String what, Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on PlatformException catch (e) {
      if (e.code == CoachModelChannel.unavailableCode) {
        return Err(coachUnavailableFailureFromWire(e.details));
      }
      return Err(
        PlatformChannelFailure(e.message ?? what, code: e.code, cause: e),
      );
    } on MissingPluginException catch (e) {
      return Err(_missingPlugin(e));
    } on FormatException catch (e) {
      return Err(UnknownFailure('$what: unexpected reply', cause: e));
    } on Object catch (e) {
      // A `TypeError` from a cast in the reply's shape, or anything else
      // the channel throws: never let it escape the `Result`.
      return Err(UnknownFailure(what, cause: e));
    }
  }
}

/// One `listen` on `steady/coach/responses`, used as the identity of
/// whichever reply stream currently owns that channel's single handler.
class _ResponseListen {
  _ResponseListen(this._controller);

  final StreamController<Object?> _controller;

  /// Closes the stream, if it hasn't been closed already.
  Future<void> close() async {
    if (!_controller.isClosed) await _controller.close();
  }
}
