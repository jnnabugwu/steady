import 'package:failures/failures.dart';

/// The on-device model can't run on this iPhone right now. One subtype per
/// reason, so the coach UI can `switch` on it and say plainly why (CLAUDE.md
/// §11). Mapped from Foundation Models' `SystemLanguageModel.availability`
/// at the `coach_data` boundary.
sealed class CoachModelUnavailableFailure extends Failure {
  /// Creates the failure with a plain-English [message].
  const CoachModelUnavailableFailure(super.message, {super.cause});
}

/// This iPhone doesn't support Apple Intelligence
/// (`UnavailableReason.deviceNotEligible`). Nothing the user can change.
final class CoachDeviceNotEligibleFailure extends CoachModelUnavailableFailure {
  /// Creates the failure; [message] defaults to plain-English copy.
  const CoachDeviceNotEligibleFailure({
    String message =
        "This iPhone doesn't support Apple Intelligence, "
        'which the coach needs.',
    super.cause,
  }) : super(message);
}

/// Apple Intelligence is supported but turned off
/// (`UnavailableReason.appleIntelligenceNotEnabled`). The user can turn it
/// on in Settings → Apple Intelligence & Siri.
final class CoachAppleIntelligenceNotEnabledFailure
    extends CoachModelUnavailableFailure {
  /// Creates the failure; [message] defaults to plain-English copy.
  const CoachAppleIntelligenceNotEnabledFailure({
    String message =
        'The coach needs Apple Intelligence. You can turn it '
        'on in Settings → Apple Intelligence & Siri.',
    super.cause,
  }) : super(message);
}

/// Apple Intelligence is on, but the model isn't ready yet, usually still
/// downloading (`UnavailableReason.modelNotReady`, or the model's assets
/// going missing mid-session). Worth trying again later.
final class CoachModelNotReadyFailure extends CoachModelUnavailableFailure {
  /// Creates the failure; [message] defaults to plain-English copy.
  const CoachModelNotReadyFailure({
    String message =
        "Apple Intelligence isn't ready yet. It may still be "
        'downloading; try again in a little while.',
    super.cause,
  }) : super(message);
}

/// The iPhone runs an iOS older than 26, which has no Foundation Models.
/// The app's iOS floor is 17, so this is a real case.
final class CoachOsTooOldFailure extends CoachModelUnavailableFailure {
  /// Creates the failure; [message] defaults to plain-English copy.
  const CoachOsTooOldFailure({
    String message = 'The coach needs iOS 26 or later.',
    super.cause,
  }) : super(message);
}

/// Unavailable for a reason this build doesn't know (a reason added in a
/// later iOS).
final class CoachModelUnavailableUnknownFailure
    extends CoachModelUnavailableFailure {
  /// Creates the failure; [message] defaults to plain-English copy.
  const CoachModelUnavailableUnknownFailure({
    String message = "The coach isn't available on this iPhone right now.",
    super.cause,
  }) : super(message);
}

/// Why a response failed, once the model was available.
enum CoachInferenceFailureReason {
  /// The session used up its context window (instructions, data, prompts
  /// and replies together). Start a new session with less in it.
  contextExceeded,

  /// Apple's built-in safety guardrails stopped the prompt or the reply.
  /// The coach UI should offer the help line (`CoachCopy.helpLine`), since
  /// this can be what a crisis message looks like from here.
  guardrailViolation,

  /// The model declined to answer.
  refusal,

  /// The device's language or region isn't supported by the model.
  unsupportedLanguage,

  /// The system is limiting requests (for example, the app is in the
  /// background). Try again shortly.
  rateLimited,

  /// The session was already answering a prompt.
  busy,

  /// The model took too long to answer.
  timeout,

  /// The session was ended, or never existed on the native side (for
  /// example, after the app was restarted).
  sessionEnded,

  /// Any other inference error.
  other,
}

/// A response failed after the model was available: a guardrail or refusal,
/// the context window running out, and so on ([reason]). Mapped from
/// Foundation Models' errors at the `coach_data` boundary.
final class CoachInferenceFailure extends Failure {
  /// Creates the failure for [reason].
  const CoachInferenceFailure(
    super.message, {
    required this.reason,
    super.cause,
  });

  /// What went wrong.
  final CoachInferenceFailureReason reason;

  @override
  List<Object?> get props => [message, reason];
}
