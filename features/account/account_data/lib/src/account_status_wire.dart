import 'package:account_domain/account_domain.dart';

/// The `steady/account` platform channel's contract, shared by the Dart
/// datasource and the Swift handlers in `app/macos/Runner/MainFlutterWindow.swift`
/// and `app/ios/Runner/AppDelegate.swift`. Change both sides together.
abstract final class AccountChannel {
  /// The channel name.
  static const name = 'steady/account';

  /// Returns one of the wire strings in [accountStatusFromWire].
  static const accountStatusMethod = 'accountStatus';

  /// Opens the system screen where the user signs in to iCloud.
  static const openAccountSettingsMethod = 'openAccountSettings';
}

/// Maps the `accountStatus` method's wire string to an [AccountStatus].
///
/// The wire strings are the enum's names (`available`, `noAccount`,
/// `restricted`, `temporarilyUnavailable`, `couldNotDetermine`,
/// `notConfigured`). Anything else, including `null` or a non-string, maps
/// to [AccountStatus.couldNotDetermine]: a newer OS adding a status must
/// never block the app or surface as a crash. The mapping is spelled out
/// rather than using `AccountStatus.values.byName`, so renaming an enum
/// value can't silently change the wire contract.
///
/// The wire format is a single string, so there's no freezed DTO here;
/// this function is the whole map → entity step (CLAUDE.md §9).
AccountStatus accountStatusFromWire(Object? raw) => switch (raw) {
  'available' => AccountStatus.available,
  'noAccount' => AccountStatus.noAccount,
  'restricted' => AccountStatus.restricted,
  'temporarilyUnavailable' => AccountStatus.temporarilyUnavailable,
  'couldNotDetermine' => AccountStatus.couldNotDetermine,
  'notConfigured' => AccountStatus.notConfigured,
  _ => AccountStatus.couldNotDetermine,
};
