import 'package:failures/failures.dart';

/// Why the coach couldn't reply, or can't run at all: every failure a
/// `CoachModel` returns. One final class per thing the coach screens have
/// to say plainly, so they can `switch` on it (CLAUDE.md §11). Mapped from
/// the proxy's error codes and from transport and App Attest errors at the
/// `coach_data` boundary (CLAUDE.md §9).
sealed class CoachModelFailure extends Failure {
  /// Creates the failure with a plain-English [message].
  const CoachModelFailure(super.message, {super.cause});
}

/// The coach can't run here right now, before anything is sent: no consent
/// yet, the coach turned off, or this iPhone can't be verified. The coach
/// screens show a card saying why instead of a conversation.
sealed class CoachUnavailableFailure extends CoachModelFailure {
  /// Creates the failure with a plain-English [message].
  const CoachUnavailableFailure(super.message, {super.cause});
}

/// The person hasn't agreed to the coach sending what a conversation needs
/// (App Store 5.1.2). Never sent: the request is refused before it's built.
/// The consent screen (#153) is what changes this.
final class CoachConsentNotGivenFailure extends CoachUnavailableFailure {
  /// Creates the failure; [message] defaults to plain-English copy.
  const CoachConsentNotGivenFailure({
    String message = "The coach isn't set up yet.",
    super.cause,
  }) : super(message);
}

/// The coach is off: the proxy's kill switch (`coach_disabled`), or a build
/// with no proxy configured. Nothing was sent to the model. Not a transport
/// failure: no retry loop, just "try again later".
final class CoachTurnedOffFailure extends CoachUnavailableFailure {
  /// Creates the failure; [message] defaults to plain-English copy.
  const CoachTurnedOffFailure({
    String message = 'The coach is off right now.',
    super.cause,
  }) : super(message);
}

/// This iPhone can't prove it's running the genuine app (App Attest isn't
/// supported here), which the proxy requires. Nothing the person can change.
final class CoachDeviceNotVerifiedFailure extends CoachUnavailableFailure {
  /// Creates the failure; [message] defaults to plain-English copy.
  const CoachDeviceNotVerifiedFailure({
    String message = "This iPhone can't be verified, which the coach needs.",
    super.cause,
  }) : super(message);
}

/// No connection, or the proxy didn't answer in time. Worth trying again.
final class CoachOfflineFailure extends CoachModelFailure {
  /// Creates the failure; [message] defaults to plain-English copy.
  const CoachOfflineFailure({
    String message = "Couldn't reach the coach.",
    super.cause,
  }) : super(message);
}

/// This iPhone's daily limit, or the coach's overall one, is used up
/// (`rate_limited`, HTTP 429).
final class CoachRateLimitedFailure extends CoachModelFailure {
  /// Creates the failure; [message] defaults to plain-English copy.
  const CoachRateLimitedFailure({
    this.retryAfter,
    String message = 'The coach has reached its limit for today.',
    super.cause,
  }) : super(message);

  /// How long until the limit resets, if the proxy said.
  final Duration? retryAfter;

  @override
  List<Object?> get props => [message, retryAfter];
}

/// The model declined to answer (`refusal`), even after the proxy's
/// fallback. This can be what a hard moment looks like from here, so the
/// coach screens discard any partial reply and show `CoachCopy.helpLine`.
final class CoachRefusalFailure extends CoachModelFailure {
  /// Creates the failure; [message] defaults to plain-English copy.
  const CoachRefusalFailure({
    String message = "The coach can't reply to that.",
    super.cause,
  }) : super(message);
}

/// Anything else on the proxy's side or between: a server error, the model
/// provider unavailable, a malformed or broken stream, a request the proxy
/// rejected, or attestation that kept failing. Worth trying again shortly.
final class CoachServerFailure extends CoachModelFailure {
  /// Creates the failure; [message] defaults to plain-English copy.
  const CoachServerFailure({
    String message = "The coach couldn't reply just now.",
    super.cause,
  }) : super(message);
}
