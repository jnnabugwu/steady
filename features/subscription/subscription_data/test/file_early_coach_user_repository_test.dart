import 'dart:io';

import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_data/subscription_data.dart';
import 'package:subscription_data/testing/early_coach_user_repository_contract.dart';
import 'package:subscription_domain/subscription_domain.dart';
import 'package:subscription_domain/testing/in_memory_early_coach_user_repository.dart';

Matcher okOf(Object? value) =>
    isA<Ok<Object?>>().having((o) => o.value, 'value', value);

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('early_coach_user'));
  tearDown(() => dir.deleteSync(recursive: true));
  File file() => File('${dir.path}/support/early_coach_offer.json');

  group('FileEarlyCoachUserRepository', () {
    runEarlyCoachUserRepositoryContractTests(
      () => FileEarlyCoachUserRepository(file()),
    );

    test('survives a relaunch, and writes the documented format', () async {
      await FileEarlyCoachUserRepository(file()).decideOnce(usedCoach: true);
      expect(await FileEarlyCoachUserRepository(file()).read(), okOf(true));
      expect(file().readAsStringSync(), '{"version":1,"usedCoach":true}');
      expect(File('${file().path}.tmp').existsSync(), isFalse);
    });

    test('an unreadable file reads as false and is never rewritten', () async {
      file()
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('{"usedCoach": "yes"');
      final repo = FileEarlyCoachUserRepository(file());
      expect(await repo.read(), okOf(false));
      expect(await repo.decideOnce(usedCoach: true), okOf(false));
      expect(file().readAsStringSync(), '{"usedCoach": "yes"');
    });

    test('a file it can not locate is a storage failure, retried', () async {
      var calls = 0;
      final repo = FileEarlyCoachUserRepository.locatedBy(() async {
        if (calls++ == 0) throw const FileSystemException('no support dir');
        return file();
      });
      expect(
        (await repo.read() as Err).failure,
        isA<EarlyCoachUserStorageFailure>(),
      );
      expect(await repo.read(), okOf(null));
    });
  });

  group('InMemoryEarlyCoachUserRepository', () {
    runEarlyCoachUserRepositoryContractTests(
      InMemoryEarlyCoachUserRepository.new,
    );
  });
}
