import 'dart:io';

import 'package:coach_data/coach_data.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late File file;

  const keyId = 'q5TAc6Tx0ZiPTyJIa0L5yB2R5iBo1KLbE4HSkj0dJvM=';

  T okValue<T>(Result<T> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => fail('Expected Ok, got $failure'),
  };

  Failure failureOf<T>(Result<T> result) => switch (result) {
    Ok(:final value) => fail('Expected Err, got Ok($value)'),
    Err(:final failure) => failure,
  };

  setUp(() {
    dir = Directory.systemTemp.createTempSync('app_attest_key_store_test');
    file = File('${dir.path}/nested/app_attest_key.json');
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('a missing file is no key, and the constructor does no I/O', () async {
    var located = 0;
    final store = FileAppAttestKeyStore.locatedBy(() async {
      located++;
      return file;
    });
    expect(located, 0);
    expect(okValue(await store.read()), isNull);
    expect(okValue(await store.read()), isNull);
    expect(located, 1);
    expect(file.existsSync(), isFalse);
  });

  test('write then read returns the key id', () async {
    final store = FileAppAttestKeyStore(file);
    okValue(await store.write(keyId));
    expect(okValue(await store.read()), keyId);
    expect(File('${file.path}.tmp').existsSync(), isFalse);
  });

  test('write replaces the stored key id', () async {
    final store = FileAppAttestKeyStore(file);
    okValue(await store.write('first'));
    okValue(await store.write(keyId));
    expect(okValue(await store.read()), keyId);
  });

  test('the key id survives a new instance (a relaunch)', () async {
    okValue(await FileAppAttestKeyStore(file).write(keyId));
    expect(okValue(await FileAppAttestKeyStore(file).read()), keyId);
  });

  test('clear forgets the key id, also for a new instance', () async {
    final store = FileAppAttestKeyStore(file);
    okValue(await store.write(keyId));
    File('${file.path}.tmp').writeAsStringSync('leftover');
    okValue(await store.clear());
    expect(okValue(await store.read()), isNull);
    expect(okValue(await FileAppAttestKeyStore(file).read()), isNull);
    expect(file.existsSync(), isFalse);
    expect(File('${file.path}.tmp').existsSync(), isFalse);
  });

  test('clear with nothing stored is Ok', () async {
    expect(okValue(await FileAppAttestKeyStore(file).clear()), unit);
  });

  test('an empty key id is not written', () async {
    final store = FileAppAttestKeyStore(file);
    okValue(await store.write(keyId));
    expect(failureOf(await store.write('')), isA<ValidationFailure>());
    expect(okValue(await store.read()), keyId);
  });

  group('unreadable contents are no key', () {
    final contents = {
      'not JSON': 'not json {',
      'empty': '',
      'a list': '["$keyId"]',
      'no keyId': '{"other": "x"}',
      'keyId not a string': '{"keyId": 42}',
      'empty keyId': '{"keyId": ""}',
    };
    for (final MapEntry(key: name, value: text) in contents.entries) {
      test(name, () async {
        file
          ..createSync(recursive: true)
          ..writeAsStringSync(text);
        final store = FileAppAttestKeyStore(file);
        expect(okValue(await store.read()), isNull);
        // Left as it was until the next write replaces it.
        expect(file.readAsStringSync(), text);
        okValue(await store.write(keyId));
        expect(okValue(await store.read()), keyId);
      });
    }
  });

  test('contents that are not UTF-8 are no key', () async {
    file
      ..createSync(recursive: true)
      ..writeAsBytesSync([0xff, 0xfe, 0xfd]);
    expect(okValue(await FileAppAttestKeyStore(file).read()), isNull);
  });

  test('a file that cannot be read is an Err', () async {
    // A directory where the file should be: reading it fails.
    Directory(file.path).createSync(recursive: true);
    final failure = failureOf(await FileAppAttestKeyStore(file).read());
    expect(failure, isA<AppAttestKeyStoreFailure>());
    expect(failure.cause, isA<FileSystemException>());
  });

  test('a file that cannot be written is an Err', () async {
    // A file where the parent directory should be.
    File('${dir.path}/nested').writeAsStringSync('in the way');
    expect(
      failureOf(await FileAppAttestKeyStore(file).write(keyId)),
      isA<AppAttestKeyStoreFailure>(),
    );
  });

  test('a locate that throws is an Err, and is retried', () async {
    var attempts = 0;
    final store = FileAppAttestKeyStore.locatedBy(() async {
      if (attempts++ == 0) throw const FileSystemException('no directory');
      return file;
    });
    expect(failureOf(await store.read()), isA<AppAttestKeyStoreFailure>());
    okValue(await store.write(keyId));
    expect(okValue(await store.read()), keyId);
  });

  test('operations run in call order', () async {
    final store = FileAppAttestKeyStore(file);
    final results = await Future.wait([
      store.write('first'),
      store.clear(),
      store.write(keyId),
      store.read(),
    ]);
    expect(okValue(results.last), keyId);
  });
}
