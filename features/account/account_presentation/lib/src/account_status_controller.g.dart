// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_status_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// This device's iCloud [AccountStatus].
///
/// Never gates the app (CLAUDE.md §7: iCloud is optional). It drives the
/// non-blocking `ICloudSyncBanner` on the home screen, and the app root
/// re-checks it on every return to the foreground.
///
/// **Lifetime: `keepAlive`.** It's app-wide state, not screen state: the
/// app root re-checks it on resume whichever screen is showing, and it
/// isn't a family, so keeping it alive holds exactly one instance.
/// Disposing it whenever the home screen went away would throw away the
/// last known status and re-read the platform channel on the way back.
///
/// Repository errors arrive as a typed [Failure] and are surfaced without
/// retrying; any other (unexpected) error goes through Riverpod's default
/// retry before it reaches `AsyncError`.

@ProviderFor(AccountStatusController)
final accountStatusControllerProvider = AccountStatusControllerProvider._();

/// This device's iCloud [AccountStatus].
///
/// Never gates the app (CLAUDE.md §7: iCloud is optional). It drives the
/// non-blocking `ICloudSyncBanner` on the home screen, and the app root
/// re-checks it on every return to the foreground.
///
/// **Lifetime: `keepAlive`.** It's app-wide state, not screen state: the
/// app root re-checks it on resume whichever screen is showing, and it
/// isn't a family, so keeping it alive holds exactly one instance.
/// Disposing it whenever the home screen went away would throw away the
/// last known status and re-read the platform channel on the way back.
///
/// Repository errors arrive as a typed [Failure] and are surfaced without
/// retrying; any other (unexpected) error goes through Riverpod's default
/// retry before it reaches `AsyncError`.
final class AccountStatusControllerProvider
    extends $AsyncNotifierProvider<AccountStatusController, AccountStatus> {
  /// This device's iCloud [AccountStatus].
  ///
  /// Never gates the app (CLAUDE.md §7: iCloud is optional). It drives the
  /// non-blocking `ICloudSyncBanner` on the home screen, and the app root
  /// re-checks it on every return to the foreground.
  ///
  /// **Lifetime: `keepAlive`.** It's app-wide state, not screen state: the
  /// app root re-checks it on resume whichever screen is showing, and it
  /// isn't a family, so keeping it alive holds exactly one instance.
  /// Disposing it whenever the home screen went away would throw away the
  /// last known status and re-read the platform channel on the way back.
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
/// Never gates the app (CLAUDE.md §7: iCloud is optional). It drives the
/// non-blocking `ICloudSyncBanner` on the home screen, and the app root
/// re-checks it on every return to the foreground.
///
/// **Lifetime: `keepAlive`.** It's app-wide state, not screen state: the
/// app root re-checks it on resume whichever screen is showing, and it
/// isn't a family, so keeping it alive holds exactly one instance.
/// Disposing it whenever the home screen went away would throw away the
/// last known status and re-read the platform channel on the way back.
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
