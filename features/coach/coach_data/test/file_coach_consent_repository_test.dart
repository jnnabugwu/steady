import 'dart:io';

import 'package:coach_data/coach_data.dart';
import 'package:coach_domain/coach_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late File file;

  T okValue<T>(Result<T> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => fail('Expected Ok, got $failure'),
  };

  Failure failureOf<T>(Result<T> result) => switch (result) {
    Ok(:final value) => fail('Expected Err, got Ok($value)'),
    Err(:final failure) => failure,
  };

  setUp(() {
    dir = Directory.systemTemp.createTempSync('coach_consent_test');
    file = File('${dir.path}/nested/coach_consent.json');
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test(
    'a missing file is not given, and the constructor does no I/O',
    () async {
      var located = 0;
      final store = FileCoachConsentRepository.locatedBy(() async {
        located++;
        return file;
      });
      expect(located, 0);
      expect(okValue(await store.readAgreedVersion()), isNull);
      expect(okValue(await store.readAgreedVersion()), isNull);
      expect(located, 1);
      expect(file.existsSync(), isFalse);
    },
  );

  test('give, then read: the version, as `{"version": n}`', () async {
    final store = FileCoachConsentRepository(file);
    okValue(await store.giveConsent(CoachConsent.currentVersion));
    expect(
      okValue(await store.readAgreedVersion()),
      CoachConsent.currentVersion,
    );
    expect(
      file.readAsStringSync(),
      '{"version":${CoachConsent.currentVersion}}',
    );
    expect(File('${file.path}.tmp').existsSync(), isFalse);
  });

  test('a later agreement replaces the earlier one', () async {
    final store = FileCoachConsentRepository(file);
    okValue(await store.giveConsent(1));
    okValue(await store.giveConsent(2));
    expect(okValue(await store.readAgreedVersion()), 2);
  });

  test('survives a new instance (a relaunch)', () async {
    okValue(await FileCoachConsentRepository(file).giveConsent(1));
    expect(
      okValue(await FileCoachConsentRepository(file).readAgreedVersion()),
      1,
    );
  });

  test('withdraw deletes the file and any leftover .tmp; a relaunch reads '
      'not given', () async {
    final store = FileCoachConsentRepository(file);
    okValue(await store.giveConsent(1));
    File('${file.path}.tmp').writeAsStringSync('leftover');
    okValue(await store.withdrawConsent());
    expect(file.existsSync(), isFalse);
    expect(File('${file.path}.tmp').existsSync(), isFalse);
    expect(okValue(await store.readAgreedVersion()), isNull);
    expect(
      okValue(await FileCoachConsentRepository(file).readAgreedVersion()),
      isNull,
    );
  });

  test('withdraw with nothing stored is Ok', () async {
    expect(
      okValue(await FileCoachConsentRepository(file).withdrawConsent()),
      unit,
    );
  });

  group('a corrupt file is not given', () {
    for (final (name, contents) in [
      ('not JSON', 'not json'),
      ('empty', ''),
      ('a list', '[1]'),
      ('no version', '{"agreed":true}'),
      ('a string version', '{"version":"1"}'),
      ('a fractional version', '{"version":1.5}'),
      ('version zero', '{"version":0}'),
      ('a negative version', '{"version":-1}'),
    ]) {
      test(name, () async {
        file
          ..parent.createSync(recursive: true)
          ..writeAsStringSync(contents);
        final store = FileCoachConsentRepository(file);
        expect(okValue(await store.readAgreedVersion()), isNull);
        // And the next agreement replaces it.
        okValue(await store.giveConsent(1));
        expect(okValue(await store.readAgreedVersion()), 1);
      });
    }

    test('invalid UTF-8', () async {
      file
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync([0xff, 0xfe, 0x00]);
      expect(
        okValue(await FileCoachConsentRepository(file).readAgreedVersion()),
        isNull,
      );
    });
  });

  test('a directory where the file should be: read is not given, a write is '
      'a typed failure', () async {
    Directory(file.path).createSync(recursive: true);
    final store = FileCoachConsentRepository(file);
    expect(okValue(await store.readAgreedVersion()), isNull);
    expect(
      failureOf(await store.giveConsent(1)),
      isA<CoachConsentStorageFailure>(),
    );
    expect(
      failureOf(await store.withdrawConsent()),
      isA<CoachConsentStorageFailure>(),
    );
  });

  test('a version below 1 is refused, and nothing is written', () async {
    final store = FileCoachConsentRepository(file);
    expect(failureOf(await store.giveConsent(0)), isA<ValidationFailure>());
    expect(file.existsSync(), isFalse);
  });

  test("a file that can't be located: read is not given, a write is a typed "
      'failure, and the next call tries again', () async {
    var attempts = 0;
    final store = FileCoachConsentRepository.locatedBy(() async {
      if (attempts++ == 0) throw const FileSystemException('no support dir');
      return file;
    });
    expect(okValue(await store.readAgreedVersion()), isNull);
    expect(okValue(await store.giveConsent(1)), unit);
    expect(okValue(await store.readAgreedVersion()), 1);

    final failing = FileCoachConsentRepository.locatedBy(
      () async => throw const FileSystemException('no support dir'),
    );
    expect(
      failureOf(await failing.giveConsent(1)),
      isA<CoachConsentStorageFailure>(),
    );
    expect(
      failureOf(await failing.withdrawConsent()),
      isA<CoachConsentStorageFailure>(),
    );
  });

  test('operations run in call order', () async {
    final store = FileCoachConsentRepository(file);
    final results = await Future.wait([
      store.giveConsent(1),
      store.withdrawConsent(),
      store.giveConsent(2),
      store.readAgreedVersion(),
    ]);
    expect(okValue(results.last), 2);
  });
}
