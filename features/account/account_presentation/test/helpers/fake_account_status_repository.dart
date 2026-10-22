import 'dart:async';

import 'package:account_domain/account_domain.dart';
import 'package:failures/failures.dart';

/// Hand-written fake for `AccountStatusRepository`.
///
/// Each method returns whatever its handler returns, and every call is
/// counted so tests can assert a re-check really re-read.
class FakeAccountStatusRepository implements AccountStatusRepository {
  FakeAccountStatusRepository({
    FutureOr<Result<AccountStatus>> Function()? onAccountStatus,
  }) : onAccountStatus =
           onAccountStatus ?? (() => const Ok(AccountStatus.available));

  FutureOr<Result<AccountStatus>> Function() onAccountStatus;

  int accountStatusCalls = 0;
  int openAccountSettingsCalls = 0;

  @override
  ResultFuture<AccountStatus> accountStatus() async {
    accountStatusCalls++;
    return await onAccountStatus();
  }

  @override
  ResultFuture<Unit> openAccountSettings() async {
    openAccountSettingsCalls++;
    return const Ok(unit);
  }
}
