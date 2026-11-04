import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:coach_data/coach_data.dart';
import 'package:failures/failures.dart';
import 'package:http/http.dart' as http;

/// One server-sent event, as the proxy writes it.
String sse(String event, Object data) =>
    'event: $event\ndata: ${jsonEncode(data)}\n\n';

/// An App Attest that records every call. Keys are `key-1`, `key-2`, …;
/// assertions `assertion-1`, …. Set the `*Results` queues to script a
/// failure.
class FakeAppAttest implements AppAttest {
  FakeAppAttest({this.realKeyIds = false});

  /// Whether key ids look like App Attest's (standard base64 of 32 bytes,
  /// which `FileAppAttestKeyStore` insists on) rather than `key-1`, ….
  final bool realKeyIds;

  /// The key id the [n]th generated key gets, when [realKeyIds].
  static String realKeyId(int n) => base64Encode(List.filled(32, n));

  bool supported = true;
  var _keys = 0;
  var _assertions = 0;

  /// Every `attestKey` call: the key and its clientDataHash.
  final List<(String, Uint8List)> attested = [];

  /// Every `generateAssertion` call: the key and its clientDataHash.
  final List<(String, Uint8List)> asserted = [];

  /// The next `generateKey` results, before the default.
  final List<Result<String>> keyResults = [];

  /// The next `attestKey` results, before the default.
  final List<Result<String>> attestResults = [];

  /// The next `generateAssertion` results, before the default.
  final List<Result<String>> assertionResults = [];

  int get calls => _keys + attested.length + asserted.length;

  @override
  Future<bool> isSupported() async => supported;

  @override
  ResultFuture<String> generateKey() async {
    if (keyResults.isNotEmpty) return keyResults.removeAt(0);
    _keys++;
    return Ok(realKeyIds ? realKeyId(_keys) : 'key-$_keys');
  }

  @override
  ResultFuture<String> attestKey(String keyId, Uint8List clientDataHash) async {
    attested.add((keyId, clientDataHash));
    if (attestResults.isNotEmpty) return attestResults.removeAt(0);
    return Ok('attestation-of-$keyId');
  }

  @override
  ResultFuture<String> generateAssertion(
    String keyId,
    Uint8List clientDataHash,
  ) async {
    asserted.add((keyId, clientDataHash));
    if (assertionResults.isNotEmpty) return assertionResults.removeAt(0);
    return Ok('assertion-${++_assertions}');
  }
}

/// A key store in memory.
class MemoryKeyStore implements AppAttestKeyStore {
  MemoryKeyStore([this.keyId]);

  String? keyId;
  int clears = 0;

  @override
  ResultFuture<String?> read() async => Ok(keyId);

  @override
  ResultFuture<Unit> write(String keyId) async {
    this.keyId = keyId;
    return const Ok(unit);
  }

  @override
  ResultFuture<Unit> clear() async {
    keyId = null;
    clears++;
    return const Ok(unit);
  }
}

/// A request the fake proxy received.
class SentRequest {
  SentRequest(this.request, this.body);

  final http.BaseRequest request;
  final Uint8List body;

  String get method => request.method;
  String get path => request.url.path;
  Map<String, String> get headers => request.headers;
  Map<String, Object?> get json =>
      jsonDecode(utf8.decode(body)) as Map<String, Object?>;
}

/// A reply response the test feeds by hand: [add] chunks, then [close].
/// Honours the request's abort trigger the way `IOClient` does.
class ManualReply {
  ManualReply({this.status = 200});

  final int status;
  late final StreamController<List<int>> _body = StreamController(
    onCancel: () => cancelled = true,
  );

  /// Whether the client cancelled the response body.
  bool cancelled = false;

  /// Whether the request's abort trigger fired.
  bool aborted = false;

  void add(String text) => _body.add(utf8.encode(text));

  void addBytes(List<int> bytes) => _body.add(bytes);

  Future<void> close() => _body.close();

  http.StreamedResponse respond(http.BaseRequest request) {
    if (request case http.Abortable(:final abortTrigger?)) {
      unawaited(
        abortTrigger.whenComplete(() {
          aborted = true;
          if (!_body.isClosed) {
            _body.addError(http.RequestAbortedException(request.url));
            unawaited(_body.close());
          }
        }),
      );
    }
    return http.StreamedResponse(
      _body.stream,
      status,
      headers: {'content-type': 'text/event-stream; charset=utf-8'},
    );
  }
}

/// Answers one reply request.
typedef ReplyHandler = FutureOr<http.StreamedResponse> Function(
  http.BaseRequest request,
);

/// The proxy, in memory: fresh challenges `challenge-1`, `challenge-2`, …;
/// registrations answered from [registerStatuses] (then 204); replies from
/// [replies] (then a two-snapshot reply that ends with `end_turn`).
class FakeProxy extends http.BaseClient {
  final List<SentRequest> sent = [];
  var _challenges = 0;

  /// The next registrations' statuses; a 401 answers `attestation_failed`.
  final List<int> registerStatuses = [];

  /// The next replies, in order.
  final List<ReplyHandler> replies = [];

  /// When set, every request throws this instead.
  Exception? throwOnSend;

  /// When set, the challenge endpoint answers with this status and an
  /// error body.
  int? challengeStatus;

  /// Called with every request as it's sent, when set.
  void Function(http.BaseRequest request)? onSend;

  /// When set, every `send` waits for this before answering.
  Future<void>? hold;

  List<SentRequest> get challenges =>
      sent.where((r) => r.path == CoachProxyWire.challengePath).toList();

  List<SentRequest> get registrations =>
      sent.where((r) => r.path == CoachProxyWire.registerPath).toList();

  List<SentRequest> get replyRequests =>
      sent.where((r) => r.path == CoachProxyWire.replyPath).toList();

  /// The challenge the proxy handed out [n]th (1-based).
  static String challenge(int n) => 'challenge-$n';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = await request.finalize().toBytes();
    sent.add(SentRequest(request, body));
    onSend?.call(request);
    if (throwOnSend case final error?) throw error;
    if (hold case final hold?) await hold;
    switch (request.url.path) {
      case CoachProxyWire.challengePath:
        if (challengeStatus case final status?) {
          return _json(status, {
            'error': {'code': 'server_error'},
          });
        }
        return _json(200, {
          'challenge': challenge(++_challenges),
          'expiresInSeconds': 300,
        });
      case CoachProxyWire.registerPath:
        final status = registerStatuses.isEmpty
            ? 204
            : registerStatuses.removeAt(0);
        if (status == 204) return http.StreamedResponse(Stream.value([]), 204);
        return _json(status, {
          'error': {
            'code': status == 401 ? 'attestation_failed' : 'bad_request',
          },
        });
      case CoachProxyWire.replyPath:
        if (replies.isNotEmpty) return await replies.removeAt(0)(request);
        return events(200, [
          sse('snapshot', {'text': 'Hi'}),
          sse('snapshot', {'text': 'Hi there.'}),
          sse('done', {'stopReason': 'end_turn'}),
        ]);
    }
    return _json(404, {});
  }

  /// A finished response of [chunks].
  static http.StreamedResponse events(
    int status,
    List<String> chunks, {
    Map<String, String> headers = const {},
  }) => http.StreamedResponse(
    Stream.fromIterable(chunks.map(utf8.encode)),
    status,
    headers: {'content-type': 'text/event-stream; charset=utf-8', ...headers},
  );

  static http.StreamedResponse _json(int status, Object body) =>
      http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(body))),
        status,
        headers: {'content-type': 'application/json'},
      );
}
