import 'package:account_domain/account_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountStatus.requiresSignIn', () {
    test('is true only for noAccount and restricted', () {
      final blocking = AccountStatus.values.where((s) => s.requiresSignIn);

      expect(blocking, [AccountStatus.noAccount, AccountStatus.restricted]);
    });

    for (final status in [
      AccountStatus.available,
      AccountStatus.temporarilyUnavailable,
      AccountStatus.couldNotDetermine,
      AccountStatus.notConfigured,
    ]) {
      test('${status.name} never requires sign-in', () {
        expect(status.requiresSignIn, isFalse);
      });
    }
  });
}
