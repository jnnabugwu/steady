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
/// - `cancelResponse({sessionId})` stops that session's reply in flight,
///   which ends with `done` on the reply stream.
/// - `endSession({sessionId})` stops any reply (ending it with `done`) and
///   drops the session.
///
/// Event channel `steady/coach/responses`, listen arguments
/// `{requestId, sessionId, prompt, maximumResponseTokens}`: streams the
/// reply, capped at `maximumResponseTokens` (`GenerationOptions`). Every
/// event is a map tagged with the listen's `requestId` (an Int the Dart
/// side picks per listen), so Dart can drop events from a reply it has
/// already moved past:
/// - `{requestId, snapshot}`: the **whole reply so far**
///   (`streamResponse(to:)` yields cumulative snapshots, and they're
///   forwarded as is);
/// - `{requestId, done: true}`: the reply finished;
/// - `{requestId, error, message, reason}`: the reply failed. `error` is
///   `contextExceeded`, `guardrailViolation`, `refusal`,
///   `unsupportedLanguage`, `rateLimited`, `busy`, `timeout`,
///   `inferenceFailed`, `unavailable` (with `reason`), `sessionNotFound` or
///   `invalidArguments`.
/// `done` or an error is the last event; no `FlutterEndOfEventStream` is
/// sent, since it can't carry a `requestId`. Errors always go through the
/// sink, never as `onListen`'s return value, which Dart would only log.
///
/// One reply streams at a time: a new listen cancels the one in flight.
/// A cancelled reply sends nothing more, except that `cancelResponse` and
/// `endSession` first send its `done`, since Dart is still listening. The next reply waits for the
/// cancelled one to stop before it touches its session, and a session
/// cancelled mid-reply is rebuilt from its transcript in that time (see
/// `replaceAfterCancel`), since the framework traps on the next request to
/// such a session.
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

  /// The latest reply's task, kept after it's cancelled or done: the next
  /// reply awaits it before looking its session up, so cancelling and
  /// rebuilding a session (`replaceAfterCancel`) always finishes before the
  /// session is asked again.
  private var responseTask: Task<Void, Never>?
  /// The session, request id and sink of the reply in flight, if any.
  private var responseSessionID: String?
  private var responseRequestID: Int?
  private var responseReply: ReplySink?

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "availability":
      result(Self.availability())
    case "startSession":
      startSession(call.arguments, result)
    case "cancelResponse":
      if let id = Self.sessionID(call.arguments), id == responseSessionID {
        finishResponse()
      }
      result(nil)
    case "endSession":
      if let id = Self.sessionID(call.arguments) {
        if id == responseSessionID { finishResponse() }
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

  /// Cancels the reply in flight, if any, without telling the Dart side:
  /// for a cancel that came from Dart's stream itself (`onCancel`, or a new
  /// listen displacing the old one), which is no longer listening. Its task
  /// stays in `responseTask` for the next reply to wait on.
  private func cancelResponse() {
    responseTask?.cancel()
    responseSessionID = nil
    responseRequestID = nil
    responseReply = nil
  }

  /// Ends the reply in flight with `done`, then cancels it: for
  /// `cancelResponse` and `endSession`, where the Dart stream is still
  /// listening and has to close. Sent from here because a cancelled reply
  /// sends nothing itself.
  private func finishResponse() {
    responseReply?.done()
    cancelResponse()
  }

  // MARK: - FlutterStreamHandler (the reply stream)

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    let args = arguments as? [String: Any]
    let requestID = args?["requestId"] as? Int
    let sessionID = args?["sessionId"] as? String
    let prompt = args?["prompt"] as? String
    let maximumResponseTokens = args?["maximumResponseTokens"] as? Int
    let previous = responseTask
    cancelResponse()
    let reply = ReplySink(requestID: requestID, events: events)
    responseSessionID = sessionID
    responseRequestID = requestID
    responseReply = reply
    responseTask = Task { @MainActor [weak self] in
      // Serialised: the previous reply has stopped, and its session has
      // been rebuilt if it was cancelled mid-reply, before this one looks
      // its session up. Looking it up any earlier could get the cancelled
      // session, which traps on its next request.
      await previous?.value
      if Task.isCancelled { return }
      let session = sessionID.flatMap { self?.sessions[$0] }
      let cancelled = await Self.respond(
        session: session, prompt: prompt, maximumResponseTokens: maximumResponseTokens,
        reply: reply)
      if cancelled, let id = sessionID, let session = session {
        self?.replaceAfterCancel(id: id, session: session)
      }
      // Finished on its own: nothing left for `finishResponse` to end.
      if !Task.isCancelled, self?.responseRequestID == requestID {
        self?.responseReply = nil
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

  /// Dart sends the listen's arguments back with `cancel`. A cancel for an
  /// older request than the one in flight is ignored, so it can't stop the
  /// newer reply. (`FlutterEventChannel` itself calls this with `nil`
  /// before a new listen, which cancels whatever is in flight.)
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    let requestID = (arguments as? [String: Any])?["requestId"] as? Int
    if requestID == nil || requestID == responseRequestID {
      cancelResponse()
    }
    return nil
  }

  /// Streams the reply to `prompt` in `session` into `reply`, then sends
  /// `done`, or one error instead. Each reply is capped at
  /// `maximumResponseTokens` (sent by the Dart side), so a reply that loops
  /// can't use up the session's context. Returns whether the reply was
  /// cancelled partway; a cancelled reply sends nothing more.
  @MainActor
  private static func respond(
    session: AnyObject?, prompt: String?, maximumResponseTokens: Int?, reply: ReplySink
  ) async -> Bool {
    guard reply.requestID != nil, let prompt = prompt, !prompt.isEmpty else {
      reply.fail(
        FlutterError(
          code: "invalidArguments", message: "Expected {requestId, sessionId, prompt}",
          details: nil))
      return false
    }
    guard #available(iOS 26.0, *) else {
      reply.fail(unavailableError("osTooOld", "The coach needs iOS 26 or later"))
      return false
    }
    guard let session = session as? LanguageModelSession else {
      reply.fail(
        FlutterError(
          code: "sessionNotFound", message: "That coach session has ended", details: nil))
      return false
    }
    let options = GenerationOptions(maximumResponseTokens: maximumResponseTokens)
    do {
      for try await snapshot in session.streamResponse(to: prompt, options: options) {
        if Task.isCancelled { return true }
        // The whole reply so far, not a delta (see the type's doc).
        reply.snapshot(snapshot.content)
      }
      // A cancelled stream ends without throwing.
      if Task.isCancelled { return true }
      reply.done()
      return false
    } catch {
      // A cancelled reply just ends; the Dart side asked for it.
      if Task.isCancelled || error is CancellationError { return true }
      reply.fail(flutterError(for: error))
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

/// The event sink for one reply, tagging every event with its listen's
/// `requestId` (see `SteadyCoachChannel`). Called only from inside that
/// reply's task, and sends nothing once the task is cancelled, so a reply
/// that has been displaced or stopped can't reach the stream after it.
private struct ReplySink {
  let requestID: Int?
  let events: FlutterEventSink

  func snapshot(_ text: String) {
    send(["snapshot": text])
  }

  func done() {
    send(["done": true])
  }

  func fail(_ error: FlutterError) {
    var event: [String: Any] = ["error": error.code]
    if let message = error.message { event["message"] = message }
    if let reason = error.details as? String { event["reason"] = reason }
    send(event)
  }

  private func send(_ event: [String: Any]) {
    if Task.isCancelled { return }
    var tagged = event
    tagged["requestId"] = requestID ?? NSNull()
    events(tagged)
  }
}
