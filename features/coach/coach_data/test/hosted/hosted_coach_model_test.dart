import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coach_data/coach_data.dart';
import 'package:coach_domain/coach_domain.dart';
import 'package:crypto/crypto.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'fakes.dart';

final Uri _base = Uri.parse('https://coach.example.com');

const _chat = CoachRequest(
  kind: CoachRequestKind.chat,
  weekContext: 'Sat Oct 24: logged fully; ate 1800 kcal',
  turns: [CoachTurn.person('Which days did I skip?')],
);

Uint8List _sha256(List<int> bytes) =>
    Uint8List.fromList(sha256.convert(bytes).bytes);

void main() {
  late FakeProxy proxy;
  late FakeAppAttest attest;
  late MemoryKeyStore keys;
  late bool consent;

  HostedCoachModel model({
    CoachProxyConfig? config,
    Duration requestTimeout = const Duration(seconds: 20),
  }) => HostedCoachModel(
    config: config ?? CoachProxyConfig(baseUrl: _base),
    appAttest: attest,
    keyStore: keys,
    consentGiven: () => consent,
    client: proxy,
    requestTimeout: requestTimeout,
  );

  setUp(() {
    proxy = FakeProxy();
    attest = FakeAppAttest();
    keys = MemoryKeyStore();
    consent = true;
  });

  /// Every event of one reply.
  Future<List<Result<CoachReplySnapshot>>> replyTo(
    HostedCoachModel coach, [
    CoachRequest request = _chat,
  ]) => coach.reply(request).toList();

  Failure? failureOf(List<Result<CoachReplySnapshot>> events) =>
      switch (events.lastOrNull) {
        Err(:final failure) => failure,
        _ => null,
      };

  List<CoachReplySnapshot> snapshotsOf(
    List<Result<CoachReplySnapshot>> events,
  ) => [
    for (final e in events)
      if (e case Ok(:final value)) value,
  ];

  group('the request body', () {
    test('chat: the kind, the week context and the turns, in order', () {
      final body = encodeCoachRequest(
        const CoachRequest(
          kind: CoachRequestKind.chat,
          weekContext: 'week',
          turns: [
            CoachTurn.person('Hi'),
            CoachTurn.coach('Hello.'),
            CoachTurn.person('Steps?'),
          ],
        ),
      );
      expect(
        utf8.decode(body),
        '{"kind":"chat","weekContext":"week","turns":['
        '{"role":"person","text":"Hi"},'
        '{"role":"coach","text":"Hello."},'
        '{"role":"person","text":"Steps?"}]}',
      );
    });

    test('weekly: app turns stay in place, by topic', () {
      final body = jsonDecode(
        utf8.decode(
          encodeCoachRequest(
            const CoachRequest(
              kind: CoachRequestKind.weekly,
              weekContext: 'week',
              turns: [
                CoachTurn.app(WeeklyTopic.logging),
                CoachTurn.coach('How did the week feel?'),
                CoachTurn.person('Fine.'),
                CoachTurn.coach('Good to hear.'),
                CoachTurn.app(WeeklyTopic.nextWeek),
              ],
            ),
          ),
        ),
      ) as Map<String, Object?>;
      expect(body['kind'], 'weekly');
      expect(body['turns'], [
        {'role': 'app', 'topic': 'logging'},
        {'role': 'coach', 'text': 'How did the week feel?'},
        {'role': 'person', 'text': 'Fine.'},
        {'role': 'coach', 'text': 'Good to hear.'},
        {'role': 'app', 'topic': 'nextWeek'},
      ]);
    });

    test('summary: no week context and no app turns', () {
      final body = jsonDecode(
        utf8.decode(
          encodeCoachRequest(
            const CoachRequest(
              kind: CoachRequestKind.summary,
              weekContext: 'ignored',
              turns: [
                CoachTurn.app(WeeklyTopic.logging),
                CoachTurn.coach('How did it feel?'),
                CoachTurn.person('Busy.'),
              ],
            ),
          ),
        ),
      ) as Map<String, Object?>;
      expect(body.keys, ['kind', 'turns']);
      expect(body['kind'], 'summary');
      expect(body['turns'], [
        {'role': 'coach', 'text': 'How did it feel?'},
        {'role': 'person', 'text': 'Busy.'},
      ]);
    });
  });

  group('App Attest', () {
    test('the first reply registers a key once, with its own challenge, and '
        'the reply carries an assertion over challenge ‖ the exact body '
        'sent', () async {
      final events = await replyTo(model());
      expect(failureOf(events), isNull);

      // Registration: challenge 1, hashed as its UTF-8 text.
      expect(attest.attested.single.$1, 'key-1');
      expect(
        attest.attested.single.$2,
        _sha256(utf8.encode(FakeProxy.challenge(1))),
      );
      expect(proxy.registrations.single.json, {
        'keyId': 'key-1',
        'attestation': 'attestation-of-key-1',
        'challenge': FakeProxy.challenge(1),
      });
      expect(keys.keyId, 'key-1');

      // The reply: a fresh challenge (2), never the registration's.
      final reply = proxy.replyRequests.single;
      expect(reply.method, 'POST');
      expect(reply.request.url, Uri.parse('$_base/api/coach/reply'));
      expect(reply.headers[CoachProxyWire.keyIdHeader], 'key-1');
      expect(reply.headers[CoachProxyWire.assertionHeader], 'assertion-1');
      expect(
        reply.headers[CoachProxyWire.challengeHeader],
        FakeProxy.challenge(2),
      );
      expect(reply.headers['content-type'], 'application/json');
      expect(reply.headers.containsKey(CoachProxyWire.devBypassHeader), false);
      // The bytes sent are the bytes encoded, and the bytes hashed.
      expect(reply.body, encodeCoachRequest(_chat));
      expect(attest.asserted.single.$1, 'key-1');
      expect(
        attest.asserted.single.$2,
        _sha256([...utf8.encode(FakeProxy.challenge(2)), ...reply.body]),
      );
    });

    test('later replies reuse the stored key, each with a fresh '
        'challenge', () async {
      keys.keyId = 'stored-key';
      final coach = model();
      await replyTo(coach);
      await replyTo(coach);
      expect(proxy.registrations, isEmpty);
      expect(attest.attested, isEmpty);
      expect(
        proxy.replyRequests.map(
          (r) => r.headers[CoachProxyWire.challengeHeader],
        ),
        [FakeProxy.challenge(1), FakeProxy.challenge(2)],
      );
      expect(
        proxy.replyRequests.map((r) => r.headers[CoachProxyWire.keyIdHeader]),
        ['stored-key', 'stored-key'],
      );
    });

    test('attestation_failed: forgets the key, attests a new one and '
        'retries once, with fresh challenges', () async {
      keys.keyId = 'stale-key';
      proxy.replies.add(
        (_) => FakeProxy.events(401, [
          sse('error', {'code': 'attestation_failed'}),
        ]),
      );
      final events = await replyTo(model());

      expect(failureOf(events), isNull);
      expect(snapshotsOf(events).last.text, 'Hi there.');
      expect(keys.clears, 1);
      expect(keys.keyId, 'key-1');
      expect(proxy.replyRequests, hasLength(2));
      expect(
        proxy.replyRequests.map((r) => r.headers[CoachProxyWire.keyIdHeader]),
        ['stale-key', 'key-1'],
      );
      // Every attempt used its own challenge: reply, register, reply.
      final used = [
        proxy.replyRequests.first.headers[CoachProxyWire.challengeHeader],
        proxy.registrations.single.json['challenge'],
        proxy.replyRequests.last.headers[CoachProxyWire.challengeHeader],
      ];
      expect(used.toSet(), hasLength(3));
    });

    test('attestation_failed twice is a server error, after exactly one '
        'retry', () async {
      keys.keyId = 'stale-key';
      for (var i = 0; i < 3; i++) {
        proxy.replies.add(
          (_) => FakeProxy.events(401, [
            sse('error', {'code': 'attestation_failed'}),
          ]),
        );
      }
      final events = await replyTo(model());
      expect(failureOf(events), isA<CoachServerFailure>());
      expect(proxy.replyRequests, hasLength(2));
      expect(proxy.registrations, hasLength(1));
    });

    test(
      'a registration rejected once attests a new key and goes on',
      () async {
        proxy.registerStatuses.add(401);
        final events = await replyTo(model());
        expect(failureOf(events), isNull);
        expect(proxy.registrations.map((r) => r.json['keyId']), [
          'key-1',
          'key-2',
        ]);
        expect(keys.keyId, 'key-2');
        expect(
          proxy.replyRequests.single.headers[CoachProxyWire.keyIdHeader],
          'key-2',
        );
      },
    );

    test('App Attest saying the key is invalid re-attests once too', () async {
      keys.keyId = 'gone-key';
      attest.assertionResults.add(
        const Err(AppAttestFailure(AppAttestFailureReason.invalidKey, 'gone')),
      );
      final events = await replyTo(model());
      expect(failureOf(events), isNull);
      expect(keys.keyId, 'key-1');
      expect(
        proxy.replyRequests.single.headers[CoachProxyWire.keyIdHeader],
        'key-1',
      );
    });

    test('App Attest failures mean what they say', () async {
      attest.keyResults.add(
        const Err(AppAttestFailure(AppAttestFailureReason.unsupported, 'no')),
      );
      expect(
        failureOf(await replyTo(model())),
        isA<CoachDeviceNotVerifiedFailure>(),
      );
      attest.keyResults.add(
        const Err(
          AppAttestFailure(AppAttestFailureReason.serviceUnavailable, 'later'),
        ),
      );
      expect(failureOf(await replyTo(model())), isA<CoachServerFailure>());
      expect(proxy.replyRequests, isEmpty);
    });
  });

  group('the reply stream', () {
    test(
      'cumulative snapshots, then a last one with the stop reason',
      () async {
        keys.keyId = 'k';
        proxy.replies.add(
          (_) => FakeProxy.events(200, [
            sse('snapshot', {'text': 'You'}),
            sse('snapshot', {'text': 'You skipped Tuesday.'}),
            sse('done', {'stopReason': 'end_turn'}),
          ]),
        );
        final events = await replyTo(model());
        expect(snapshotsOf(events), const [
          CoachReplySnapshot(text: 'You'),
          CoachReplySnapshot(text: 'You skipped Tuesday.'),
          CoachReplySnapshot(
            text: 'You skipped Tuesday.',
            stopReason: CoachStopReason.endTurn,
          ),
        ]);
      },
    );

    test('max_tokens is reported as such', () async {
      keys.keyId = 'k';
      proxy.replies.add(
        (_) => FakeProxy.events(200, [
          sse('snapshot', {'text': 'On Friday you'}),
          sse('done', {'stopReason': 'max_tokens'}),
        ]),
      );
      final last = snapshotsOf(await replyTo(model())).last;
      expect(last.stopReason, CoachStopReason.maxTokens);
      expect(last.text, 'On Friday you');
    });

    test('events split across chunks anywhere still parse', () async {
      keys.keyId = 'k';
      final whole = [
        sse('snapshot', {'text': 'Café 🙂'}),
        sse('done', {'stopReason': 'end_turn'}),
      ].join();
      final bytes = utf8.encode(whole);
      proxy.replies.add(
        (_) => http.StreamedResponse(
          Stream.fromIterable([
            for (var i = 0; i < bytes.length; i += 3)
              bytes.sublist(i, i + 3 > bytes.length ? bytes.length : i + 3),
          ]),
          200,
        ),
      );
      expect(snapshotsOf(await replyTo(model())).last.text, 'Café 🙂');
    });

    test(
      'a stream that closes without done or error is a server error',
      () async {
        keys.keyId = 'k';
        proxy.replies.add(
          (_) => FakeProxy.events(200, [
            sse('snapshot', {'text': 'Half a'}),
          ]),
        );
        final events = await replyTo(model());
        expect(snapshotsOf(events).single.text, 'Half a');
        expect(failureOf(events), isA<CoachServerFailure>());
      },
    );

    test('a malformed snapshot is a server error', () async {
      keys.keyId = 'k';
      proxy.replies.add(
        (_) => FakeProxy.events(200, ['event: snapshot\ndata: {oops\n\n']),
      );
      expect(failureOf(await replyTo(model())), isA<CoachServerFailure>());
    });

    test('nothing after done is read', () async {
      keys.keyId = 'k';
      proxy.replies.add(
        (_) => FakeProxy.events(200, [
          sse('done', {'stopReason': 'end_turn'}),
          sse('snapshot', {'text': 'late'}),
          sse('error', {'code': 'server_error'}),
        ]),
      );
      final events = await replyTo(model());
      expect(events, hasLength(1));
      expect(failureOf(events), isNull);
    });
  });

  group('every proxy error code becomes its failure', () {
    final cases = <String, (int, Matcher)>{
      'refusal': (200, isA<CoachRefusalFailure>()),
      'rate_limited': (429, isA<CoachRateLimitedFailure>()),
      'coach_disabled': (503, isA<CoachTurnedOffFailure>()),
      'bad_request': (400, isA<CoachServerFailure>()),
      'upstream_unavailable': (503, isA<CoachServerFailure>()),
      'server_error': (500, isA<CoachServerFailure>()),
      'something_new': (500, isA<CoachServerFailure>()),
    };
    for (final MapEntry(key: code, value: (status, matcher)) in cases.entries) {
      test(code, () async {
        keys.keyId = 'k';
        proxy.replies.add(
          (_) => FakeProxy.events(status, [
            sse('error', {'code': code}),
          ]),
        );
        final events = await replyTo(model());
        expect(failureOf(events), matcher);
        // Never retried: one request.
        expect(proxy.replyRequests, hasLength(1));
      });
    }

    test('rate_limited carries retryAfter, from the event or the '
        'header', () async {
      keys.keyId = 'k';
      proxy.replies
        ..add(
          (_) => FakeProxy.events(429, [
            sse('error', {'code': 'rate_limited', 'retryAfter': 3600}),
          ]),
        )
        ..add(
          (_) => FakeProxy.events(
            429,
            [
              sse('error', {'code': 'rate_limited'}),
            ],
            headers: {'retry-after': '120'},
          ),
        )
        // Not the proxy's events at all, but a 429 with the header.
        ..add(
          (_) => FakeProxy.events(
            429,
            ['Too many requests'],
            headers: {'retry-after': '60'},
          ),
        );
      final coach = model();
      expect(
        failureOf(await replyTo(coach)),
        const CoachRateLimitedFailure(retryAfter: Duration(hours: 1)),
      );
      expect(
        failureOf(await replyTo(coach)),
        const CoachRateLimitedFailure(retryAfter: Duration(minutes: 2)),
      );
      expect(
        failureOf(await replyTo(coach)),
        const CoachRateLimitedFailure(retryAfter: Duration(minutes: 1)),
      );
    });

    test('a refusal after snapshots still ends in the refusal', () async {
      keys.keyId = 'k';
      proxy.replies.add(
        (_) => FakeProxy.events(200, [
          sse('snapshot', {'text': 'Partial'}),
          sse('error', {'code': 'refusal'}),
        ]),
      );
      final events = await replyTo(model());
      expect(snapshotsOf(events).single.text, 'Partial');
      expect(failureOf(events), isA<CoachRefusalFailure>());
    });

    test('attestation_failed mid-stream is not retried', () async {
      keys.keyId = 'k';
      proxy.replies.add(
        (_) => FakeProxy.events(200, [
          sse('snapshot', {'text': 'Partial'}),
          sse('error', {'code': 'attestation_failed'}),
        ]),
      );
      expect(failureOf(await replyTo(model())), isA<CoachServerFailure>());
      expect(proxy.replyRequests, hasLength(1));
    });

    test("a page that isn't the proxy (a login page, say) is a server "
        'error, not an attestation failure', () async {
      keys.keyId = 'k';
      proxy.replies.add(
        (_) => FakeProxy.events(401, ['<html>Log in to Vercel</html>']),
      );
      expect(failureOf(await replyTo(model())), isA<CoachServerFailure>());
      expect(keys.clears, 0);
    });

    test('a failed challenge is a server error', () async {
      proxy.challengeStatus = 500;
      expect(failureOf(await replyTo(model())), isA<CoachServerFailure>());
      expect(proxy.replyRequests, isEmpty);
    });
  });

  group('transport errors', () {
    test('no connection is offline', () async {
      for (final error in <Exception>[
        const SocketException('Network is unreachable'),
        http.ClientException('Connection closed'),
      ]) {
        proxy.throwOnSend = error;
        expect(
          failureOf(await replyTo(model())),
          isA<CoachOfflineFailure>(),
          reason: '$error',
        );
      }
    });

    test('no answer in time is offline, and the request is aborted', () async {
      keys.keyId = 'k';
      final reply = ManualReply();
      proxy.replies.add((request) async {
        await Completer<void>().future; // never answers
        return reply.respond(request);
      });
      final events = await replyTo(
        model(requestTimeout: const Duration(milliseconds: 10)),
      );
      expect(failureOf(events), isA<CoachOfflineFailure>());
      final sent = proxy.replyRequests.single.request as http.Abortable;
      expect(sent.abortTrigger, completes);
    });

    test('anything unexpected is a server error, never an exception', () async {
      proxy.throwOnSend = const FormatException('bug');
      expect(failureOf(await replyTo(model())), isA<CoachServerFailure>());
    });
  });

  group('one reply in flight at a time', () {
    test('a second reply sends nothing until the first is over', () async {
      keys.keyId = 'k';
      final first = ManualReply();
      proxy.replies.add(first.respond);
      final coach = model();

      final firstEvents = <Result<CoachReplySnapshot>>[];
      final firstDone = Completer<void>();
      coach.reply(_chat).listen(firstEvents.add, onDone: firstDone.complete);
      await pumpEventQueue();
      expect(proxy.sent, hasLength(2)); // challenge, reply

      final second = coach.reply(_chat).toList();
      await pumpEventQueue();
      // Not even a challenge: its assertion's counter must come after.
      expect(proxy.sent, hasLength(2));

      first
        ..add(sse('snapshot', {'text': 'One.'}))
        ..add(sse('done', {'stopReason': 'end_turn'}));
      await first.close();
      await firstDone.future;
      final secondEvents = await second;
      expect(failureOf(secondEvents), isNull);
      expect(proxy.replyRequests, hasLength(2));
      // The second's assertion was made after the first reply finished.
      expect(attest.asserted, hasLength(2));
    });

    test('a cancelled reply lets the next one go', () async {
      keys.keyId = 'k';
      final first = ManualReply();
      proxy.replies.add(first.respond);
      final coach = model();
      final subscription = coach.reply(_chat).listen((_) {});
      await pumpEventQueue();
      final second = coach.reply(_chat).toList();
      await pumpEventQueue();
      expect(proxy.replyRequests, hasLength(1));

      var firstTornDownBeforeNext = false;
      proxy.onSend = (request) {
        if (request.url.path == CoachProxyWire.challengePath) {
          firstTornDownBeforeNext = first.cancelled;
        }
      };
      await subscription.cancel();
      expect(failureOf(await second), isNull);
      expect(proxy.replyRequests, hasLength(2));
      // The first response was torn down before the next challenge.
      expect(firstTornDownBeforeNext, isTrue);
    });
  });

  group('cancelling', () {
    test('mid-reply aborts the request and emits nothing more', () async {
      keys.keyId = 'k';
      final reply = ManualReply();
      proxy.replies.add(reply.respond);
      final events = <Result<CoachReplySnapshot>>[];
      final subscription = model().reply(_chat).listen(events.add);
      await pumpEventQueue();
      reply.add(sse('snapshot', {'text': 'Tuesday was'}));
      await pumpEventQueue();
      expect(snapshotsOf(events).single.text, 'Tuesday was');

      await subscription.cancel();
      await pumpEventQueue();
      expect(reply.aborted, isTrue);
      expect(reply.cancelled, isTrue);
      expect(events, hasLength(1));
    });

    test('before the reply is sent sends nothing further', () async {
      keys.keyId = 'k';
      final hold = Completer<void>();
      proxy.hold = hold.future;
      final subscription = model().reply(_chat).listen((_) {});
      await pumpEventQueue();
      expect(proxy.challenges, hasLength(1));

      await subscription.cancel();
      proxy.hold = null;
      hold.complete();
      await pumpEventQueue();
      expect(proxy.replyRequests, isEmpty);
      expect(attest.asserted, isEmpty);
    });
  });

  group('nothing is sent', () {
    test(
      'without consent: not even a challenge or an App Attest call',
      () async {
        consent = false;
        final events = await replyTo(model());
        expect(failureOf(events), isA<CoachConsentNotGivenFailure>());
        expect(proxy.sent, isEmpty);
        expect(attest.calls, 0);
      },
    );

    test('when the consent check itself throws', () async {
      final coach = HostedCoachModel(
        config: CoachProxyConfig(baseUrl: _base),
        appAttest: attest,
        keyStore: keys,
        consentGiven: () => throw StateError('not ready'),
        client: proxy,
      );
      expect(
        failureOf(await replyTo(coach)),
        isA<CoachConsentNotGivenFailure>(),
      );
      expect(proxy.sent, isEmpty);
    });

    test('without a proxy URL: the coach is off', () async {
      final coach = model(config: const CoachProxyConfig());
      expect(failureOf(await replyTo(coach)), isA<CoachTurnedOffFailure>());
      expect(
        await coach.checkAvailability(),
        isA<Err<Unit>>().having(
          (e) => e.failure,
          'failure',
          isA<CoachTurnedOffFailure>(),
        ),
      );
      expect(proxy.sent, isEmpty);
    });

    test('where App Attest is unsupported and there is no bypass: this '
        "iPhone can't be verified", () async {
      attest.supported = false;
      final coach = model();
      expect(
        failureOf(await replyTo(coach)),
        isA<CoachDeviceNotVerifiedFailure>(),
      );
      expect(
        await coach.checkAvailability(),
        isA<Err<Unit>>().having(
          (e) => e.failure,
          'failure',
          isA<CoachDeviceNotVerifiedFailure>(),
        ),
      );
      expect(proxy.sent, isEmpty);
    });
  });

  group('debug builds (this test run is one)', () {
    test('without App Attest, the dev bypass replaces the attestation '
        'headers, with no challenge', () async {
      attest.supported = false;
      final coach = model(
        config: CoachProxyConfig(baseUrl: _base, devBypassToken: 'dev-token'),
      );
      expect(await coach.checkAvailability(), isA<Ok<Unit>>());
      final events = await replyTo(coach);
      expect(failureOf(events), isNull);
      expect(proxy.challenges, isEmpty);
      final headers = proxy.replyRequests.single.headers;
      expect(headers[CoachProxyWire.devBypassHeader], 'dev-token');
      expect(headers.containsKey(CoachProxyWire.keyIdHeader), isFalse);
      expect(headers.containsKey(CoachProxyWire.assertionHeader), isFalse);
      expect(attest.calls, 0);
    });

    test('a rejected bypass is a server error, not retried', () async {
      attest.supported = false;
      proxy.replies.add(
        (_) => FakeProxy.events(401, [
          sse('error', {'code': 'attestation_failed'}),
        ]),
      );
      final coach = model(
        config: CoachProxyConfig(baseUrl: _base, devBypassToken: 'dev-token'),
      );
      expect(failureOf(await replyTo(coach)), isA<CoachServerFailure>());
      expect(proxy.replyRequests, hasLength(1));
    });

    test('with App Attest, the bypass token is never sent', () async {
      final coach = model(
        config: CoachProxyConfig(baseUrl: _base, devBypassToken: 'dev-token'),
      );
      await replyTo(coach);
      for (final request in proxy.sent) {
        expect(
          request.headers.containsKey(CoachProxyWire.devBypassHeader),
          isFalse,
        );
      }
    });

    test('the Vercel protection bypass goes on every request', () async {
      final coach = model(
        config: CoachProxyConfig(
          baseUrl: _base,
          vercelProtectionBypass: 'vercel-secret',
        ),
      );
      await replyTo(coach);
      expect(proxy.sent.map((r) => r.path), [
        CoachProxyWire.challengePath,
        CoachProxyWire.registerPath,
        CoachProxyWire.challengePath,
        CoachProxyWire.replyPath,
      ]);
      for (final request in proxy.sent) {
        expect(
          request.headers[CoachProxyWire.vercelBypassHeader],
          'vercel-secret',
        );
      }
    });
  });

  group('the key lifecycle, with the real file key store', () {
    late Directory dir;
    late File file;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('app_attest_key');
      file = File('${dir.path}/app_attest_key.json');
      attest = FakeAppAttest(realKeyIds: true);
    });

    tearDown(() => dir.delete(recursive: true));

    HostedCoachModel launch() => HostedCoachModel(
      config: CoachProxyConfig(baseUrl: _base),
      appAttest: attest,
      keyStore: FileAppAttestKeyStore(file),
      consentGiven: () => consent,
      client: proxy,
    );

    test(
      'attests once per install: a relaunch reuses the stored key',
      () async {
        expect(failureOf(await replyTo(launch())), isNull);
        expect(file.existsSync(), isTrue);
        expect(proxy.registrations, hasLength(1));

        // A new model over the same file: the app relaunched.
        expect(failureOf(await replyTo(launch())), isNull);
        expect(proxy.registrations, hasLength(1));
        expect(attest.attested, hasLength(1));
        expect(
          proxy.replyRequests.map((r) => r.headers[CoachProxyWire.keyIdHeader]),
          [FakeAppAttest.realKeyId(1), FakeAppAttest.realKeyId(1)],
        );
      },
    );

    test('attestation_failed replaces the stored key with a new one', () async {
      await replyTo(launch());
      proxy.replies.add(
        (_) => FakeProxy.events(401, [
          sse('error', {'code': 'attestation_failed'}),
        ]),
      );
      expect(failureOf(await replyTo(launch())), isNull);
      expect(proxy.registrations.map((r) => r.json['keyId']), [
        FakeAppAttest.realKeyId(1),
        FakeAppAttest.realKeyId(2),
      ]);

      // The next launch uses the new key, without attesting again.
      await replyTo(launch());
      expect(proxy.registrations, hasLength(2));
      expect(
        proxy.replyRequests.last.headers[CoachProxyWire.keyIdHeader],
        FakeAppAttest.realKeyId(2),
      );
    });

    test('a corrupt key file attests a new key', () async {
      file.writeAsStringSync('{not json');
      expect(failureOf(await replyTo(launch())), isNull);
      expect(proxy.registrations, hasLength(1));
    });
  });

  test('checkAvailability makes no request', () async {
    expect(await model().checkAvailability(), isA<Ok<Unit>>());
    expect(proxy.sent, isEmpty);
    expect(attest.calls, 0);
  });
}
