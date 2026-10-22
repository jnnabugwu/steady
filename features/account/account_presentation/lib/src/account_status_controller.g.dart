// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_status_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// This device's iCloud [AccountStatus].
///
/// **Lifetime: `keepAlive`.** The app router reads this on every
/// navigation to decide whether to send the user to the sign-in screen, and
/// listens to it so the redirect re-runs when the status changes. It's
/// app-wide state, not screen state, and it isn't a family, so keeping it
/// alive holds exactly one instance. Auto-dispose would only work because
/// the router happens to listen; disposing it would also throw away the
/// last known status and re-read the platform channel on the next
/// navigation.
///
/// Repository errors arrive as a typed [Failure] and are surfaced without
/// retrying; any other (unexpected) error goes through Riverpod's default
/// retry before it reaches `AsyncError`.

@ProviderFor(AccountStatusController)
final accountStatusControllerProvider = AccountStatusControllerProvider._();

/// This device's iCloud [AccountStatus].
///
/// **Lifetime: `keepAlive`.** The app router reads this on every
/// navigation to decide whether to send the user to the sign-in screen, and
/// listens to it so the redirect re-runs when the status changes. It's
/// app-wide state, not screen state, and it isn't a family, so keeping it
/// alive holds exactly one instance. Auto-dispose would only work because
/// the router happens to listen; disposing it would also throw away the
/// last known status and re-read the platform channel on the next
/// navigation.
///
/// Repository errors arrive as a typed [Failure] and are surfaced without
/// retrying; any other (unexpected) error goes through Riverpod's default
/// retry before it reaches `AsyncError`.
final class AccountStatusControllerProvider
    extends $AsyncNotifierProvider<AccountStatusController, AccountStatus> {
  /// This device's iCloud [AccountStatus].
  ///
  /// **Lifetime: `keepAlive`.** The app router reads this on every
  /// navigation to decide whether to send the user to the sign-in screen, and
  /// listens to it so the redirect re-runs when the status changes. It's
  /// app-wide state, not screen state, and it isn't a family, so keeping it
  /// alive holds exactly one instance. Auto-dispose would only work because
  /// the router happens to listen; disposing it would also throw away the
  /// last known status and re-read the platform channel on the next
  /// navigation.
  ///
  /// Repository errors arrive as a typed [Failure] and are surfaced without
  /// retrying; any other (unexpected) error goes through Riverpod's default
  /// retry before it reaches `AsyncError`.
  AccountStatusControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: _retryUnlessFailure,
        name: r'accountStatusControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountStatusControllerHash();

  @$internal
  @override
  AccountStatusController create() => AccountStatusController();
}

String _$accountStatusControllerHash() =>
    r'5f6a6b6689c0efea2e2c73b54f9d4f9d7aa6c0bc';

/// This device's iCloud [AccountStatus].
///
/// **Lifetime: `keepAlive`.** The app router reads this on every
/// navigation to decide whether to send the user to the sign-in screen, and
/// listens to it so the redirect re-runs when the status changes. It's
/// app-wide state, not screen state, and it isn't a family, so keeping it
/// alive holds exactly one instance. Auto-dispose would only work because
/// the router happens to listen; disposing it would also throw away the
/// last known status and re-read the platform channel on the next
/// navigation.
///
/// Repository errors arrive as a typed [Failure] and are surfaced without
/// retrying; any other (unexpected) error goes through Riverpod's default
/// retry before it reaches `AsyncError`.

abstract class _$AccountStatusController extends $AsyncNotifier<AccountStatus> {
  FutureOr<AccountStatus> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AccountStatus>, AccountStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AccountStatus>, AccountStatus>,
              AsyncValue<AccountStatus>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
