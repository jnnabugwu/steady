import 'package:account_data/account_data.dart';
import 'package:account_domain/account_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns the current status and counts reads', () async {
    final repository = InMemoryAccountStatusRepository(
      status: AccountStatus.noAccount,
    );

    expect(
      (await repository.accountStatus() as Ok<AccountStatus>).value,
      AccountStatus.noAccount,
    );
    repository.status = AccountStatus.available;
    expect(
      (await repository.accountStatus() as Ok<AccountStatus>).value,
      AccountStatus.available,
    );
    expect(repository.accountStatusCalls, 2);
  });

  test('returns the failure when one is set', () async {
    const failure = PlatformChannelFailure('down');
    final repository = InMemoryAccountStatusRepository()..failure = failure;

    final result = await repository.accountStatus();

    expect((result as Err<AccountStatus>).failure, failure);
  });

  test('counts openAccountSettings calls', () async {
    final repository = InMemoryAccountStatusRepository();

    expect(await repository.openAccountSettings(), isA<Ok<Unit>>());
    expect(repository.openAccountSettingsCalls, 1);
  });
}
