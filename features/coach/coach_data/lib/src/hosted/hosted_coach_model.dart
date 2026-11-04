import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpException, SocketException, TlsException;
import 'dart:typed_data';

import 'package:coach_data/src/app_attest/app_attest.dart';
import 'package:coach_data/src/hosted/coach_proxy_config.dart';
import 'package:coach_data/src/hosted/coach_proxy_wire.dart';
import 'package:coach_data/src/hosted/coach_sse.dart';
import 'package:coach_domain/coach_domain.dart';
import 'package:crypto/crypto.dart';
import 'package:failures/failures.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// [CoachModel] over Steady's coach proxy (`jnnabugwu/steady-backend`):
/// HTTPS, with replies streamed back as server-sent events. iPhone only;
/// the app binds it nowhere else (CLAUDE.md §11).
///
/// **Per reply** (the proxy's "API contract"):
///
/// 1. Refuse at once, sending nothing, without consent
///    ([CoachConsentNotGivenFailure]) or a proxy URL ([CoachTurnedOffFailure]).
///    Consent is read again right before the reply's `POST`, so a "no"
///    given while the challenge was fetched still stops it.
/// 2. Serialize the request once ([encodeCoachRequest]): those exact bytes
///    are hashed and sent.
/// 3. With App Attest: register a key once per install (a fresh challenge,
///    `generateKey`, `attestKey` over SHA-256(challenge), `POST
///    /api/attest/register`, then the key id is stored), then a fresh
///    challenge for this reply and an assertion over SHA-256(challenge ‖
///    body). Debug builds where App Attest isn't supported (the Simulator)
///    send the dev bypass token instead, when the build has one; anywhere
///    else, [CoachDeviceNotVerifiedFailure].
/// 4. `POST /api/coach/reply` and parse its events: each `snapshot` is the
///    whole reply so far; `done` ends it with its stop reason; `error` is
///    mapped to its [CoachModelFailure] ([coachFailureForCode]). A stream
///    that closes without either is a [CoachServerFailure].
///
/// **`attestation_failed`** (or App Attest saying the key is invalid):
/// forget the key, attest a new one, and retry once, with fresh challenges.
/// Failing again is a [CoachServerFailure].
///
/// **One reply in flight at a time.** The proxy rejects an assertion whose
/// counter isn't higher than the last one it accepted, so two concurrent
/// requests could arrive out of order. A reply waits for the one before it
/// to finish, fail or be cancelled before it fetches its challenge.
///
/// **Cancelling** the reply's subscription aborts whichever request is in
/// flight (the proxy then stops the model) and sends nothing further.
///
/// **Errors** never leave as exceptions: no connection or a timeout is a
/// [CoachOfflineFailure], anything else unexpected a [CoachServerFailure]
/// (CLAUDE.md §9). Nothing here logs, and no failure carries a request or
/// response body.
class HostedCoachModel implements CoachModel {
  /// Creates the model.
  ///
  /// `consentGiven` is read before every reply and again right before its
  /// `POST`, and nothing is sent unless it says `true` (#153). [client] is
  /// for tests; by default the model owns an [http.Client] ([close] closes
  /// it). [requestTimeout] bounds every request up to its response headers
  /// (and a challenge's or registration's whole body); [replyIdleTimeout]
  /// bounds the wait between a reply's chunks, longer than the proxy's own
  /// 110-second deadline, which ends every stream with an event first.
  HostedCoachModel({
    required this._config,
    required this._appAttest,
    required this._keyStore,
    required this._consentGiven,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 20),
    this.replyIdleTimeout = const Duration(seconds: 120),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final CoachProxyConfig _config;
  final AppAttest _appAttest;
  final AppAttestKeyStore _keyStore;
  final bool Function() _consentGiven;
  final http.Client _client;
  final bool _ownsClient;

  /// The longest wait for a response's headers.
  final Duration requestTimeout;

  /// The longest wait between two chunks of a streaming reply.
  final Duration replyIdleTimeout;

  /// Completes when the reply in flight is over: the next one waits for it.
  Future<void> _inFlight = Future<void>.value();

  static const _notConfigured = CoachTurnedOffFailure(
    cause: 'COACH_PROXY_URL is not set for this build',
  );

  @override
  ResultFuture<Unit> checkAvailability() async {
    if (_config.baseUrl == null) return const Err(_notConfigured);
    return switch (await _auth()) {
      _NoAuth() => const Err(CoachDeviceNotVerifiedFailure()),
      _AppAttestAuth() || _DevBypassAuth() => const Ok(unit),
    };
  }

  @override
  Stream<Result<CoachReplySnapshot>> reply(CoachRequest request) {
    final call = _ReplyCall();
    late final StreamController<Result<CoachReplySnapshot>> out;
    out = StreamController<Result<CoachReplySnapshot>>(
      onListen: () => unawaited(_serialized(request, call, out)),
      onCancel: call.cancel,
    );
    return out.stream;
  }

  /// Closes the HTTP client this model made. A reply in flight is aborted.
  void close() {
    if (_ownsClient) _client.close();
  }

  /// Runs [request] once the reply before it is over ([_inFlight]), and
  /// turns whatever ends it into the stream's last event.
  Future<void> _serialized(
    CoachRequest request,
    _ReplyCall call,
    StreamController<Result<CoachReplySnapshot>> out,
  ) async {
    final previous = _inFlight;
    final over = Completer<void>();
    _inFlight = over.future;
    try {
      await previous;
      call.check();
      await _reply(request, call, (snapshot) {
        if (!call.cancelled) out.add(Ok(snapshot));
      });
    } on _Cancelled {
      // Cancelled: the listener is gone, so there's no one to tell.
    } on _Stop catch (stop) {
      if (!call.cancelled) out.add(Err(stop.failure));
    } on Object catch (error) {
      // An aborted request throws once cancelled; that's not a failure.
      if (!call.cancelled) out.add(Err(_failureFor(error)));
    } finally {
      call.abort();
      over.complete();
      unawaited(out.close());
    }
  }

  Future<void> _reply(
    CoachRequest request,
    _ReplyCall call,
    void Function(CoachReplySnapshot) emit,
  ) async {
    if (!_hasConsent()) throw const _Stop(CoachConsentNotGivenFailure());
    final base = _config.baseUrl;
    if (base == null) throw const _Stop(_notConfigured);
    final body = encodeCoachRequest(request);
    final auth = await _auth();
    call.check();
    switch (auth) {
      case _NoAuth():
        throw const _Stop(CoachDeviceNotVerifiedFailure());
      case _DevBypassAuth(:final token):
        final outcome = await _streamReply(
          base,
          body,
          {CoachProxyWire.devBypassHeader: token},
          call,
          emit,
        );
        // No key to renew: a rejected bypass is the proxy refusing it.
        if (outcome == _Outcome.rejected) throw _attestationKeptFailing;
      case _AppAttestAuth():
        for (var attempt = 0; ; attempt++) {
          try {
            final keyId = await _registeredKey(base, call);
            final challenge = await _challenge(base, call);
            final assertion = _attested(
              await _appAttest.generateAssertion(
                keyId,
                _assertionHash(challenge, body),
              ),
            );
            call.check();
            final outcome = await _streamReply(
              base,
              body,
              {
                CoachProxyWire.keyIdHeader: keyId,
                CoachProxyWire.assertionHeader: assertion,
                CoachProxyWire.challengeHeader: challenge,
              },
              call,
              emit,
            );
            if (outcome == _Outcome.done) return;
            throw const _Rejected();
          } on _Rejected {
            // Once: forget the key, so the retry attests a new one.
            if (attempt > 0) throw _attestationKeptFailing;
            await _keyStore.clear();
            call.check();
          }
        }
    }
  }

  static const _attestationKeptFailing = _Stop(
    CoachServerFailure(cause: 'attestation_failed after one re-attest'),
  );

  bool _hasConsent() {
    try {
      return _consentGiven();
    } on Object {
      return false;
    }
  }

  /// How this build proves a request is the genuine app. The dev bypass is
  /// behind [kDebugMode], a compile-time constant: dead code in a profile or
  /// release build, whatever the config holds.
  Future<_Auth> _auth() async {
    bool supported;
    try {
      supported = await _appAttest.isSupported();
    } on Object {
      supported = false;
    }
    if (supported) return const _AppAttestAuth();
    if (kDebugMode) {
      final token = _config.devBypassToken;
      if (token != null) return _DevBypassAuth(token);
    }
    return const _NoAuth();
  }

  /// The stored key id, or a new key attested and registered with the proxy
  /// (then stored).
  Future<String> _registeredKey(Uri base, _ReplyCall call) async {
    final stored = await _keyStore.read();
    call.check();
    if (stored case Ok(value: final keyId?) when keyId.isNotEmpty) {
      return keyId;
    }
    // A failed read registers a new key: better than no coach.
    final challenge = await _challenge(base, call);
    final keyId = _attested(await _appAttest.generateKey());
    call.check();
    final attestation = _attested(
      await _appAttest.attestKey(keyId, _sha256(utf8.encode(challenge))),
    );
    call.check();
    final request = _request('POST', base, CoachProxyWire.registerPath, call)
      ..headers['content-type'] = 'application/json'
      ..bodyBytes = utf8.encode(
        jsonEncode({
          'keyId': keyId,
          'attestation': attestation,
          'challenge': challenge,
        }),
      );
    final response = await _send(request, call);
    if (response.statusCode == 204 || response.statusCode == 200) {
      // A failed write only means attesting again next time.
      await _keyStore.write(keyId);
      call.check();
      return keyId;
    }
    final code = _errorCode(response.bodyBytes);
    if (code == CoachProxyWire.attestationFailed) throw const _Rejected();
    throw _Stop(coachFailureForCode(code));
  }

  /// A fresh one-time challenge. Every attestation, reply and retry uses
  /// its own.
  Future<String> _challenge(Uri base, _ReplyCall call) async {
    final response = await _send(
      _request('GET', base, CoachProxyWire.challengePath, call),
      call,
    );
    if (response.statusCode != 200) {
      throw _Stop(coachFailureForCode(_errorCode(response.bodyBytes)));
    }
    final challenge = _jsonObject(response.bodyBytes)?['challenge'];
    if (challenge is! String || challenge.isEmpty) {
      throw const _Stop(CoachServerFailure(cause: 'malformed challenge'));
    }
    return challenge;
  }

  /// Sends the reply request and streams its events into [emit]. Returns
  /// [_Outcome.done] after `done`, or [_Outcome.rejected] for
  /// `attestation_failed` before any snapshot; throws [_Stop] for any other
  /// failure.
  Future<_Outcome> _streamReply(
    Uri base,
    Uint8List body,
    Map<String, String> authHeaders,
    _ReplyCall call,
    void Function(CoachReplySnapshot) emit,
  ) async {
    // Again, right before the conversation leaves the phone: consent may
    // have been withdrawn while the key or the challenge was fetched.
    if (!_hasConsent()) throw const _Stop(CoachConsentNotGivenFailure());
    final request = _request('POST', base, CoachProxyWire.replyPath, call)
      ..headers.addAll(authHeaders)
      ..headers['content-type'] = 'application/json'
      ..headers['accept'] = 'text/event-stream'
      ..bodyBytes = body;
    final response = await _headers(request, call);
    call.check();
    final retryAfterHeader = coachRetryAfter(response.headers['retry-after']);

    final outcome = Completer<_Outcome>();
    var text = '';
    var snapshots = 0;
    void fail(CoachModelFailure failure) {
      if (!outcome.isCompleted) outcome.completeError(_Stop(failure));
    }

    final events = coachSseEvents(response.stream.timeout(replyIdleTimeout))
        .listen(
          (event) {
            if (outcome.isCompleted) return;
            switch (event.event) {
              case CoachProxyWire.snapshotEvent:
                final snapshot = _jsonObject(utf8.encode(event.data))?['text'];
                if (snapshot is! String) {
                  return fail(
                    const CoachServerFailure(cause: 'malformed snapshot'),
                  );
                }
                text = snapshot;
                snapshots++;
                emit(CoachReplySnapshot(text: snapshot));
              case CoachProxyWire.doneEvent:
                final data = _jsonObject(utf8.encode(event.data));
                emit(
                  CoachReplySnapshot(
                    text: text,
                    stopReason: coachStopReasonFromWire(data?['stopReason']),
                  ),
                );
                outcome.complete(_Outcome.done);
              case CoachProxyWire.errorEvent:
                final data = _jsonObject(utf8.encode(event.data));
                final code = data?['code'];
                if (code == CoachProxyWire.attestationFailed &&
                    snapshots == 0) {
                  outcome.complete(_Outcome.rejected);
                  return;
                }
                fail(
                  coachFailureForCode(
                    code,
                    retryAfter:
                        coachRetryAfter(data?['retryAfter']) ??
                        retryAfterHeader,
                  ),
                );
            }
          },
          onError: (Object error, StackTrace stack) {
            if (!outcome.isCompleted) outcome.completeError(error, stack);
          },
          onDone: () => fail(
            // No `done` or `error`: a broken connection, or not the proxy
            // answering at all (a login page, say). The status is a hint.
            response.statusCode == 429
                ? CoachRateLimitedFailure(retryAfter: retryAfterHeader)
                : CoachServerFailure(
                    cause:
                        'stream closed without done or error '
                        '(HTTP ${response.statusCode})',
                  ),
          ),
        );
    call.onCancel(() {
      if (!outcome.isCompleted) outcome.completeError(const _Cancelled());
    });
    try {
      return await outcome.future;
    } finally {
      // Awaited: the next reply waits for this one's response to be torn
      // down, so two requests are never open at once.
      await events.cancel();
    }
  }

  /// [path] under the proxy's base URL, abortable by [call], with the
  /// Vercel protection bypass in a debug build that has one.
  http.AbortableRequest _request(
    String method,
    Uri base,
    String path,
    _ReplyCall call,
  ) {
    final request = http.AbortableRequest(
      method,
      base.replace(path: '${base.path}$path'),
      abortTrigger: call.abortTrigger,
    );
    if (kDebugMode) {
      final bypass = _config.vercelProtectionBypass;
      if (bypass != null) {
        request.headers[CoachProxyWire.vercelBypassHeader] = bypass;
      }
    }
    return request;
  }

  /// Sends [request] and waits for its response headers, at most
  /// [requestTimeout].
  Future<http.StreamedResponse> _headers(
    http.BaseRequest request,
    _ReplyCall call,
  ) async {
    try {
      return await _client.send(request).timeout(requestTimeout);
    } on TimeoutException {
      call.abort();
      rethrow;
    }
  }

  /// Sends [request] and reads its whole (small) response.
  Future<http.Response> _send(http.BaseRequest request, _ReplyCall call) async {
    final streamed = await _headers(request, call);
    call.check();
    try {
      return await http.Response.fromStream(streamed).timeout(requestTimeout);
    } on TimeoutException {
      call.abort();
      rethrow;
    }
  }

  /// [result]'s value; an App Attest failure becomes what it means here.
  static String _attested(Result<String> result) => switch (result) {
    Ok(:final value) => value,
    Err(failure: AppAttestFailure(reason: AppAttestFailureReason.invalidKey)) =>
      throw const _Rejected(),
    Err(
      failure: AppAttestFailure(reason: AppAttestFailureReason.unsupported),
    ) =>
      throw const _Stop(CoachDeviceNotVerifiedFailure()),
    Err(:final failure) => throw _Stop(CoachServerFailure(cause: failure)),
  };

  static CoachModelFailure _failureFor(Object error) => switch (error) {
    TimeoutException() ||
    SocketException() ||
    TlsException() ||
    HttpException() ||
    http.ClientException() => CoachOfflineFailure(cause: error),
    _ => CoachServerFailure(cause: error),
  };

  static Uint8List _sha256(List<int> bytes) =>
      Uint8List.fromList(sha256.convert(bytes).bytes);

  /// SHA-256 of the challenge's UTF-8 bytes followed directly by the body's.
  static Uint8List _assertionHash(String challenge, Uint8List body) => _sha256(
    (BytesBuilder(copy: false)
          ..add(utf8.encode(challenge))
          ..add(body))
        .takeBytes(),
  );

  /// An error response's `{"error": {"code": ...}}`, or `null`.
  static Object? _errorCode(List<int> body) => switch (_jsonObject(body)) {
    {'error': {'code': final Object? code}} => code,
    _ => null,
  };

  static Map<String, Object?>? _jsonObject(List<int> bytes) {
    try {
      final value = jsonDecode(utf8.decode(bytes));
      return value is Map<String, Object?> ? value : null;
    } on FormatException {
      return null;
    }
  }
}

/// One reply's lifetime: cancelled by its listener, aborting its requests.
class _ReplyCall {
  final Completer<void> _abort = Completer<void>();
  final List<void Function()> _onCancel = [];

  /// Whether the listener cancelled.
  bool cancelled = false;

  /// Completes to abort every request this reply made.
  Future<void> get abortTrigger => _abort.future;

  void cancel() {
    if (cancelled) return;
    cancelled = true;
    abort();
    for (final callback in [..._onCancel]) {
      callback();
    }
  }

  void abort() {
    if (!_abort.isCompleted) _abort.complete();
  }

  void onCancel(void Function() callback) {
    if (cancelled) return callback();
    _onCancel.add(callback);
  }

  /// Stops the reply here if it was cancelled.
  void check() {
    if (cancelled) throw const _Cancelled();
  }
}

sealed class _Auth {
  const _Auth();
}

final class _AppAttestAuth extends _Auth {
  const _AppAttestAuth();
}

final class _DevBypassAuth extends _Auth {
  const _DevBypassAuth(this.token);

  final String token;
}

final class _NoAuth extends _Auth {
  const _NoAuth();
}

enum _Outcome { done, rejected }

/// Ends a reply with [failure].
final class _Stop implements Exception {
  const _Stop(this.failure);

  final CoachModelFailure failure;
}

/// The proxy or App Attest rejected the key: re-attest once.
final class _Rejected implements Exception {
  const _Rejected();
}

/// The listener cancelled: stop quietly.
final class _Cancelled implements Exception {
  const _Cancelled();
}
