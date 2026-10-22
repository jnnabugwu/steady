import 'package:account_domain/account_domain.dart';
import 'package:failures/failures.dart';

/// In-memory [AccountStatusRepository] for tests and previews.
///
/// Returns [status] (or [failure], if set) from every read, and counts
/// calls so tests can assert a re-check actually re-read.
class InMemoryAccountStatusRepository implements AccountStatusRepository {
  /// Creates the repository, reporting [status] until it's changed.
  InMemoryAccountStatusRepository({this.status = AccountStatus.available});

  /// What [accountStatus] returns while [failure] is `null`.
  AccountStatus status;

  /// When set, [accountStatus] returns `Err(failure)` instead of [status].
  Failure? failure;

  /// How many times [accountStatus] has been called.
  int accountStatusCalls = 0;

  /// How many times [openAccountSettings] has been called.
  int openAccountSettingsCalls = 0;

  @override
  ResultFuture<AccountStatus> accountStatus() async {
    accountStatusCalls++;
    final failure = this.failure;
    return failure == null ? Ok(status) : Err(failure);
  }

  @override
  ResultFuture<Unit> openAccountSettings() async {
    openAccountSettingsCalls++;
    return const Ok(unit);
  }
}
