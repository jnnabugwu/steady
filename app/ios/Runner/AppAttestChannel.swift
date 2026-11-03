import DeviceCheck
import Flutter
import Foundation

/// The `steady/app_attest` platform channel (#150), iOS only: Apple App
/// Attest (`DCAppAttestService`), which the hosted coach uses to prove each
/// request to Steady's proxy comes from the genuine app on a real iPhone.
/// The Dart side is `MethodChannelAppAttest` in `features/coach/coach_data`
/// (contract: `AppAttestChannel` in `app_attest_wire.dart`); change both
/// together. There is no macOS twin on purpose: the coach runs on the iPhone
/// only (CLAUDE.md §11).
///
/// A translation layer with no logic of its own. The Dart side computes
/// every `clientDataHash`, checks its length, and owns the key's lifecycle
/// and the proxy flow. The private key never leaves the Secure Enclave; only
/// its id, attestations and assertions cross the channel.
///
/// Methods (bytes in as `FlutterStandardTypedData`, results out as standard
/// base64 strings):
/// - `isSupported` returns `DCAppAttestService.shared.isSupported`. False in
///   the Simulator.
/// - `generateKey` returns the new key's id (already base64).
/// - `attestKey({keyId, clientDataHash})` returns the attestation object.
/// - `generateAssertion({keyId, clientDataHash})` returns the assertion.
///
/// Errors are `FlutterError`s with the `DCError` code translated:
/// `unsupported` (`.featureUnsupported`), `invalidKey` (`.invalidKey`),
/// `serviceUnavailable` (`.serverUnavailable`), `invalidInput`
/// (`.invalidInput`, or arguments missing or of the wrong type) and
/// `unknown` (`.unknownSystemFailure`, a code added in a later iOS, or an
/// error that isn't a `DCError`).
///
/// The environment (Apple's development or production attestation) comes
/// from the `com.apple.developer.devicecheck.appattest-environment`
/// entitlement, set per build configuration (`STEADY_APP_ATTEST_ENVIRONMENT` in
/// `Flutter/Debug.xcconfig` and `Flutter/Release.xcconfig`).
enum SteadyAppAttestChannel {
  /// Registers the channel. Called once from `AppDelegate`, next to the
  /// other runner-adjacent channels.
  static func register(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "SteadyAppAttestChannel") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "steady/app_attest", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      handle(call, result: result)
    }
  }

  private static var service: DCAppAttestService { DCAppAttestService.shared }

  private static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported":
      result(service.isSupported)
    case "generateKey":
      service.generateKey { keyId, error in
        reply(result, keyId, error)
      }
    case "attestKey":
      guard let input = keyAndHash(call, result) else { return }
      service.attestKey(input.keyId, clientDataHash: input.hash) { attestation, error in
        reply(result, attestation?.base64EncodedString(), error)
      }
    case "generateAssertion":
      guard let input = keyAndHash(call, result) else { return }
      service.generateAssertion(input.keyId, clientDataHash: input.hash) { assertion, error in
        reply(result, assertion?.base64EncodedString(), error)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// `{keyId, clientDataHash}` from `call`, or `nil` after answering
  /// `invalidInput` if either is missing or of the wrong type.
  private static func keyAndHash(
    _ call: FlutterMethodCall, _ result: FlutterResult
  ) -> (keyId: String, hash: Data)? {
    guard let args = call.arguments as? [String: Any],
      let keyId = args["keyId"] as? String,
      let hash = args["clientDataHash"] as? FlutterStandardTypedData
    else {
      result(
        FlutterError(
          code: "invalidInput", message: "Expected {keyId, clientDataHash}", details: nil))
      return nil
    }
    return (keyId, hash.data)
  }

  /// Answers on the main thread: App Attest calls its completion handlers
  /// on a queue of its own.
  private static func reply(_ result: @escaping FlutterResult, _ value: String?, _ error: Error?) {
    DispatchQueue.main.async {
      if let error = error {
        result(
          FlutterError(code: wireCode(error), message: error.localizedDescription, details: nil))
      } else if let value = value {
        result(value)
      } else {
        result(FlutterError(code: "unknown", message: "App Attest returned nothing", details: nil))
      }
    }
  }

  private static func wireCode(_ error: Error) -> String {
    guard let error = error as? DCError else { return "unknown" }
    switch error.code {
    case .featureUnsupported: return "unsupported"
    case .invalidKey: return "invalidKey"
    case .serverUnavailable: return "serviceUnavailable"
    case .invalidInput: return "invalidInput"
    case .unknownSystemFailure: return "unknown"
    @unknown default: return "unknown"
    }
  }
}
