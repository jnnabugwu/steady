import 'dart:async';
import 'dart:io';

import 'package:coach_data/coach_data.dart';
import 'package:coach_domain/coach_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/early_coach_offer.dart';
import 'package:steady/providers.dart';
import 'package:subscription_data/subscription_data.dart';
import 'package:subscription_domain/subscription_domain.dart';
import 'package:subscription_domain/testing/in_memory_early_coach_user_repository.dart';
import 'package:subscription_presentation/subscription_presentation.dart';

/// Two weeks free for people who used the coach on 1.0 (#188): the flag,
/// decided once from `coach_sessions.json`, through the real file stores.
///
/// The sessions file here is written by today's `FileCoachRepository`, not
/// by a 1.0 build: that 1.1.0 reads 1.0's file as-is is from the code (the
/// codec is unchanged since before 1.0), to confirm on a phone updated
/// from 1.0 (#185).
void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('early_coach'));
  tearDown(() => dir.deleteSync(recursive: true));

  File sessionsFile() => File('${dir.path}/coach_sessions.json');
  File flagFile() => File('${dir.path}/early_coach_offer.json');

  final session = CoachSession(
    id: 'from-1.0',
    kind: CoachSessionKind.chat,
    startedAt: DateTime(2026, 11, 10, 20),
    summary: 'A chat on 1.0.',
  );

  // The first 1.1.0 launch, after the session above.
  final launchedAt = DateTime(2026, 11, 18, 9);

  Future<bool?> launch() => recordEarlyCoachUser(
    flag: FileEarlyCoachUserRepository(flagFile()),
    coach: FileCoachRepository(sessionsFile()),
    launchedAt: launchedAt,
  );

  test('an updated phone with a coach session gets the offer', () async {
    await FileCoachRepository(sessionsFile()).saveSession(session);
    expect(await launch(), isTrue);
    expect(
      await FileEarlyCoachUserRepository(flagFile()).read(),
      isA<Ok<bool?>>().having((o) => o.value, 'value', isTrue),
    );
  });

  test('no coach_sessions.json (a new install): no offer', () async {
    expect(await launch(), isFalse);
  });

  test('an empty coach_sessions.json: no offer', () async {
    final coach = FileCoachRepository(sessionsFile());
    await coach.saveSession(session);
    await coach.deleteAll();
    expect(await launch(), isFalse);
  });

  test('decided once: sessions added later never give the offer', () async {
    expect(await launch(), isFalse);
    await FileCoachRepository(sessionsFile()).saveSession(session);
    expect(await launch(), isFalse);
  });

  test('decided once: deleting coach history later keeps it', () async {
    await FileCoachRepository(sessionsFile()).saveSession(session);
    expect(await launch(), isTrue);
    await FileCoachRepository(sessionsFile()).deleteAll();
    expect(await launch(), isTrue);
  });

  test('once decided, the sessions are not read again', () async {
    final flag = InMemoryEarlyCoachUserRepository(decided: false);
    final coach = _CountingCoach();
    expect(
      await recordEarlyCoachUser(
        flag: flag,
        coach: coach,
        launchedAt: launchedAt,
      ),
      isFalse,
    );
    expect(coach.reads, 0);
  });

  test(
    'a coach_sessions.json that can not be decoded counts as used',
    () async {
      sessionsFile().writeAsStringSync('{"not": "sessions"');
      expect(await launch(), isTrue);
    },
  );

  test(
    'a storage error decides nothing; the next launch tries again',
    () async {
      final flag = InMemoryEarlyCoachUserRepository();
      final failing = _CountingCoach(
        answer: const Err(CoachHistoryStorageFailure('disk')),
      );
      expect(
        await recordEarlyCoachUser(
          flag: flag,
          coach: failing,
          launchedAt: launchedAt,
        ),
        isNull,
      );
      expect(flag.decided, isNull);

      final working = _CountingCoach(answer: Ok([session]));
      expect(
        await recordEarlyCoachUser(
          flag: flag,
          coach: working,
          launchedAt: launchedAt,
        ),
        isTrue,
      );
    },
  );

  group('a check that finishes after the app started', () {
    // main.dart's timeout doesn't cancel the check, so its read can come
    // back after 1.1.0 has made a session of its own.
    final madeThisLaunch = session.copyWith(
      id: 'from-1.1.0',
      startedAt: launchedAt.add(const Duration(seconds: 30)),
    );

    test('does not count a session made in this launch', () async {
      await FileCoachRepository(sessionsFile()).saveSession(madeThisLaunch);
      expect(await launch(), isFalse);
      expect(
        await FileEarlyCoachUserRepository(flagFile()).read(),
        isA<Ok<bool?>>().having((o) => o.value, 'value', isFalse),
      );
    });

    test('still counts a session from before it', () async {
      final coach = FileCoachRepository(sessionsFile());
      await coach.saveSession(session);
      await coach.saveSession(madeThisLaunch);
      expect(await launch(), isTrue);
    });

    test("through main.dart's timeout: decides later, from before the "
        'launch', () async {
      final flag = InMemoryEarlyCoachUserRepository();
      final reply = Completer<Result<List<CoachSession>>>();
      final slow = _CountingCoach(reply: reply.future);
      final check = recordEarlyCoachUser(
        flag: flag,
        coach: slow,
        launchedAt: launchedAt,
      );
      await expectLater(
        check.timeout(const Duration(milliseconds: 10)),
        throwsA(isA<TimeoutException>()),
      );
      // The app has started and made a session; then the read returns.
      reply.complete(Ok([madeThisLaunch]));
      expect(await check, isFalse);
      expect(flag.decided, isFalse);
    });
  });

  test('a flag that can not be read decides nothing', () async {
    final flag = InMemoryEarlyCoachUserRepository()
      ..failNextWith = const EarlyCoachUserStorageFailure('disk');
    final coach = _CountingCoach(answer: Ok([session]));
    expect(
      await recordEarlyCoachUser(
        flag: flag,
        coach: coach,
        launchedAt: launchedAt,
      ),
      isNull,
    );
    expect(flag.decided, isNull);
    expect(coach.reads, 0);
  });

  group('the binding', () {
    test('iOS binds the file store, and this build has no offer code', () {
      final ios = ProviderContainer.test(
        overrides: appProviderOverridesFor(isIOS: true),
      );
      expect(
        ios.read(earlyCoachUserRepositoryProvider),
        isA<FileEarlyCoachUserRepository>(),
      );
      // No --dart-define=EARLY_COACH_OFFER_CODE in tests: no offer shown.
      expect(ios.read(earlyCoachOfferCodeProvider), isEmpty);
    });

    test('the Mac binds no flag', () {
      final mac = ProviderContainer.test(
        overrides: appProviderOverridesFor(isIOS: false),
      );
      expect(mac.read(earlyCoachUserRepositoryProvider), isNull);
    });
  });
}

class _CountingCoach implements CoachRepository {
  _CountingCoach({this.answer = const Ok([]), this.reply});

  final Result<List<CoachSession>> answer;

  /// When set, what [listSessions] waits for instead of [answer].
  final Future<Result<List<CoachSession>>>? reply;
  int reads = 0;

  @override
  ResultFuture<List<CoachSession>> listSessions() async {
    reads++;
    return await (reply ?? Future.value(answer));
  }

  @override
  ResultFuture<CoachSession?> getSession(String id) async => const Ok(null);

  @override
  ResultFuture<Unit> saveSession(CoachSession session) async => const Ok(unit);

  @override
  ResultFuture<Unit> deleteAll() async => const Ok(unit);
}
