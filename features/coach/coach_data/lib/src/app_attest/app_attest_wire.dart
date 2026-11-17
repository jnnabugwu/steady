import 'package:coach_data/src/app_attest/app_attest.dart';

/// The `steady/app_attest` platform channel's contract, shared by
/// `MethodChannelAppAttest` and the Swift handler in
/// `app/ios/Runner/AppAttestChannel.swift`. Change both sides together.
///
/// iOS only: nothing on macOS answers this channel, and the app never binds
/// App Attest there (CLAUDE.md §11).
///
/// The Swift side is a translation layer over `DCAppAttestService.shared`
/// with no logic of its own: bytes in as `FlutterStandardTypedData`
/// (`Uint8List` here), results out as standard base64 strings (with
/// padding), errors as `FlutterError`s whose code is one of [errorCodes]'
/// keys.
abstract final class AppAttestChannel {
  /// The method channel's name.
  static const name = 'steady/app_attest';

  /// No arguments. Returns `DCAppAttestService.shared.isSupported` (a
  /// bool). False in the Simulator.
  static const isSupportedMethod = 'isSupported';

  /// No arguments. Returns the new key's id (`generateKey`'s `keyId`,
  /// already standard base64).
  static const generateKeyMethod = 'generateKey';

  /// Arguments `{keyId: String, clientDataHash: Uint8List}`. Returns the
  /// attestation object (`attestKey`'s `Data`), standard base64.
  static const attestKeyMethod = 'attestKey';

  /// Arguments `{keyId: String, clientDataHash: Uint8List}`. Returns the
  /// assertion (`generateAssertion`'s `Data`), standard base64.
  static const generateAssertionMethod = 'generateAssertion';

  /// The length of every `clientDataHash`: a SHA-256 digest.
  static const clientDataHashLength = 32;

  /// The `FlutterError` codes, mapped from `DCError.Code`, and the reason
  /// for each. Any other code is [AppAttestFailureReason.unknown].
  ///
  /// - `unsupported`: `.featureUnsupported` (the Simulator, or hardware
  ///   without App Attest);
  /// - `invalidKey`: `.invalidKey` (the key is gone, for example after a
  ///   restore onto another device: generate a new one and attest again);
  /// - `serviceUnavailable`: `.serverUnavailable` (Apple's attestation
  ///   service: retry later);
  /// - `invalidInput`: `.invalidInput`, or arguments missing or of the wrong
  ///   type;
  /// - `unknown`: `.unknownSystemFailure`, a later `DCError` code, or an
  ///   error that isn't a `DCError`.
  static const Map<String, AppAttestFailureReason> errorCodes = {
    'unsupported': AppAttestFailureReason.unsupported,
    'invalidKey': AppAttestFailureReason.invalidKey,
    'serviceUnavailable': AppAttestFailureReason.serviceUnavailable,
    'invalidInput': AppAttestFailureReason.invalidInput,
    'unknown': AppAttestFailureReason.unknown,
  };
}
