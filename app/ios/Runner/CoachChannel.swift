import Flutter
import Foundation
import FoundationModels

/// The `steady/coach` platform channels (#79), iOS only: Apple Foundation
/// Models, the on-device model, for the coach. The Dart side is
/// `MethodChannelCoachModel` in `features/coach/coach_data` (contract:
/// `CoachModelChannel` in `coach_model_wire.dart`); change both together.
/// There is no macOS twin on purpose: the coach runs on the iPhone only
/// (CLAUDE.md §11).
///
/// The app's iOS floor is 17 and Foundation Models is iOS 26+, so every use
/// of it is behind `#available(iOS 26.0, *)`; below that the model is
/// `unavailable` with reason `osTooOld`. Only the on-device
/// `SystemLanguageModel` is used, never `PrivateCloudComputeLanguageModel`
/// (a server model): nothing leaves the iPhone. The on-device model needs no
/// entitlement.
///
/// Method channel `steady/coach`:
/// - `availability` returns `{status: "available", contextSize: Int}` or
///   `{status: "unavailable", reason}`, reason `deviceNotEligible`,
///   `appleIntelligenceNotEnabled`, `modelNotReady`, `osTooOld` or `unknown`.
///   `contextSize` is `SystemLanguageModel.contextSize`: 4,096 tokens before
///   iOS 27 (back-deployed), the model's own value from iOS 27 on.
/// - `startSession({instructions})` starts a `LanguageModelSession` with
///   those instructions and returns its id. `FlutterError` `unavailable`
///   (reason in `details`) if the model can't run.
/// - `cancelResponse({sessionId})` stops that session's reply in flight.
/// - `endSession({sessionId})` stops any reply and drops the session.
///
/// Event channel `steady/coach/responses`, listen arguments
/// `{sessionId, prompt, maximumResponseTokens}`: streams the reply, capped
/// at `maximumResponseTokens` (`GenerationOptions`). Each event is the **whole reply
/// so far** (`streamResponse(to:)` yields cumulative snapshots, and they're
/// forwarded as is), then end of stream. A failure is one `FlutterError`
/// event (code `contextExceeded`, `guardrailViolation`, `refusal`,
/// `unsupportedLanguage`, `rateLimited`, `busy`, `timeout`,
/// `inferenceFailed`, `unavailable` or `sessionNotFound`), then end of
/// stream. Errors always go through the sink, never as `onListen`'s return
/// value, which Dart would only log. One reply streams at a time: a new
/// listen cancels the one in flight. Cancelling stops the model (the Swift
/// task is cancelled) and ends the stream without an error; the session is
/// then rebuilt from its transcript (see `replaceAfterCancel`), since the
/// framework traps on the next request to a session cancelled mid-reply.
enum SteadyCoachChannel {
  /// Registers both channels. Called once from `AppDelegate`, next to the
  /// other runner-adjacent channels.
  static func register(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "SteadyCoachChannel") else {
      return
    }
    let messenger = registrar.messenger()
    let handler = CoachHandler()
    FlutterMethodChannel(name: "steady/coach", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        handler.handle(call, result: result)
      }
    FlutterEventChannel(name: "steady/coach/responses", binaryMessenger: messenger)
      .setStreamHandler(handler)
  }
}

/// Holds the live sessions. Flutter calls it on the main thread, and every
/// reply task runs on the main actor, so the state needs no lock.
private final class CoachHandler: NSObject, FlutterStreamHandler {
  /// Live sessions by id. Each value is a `LanguageModelSession`, stored as
  /// `AnyObject` so this class doesn't itself need iOS 26.
  private var sessions: [String: AnyObject] = [:]

  /// The reply streaming now, if any, and its session's id.
  private var responseTask: Task<Void, Never>?
  private var responseSessionID: String?

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "availability":
      result(Self.availability())
    case "startSession":
      startSession(call.arguments, result)
    case "cancelResponse":
      if let id = Self.sessionID(call.arguments), id == responseSessionID {
        cancelResponse()
      }
      result(nil)
    case "endSession":
      if let id = Self.sessionID(call.arguments) {
        if id == responseSessionID { cancelResponse() }
        sessions.removeValue(forKey: id)
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Availability

  private static func availability() -> [String: Any] {
    guard #available(iOS 26.0, *) else {
      return ["status": "unavailable", "reason": "osTooOld"]
    }
    let model = SystemLanguageModel.default
    switch model.availability {
    case .available:
      return ["status": "available", "contextSize": model.contextSize]
    case .unavailable(let reason):
      return ["status": "unavailable", "reason": wireReason(reason)]
    }
  }

  @available(iOS 26.0, *)
  private static func wireReason(_ reason: SystemLanguageModel.Availability.UnavailableReason)
    -> String
  {
    switch reason {
    case .deviceNotEligible: return "deviceNotEligible"
    case .appleIntelligenceNotEnabled: return "appleIntelligenceNotEnabled"
    case .modelNotReady: return "modelNotReady"
    @unknown default: return "unknown"
    }
  }

  private static func unavailableError(_ reason: String, _ message: String) -> FlutterError {
    FlutterError(code: "unavailable", message: message, details: reason)
  }

  // MARK: - Sessions

  private static func sessionID(_ arguments: Any?) -> String? {
    (arguments as? [String: Any])?["sessionId"] as? String
  }

  private func startSession(_ arguments: Any?, _ result: @escaping FlutterResult) {
    guard
      let instructions = (arguments as? [String: Any])?["instructions"] as? String,
      !instructions.isEmpty
    else {
      result(
        FlutterError(code: "invalidArguments", message: "Expected {instructions}", details: nil))
      return
    }
    let status = Self.availability()
    guard status["status"] as? String == "available", #available(iOS 26.0, *) else {
      let reason = status["reason"] as? String ?? "unknown"
      result(Self.unavailableError(reason, "The on-device model is unavailable: \(reason)"))
      return
    }
    let session = LanguageModelSession(instructions: instructions)
    let id = UUID().uuidString
    sessions[id] = session
    result(id)
  }

  private func cancelResponse() {
    responseTask?.cancel()
    responseTask = nil
    responseSessionID = nil
  }

  // MARK: - FlutterStreamHandler (the reply stream)

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    cancelResponse()
    let args = arguments as? [String: Any]
    let sessionID = args?["sessionId"] as? String
    let prompt = args?["prompt"] as? String
    let maximumResponseTokens = args?["maximumResponseTokens"] as? Int
    let session = sessionID.flatMap { sessions[$0] }
    responseSessionID = sessionID
    responseTask = Task { @MainActor [weak self] in
      let cancelled = await Self.respond(
        session: session, prompt: prompt, maximumResponseTokens: maximumResponseTokens,
        events: events)
      if cancelled, let id = sessionID, let session = session {
        self?.replaceAfterCancel(id: id, session: session)
      }
    }
    return nil
  }

  /// Swaps a session whose reply was cancelled for a fresh one built from
  /// its transcript (which keeps the partial reply). Found by running the
  /// real model (macOS 26.6 host, the same framework): the next request on a
  /// session whose stream was cancelled mid-reply traps inside
  /// FoundationModels (`EXC_BREAKPOINT`), crashing the app, while a session
  /// rebuilt with `LanguageModelSession(transcript:)` answers normally.
  private func replaceAfterCancel(id: String, session: AnyObject) {
    guard #available(iOS 26.0, *), let old = session as? LanguageModelSession,
      sessions[id] === session
    else { return }
    sessions[id] = LanguageModelSession(transcript: old.transcript)
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    cancelResponse()
    return nil
  }

  /// Streams the reply to `prompt` in `session` into `events`, then ends
  /// the stream. A failure is one error event before the end. Each reply is
  /// capped at `maximumResponseTokens` (sent by the Dart side), so a reply
  /// that loops can't use up the session's context. Returns whether the
  /// reply was cancelled partway.
  @MainActor
  private static func respond(
    session: AnyObject?, prompt: String?, maximumResponseTokens: Int?,
    events: @escaping FlutterEventSink
  ) async -> Bool {
    defer { events(FlutterEndOfEventStream) }
    guard let prompt = prompt, !prompt.isEmpty else {
      events(
        FlutterError(code: "invalidArguments", message: "Expected {sessionId, prompt}", details: nil)
      )
      return false
    }
    guard #available(iOS 26.0, *) else {
      events(unavailableError("osTooOld", "The coach needs iOS 26 or later"))
      return false
    }
    guard let session = session as? LanguageModelSession else {
      events(
        FlutterError(
          code: "sessionNotFound", message: "That coach session has ended", details: nil))
      return false
    }
    let options = GenerationOptions(maximumResponseTokens: maximumResponseTokens)
    do {
      for try await snapshot in session.streamResponse(to: prompt, options: options) {
        if Task.isCancelled { return true }
        // The whole reply so far, not a delta (see the type's doc).
        events(snapshot.content)
      }
      return Task.isCancelled
    } catch {
      // A cancelled reply just ends; the Dart side asked for it.
      if Task.isCancelled || error is CancellationError { return true }
      events(flutterError(for: error))
      return false
    }
  }

  // MARK: - Errors

  /// Maps a Foundation Models error to the wire codes. iOS 27 throws
  /// `LanguageModelError`, `LanguageModelSession.Error` and
  /// `SystemLanguageModel.Error`; iOS 26 throws
  /// `LanguageModelSession.GenerationError` (deprecated in 27). Both are
  /// handled, since the app runs on either.
  @available(iOS 26.0, *)
  private static func flutterError(for error: Error) -> FlutterError {
    let message = error.localizedDescription
    func coded(_ code: String) -> FlutterError {
      FlutterError(code: code, message: message, details: nil)
    }
    if #available(iOS 27.0, *) {
      if let error = error as? LanguageModelError {
        switch error {
        case .contextSizeExceeded: return coded("contextExceeded")
        case .rateLimited: return coded("rateLimited")
        case .guardrailViolation: return coded("guardrailViolation")
        case .refusal: return coded("refusal")
        case .unsupportedLanguageOrLocale: return coded("unsupportedLanguage")
        case .timeout: return coded("timeout")
        default: return coded("inferenceFailed")
        }
      }
      if let error = error as? LanguageModelSession.Error {
        switch error {
        case .concurrentRequests: return coded("busy")
        default: return coded("inferenceFailed")
        }
      }
      if error is SystemLanguageModel.Error {
        // Its one case is `assetsUnavailable`: the model went missing.
        return unavailableError("modelNotReady", message)
      }
    }
    if let error = error as? LanguageModelSession.GenerationError {
      switch error {
      case .exceededContextWindowSize: return coded("contextExceeded")
      case .assetsUnavailable: return unavailableError("modelNotReady", message)
      case .guardrailViolation: return coded("guardrailViolation")
      case .unsupportedLanguageOrLocale: return coded("unsupportedLanguage")
      case .rateLimited: return coded("rateLimited")
      case .concurrentRequests: return coded("busy")
      case .refusal: return coded("refusal")
      default: return coded("inferenceFailed")
      }
    }
    return coded("inferenceFailed")
  }
}
