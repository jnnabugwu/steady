import 'dart:convert';
import 'dart:io';

import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onboarding_data/onboarding_data.dart';
import 'package:onboarding_domain/onboarding_domain.dart';

T _ok<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => fail('Expected Ok, got $failure'),
};

Failure _err<T>(Result<T> result) => switch (result) {
  Ok(:final value) => fail('Expected Err, got Ok($value)'),
  Err(:final failure) => failure,
};

const _answers = AboutMe(
  voice: CoachVoice.gentle,
  tracking: FoodTracking.calAi,
  activities: {OnboardingActivity.tennis, OnboardingActivity.walks},
  weekends: WeekendShape.busier,
  hardParts: {HardPart.eatingOut, HardPart.lateNights},
  note: 'I work nights twice a month',
);

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('onboarding_test');
    file = File('${dir.path}/nested/onboarding.json');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Map<String, Object?> onDisk() =>
      jsonDecode(file.readAsStringSync()) as Map<String, Object?>;

  void write(Object? json) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(json));
  }

  Map<String, Object?> validFile({
    Object? schemaVersion = 1,
    Object? completed = true,
    Map<String, Object?>? aboutMe,
  }) => {
    'schemaVersion': schemaVersion,
    'completed': completed,
    'aboutMe': aboutMe ?? encodeAboutMe(_answers),
  };

  group('a missing file', () {
    test('is a first launch, and nothing is written', () async {
      final repo = FileOnboardingRepository(file);
      expect(_ok(await repo.read()), OnboardingRecord.initial);
      expect(file.existsSync(), isFalse);
      expect(file.parent.existsSync(), isFalse);
    });

    test('a write creates it, parent directories included', () async {
      await FileOnboardingRepository(file).markCompleted();
      expect(file.existsSync(), isTrue);
    });
  });

  group('the file', () {
    test('is the shape in the design doc, with a schemaVersion', () async {
      // Pins our own format: the `aboutMe` object is the design doc's
      // example ("About me, as the proxy will receive it") verbatim, but
      // the proxy doesn't read it yet, so whether the proxy accepts this
      // shape is still an assumption.
      final repo = FileOnboardingRepository(file);
      await repo.saveAboutMe(_answers);
      await repo.markCompleted();
      expect(onDisk(), {
        'schemaVersion': 1,
        'completed': true,
        'aboutMe': {
          'voice': 'gentle',
          'tracking': 'calAi',
          'activities': ['tennis', 'walks'],
          'weekends': 'busier',
          'hardParts': ['eatingOut', 'lateNights'],
          'note': 'I work nights twice a month',
        },
      });
    });

    test('leaves out skipped single answers; skipped lists are []', () async {
      await FileOnboardingRepository(file).saveAboutMe(AboutMe.empty);
      expect(onDisk(), {
        'schemaVersion': 1,
        'completed': false,
        'aboutMe': {'activities': <Object?>[], 'hardParts': <Object?>[]},
      });
    });

    test('writes lists in declaration order, whatever the set order', () async {
      await FileOnboardingRepository(file).saveAboutMe(
        const AboutMe(
          activities: {OnboardingActivity.yoga, OnboardingActivity.gym},
          hardParts: {HardPart.travel, HardPart.eatingOut},
        ),
      );
      final aboutMe = onDisk()['aboutMe']! as Map<String, Object?>;
      expect(aboutMe['activities'], ['gym', 'yoga']);
      expect(aboutMe['hardParts'], ['eatingOut', 'travel']);
    });

    test('holds nothing but the listed fields', () async {
      // Screen 3's "Where did you hear about Steady?" is an analytics event
      // only; nothing about it, or any body or goal answer, is stored.
      final repo = FileOnboardingRepository(file);
      await repo.saveAboutMe(_answers);
      await repo.markCompleted();
      expect(onDisk().keys, {'schemaVersion', 'completed', 'aboutMe'});
      expect((onDisk()['aboutMe']! as Map<String, Object?>).keys, {
        'voice',
        'tracking',
        'activities',
        'weekends',
        'hardParts',
        'note',
      });
    });

    test('leaves no .tmp behind after a write', () async {
      await FileOnboardingRepository(file).saveAboutMe(_answers);
      expect(File('${file.path}.tmp').existsSync(), isFalse);
    });
  });

  group('persists across a new instance (an app restart)', () {
    test('About me round-trips through the file', () async {
      await FileOnboardingRepository(file).saveAboutMe(_answers);
      // A fresh instance can only see it through the file.
      expect(
        _ok(await FileOnboardingRepository(file).read()),
        const OnboardingRecord(aboutMe: _answers),
      );
    });

    test('completion persists', () async {
      await FileOnboardingRepository(file).markCompleted();
      expect(
        _ok(await FileOnboardingRepository(file).read()).completed,
        isTrue,
      );
    });

    test(
      'editing About me later, in a new instance, keeps it completed',
      () async {
        final onboarding = FileOnboardingRepository(file);
        await onboarding.saveAboutMe(_answers);
        await onboarding.markCompleted();

        // Days later, Settings → About me.
        const edited = AboutMe(voice: CoachVoice.direct);
        final saved = _ok(
          await FileOnboardingRepository(file).saveAboutMe(edited),
        );
        expect(saved, const OnboardingRecord(completed: true, aboutMe: edited));
        expect(_ok(await FileOnboardingRepository(file).read()), saved);
      },
    );

    test('a note at the limit survives, emoji and all', () async {
      final note = '🎾 ${'é' * 50}${'😀' * (aboutMeNoteMaxChars - 52)}';
      expect(note.runes.length, aboutMeNoteMaxChars);
      await FileOnboardingRepository(file).saveAboutMe(AboutMe(note: note));
      expect(
        _ok(await FileOnboardingRepository(file).read()).aboutMe.note,
        note,
      );
    });
  });

  group('a corrupt file', () {
    final corrupt = <String, Object? Function()>{
      'not JSON': () => '{"schemaVersion": 1, "complet',
      'JSON, not an object': () => ['schemaVersion', 1],
      'no schemaVersion': () => {
        'completed': true,
        'aboutMe': <String, Object?>{},
      },
      'schemaVersion 0': () => validFile(schemaVersion: 0),
      'schemaVersion as a string': () => validFile(schemaVersion: '1'),
      'no completed': () => {
        'schemaVersion': 1,
        'aboutMe': <String, Object?>{},
      },
      'completed as a string': () => validFile(completed: 'yes'),
      'no aboutMe': () => {'schemaVersion': 1, 'completed': true},
      'aboutMe as a list': () => {
        'schemaVersion': 1,
        'completed': true,
        'aboutMe': <Object?>[],
      },
      'a code as a number': () => validFile(aboutMe: {'voice': 2}),
      'a list as a string': () => validFile(aboutMe: {'activities': 'gym'}),
      'a number in a list': () => validFile(
        aboutMe: {
          'hardParts': ['travel', 3],
        },
      ),
      'note as a number': () => validFile(aboutMe: {'note': 42}),
    };

    for (final MapEntry(key: name, value: contents) in corrupt.entries) {
      test('$name: read is Err(OnboardingUnreadableFailure)', () async {
        final json = contents();
        if (json is String) {
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(json);
        } else {
          write(json);
        }
        final before = file.readAsBytesSync();

        expect(
          _err(await FileOnboardingRepository(file).read()),
          isA<OnboardingUnreadableFailure>(),
        );
        // A read never touches it.
        expect(file.readAsBytesSync(), before);
      });
    }

    test('invalid UTF-8 is unreadable too', () async {
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync([0x7b, 0xff, 0xfe, 0x7d]);
      expect(
        _err(await FileOnboardingRepository(file).read()),
        isA<OnboardingUnreadableFailure>(),
      );
    });

    test('an empty file is unreadable', () async {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('');
      expect(
        _err(await FileOnboardingRepository(file).read()),
        isA<OnboardingUnreadableFailure>(),
      );
    });

    test('saveAboutMe replaces it, starting from a first launch', () async {
      // Our decision, not a platform fact: nothing in a corrupt file can be
      // read, and keeping it would block every later write. "completed"
      // can't be known, so it's false (onboarding may show once more).
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('not json');
      final repo = FileOnboardingRepository(file);
      expect(
        _ok(await repo.saveAboutMe(_answers)),
        const OnboardingRecord(aboutMe: _answers),
      );
      expect(
        _ok(await FileOnboardingRepository(file).read()).aboutMe,
        _answers,
      );
    });

    test('markCompleted replaces it, with nothing answered', () async {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('not json');
      expect(
        _ok(await FileOnboardingRepository(file).markCompleted()),
        const OnboardingRecord(completed: true),
      );
      expect(
        _ok(await FileOnboardingRepository(file).read()),
        const OnboardingRecord(completed: true),
      );
    });

    test('a read recovers once the file is fixed', () async {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('not json');
      final repo = FileOnboardingRepository(file);
      expect(_err(await repo.read()), isA<OnboardingUnreadableFailure>());

      write(validFile());
      expect(
        _ok(await repo.read()),
        const OnboardingRecord(completed: true, aboutMe: _answers),
      );
    });
  });

  group('a newer Steady wrote it (forward compatible)', () {
    test('unknown single codes read as skipped', () async {
      write(
        validFile(
          aboutMe: {
            'voice': 'sarcastic',
            'tracking': 'myFitnessPal',
            'weekends': 'nonexistent',
          },
        ),
      );
      final aboutMe = _ok(await FileOnboardingRepository(file).read()).aboutMe;
      expect(aboutMe.voice, isNull);
      expect(aboutMe.tracking, isNull);
      expect(aboutMe.weekends, isNull);
    });

    test('unknown codes in a list are dropped, known ones kept', () async {
      write(
        validFile(
          aboutMe: {
            'activities': ['pickleball', 'tennis', 'climbing', 'yoga'],
            'hardParts': ['shiftWork', 'travel'],
          },
        ),
      );
      final aboutMe = _ok(await FileOnboardingRepository(file).read()).aboutMe;
      expect(aboutMe.activities, {
        OnboardingActivity.tennis,
        OnboardingActivity.yoga,
      });
      expect(aboutMe.hardParts, {HardPart.travel});
    });

    test('codes are case-sensitive: "CalAi" is unknown', () async {
      // Encodes our own choice: codes match `name` exactly.
      write(validFile(aboutMe: {'tracking': 'CalAi'}));
      expect(
        _ok(await FileOnboardingRepository(file).read()).aboutMe.tracking,
        isNull,
      );
    });

    test('a higher schemaVersion and unknown keys are read anyway', () async {
      write({
        ...validFile(schemaVersion: 2),
        'completedAt': '2027-01-01T00:00:00Z',
        'aboutMe': {...encodeAboutMe(_answers), 'pronouns': 'they'},
      });
      expect(
        _ok(await FileOnboardingRepository(file).read()),
        const OnboardingRecord(completed: true, aboutMe: _answers),
      );
    });

    test('missing and null answers read as skipped', () async {
      write(
        validFile(aboutMe: {'voice': null, 'activities': null, 'note': null}),
      );
      expect(
        _ok(await FileOnboardingRepository(file).read()).aboutMe,
        AboutMe.empty,
      );
    });

    test('a note over the limit is cut to it, by code point', () async {
      write(validFile(aboutMe: {'note': '😀' * (aboutMeNoteMaxChars + 20)}));
      expect(
        _ok(await FileOnboardingRepository(file).read()).aboutMe.note,
        '😀' * aboutMeNoteMaxChars,
      );
    });

    test('a write rewrites it in this version (unknown codes go)', () async {
      // Accepted loss: an older Steady rewriting the file drops what it
      // can't read. Only reachable by going back a version (TestFlight).
      write(
        validFile(
          schemaVersion: 2,
          aboutMe: {
            'activities': ['pickleball', 'tennis'],
          },
        ),
      );
      await FileOnboardingRepository(file).markCompleted();
      expect(onDisk()['schemaVersion'], onboardingSchemaVersion);
      expect((onDisk()['aboutMe']! as Map<String, Object?>)['activities'], [
        'tennis',
      ]);
    });
  });

  group('file-system errors', () {
    test('a file that is a directory: read is a storage failure', () async {
      Directory(file.path).createSync(recursive: true);
      expect(
        _err(await FileOnboardingRepository(file).read()),
        isA<OnboardingStorageFailure>(),
      );
    });

    test(
      'a write that fails is a storage failure and changes nothing',
      () async {
        await FileOnboardingRepository(file).saveAboutMe(_answers);
        final before = file.readAsBytesSync();
        // A directory where the .tmp goes: writing it fails.
        Directory('${file.path}.tmp').createSync();

        final repo = FileOnboardingRepository(file);
        expect(
          _err(await repo.markCompleted()),
          isA<OnboardingStorageFailure>(),
        );
        expect(file.readAsBytesSync(), before);
        expect(_ok(await repo.read()).completed, isFalse);
      },
    );

    test('a write on an unreadable path is refused, not forced', () async {
      // A storage failure on the read inside a write stops it: only a file
      // that parses wrong is replaced.
      Directory(file.path).createSync(recursive: true);
      expect(
        _err(await FileOnboardingRepository(file).saveAboutMe(_answers)),
        isA<OnboardingStorageFailure>(),
      );
      expect(Directory(file.path).existsSync(), isTrue);
    });

    test(
      'a locate that throws is a storage failure; the next call retries',
      () async {
        var calls = 0;
        final repo = FileOnboardingRepository.locatedBy(() async {
          calls++;
          if (calls == 1) throw const FileSystemException('no support dir');
          return file;
        });
        expect(_err(await repo.read()), isA<OnboardingStorageFailure>());
        expect(_ok(await repo.read()), OnboardingRecord.initial);
        expect(calls, 2);
      },
    );

    test('locate runs once it succeeds, and lazily', () async {
      var calls = 0;
      final repo = FileOnboardingRepository.locatedBy(() async {
        calls++;
        return file;
      });
      expect(calls, 0);
      await repo.read();
      await repo.markCompleted();
      expect(calls, 1);
    });
  });

  test('a leftover .tmp from a crash mid-write is ignored', () async {
    write(validFile(completed: false));
    File('${file.path}.tmp').writeAsStringSync('half a fi');
    final repo = FileOnboardingRepository(file);
    expect(_ok(await repo.read()).completed, isFalse);
    // And the next write goes through, replacing it.
    expect(_ok(await repo.markCompleted()).completed, isTrue);
    expect(_ok(await FileOnboardingRepository(file).read()).completed, isTrue);
  });

  test('overlapping writes are serialized and neither is lost', () async {
    // Without the queue, each write's read-modify-write could read the
    // file before the other wrote it, and one change would vanish.
    final repo = FileOnboardingRepository(file);
    final results = await Future.wait([
      repo.saveAboutMe(_answers),
      repo.markCompleted(),
      repo.saveAboutMe(_answers.copyWith(note: 'second')),
    ]);
    expect(_ok(results[1]).completed, isTrue);
    expect(
      _ok(await FileOnboardingRepository(file).read()),
      OnboardingRecord(
        completed: true,
        aboutMe: _answers.copyWith(note: 'second'),
      ),
    );
  });

  test('two instances on one file see each other (no cache)', () async {
    // Encodes our choice to read the file on every call, not a platform
    // fact; the app should still bind one instance.
    final a = FileOnboardingRepository(file);
    final b = FileOnboardingRepository(file);
    await a.saveAboutMe(_answers);
    await b.markCompleted();
    expect(
      _ok(await a.read()),
      const OnboardingRecord(completed: true, aboutMe: _answers),
    );
  });
}
