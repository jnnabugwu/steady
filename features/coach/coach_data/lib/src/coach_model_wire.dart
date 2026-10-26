import 'package:coach_domain/coach_domain.dart';

/// The `steady/coach` platform channels' contract, shared by
/// `MethodChannelCoachModel` and the Swift handler in
/// `app/ios/Runner/CoachChannel.swift`. Change both sides together.
///
/// iOS only: nothing on macOS answers these channels, and the app never
/// binds the coach model there (CLAUDE.md §11).
///
/// Verified against the iOS 27.1 SDK's `FoundationModels.swiftinterface`
/// (Xcode 27.1):
/// - `SystemLanguageModel.default.availability` is `.available` or
///   `.unavailable(reason)`, reason `deviceNotEligible`,
///   `appleIntelligenceNotEnabled` or `modelNotReady` (a non-frozen enum,
///   so a later iOS can add one: [unknownReason]).
/// - `LanguageModelSession.streamResponse(to:)` yields **cumulative
///   snapshots** (`Snapshot.content`, the whole reply so far), not deltas.
///   The native side forwards each snapshot as is.
/// - No entitlement is needed for the on-device model. (Only the iOS 27
///   `PrivateCloudComputeLanguageModel`, a server model, needs a managed
///   entitlement; Steady never uses it.)
abstract final class CoachModelChannel {
  /// The method channel's name.
  static const name = 'steady/coach';

  /// The event channel the replies stream on. Listen arguments are
  /// `{requestId: int, sessionId: String, prompt: String,
  /// maximumResponseTokens: int}` ([maximumResponseTokens]); `requestId`
  /// is new for every listen, and `cancel` sends the same arguments back.
  ///
  /// Every event is a map tagged with that `requestId`, so an event from an
  /// earlier listen can be told apart and dropped:
  /// - `{requestId, snapshot: String, outputTokens: int?}`: the whole reply
  ///   so far, and how many tokens the model has generated for it, where
  ///   Foundation Models reports that (`Snapshot.usage`, iOS 27 and later;
  ///   absent on iOS 26). It's the only sign that a reply reached
  ///   [maximumResponseTokens]: Foundation Models gives no stop reason
  ///   (`CoachKeepGoing` in `coach_domain`);
  /// - `{requestId, done: true}`: the reply finished;
  /// - `{requestId, error: String, message: String?, reason: String?}`:
  ///   the reply failed, `error` one of [inferenceCodes]' keys,
  ///   [unavailableCode] (with `reason`, one of [unavailableReasons]' keys),
  ///   [sessionNotFoundCode] or [invalidArgumentsCode].
  ///
  /// `done` or an error is the last event; the native side sends no
  /// end-of-stream message, which couldn't carry a `requestId`. Cancelling
  /// the subscription stops the model, and a cancelled reply sends nothing
  /// more. Only one stream is live at a time: a new listen cancels the old
  /// one, and the native side waits for it to stop before starting the new
  /// reply.
  static const responsesName = 'steady/coach/responses';

  /// No arguments. Returns `{status: 'available', contextSize: int}` or
  /// `{status: 'unavailable', reason: String}`, reason one of
  /// [unavailableReasons]' keys.
  static const availabilityMethod = 'availability';

  /// Arguments `{instructions: String}`. Returns the new session's id
  /// (a String). Fails with [unavailableCode] (the reason in `details`)
  /// when the model can't run.
  static const startSessionMethod = 'startSession';

  /// Arguments `{sessionId: String}`. Stops the reply in flight in that
  /// session, if any; its event stream gets `done` and ends. Returns
  /// `null`.
  static const cancelResponseMethod = 'cancelResponse';

  /// Arguments `{sessionId: String}`. Stops any reply in flight in that
  /// session (its event stream gets `done` and ends) and drops the
  /// session. Returns `null`.
  static const endSessionMethod = 'endSession';

  /// The `FlutterError` code for "the model can't run"; `details` is the
  /// reason, one of [unavailableReasons]' keys.
  static const unavailableCode = 'unavailable';

  /// The error code for a listen without a `requestId` or a prompt, which
  /// `MethodChannelCoachModel` never sends (it checks the prompt first).
  /// Like any code not in [inferenceCodes], it maps to
  /// `CoachInferenceFailureReason.other`.
  static const invalidArgumentsCode = 'invalidArguments';

  /// The `FlutterError` code for a session id the native side doesn't have
  /// (ended, or lost when the app restarted).
  static const sessionNotFoundCode = 'sessionNotFound';

  /// The reason string the native side sends for an unavailable reason it
  /// doesn't recognise (one added in a later iOS).
  static const unknownReason = 'unknown';

  /// The model's context window when the native side doesn't report one.
  ///
  /// **The context limit (#79):** 4,096 tokens on iOS 26, for everything in
  /// a session together: instructions, the week's data, every prompt and
  /// every reply. Source: `SystemLanguageModel.contextSize` in the SDK,
  /// back-deployed to iOS 26.0, which returns 4,096 before iOS 27 and the
  /// model's own value from iOS 27 on; the SDK's docs for the context error
  /// give the same 4,096 ("about three to four characters per token" in
  /// English). The native side reports the real value at runtime
  /// (`CoachModelInfo.contextSize`); the context builder (#80) has to stay
  /// under that, and under this floor if it plans ahead.
  static const defaultContextSize = 4096;

  /// The most tokens one reply may use, sent with every listen as
  /// `maximumResponseTokens` (Foundation Models' `GenerationOptions`).
  ///
  /// The coach's replies are a few sentences, far under this. The cap is a
  /// guard: running the real model (macOS 26.6 host, the same framework),
  /// one reply looped on a repeated list for over three minutes. Uncapped,
  /// that would eat the whole 4,096-token context and end the session.
  /// Defined in `coach_domain` ([coachMaxReplyTokens]), whose context
  /// budget reserves exactly this much room for every reply.
  static const int maximumResponseTokens = coachMaxReplyTokens;

  /// The unavailable reasons on the wire, and the failure for each.
  static const Map<String, CoachModelUnavailableFailure> unavailableReasons = {
    'deviceNotEligible': CoachDeviceNotEligibleFailure(),
    'appleIntelligenceNotEnabled': CoachAppleIntelligenceNotEnabledFailure(),
    'modelNotReady': CoachModelNotReadyFailure(),
    'osTooOld': CoachOsTooOldFailure(),
    unknownReason: CoachModelUnavailableUnknownFailure(),
  };

  /// The inference error codes on the wire, mapped from Foundation Models'
  /// `LanguageModelError` (iOS 27), `LanguageModelSession.Error` (iOS 27)
  /// and `LanguageModelSession.GenerationError` (iOS 26). Any other code
  /// is [CoachInferenceFailureReason.other].
  static const Map<String, CoachInferenceFailureReason> inferenceCodes = {
    'contextExceeded': CoachInferenceFailureReason.contextExceeded,
    'guardrailViolation': CoachInferenceFailureReason.guardrailViolation,
    'refusal': CoachInferenceFailureReason.refusal,
    'unsupportedLanguage': CoachInferenceFailureReason.unsupportedLanguage,
    'rateLimited': CoachInferenceFailureReason.rateLimited,
    'busy': CoachInferenceFailureReason.busy,
    'timeout': CoachInferenceFailureReason.timeout,
    'inferenceFailed': CoachInferenceFailureReason.other,
  };
}

/// The failure for an unavailable [reason] from the wire. Anything
/// unknown, including `null`, is [CoachModelUnavailableUnknownFailure].
CoachModelUnavailableFailure coachUnavailableFailureFromWire(Object? reason) =>
    CoachModelChannel.unavailableReasons[reason] ??
    const CoachModelUnavailableUnknownFailure();

/// Decodes the `availability` reply: `Ok`'s info, or the unavailable
/// failure to return. Throws [FormatException] for any other shape.
({CoachModelInfo? info, CoachModelUnavailableFailure? failure})
coachAvailabilityFromWire(Object? raw) {
  if (raw is! Map<Object?, Object?>) {
    throw FormatException('Expected an availability map', raw);
  }
  switch (raw['status']) {
    case 'available':
      final size = raw['contextSize'];
      if (size != null && (size is! int || size <= 0)) {
        throw FormatException('Expected a positive contextSize', size);
      }
      return (
        info: CoachModelInfo(
          contextSize: size as int? ?? CoachModelChannel.defaultContextSize,
        ),
        failure: null,
      );
    case 'unavailable':
      return (
        info: null,
        failure: coachUnavailableFailureFromWire(raw['reason']),
      );
    default:
      throw FormatException('Unknown availability status', raw['status']);
  }
}
