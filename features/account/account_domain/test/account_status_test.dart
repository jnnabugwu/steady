import 'package:account_domain/account_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountStatus.blocksSync', () {
    test(
      'is true only for noAccount, restricted and temporarilyUnavailable',
      () {
        final notSyncing = AccountStatus.values.where((s) => s.blocksSync);

        expect(notSyncing, [
          AccountStatus.noAccount,
          AccountStatus.restricted,
          AccountStatus.temporarilyUnavailable,
        ]);
      },
    );

    for (final status in [
      AccountStatus.available,
      AccountStatus.couldNotDetermine,
      AccountStatus.notConfigured,
    ]) {
      test('${status.name} does not block sync', () {
        expect(status.blocksSync, isFalse);
      });
    }
  });
}
