import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_domain/subscription_domain.dart';

/// Runs the shared `EarlyCoachUserRepository` contract against whatever
/// [build] constructs, each test on a fresh, empty store (#188). Test-only.
void runEarlyCoachUserRepositoryContractTests(
  EarlyCoachUserRepository Function() build,
) {
  T ok<T>(Result<T> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => fail('Expected Ok, got $failure'),
  };

  group('EarlyCoachUserRepository contract', () {
    test('an empty store is undecided', () async {
      expect(ok(await build().read()), isNull);
    });

    for (final usedCoach in [true, false]) {
      test('deciding $usedCoach stores it', () async {
        final repo = build();
        expect(ok(await repo.decideOnce(usedCoach: usedCoach)), usedCoach);
        expect(ok(await repo.read()), usedCoach);
      });
    }

    test('it is decided only once: true stays true', () async {
      final repo = build();
      await repo.decideOnce(usedCoach: true);
      expect(ok(await repo.decideOnce(usedCoach: false)), isTrue);
      expect(ok(await repo.read()), isTrue);
    });

    test('it is decided only once: false stays false (a new install that '
        'later uses the coach never gets the offer)', () async {
      final repo = build();
      await repo.decideOnce(usedCoach: false);
      expect(ok(await repo.decideOnce(usedCoach: true)), isFalse);
      expect(ok(await repo.read()), isFalse);
    });
  });
}
