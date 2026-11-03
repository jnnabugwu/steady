import 'dart:convert';

import 'package:coach_data/coach_data.dart';
import 'package:failures/failures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The `steady/app_attest` contract (`AppAttestChannel`), against a fake
/// native handler. The Swift side is `app/ios/Runner/AppAttestChannel.swift`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(AppAttestChannel.name);
  late List<MethodCall> calls;
  late MethodChannelAppAttest attest;

  final hash = Uint8List.fromList(List.generate(32, (i) => i));
  final attestation = base64.encode(utf8.encode('attestation object'));
  final assertion = base64.encode(utf8.encode('assertion object'));
  const keyId = 'q5TAc6Tx0ZiPTyJIa0L5yB2R5iBo1KLbE4HSkj0dJvM=';

  TestDefaultBinaryMessenger messenger() =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void answer(Object? Function(MethodCall call) handler) {
    messenger().setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  }

  String okValue(Result<String> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => fail('Expected Ok, got $failure'),
  };

  AppAttestFailure failureOf(Result<String> result) => switch (result) {
    Ok(:final value) => fail('Expected Err, got Ok($value)'),
    Err(:final failure) => failure as AppAttestFailure,
  };

  /// Every method that returns a `Result`, called with valid arguments.
  final methods = <String, Future<Result<String>> Function()>{
    AppAttestChannel.generateKeyMethod: () => attest.generateKey(),
    AppAttestChannel.attestKeyMethod: () => attest.attestKey(keyId, hash),
    AppAttestChannel.generateAssertionMethod: () =>
        attest.generateAssertion(keyId, hash),
  };

  setUp(() {
    calls = [];
    attest = MethodChannelAppAttest();
  });

  tearDown(() => messenger().setMockMethodCallHandler(channel, null));

  group('isSupported', () {
    test('returns the native bool', () async {
      answer((_) => true);
      expect(await attest.isSupported(), isTrue);
      answer((_) => false);
      expect(await attest.isSupported(), isFalse);
      expect(calls.map((c) => c.method), [
        AppAttestChannel.isSupportedMethod,
        AppAttestChannel.isSupportedMethod,
      ]);
      expect(calls.first.arguments, isNull);
    });

    test('is false when the native side fails', () async {
      answer((_) => throw PlatformException(code: 'unknown'));
      expect(await attest.isSupported(), isFalse);
    });

    test('is false for a reply that is not a bool', () async {
      answer((_) => 'yes');
      expect(await attest.isSupported(), isFalse);
    });

    test('is false with no native handler (macOS)', () async {
      expect(await attest.isSupported(), isFalse);
    });
  });

  group('generateKey', () {
    test('sends no arguments and returns the key id', () async {
      answer((_) => keyId);
      expect(okValue(await attest.generateKey()), keyId);
      expect(calls.single.method, AppAttestChannel.generateKeyMethod);
      expect(calls.single.arguments, isNull);
    });
  });

  group('attestKey', () {
    test('passes the key id and the 32-byte hash through', () async {
      answer((_) => attestation);
      expect(okValue(await attest.attestKey(keyId, hash)), attestation);
      final call = calls.single;
      expect(call.method, AppAttestChannel.attestKeyMethod);
      final args = call.arguments as Map<Object?, Object?>;
      expect(args.keys, unorderedEquals(['keyId', 'clientDataHash']));
      expect(args['keyId'], keyId);
      expect(args['clientDataHash'], isA<Uint8List>());
      expect(args['clientDataHash'], hash);
    });
  });

  group('generateAssertion', () {
    test('passes the key id and the 32-byte hash through', () async {
      answer((_) => assertion);
      expect(okValue(await attest.generateAssertion(keyId, hash)), assertion);
      final call = calls.single;
      expect(call.method, AppAttestChannel.generateAssertionMethod);
      final args = call.arguments as Map<Object?, Object?>;
      expect(args.keys, unorderedEquals(['keyId', 'clientDataHash']));
      expect(args['keyId'], keyId);
      expect(args['clientDataHash'], isA<Uint8List>());
      expect(args['clientDataHash'], hash);
    });
  });

  group('invalid arguments never reach native', () {
    final cases = <String, Future<Result<String>> Function()>{
      'attestKey, empty key id': () => attest.attestKey('', hash),
      'attestKey, 31-byte hash': () => attest.attestKey(keyId, Uint8List(31)),
      'attestKey, 33-byte hash': () => attest.attestKey(keyId, Uint8List(33)),
      'generateAssertion, empty key id': () =>
          attest.generateAssertion('', hash),
      'generateAssertion, empty hash': () =>
          attest.generateAssertion(keyId, Uint8List(0)),
    };
    for (final MapEntry(key: name, value: call) in cases.entries) {
      test(name, () async {
        answer((_) => attestation);
        expect(
          failureOf(await call()).reason,
          AppAttestFailureReason.invalidInput,
        );
        expect(calls, isEmpty);
      });
    }
  });

  for (final MapEntry(key: method, value: call) in methods.entries) {
    group('$method errors', () {
      for (final MapEntry(key: code, value: reason)
          in AppAttestChannel.errorCodes.entries) {
        test('wire code $code is $reason', () async {
          answer((_) => throw PlatformException(code: code, message: 'nope'));
          final failure = failureOf(await call());
          expect(failure.reason, reason);
          expect(failure.message, 'nope');
          expect(failure.cause, isA<PlatformException>());
        });
      }

      test('an unknown wire code is unknown', () async {
        answer((_) => throw PlatformException(code: 'somethingNew'));
        expect(failureOf(await call()).reason, AppAttestFailureReason.unknown);
      });

      test('no native handler (macOS) is unsupported', () async {
        final failure = failureOf(await call());
        expect(failure.reason, AppAttestFailureReason.unsupported);
        expect(failure.cause, isA<MissingPluginException>());
      });

      test('a reply that is not a string is unknown', () async {
        answer((_) => 42);
        expect(failureOf(await call()).reason, AppAttestFailureReason.unknown);
      });

      test('an empty reply is unknown', () async {
        answer((_) => '');
        expect(failureOf(await call()).reason, AppAttestFailureReason.unknown);
      });

      test('a reply that is not base64 is unknown', () async {
        answer((_) => 'not base64!');
        expect(failureOf(await call()).reason, AppAttestFailureReason.unknown);
      });
    });
  }

  test('every DCError wire code has its own reason', () {
    expect(AppAttestChannel.errorCodes, {
      'unsupported': AppAttestFailureReason.unsupported,
      'invalidKey': AppAttestFailureReason.invalidKey,
      'serviceUnavailable': AppAttestFailureReason.serviceUnavailable,
      'invalidInput': AppAttestFailureReason.invalidInput,
      'unknown': AppAttestFailureReason.unknown,
    });
    expect(
      AppAttestChannel.errorCodes.values.toSet(),
      AppAttestFailureReason.values.toSet(),
    );
  });
}
