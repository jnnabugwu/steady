import 'dart:async';

import 'package:coach_data/coach_data.dart';
import 'package:coach_domain/coach_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The `steady/coach` contract (`CoachModelChannel`), against fake native
/// handlers. The Swift side is `app/ios/Runner/CoachChannel.swift`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(CoachModelChannel.name);
  const responses = EventChannel(CoachModelChannel.responsesName);
  const session = CoachModelSession(id: 's1');
  late List<MethodCall> calls;
  late List<Object?> listens;
  late List<Object?> cancels;
  late MethodChannelCoachModel model;

  TestDefaultBinaryMessenger messenger() =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void answer(Object? Function(MethodCall call) handler) {
    messenger().setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  }

  /// Fakes the reply stream: [onListen] gets the listen arguments and the
  /// sink to answer on.
  void stream(void Function(Object? args, MockStreamHandlerEventSink sink) on) {
    messenger().setMockStreamHandler(
      responses,
      MockStreamHandler.inline(
        onListen: (args, sink) {
          listens.add(args);
          on(args, sink);
        },
        onCancel: cancels.add,
      ),
    );
  }

  /// The `requestId` the Dart side tagged a listen with.
  Object? requestId(Object? args) =>
      (args! as Map<Object?, Object?>)['requestId'];

  /// The native side's events for the listen with [args]
  /// (`CoachModelChannel.responsesName`).
  Map<String, Object?> snapshot(Object? args, String text) => {
    'requestId': requestId(args),
    'snapshot': text,
  };
  Map<String, Object?> done(Object? args) => {
    'requestId': requestId(args),
    'done': true,
  };
  Map<String, Object?> error(
    Object? args,
    String code, {
    String? message,
    String? reason,
  }) => {
    'requestId': requestId(args),
    'error': code,
    'message': ?message,
    'reason': ?reason,
  };

  T okValue<T>(Result<T> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => fail('Expected Ok, got $failure'),
  };

  /// A snapshot event's reply text.
  String text(Result<CoachReplySnapshot> result) => okValue(result).text;

  Failure errFailure<T>(Result<T> result) => switch (result) {
    Ok(:final value) => fail('Expected Err, got Ok($value)'),
    Err(:final failure) => failure,
  };

  setUp(() {
    calls = [];
    listens = [];
    cancels = [];
    model = MethodChannelCoachModel();
  });

  tearDown(() {
    messenger()
      ..setMockMethodCallHandler(channel, null)
      ..setMockStreamHandler(responses, null);
  });

  group('checkAvailability', () {
    test('available passes the context size through', () async {
      answer((_) => {'status': 'available', 'contextSize': 4096});
      final info = okValue(await model.checkAvailability());
      expect(info, const CoachModelInfo(contextSize: 4096));
      expect(calls.single.method, 'availability');
      expect(calls.single.arguments, isNull);
    });

    test('available without a context size falls back to 4,096', () async {
      answer((_) => {'status': 'available'});
      expect(
        okValue(await model.checkAvailability()).contextSize,
        CoachModelChannel.defaultContextSize,
      );
      expect(CoachModelChannel.defaultContextSize, 4096);
    });

    final reasons = <String?, Type>{
      'deviceNotEligible': CoachDeviceNotEligibleFailure,
      'appleIntelligenceNotEnabled': CoachAppleIntelligenceNotEnabledFailure,
      'modelNotReady': CoachModelNotReadyFailure,
      'osTooOld': CoachOsTooOldFailure,
      'unknown': CoachModelUnavailableUnknownFailure,
      'somethingNew': CoachModelUnavailableUnknownFailure,
      null: CoachModelUnavailableUnknownFailure,
    };
    for (final MapEntry(key: reason, value: type) in reasons.entries) {
      test('unavailable "$reason" is a $type', () async {
        answer((_) => {'status': 'unavailable', 'reason': reason});
        final failure = errFailure(await model.checkAvailability());
        expect(failure, isA<CoachModelUnavailableFailure>());
        expect(failure.runtimeType, type);
      });
    }

    final malformed = <String, Object?>{
      'not a map': 'available',
      'an unknown status': {'status': 'maybe'},
      'a zero context size': {'status': 'available', 'contextSize': 0},
      'a string context size': {'status': 'available', 'contextSize': '4096'},
    };
    for (final MapEntry(key: name, value: reply) in malformed.entries) {
      test('$name is an UnknownFailure', () async {
        answer((_) => reply);
        expect(
          errFailure(await model.checkAvailability()),
          isA<UnknownFailure>(),
        );
      });
    }
  });

  group('startSession', () {
    test('sends the instructions and returns the session id', () async {
      answer((_) => 'abc');
      final started = okValue(
        await model.startSession(instructions: CoachInstructions.chat),
      );
      expect(started, const CoachModelSession(id: 'abc'));
      expect(calls.single.method, 'startSession');
      expect(calls.single.arguments, {'instructions': CoachInstructions.chat});
    });

    test('empty instructions are a ValidationFailure, without calling '
        'native', () async {
      answer((_) => 'abc');
      expect(
        errFailure(await model.startSession(instructions: '  ')),
        isA<ValidationFailure>(),
      );
      expect(calls, isEmpty);
    });

    test('the unavailable error maps its reason', () async {
      answer(
        (_) => throw PlatformException(
          code: CoachModelChannel.unavailableCode,
          message: 'Apple Intelligence is off',
          details: 'appleIntelligenceNotEnabled',
        ),
      );
      expect(
        errFailure(await model.startSession(instructions: 'x')),
        isA<CoachAppleIntelligenceNotEnabledFailure>(),
      );
    });

    test('any other platform error is a PlatformChannelFailure', () async {
      answer((_) => throw PlatformException(code: 'invalidArguments'));
      final failure = errFailure(await model.startSession(instructions: 'x'));
      expect(failure, isA<PlatformChannelFailure>());
      expect((failure as PlatformChannelFailure).code, 'invalidArguments');
    });

    test('a non-string id is an UnknownFailure', () async {
      answer((_) => 42);
      expect(
        errFailure(await model.startSession(instructions: 'x')),
        isA<UnknownFailure>(),
      );
    });
  });

  group('streamResponse', () {
    test('listens with the session, prompt and a request id, and passes '
        'snapshots through in order', () async {
      stream((args, sink) {
        sink
          ..success(snapshot(args, 'Hi'))
          ..success(snapshot(args, 'Hi there'))
          ..success(snapshot(args, 'Hi there. How did the week feel?'))
          ..success(done(args));
      });
      final events = await model.streamResponse(session, 'Hello').toList();
      expect(listens.single, {
        'sessionId': 's1',
        'prompt': 'Hello',
        'maximumResponseTokens': 512,
        'requestId': isA<int>(),
      });
      expect(events.map(text), [
        'Hi',
        'Hi there',
        'Hi there. How did the week feel?',
      ]);
    });

    test("passes the model's output token count through, where it sends "
        'one (iOS 27), and null where it does not (iOS 26)', () async {
      stream((args, sink) {
        sink
          ..success(snapshot(args, 'Hi'))
          ..success({...snapshot(args, 'Hi there'), 'outputTokens': 512})
          ..success({...snapshot(args, 'Hi there.'), 'outputTokens': 'x'})
          ..success(done(args));
      });
      final events = await model.streamResponse(session, 'Hello').toList();
      expect(events.map((e) => okValue(e).outputTokens), [null, 512, null]);
      expect(
        okValue(events[1]),
        const CoachReplySnapshot(text: 'Hi there', outputTokens: 512),
      );
    });

    test('every listen gets a new request id', () async {
      stream((args, sink) => sink.success(done(args)));
      await model.streamResponse(session, 'One').toList();
      await MethodChannelCoachModel().streamResponse(session, 'Two').toList();
      expect(listens.map(requestId).toSet(), hasLength(2));
    });

    test('a second reply closes the one it displaces, and still gets its '
        'own events', () async {
      // The native side has one event sink and the messenger one handler
      // per channel name, so two reply streams can't coexist. Two can be
      // *asked for* though: a session finishing its summary after its
      // screen closed, while the next chat starts. The displaced one used
      // to hang forever, never emitting and never closing.
      final sinks = <MockStreamHandlerEventSink>[];
      stream((_, sink) => sinks.add(sink));

      final first = <Result<CoachReplySnapshot>>[];
      var firstDone = false;
      model
          .streamResponse(session, 'Summarise')
          .listen(first.add, onDone: () => firstDone = true);
      await pumpEventQueue();
      expect(firstDone, isFalse);

      final second = <Result<CoachReplySnapshot>>[];
      model
          .streamResponse(const CoachModelSession(id: 's2'), 'Hello')
          .listen(second.add);
      await pumpEventQueue();

      // Displaced and closed, not left waiting.
      expect(firstDone, isTrue);
      expect(first, isEmpty);
      // No native cancel for the displaced reply: the new listen already
      // stops it natively, and a cancel arriving after that listen would
      // stop the new reply instead.
      expect(cancels, isEmpty);

      // The live stream still gets its own events through the handler it
      // now owns.
      sinks.last.success(snapshot(listens.last, 'Hi'));
      await pumpEventQueue();
      expect(second.map(text), ['Hi']);
    });

    test("late events from a displaced reply, its done included, don't "
        'reach or close the live stream', () async {
      // The native side may have sent events for the first reply before it
      // got the second listen and stopped the first. They arrive after the
      // second stream owns the handler.
      final sinks = <MockStreamHandlerEventSink>[];
      stream((_, sink) => sinks.add(sink));

      model.streamResponse(session, 'Summarise').listen((_) {});
      await pumpEventQueue();
      final firstArgs = listens.single;

      final second = <Result<CoachReplySnapshot>>[];
      var secondDone = false;
      model
          .streamResponse(session, 'Hello')
          .listen(second.add, onDone: () => secondDone = true);
      await pumpEventQueue();
      final secondArgs = listens.last;

      sinks.last
        ..success(snapshot(firstArgs, 'The week was'))
        ..success(error(firstArgs, 'busy', message: 'Late'))
        ..success(done(firstArgs));
      await pumpEventQueue();
      expect(second, isEmpty);
      expect(secondDone, isFalse);

      sinks.last
        ..success(snapshot(secondArgs, 'Hi'))
        ..success(done(secondArgs));
      await pumpEventQueue();
      expect(second.map(text), ['Hi']);
      expect(secondDone, isTrue);
    });

    final codes = <String, CoachInferenceFailureReason>{
      'contextExceeded': CoachInferenceFailureReason.contextExceeded,
      'guardrailViolation': CoachInferenceFailureReason.guardrailViolation,
      'refusal': CoachInferenceFailureReason.refusal,
      'unsupportedLanguage': CoachInferenceFailureReason.unsupportedLanguage,
      'rateLimited': CoachInferenceFailureReason.rateLimited,
      'busy': CoachInferenceFailureReason.busy,
      'timeout': CoachInferenceFailureReason.timeout,
      'inferenceFailed': CoachInferenceFailureReason.other,
      'sessionNotFound': CoachInferenceFailureReason.sessionEnded,
      CoachModelChannel.invalidArgumentsCode: CoachInferenceFailureReason.other,
      'somethingNew': CoachInferenceFailureReason.other,
    };
    for (final MapEntry(key: code, value: reason) in codes.entries) {
      test('error "$code" ends the stream with a $reason failure', () async {
        stream((args, sink) {
          sink
            ..success(snapshot(args, 'Partial'))
            ..success(error(args, code, message: 'Nope'))
            ..success(snapshot(args, 'ignored'));
        });
        final events = await model.streamResponse(session, 'Hi').toList();
        expect(events, hasLength(2));
        expect(text(events.first), 'Partial');
        final failure = errFailure(events.last);
        expect(failure, isA<CoachInferenceFailure>());
        expect((failure as CoachInferenceFailure).reason, reason);
        expect(failure.message, 'Nope');
      });
    }

    test('an unavailable error mid-stream maps its reason', () async {
      stream((args, sink) {
        sink.success(
          error(
            args,
            CoachModelChannel.unavailableCode,
            message: 'Assets missing',
            reason: 'modelNotReady',
          ),
        );
      });
      final events = await model.streamResponse(session, 'Hi').toList();
      expect(errFailure(events.single), isA<CoachModelNotReadyFailure>());
    });

    final malformed = <String, Object? Function(Object? args)>{
      'a bare string': (_) => 'Hi',
      'an untagged snapshot': (_) => {'snapshot': 'Hi'},
      'a non-string snapshot': (args) => {
        'requestId': requestId(args),
        'snapshot': 7,
      },
      'an unknown event': (args) => {'requestId': requestId(args)},
    };
    for (final MapEntry(key: name, value: event) in malformed.entries) {
      test('$name is an UnknownFailure and ends the stream', () async {
        stream((args, sink) {
          sink
            ..success(event(args))
            ..success(snapshot(args, 'ignored'));
        });
        final events = await model.streamResponse(session, 'Hi').toList();
        expect(errFailure(events.single), isA<UnknownFailure>());
      });
    }

    test('an empty prompt is a ValidationFailure, without listening', () async {
      stream((args, sink) => sink.success(done(args)));
      final events = await model.streamResponse(session, ' ').toList();
      expect(errFailure(events.single), isA<ValidationFailure>());
      expect(listens, isEmpty);
    });

    test('cancelling the subscription cancels the native stream, with the '
        "listen's request id", () async {
      stream((args, sink) => sink.success(snapshot(args, 'Thinking')));
      final first = Completer<Result<CoachReplySnapshot>>();
      final subscription = model
          .streamResponse(session, 'Hi')
          .listen(first.complete);
      expect(text(await first.future), 'Thinking');
      await subscription.cancel();
      expect(cancels, [listens.single]);
    });
  });

  group('cancelResponse and endSession', () {
    test('send the session id', () async {
      answer((_) => null);
      expect(okValue(await model.cancelResponse(session)), unit);
      expect(okValue(await model.endSession(session)), unit);
      expect(calls.map((c) => c.method), ['cancelResponse', 'endSession']);
      expect(calls.map((c) => c.arguments), [
        {'sessionId': 's1'},
        {'sessionId': 's1'},
      ]);
    });

    for (final method in ['cancelResponse', 'endSession']) {
      test('$method closes the reply stream through its done', () async {
        // The native side answers either call by sending the reply's
        // tagged done before stopping it (a cancelled reply sends nothing
        // itself), so the stream the coach UI is reading ends.
        late MockStreamHandlerEventSink sink;
        stream((args, s) => sink = s..success(snapshot(args, 'Thinking')));
        answer((call) {
          if (call.method == method) sink.success(done(listens.single));
          return null;
        });

        final events = <Result<CoachReplySnapshot>>[];
        var closed = false;
        model
            .streamResponse(session, 'Hi')
            .listen(events.add, onDone: () => closed = true);
        await pumpEventQueue();
        expect(closed, isFalse);

        final stopped = method == 'cancelResponse'
            ? await model.cancelResponse(session)
            : await model.endSession(session);
        expect(okValue(stopped), unit);
        await pumpEventQueue();
        expect(events.map(text), ['Thinking']);
        expect(closed, isTrue);
      });
    }
  });

  test('no native handler (macOS) is a PlatformChannelFailure', () async {
    // No mock handlers: the channels throw MissingPluginException.
    final failure = errFailure(await model.checkAvailability());
    expect(failure, isA<PlatformChannelFailure>());
    expect((failure as PlatformChannelFailure).code, 'missingPlugin');

    final events = await model.streamResponse(session, 'Hi').toList();
    final streamFailure = errFailure(events.single);
    expect(streamFailure, isA<PlatformChannelFailure>());
    expect((streamFailure as PlatformChannelFailure).code, 'missingPlugin');
  });
}
