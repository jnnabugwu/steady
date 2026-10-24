import 'dart:convert';
import 'dart:io';

import 'package:cravings_data/cravings_data.dart';
import 'package:cravings_domain/cravings_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

CravingEvent _event(
  String id,
  DateTime startedAt, {
  Set<CravingReason> reasons = const {},
  CravingOutcome outcome = CravingOutcome.passed,
}) => CravingEvent(
  id: id,
  startedAt: startedAt,
  endedAt: startedAt.add(const Duration(seconds: 95)),
  intensityBefore: 4,
  intensityAfter: 2,
  reasons: reasons,
  tookMinute: true,
  outcome: outcome,
);

T _ok<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => fail('Expected Ok, got $failure'),
};

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cravings_test');
    file = File('${dir.path}/nested/cravings.json');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  final start = DateTime(2026);
  final end = DateTime(2027);

  group('FileCravingRepository', () {
    test('a missing file is an empty store, and nothing is written', () async {
      final repo = FileCravingRepository(file);
      expect(_ok(await repo.getBetween(start, end)), isEmpty);
      expect(file.existsSync(), isFalse);
    });

    test('round-trips every field through the file', () async {
      final events = [
        _event(
          'a',
          DateTime(2026, 10, 20, 18, 30, 5, 123, 456),
          reasons: {CravingReason.stressed, CravingReason.tired},
        ),
        CravingEvent(
          id: 'b',
          startedAt: DateTime(2026, 10, 21, 9),
          intensityBefore: 5,
          reasons: CravingReason.values.toSet(),
          tookMinute: false,
          outcome: CravingOutcome.hungry,
        ),
      ];
      final writer = FileCravingRepository(file);
      for (final e in events.reversed) {
        _ok(await writer.save(e));
      }

      // A fresh instance can only see them through the file.
      final reader = FileCravingRepository(file);
      expect(_ok(await reader.getBetween(start, end)), events);
    });

    test('stores no food, calories or notes: only the listed fields', () async {
      await FileCravingRepository(file).save(_event('a', DateTime(2026, 5)));
      final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      final entry = (json['cravings']! as List<Object?>).single! as Map;
      expect(entry.keys.toSet(), {
        'id',
        'startedAt',
        'endedAt',
        'intensityBefore',
        'intensityAfter',
        'reasons',
        'tookMinute',
        'outcome',
      });
      expect(json['version'], 1);
    });

    test('save replaces an event with the same id', () async {
      final repo = FileCravingRepository(file);
      final first = _event('a', DateTime(2026, 5));
      _ok(await repo.save(first));
      _ok(await repo.save(first.copyWith(outcome: CravingOutcome.notSure)));

      final stored = _ok(
        await FileCravingRepository(file).getBetween(start, end),
      );
      expect(stored.single.outcome, CravingOutcome.notSure);
    });

    test(
      'getBetween is start-inclusive, end-exclusive, oldest first',
      () async {
        final repo = FileCravingRepository(file);
        for (final e in [
          _event('late', DateTime(2026, 10, 24)),
          _event('in2', DateTime(2026, 10, 23, 23, 59)),
          _event('in1', DateTime(2026, 10, 17)),
          _event('early', DateTime(2026, 10, 16, 23, 59)),
        ]) {
          _ok(await repo.save(e));
        }
        final window = _ok(
          await repo.getBetween(DateTime(2026, 10, 17), DateTime(2026, 10, 24)),
        );
        expect(window.map((e) => e.id), ['in1', 'in2']);
      },
    );

    test('rejects an intensity outside 1 to 5 and writes nothing', () async {
      final repo = FileCravingRepository(file);
      final bad = _BadIntensityEvent();
      final result = await repo.save(bad);
      expect(
        result,
        isA<Err<Unit>>().having(
          (e) => e.failure,
          'failure',
          isA<ValidationFailure>(),
        ),
      );
      expect(file.existsSync(), isFalse);
    });

    group('a corrupt file', () {
      const garbage = '{"version": 1, "cravings": [ not json';

      setUp(() {
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(garbage);
      });

      test(
        'returns Err from reads and saves, and is never overwritten',
        () async {
          final repo = FileCravingRepository(file);
          expect(
            await repo.getBetween(start, end),
            isA<Err<List<CravingEvent>>>(),
          );
          expect(
            await repo.save(_event('a', DateTime(2026, 5))),
            isA<Err<Unit>>().having(
              (e) => e.failure,
              'failure',
              isA<UnknownFailure>(),
            ),
          );
          expect(file.readAsStringSync(), garbage);
        },
      );

      test('an unknown enum name or bad intensity counts as corrupt', () async {
        for (final entry in [
          {..._validEntry, 'outcome': 'resisted'},
          {
            ..._validEntry,
            'reasons': ['hangry'],
          },
          {..._validEntry, 'intensityBefore': 9},
        ]) {
          final contents = jsonEncode({
            'version': 1,
            'cravings': [entry],
          });
          file.writeAsStringSync(contents);
          final result = await FileCravingRepository(
            file,
          ).getBetween(start, end);
          expect(result, isA<Err<List<CravingEvent>>>(), reason: '$entry');
          expect(file.readAsStringSync(), contents);
        }
      });

      test('recovers on the next call once the file is fixed', () async {
        final repo = FileCravingRepository(file);
        expect(
          await repo.getBetween(start, end),
          isA<Err<List<CravingEvent>>>(),
        );

        file.writeAsStringSync(
          jsonEncode({
            'version': 1,
            'cravings': [_validEntry],
          }),
        );
        expect(_ok(await repo.getBetween(start, end)), hasLength(1));
      });

      test('deleteAll still deletes it', () async {
        final repo = FileCravingRepository(file);
        _ok(await repo.deleteAll());
        expect(file.existsSync(), isFalse);
        expect(_ok(await repo.getBetween(start, end)), isEmpty);
      });
    });

    test('concurrent saves are serialized and none is lost', () async {
      final repo = FileCravingRepository(file);
      final results = await Future.wait([
        for (var i = 0; i < 25; i++)
          repo.save(_event('e$i', DateTime(2026, 10, 1, 0, i))),
      ]);
      expect(results, everyElement(isA<Ok<Unit>>()));

      final stored = _ok(
        await FileCravingRepository(file).getBetween(start, end),
      );
      expect(stored.map((e) => e.id), [for (var i = 0; i < 25; i++) 'e$i']);
      expect(File('${file.path}.tmp').existsSync(), isFalse);
    });

    test('deleteAll removes every event, from memory and disk', () async {
      final repo = FileCravingRepository(file);
      _ok(await repo.save(_event('a', DateTime(2026, 5))));
      _ok(await repo.save(_event('b', DateTime(2026, 6))));

      _ok(await repo.deleteAll());

      expect(file.existsSync(), isFalse);
      expect(_ok(await repo.getBetween(start, end)), isEmpty);
      expect(
        _ok(await FileCravingRepository(file).getBetween(start, end)),
        isEmpty,
      );
    });

    test('deleteAll queued behind a save runs after it', () async {
      final repo = FileCravingRepository(file);
      final saving = repo.save(_event('a', DateTime(2026, 5)));
      final deleting = repo.deleteAll();
      _ok(await saving);
      _ok(await deleting);
      expect(_ok(await repo.getBetween(start, end)), isEmpty);
    });

    test('a write failure returns Err and leaves memory unchanged', () async {
      // The file's parent is a regular file, so nothing can be written.
      final blocker = File('${dir.path}/blocker')..writeAsStringSync('x');
      final repo = FileCravingRepository(File('${blocker.path}/cravings.json'));
      expect(await repo.save(_event('a', DateTime(2026, 5))), isA<Err<Unit>>());
      expect(_ok(await repo.getBetween(start, end)), isEmpty);
    });

    test(
      'locatedBy finds the file lazily, and a failed lookup is retried',
      () async {
        var calls = 0;
        final repo = FileCravingRepository.locatedBy(() async {
          calls++;
          if (calls == 1) throw const FileSystemException('no support dir');
          return file;
        });
        expect(calls, 0);
        expect(
          await repo.getBetween(start, end),
          isA<Err<List<CravingEvent>>>(),
        );
        _ok(await repo.save(_event('a', DateTime(2026, 5))));
        expect(calls, 2);
        expect(file.existsSync(), isTrue);
      },
    );
  });
}

const _validEntry = <String, Object?>{
  'id': 'x',
  'startedAt': '2026-10-20T18:00:00.000Z',
  'intensityBefore': 3,
  'reasons': ['bored'],
  'tookMinute': false,
  'outcome': 'notSure',
};

/// An event whose intensity bypasses the constructor's assert (asserts are
/// debug-only, so release builds could construct one).
class _BadIntensityEvent implements CravingEvent {
  @override
  String get id => 'bad';
  @override
  DateTime get startedAt => DateTime(2026, 5);
  @override
  DateTime? get endedAt => null;
  @override
  int get intensityBefore => 0;
  @override
  int? get intensityAfter => null;
  @override
  Set<CravingReason> get reasons => const {};
  @override
  bool get tookMinute => false;
  @override
  CravingOutcome get outcome => CravingOutcome.notSure;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
