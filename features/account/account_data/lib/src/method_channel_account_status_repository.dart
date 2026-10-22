import 'package:account_data/src/account_status_wire.dart';
import 'package:account_domain/account_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter/services.dart';

/// [AccountStatusRepository] backed by the `steady/account` platform
/// channel ([AccountChannel]).
///
/// The native side lives runner-adjacent, not in a separate plugin
/// (CLAUDE.md §8): `MainFlutterWindow.swift` on macOS and `AppDelegate.swift`
/// on iOS. Until CloudKit is configured (the `SteadyCloudKitEnabled`
/// Info.plist flag, flipped by #43), the native side answers
/// `notConfigured` without touching CloudKit.
///
/// Every platform error is mapped to a typed [Failure] here, so the UI never
/// sees a raw [PlatformException] (CLAUDE.md §9).
class MethodChannelAccountStatusRepository implements AccountStatusRepository {
  /// Creates the repository. [channel] is for tests; the default is the
  /// real `steady/account` channel.
  MethodChannelAccountStatusRepository({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(AccountChannel.name);

  final MethodChannel _channel;

  @override
  ResultFuture<AccountStatus> accountStatus() async {
    try {
      final raw = await _channel.invokeMethod<Object?>(
        AccountChannel.accountStatusMethod,
      );
      return Ok(accountStatusFromWire(raw));
    } on PlatformException catch (e) {
      return Err(
        PlatformChannelFailure(
          e.message ?? 'Could not read the iCloud account status',
          code: e.code,
          cause: e,
        ),
      );
    } on MissingPluginException catch (e) {
      return Err(
        PlatformChannelFailure(
          'iCloud account status is not available on this platform',
          code: 'missingPlugin',
          cause: e,
        ),
      );
    }
  }

  @override
  ResultFuture<Unit> openAccountSettings() async {
    try {
      await _channel.invokeMethod<void>(
        AccountChannel.openAccountSettingsMethod,
      );
      return const Ok(unit);
    } on PlatformException catch (e) {
      return Err(
        PlatformChannelFailure(
          e.message ?? 'Could not open Settings',
          code: e.code,
          cause: e,
        ),
      );
    } on MissingPluginException catch (e) {
      return Err(
        PlatformChannelFailure(
          'Opening Settings is not available on this platform',
          code: 'missingPlugin',
          cause: e,
        ),
      );
    }
  }
}
