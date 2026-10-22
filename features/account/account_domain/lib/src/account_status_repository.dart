import 'package:account_domain/src/account_status.dart';
import 'package:failures/failures.dart';

/// Reads this device's iCloud account status, and opens the system screen
/// where the user can sign in.
abstract class AccountStatusRepository {
  /// The current [AccountStatus]. A status the platform reports but this
  /// app doesn't recognise is `Ok(AccountStatus.couldNotDetermine)`, not an
  /// error; an `Err` means the status couldn't be read at all.
  ResultFuture<AccountStatus> accountStatus();

  /// Opens the system settings screen where the user can sign in to iCloud
  /// (the Apple Account pane on macOS, Settings on iOS).
  ResultFuture<Unit> openAccountSettings();
}
