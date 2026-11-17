import 'dart:convert';

import 'package:coach_data/src/app_attest/app_attest.dart';
import 'package:coach_data/src/app_attest/app_attest_wire.dart';
import 'package:failures/failures.dart';
import 'package:flutter/services.dart';

/// [AppAttest] backed by the `steady/app_attest` platform channel
/// ([AppAttestChannel]): `DCAppAttestService`, on the iPhone only.
///
/// The native side lives runner-adjacent, like the HealthKit channel
/// (CLAUDE.md §8): `app/ios/Runner/AppAttestChannel.swift`. macOS has no
/// handler and the app doesn't bind this there at all (§11).
///
/// **Hashing is the caller's job** (`HostedCoachModel`, #151), per the
/// proxy's contract (steady-backend `README.md`, "Encodings"):
/// - for [attestKey], `clientDataHash` is SHA-256 of the challenge's UTF-8
///   text (the base64url string as sent, not decoded);
/// - for [generateAssertion], it's SHA-256 of the challenge's UTF-8 bytes
///   followed directly by the exact bytes sent as the HTTP body.
///
/// This class only checks the hash is 32 bytes long.
///
/// Every failure is an [AppAttestFailure], returned, never thrown (§9):
/// - a `FlutterError` code from [AppAttestChannel.errorCodes] becomes its
///   reason, and any other code [AppAttestFailureReason.unknown];
/// - a missing native handler (`MissingPluginException`, as on macOS) is
///   [AppAttestFailureReason.unsupported];
/// - an empty key id or a hash that isn't 32 bytes is
///   [AppAttestFailureReason.invalidInput], without calling native;
/// - a reply that isn't a non-empty base64 string is
///   [AppAttestFailureReason.unknown].
class MethodChannelAppAttest implements AppAttest {
  /// Creates the client. [channel] is for tests; the default is the real
  /// `steady/app_attest` channel.
  MethodChannelAppAttest({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(AppAttestChannel.name);

  final MethodChannel _channel;

  /// False on any error too (no handler, a native failure, a reply that
  /// isn't a bool): a device that can't say whether it can attest can't
  /// attest.
  @override
  Future<bool> isSupported() async {
    try {
      final supported = await _channel.invokeMethod<Object?>(
        AppAttestChannel.isSupportedMethod,
      );
      return supported == true;
    } on Object {
      return false;
    }
  }

  @override
  ResultFuture<String> generateKey() => _call(
    'Could not create an App Attest key',
    () => _channel.invokeMethod<Object?>(AppAttestChannel.generateKeyMethod),
  );

  @override
  ResultFuture<String> attestKey(String keyId, Uint8List clientDataHash) =>
      _callWithKey(
        'Could not attest the App Attest key',
        AppAttestChannel.attestKeyMethod,
        keyId,
        clientDataHash,
      );

  @override
  ResultFuture<String> generateAssertion(
    String keyId,
    Uint8List clientDataHash,
  ) => _callWithKey(
    'Could not sign the coach request',
    AppAttestChannel.generateAssertionMethod,
    keyId,
    clientDataHash,
  );

  Future<Result<String>> _callWithKey(
    String what,
    String method,
    String keyId,
    Uint8List clientDataHash,
  ) async {
    if (keyId.isEmpty) {
      return Err(
        AppAttestFailure(
          AppAttestFailureReason.invalidInput,
          '$what: the key id is empty',
        ),
      );
    }
    if (clientDataHash.length != AppAttestChannel.clientDataHashLength) {
      return Err(
        AppAttestFailure(
          AppAttestFailureReason.invalidInput,
          '$what: clientDataHash must be '
          '${AppAttestChannel.clientDataHashLength} bytes, '
          'got ${clientDataHash.length}',
        ),
      );
    }
    return await _call(
      what,
      () => _channel.invokeMethod<Object?>(method, {
        'keyId': keyId,
        'clientDataHash': clientDataHash,
      }),
    );
  }

  /// Runs [invoke] and checks its reply is a non-empty base64 string,
  /// mapping every exception to an [AppAttestFailure] described by [what].
  Future<Result<String>> _call(
    String what,
    Future<Object?> Function() invoke,
  ) async {
    try {
      final reply = await invoke();
      if (reply is! String || reply.isEmpty) {
        return Err(
          AppAttestFailure(
            AppAttestFailureReason.unknown,
            '$what: expected a base64 string',
            cause: FormatException('Expected a base64 string', reply),
          ),
        );
      }
      try {
        base64.decode(reply);
      } on FormatException catch (e) {
        return Err(
          AppAttestFailure(
            AppAttestFailureReason.unknown,
            '$what: the reply is not base64',
            cause: e,
          ),
        );
      }
      return Ok(reply);
    } on PlatformException catch (e) {
      return Err(
        AppAttestFailure(
          AppAttestChannel.errorCodes[e.code] ?? AppAttestFailureReason.unknown,
          e.message ?? what,
          cause: e,
        ),
      );
    } on MissingPluginException catch (e) {
      return Err(
        AppAttestFailure(
          AppAttestFailureReason.unsupported,
          'App Attest is not available on this platform',
          cause: e,
        ),
      );
    } on Object catch (e) {
      // Anything else the channel throws: never let it escape the `Result`.
      return Err(
        AppAttestFailure(AppAttestFailureReason.unknown, what, cause: e),
      );
    }
  }
}
