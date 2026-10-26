import 'dart:convert';
import 'dart:io';

import 'package:coach_data/coach_data.dart';
import 'package:coach_domain/coach_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

CoachSession _session(
  String id,
  DateTime startedAt, {
  CoachSessionKind kind = CoachSessionKind.chat,
  String? summary,
  List<CoachMessage> messages = const [],
}) => CoachSession(
  id: id,
  kind: kind,
  startedAt: startedAt,
  summary: summary,
  messages: messages,
);

T _ok<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => fail('Expected Ok, got $failure'),
};

Matcher _errOf<T, F extends Failure>() =>
    isA<Err<T>>().having((e) => e.failure, 'failure', isA<F>());

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('coach_test');
    file = File('${dir.path}/nested/coach_sessions.json');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  group('FileCoachRepository', () {
    test('a missing file is an empty store, and nothing is written', () async {
      final repo = FileCoachRepository(file);
      expect(_ok(await repo.listSessions()), isEmpty);
      expect(_ok(await repo.getSession('a')), isNull);
      expect(file.existsSync(), isFalse);
    });

    test('round-trips every field through the file', () async {
      final weeklyStart = DateTime(2026, 10, 23, 19, 0, 5, 123, 456);
      final sessions = [
        CoachSession(
          id: 'weekly',
          kind: CoachSessionKind.weekly,
          startedAt: weeklyStart,
          endedAt: weeklyStart.add(const Duration(minutes: 15)),
          summary: 'Steps were steady; two "partial" days, both Thursdays.',
          messages: [
            CoachMessage(
              role: CoachMessageRole.coach,
              text: 'How did the week feel?',
              at: weeklyStart,
            ),
            CoachMessage(
              role: CoachMessageRole.user,
              text: 'Busy.\nBut okay, I think — ✓',
              at: weeklyStart.add(const Duration(seconds: 40)),
            ),
          ],
        ),
        // Open, no summary, no messages yet.
        _session('chat', DateTime(2026, 10, 20, 8)),
      ];
      final writer = FileCoachRepository(file);
      for (final s in sessions.reversed) {
        _ok(await writer.saveSession(s));
      }

      // A fresh instance can only see them through the file.
      final reader = FileCoachRepository(file);
      expect(_ok(await reader.listSessions()), sessions);
      expect(_ok(await reader.getSession('weekly')), sessions.first);
    });

    test('writes the documented shape: UTC times, enums by name, no '
        'null keys', () async {
      final at = DateTime.utc(2026, 10, 23, 1);
      await FileCoachRepository(file).saveSession(
        _session(
          'a',
          at.toLocal(),
          messages: [
            CoachMessage(role: CoachMessageRole.user, text: 'hi', at: at),
          ],
        ),
      );
      final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      expect(json['version'], 1);
      final entry = (json['sessions']! as List<Object?>).single! as Map;
      expect(entry, {
        'id': 'a',
        'kind': 'chat',
        'startedAt': '2026-10-23T01:00:00.000Z',
        'messages': [
          {'role': 'user', 'text': 'hi', 'at': '2026-10-23T01:00:00.000Z'},
        ],
      });
    });

    test('listSessions is newest first, ties by id', () async {
      final repo = FileCoachRepository(file);
      for (final s in [
        _session('old', DateTime(2026, 9, 30)),
        _session('b', DateTime(2026, 10, 20)),
        _session('new', DateTime(2026, 10, 23)),
        _session('a', DateTime(2026, 10, 20)),
      ]) {
        _ok(await repo.saveSession(s));
      }
      expect(_ok(await repo.listSessions()).map((s) => s.id), [
        'new',
        'a',
        'b',
        'old',
      ]);
      expect(
        _ok(await FileCoachRepository(file).listSessions()).map((s) => s.id),
        ['new', 'a', 'b', 'old'],
      );
    });

    test('saveSession replaces a session with the same id', () async {
      final repo = FileCoachRepository(file);
      final first = _session('a', DateTime(2026, 10, 23, 19));
      _ok(await repo.saveSession(first));
      final grown = first.copyWith(
        endedAt: DateTime(2026, 10, 23, 19, 15),
        summary: 'Short and calm.',
        messages: [
          CoachMessage(
            role: CoachMessageRole.coach,
            text: 'Hi',
            at: DateTime(2026, 10, 23, 19),
          ),
        ],
      );
      _ok(await repo.saveSession(grown));

      final stored = _ok(await FileCoachRepository(file).listSessions());
      expect(stored, [grown]);
    });

    test('getSession finds one by id, or Ok(null)', () async {
      final repo = FileCoachRepository(file);
      final a = _session('a', DateTime(2026, 10, 3));
      _ok(await repo.saveSession(a));
      _ok(await repo.saveSession(_session('b', DateTime(2026, 10, 2))));
      expect(_ok(await repo.getSession('a')), a);
      expect(_ok(await repo.getSession('missing')), isNull);
    });

    test('rejects an invalid session and writes nothing', () async {
      final repo = FileCoachRepository(file);
      final start = DateTime(2026, 10, 23, 19);
      for (final bad in [
        _session('', start),
        _session(
          'a',
          start,
        ).copyWith(endedAt: start.subtract(const Duration(minutes: 1))),
      ]) {
        expect(
          await repo.saveSession(bad),
          _errOf<Unit, ValidationFailure>(),
          reason: '$bad',
        );
      }
      expect(file.existsSync(), isFalse);
      expect(_ok(await repo.listSessions()), isEmpty);
    });

    group('a corrupt file', () {
      const garbage = '{"version": 1, "sessions": [ not json';

      setUp(() {
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(garbage);
      });

      test('returns Err from every read and save, and is never '
          'overwritten', () async {
        final repo = FileCoachRepository(file);
        expect(
          await repo.listSessions(),
          _errOf<List<CoachSession>, CoachHistoryUnreadableFailure>(),
        );
        expect(
          await repo.getSession('a'),
          _errOf<CoachSession?, CoachHistoryUnreadableFailure>(),
        );
        expect(
          await repo.saveSession(_session('a', DateTime(2026, 5))),
          _errOf<Unit, CoachHistoryUnreadableFailure>(),
        );
        expect(file.readAsStringSync(), garbage);
      });

      test('an unknown enum, missing field or bad time counts as '
          'corrupt', () async {
        for (final contents in [
          {
            'version': 1,
            'sessions': [
              {..._validEntry, 'kind': 'therapy'},
            ],
          },
          {
            'version': 1,
            'sessions': [
              {
                ..._validEntry,
                'messages': [
                  {'role': 'system', 'text': 'x', 'at': _validTime},
                ],
              },
            ],
          },
          {
            'version': 1,
            'sessions': [
              {..._validEntry}..remove('messages'),
            ],
          },
          {
            'version': 1,
            'sessions': [
              {..._validEntry, 'startedAt': 'last Friday'},
            ],
          },
          {
            'version': 2,
            'sessions': [_validEntry],
          },
          {'version': 1, 'cravings': <Object?>[]},
          // A session `saveSession` would have rejected is corrupt too:
          // this app can't have written it, so it isn't history.
          {
            'version': 1,
            'sessions': [
              {..._validEntry, 'id': ''},
            ],
          },
          {
            'version': 1,
            'sessions': [
              {..._validEntry, 'endedAt': '2026-10-22T00:00:00.000Z'},
            ],
          },
        ]) {
          final encoded = jsonEncode(contents);
          file.writeAsStringSync(encoded);
          final result = await FileCoachRepository(file).listSessions();
          expect(
            result,
            _errOf<List<CoachSession>, CoachHistoryUnreadableFailure>(),
            reason: encoded,
          );
          expect(file.readAsStringSync(), encoded);
        }
      });

      test('recovers on the next call once the file is fixed', () async {
        final repo = FileCoachRepository(file);
        expect(await repo.listSessions(), isA<Err<List<CoachSession>>>());

        file.writeAsStringSync(
          jsonEncode({
            'version': 1,
            'sessions': [_validEntry],
          }),
        );
        expect(_ok(await repo.listSessions()), hasLength(1));
      });

      test('deleteAll still deletes it', () async {
        final repo = FileCoachRepository(file);
        _ok(await repo.deleteAll());
        expect(file.existsSync(), isFalse);
        expect(_ok(await repo.listSessions()), isEmpty);
      });
    });

    test('concurrent saves are serialized and none is lost', () async {
      final repo = FileCoachRepository(file);
      final results = await Future.wait([
        for (var i = 0; i < 25; i++)
          repo.saveSession(_session('s$i', DateTime(2026, 10, 1, 0, i))),
      ]);
      expect(results, everyElement(isA<Ok<Unit>>()));

      final stored = _ok(await FileCoachRepository(file).listSessions());
      expect(stored.map((s) => s.id), [for (var i = 24; i >= 0; i--) 's$i']);
      expect(File('${file.path}.tmp').existsSync(), isFalse);
    });

    test('concurrent saves of one growing session keep the last', () async {
      final repo = FileCoachRepository(file);
      final base = _session('a', DateTime(2026, 10, 23, 19));
      final at = DateTime(2026, 10, 23, 19);
      await Future.wait([
        for (var i = 1; i <= 10; i++)
          repo.saveSession(
            base.copyWith(
              messages: [
                for (var j = 0; j < i; j++)
                  CoachMessage(role: CoachMessageRole.user, text: '$j', at: at),
              ],
            ),
          ),
      ]);
      final stored = _ok(await FileCoachRepository(file).listSessions());
      expect(stored.single.messages, hasLength(10));
    });

    test('deleteAll removes every session, from memory and disk', () async {
      final repo = FileCoachRepository(file);
      _ok(await repo.saveSession(_session('a', DateTime(2026, 5))));
      _ok(await repo.saveSession(_session('b', DateTime(2026, 6))));

      _ok(await repo.deleteAll());

      expect(file.existsSync(), isFalse);
      expect(_ok(await repo.listSessions()), isEmpty);
      expect(_ok(await FileCoachRepository(file).listSessions()), isEmpty);
    });

    test('deleteAll also removes a leftover temp file', () async {
      final tmp = File('${file.path}.tmp');
      tmp.parent.createSync(recursive: true);
      tmp.writeAsStringSync('half-written');
      _ok(await FileCoachRepository(file).deleteAll());
      expect(tmp.existsSync(), isFalse);
    });

    test('deleteAll queued behind a save runs after it', () async {
      final repo = FileCoachRepository(file);
      final saving = repo.saveSession(_session('a', DateTime(2026, 5)));
      final deleting = repo.deleteAll();
      _ok(await saving);
      _ok(await deleting);
      expect(_ok(await repo.listSessions()), isEmpty);
    });

    test('a write failure returns Err and leaves memory unchanged', () async {
      // The file's parent is a regular file, so nothing can be written.
      final blocker = File('${dir.path}/blocker')..writeAsStringSync('x');
      final repo = FileCoachRepository(
        File('${blocker.path}/coach_sessions.json'),
      );
      expect(
        await repo.saveSession(_session('a', DateTime(2026, 5))),
        _errOf<Unit, CoachHistoryStorageFailure>(),
      );
      expect(_ok(await repo.listSessions()), isEmpty);
    });

    test('a list is a snapshot: later saves do not change it', () async {
      final repo = FileCoachRepository(file);
      _ok(await repo.saveSession(_session('a', DateTime(2026, 5))));
      final before = _ok(await repo.listSessions());
      _ok(await repo.saveSession(_session('b', DateTime(2026, 6))));
      expect(before.map((s) => s.id), ['a']);
      expect(() => before.add(before.first), throwsUnsupportedError);
    });

    test(
      'locatedBy finds the file lazily, and a failed lookup is retried',
      () async {
        var calls = 0;
        final repo = FileCoachRepository.locatedBy(() async {
          calls++;
          if (calls == 1) throw const FileSystemException('no support dir');
          return file;
        });
        expect(calls, 0);
        expect(
          await repo.listSessions(),
          _errOf<List<CoachSession>, CoachHistoryStorageFailure>(),
        );
        _ok(await repo.saveSession(_session('a', DateTime(2026, 5))));
        expect(calls, 2);
        expect(file.existsSync(), isTrue);
      },
    );
  });
}

const _validTime = '2026-10-23T00:00:00.000Z';

const _validEntry = <String, Object?>{
  'id': 'x',
  'kind': 'weekly',
  'startedAt': _validTime,
  'summary': 'A calm week.',
  'messages': [
    {'role': 'coach', 'text': 'Hi', 'at': _validTime},
  ],
};
