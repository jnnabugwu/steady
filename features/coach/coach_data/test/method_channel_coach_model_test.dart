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
  late int cancels;
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
        onCancel: (_) => cancels++,
      ),
    );
  }

  T okValue<T>(Result<T> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => fail('Expected Ok, got $failure'),
  };

  Failure errFailure<T>(Result<T> result) => switch (result) {
    Ok(:final value) => fail('Expected Err, got Ok($value)'),
    Err(:final failure) => failure,
  };

  setUp(() {
    calls = [];
    listens = [];
    cancels = 0;
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
    test('listens with the session and prompt, and passes snapshots '
        'through in order', () async {
      stream((_, sink) {
        sink
          ..success('Hi')
          ..success('Hi there')
          ..success('Hi there. How did the week feel?')
          ..endOfStream();
      });
      final events = await model.streamResponse(session, 'Hello').toList();
      expect(listens.single, {
        'sessionId': 's1',
        'prompt': 'Hello',
        'maximumResponseTokens': 512,
      });
      expect(events.map(okValue), [
        'Hi',
        'Hi there',
        'Hi there. How did the week feel?',
      ]);
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

      final first = <Result<String>>[];
      var firstDone = false;
      model
          .streamResponse(session, 'Summarise')
          .listen(first.add, onDone: () => firstDone = true);
      await pumpEventQueue();
      expect(firstDone, isFalse);

      final second = <Result<String>>[];
      model
          .streamResponse(const CoachModelSession(id: 's2'), 'Hello')
          .listen(second.add);
      await pumpEventQueue();

      // Displaced and closed, not left waiting.
      expect(firstDone, isTrue);
      expect(first, isEmpty);
      // The displaced stream is cancelled natively too, so the model stops
      // generating a reply nobody is listening to.
      expect(cancels, 1);

      // The live stream still gets its own events through the handler it
      // now owns.
      sinks.last.success('Hi');
      await pumpEventQueue();
      expect(second.map(okValue), ['Hi']);
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
      'somethingNew': CoachInferenceFailureReason.other,
    };
    for (final MapEntry(key: code, value: reason) in codes.entries) {
      test('error "$code" ends the stream with a $reason failure', () async {
        stream((_, sink) {
          sink
            ..success('Partial')
            ..error(code: code, message: 'Nope')
            ..endOfStream();
        });
        final events = await model.streamResponse(session, 'Hi').toList();
        expect(events, hasLength(2));
        expect(okValue(events.first), 'Partial');
        final failure = errFailure(events.last);
        expect(failure, isA<CoachInferenceFailure>());
        expect((failure as CoachInferenceFailure).reason, reason);
        expect(failure.message, 'Nope');
      });
    }

    test('an unavailable error mid-stream maps its reason', () async {
      stream((_, sink) {
        sink
          ..error(
            code: CoachModelChannel.unavailableCode,
            message: 'Assets missing',
            details: 'modelNotReady',
          )
          ..endOfStream();
      });
      final events = await model.streamResponse(session, 'Hi').toList();
      expect(errFailure(events.single), isA<CoachModelNotReadyFailure>());
    });

    test(
      'a non-string event is an UnknownFailure and ends the stream',
      () async {
        stream((_, sink) {
          sink
            ..success(7)
            ..success('ignored')
            ..endOfStream();
        });
        final events = await model.streamResponse(session, 'Hi').toList();
        expect(errFailure(events.single), isA<UnknownFailure>());
      },
    );

    test('an empty prompt is a ValidationFailure, without listening', () async {
      stream((_, sink) => sink.endOfStream());
      final events = await model.streamResponse(session, ' ').toList();
      expect(errFailure(events.single), isA<ValidationFailure>());
      expect(listens, isEmpty);
    });

    test('cancelling the subscription cancels the native stream', () async {
      stream((_, sink) => sink.success('Thinking'));
      final first = Completer<Result<String>>();
      final subscription = model
          .streamResponse(session, 'Hi')
          .listen(first.complete);
      expect(okValue(await first.future), 'Thinking');
      await subscription.cancel();
      expect(cancels, 1);
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
