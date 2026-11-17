import 'dart:convert';
import 'dart:typed_data';

import 'package:coach_domain/coach_domain.dart';

/// The proxy's wire format (`README.md` in `jnnabugwu/steady-backend`, "API
/// contract"): the reply request's body, the server-sent events a reply
/// streams back, and its error codes.
abstract final class CoachProxyWire {
  /// `GET`: a one-time challenge, `{"challenge": "<43 chars>"}`.
  static const String challengePath = '/api/attest/challenge';

  /// `POST {keyId, attestation, challenge}`: registers an attested key.
  static const String registerPath = '/api/attest/register';

  /// `POST <CoachRequest body>`: streams a reply as server-sent events.
  static const String replyPath = '/api/coach/reply';

  /// The App Attest key id.
  static const String keyIdHeader = 'x-steady-attest-key-id';

  /// The assertion, base64.
  static const String assertionHeader = 'x-steady-attest-assertion';

  /// The challenge the assertion's `clientDataHash` covers.
  static const String challengeHeader = 'x-steady-attest-challenge';

  /// Debug builds where App Attest isn't supported: the dev bypass token,
  /// instead of the three headers above.
  static const String devBypassHeader = 'x-steady-dev-bypass';

  /// Debug builds: Vercel's Deployment Protection bypass, for Preview.
  static const String vercelBypassHeader = 'x-vercel-protection-bypass';

  /// The event carrying the whole reply so far: `{"text": "..."}`.
  static const String snapshotEvent = 'snapshot';

  /// The reply finished: `{"stopReason": "end_turn" | "max_tokens"}`.
  static const String doneEvent = 'done';

  /// The reply failed: `{"code": "<code>"}`, plus `retryAfter` (seconds)
  /// for `rate_limited`.
  static const String errorEvent = 'error';

  /// The proxy's `attestation_failed` code: re-attest once and retry.
  static const String attestationFailed = 'attestation_failed';
}

/// [request] as the reply endpoint's JSON body, UTF-8 encoded. Serialized
/// once: these exact bytes are hashed into the assertion and sent.
///
/// A summary leaves out the week's context (the proxy ignores it) and any
/// app turns (the proxy allows them only in a weekly request).
Uint8List encodeCoachRequest(CoachRequest request) {
  final summary = request.kind == CoachRequestKind.summary;
  return utf8.encode(
    jsonEncode({
      'kind': request.kind.name,
      if (!summary && request.weekContext != null)
        'weekContext': request.weekContext,
      'turns': [
        for (final turn in request.turns)
          if (!(summary && turn is CoachTopicTurn)) _turnJson(turn),
      ],
    }),
  );
}

Map<String, Object> _turnJson(CoachTurn turn) => switch (turn) {
  CoachPersonTurn(:final text) => {'role': 'person', 'text': text},
  CoachReplyTurn(:final text) => {'role': 'coach', 'text': text},
  CoachTopicTurn(:final topic) => {'role': 'app', 'topic': topic.name},
};

/// A `done` event's stop reason. Anything this build doesn't know counts as
/// a finished reply.
CoachStopReason coachStopReasonFromWire(Object? value) => switch (value) {
  'max_tokens' => CoachStopReason.maxTokens,
  _ => CoachStopReason.endTurn,
};

/// The failure for a proxy error [code] (an `error` event's, or an error
/// response's), with [retryAfter] for `rate_limited`.
///
/// `attestation_failed` only lands here once the one re-attest and retry
/// has been spent, so it's a server error; `bad_request` is a bug in this
/// build, never retried.
CoachModelFailure coachFailureForCode(Object? code, {Duration? retryAfter}) =>
    switch (code) {
      'refusal' => const CoachRefusalFailure(),
      'rate_limited' => CoachRateLimitedFailure(retryAfter: retryAfter),
      'coach_disabled' => const CoachTurnedOffFailure(),
      'upstream_unavailable' => const CoachServerFailure(
        message: 'The coach is busy right now. Try again shortly.',
      ),
      // The code goes in `cause`, for diagnostics; the message stays plain.
      _ => CoachServerFailure(cause: 'proxy error code: $code'),
    };

/// A `retryAfter` or `retry-after` value in seconds, as a [Duration], or
/// `null` if it isn't a non-negative number.
Duration? coachRetryAfter(Object? seconds) {
  final value = switch (seconds) {
    final num n => n,
    final String s => num.tryParse(s.trim()),
    _ => null,
  };
  if (value == null || value < 0 || !value.isFinite) return null;
  return Duration(milliseconds: (value * 1000).round());
}
