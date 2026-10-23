// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'icloud_banner_dismissal.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the user has dismissed the iCloud sync banner
/// (`ICloudSyncBanner`) this session.
///
/// Pure UI state that never reaches a repository (CLAUDE.md §4), so it's a
/// small Notifier with nothing persisted: a fresh launch starts at `false`,
/// and the banner comes back if iCloud still isn't syncing.
///
/// **Lifetime: `keepAlive`.** "Hidden for the rest of the session" has to
/// outlive the home screen: auto-dispose would bring the banner back the
/// next time the history is rebuilt (a cold start into `/import` that then
/// goes home, for example). It isn't a family, so it's one `bool` for the
/// app's lifetime.

@ProviderFor(ICloudBannerDismissal)
final iCloudBannerDismissalProvider = ICloudBannerDismissalProvider._();

/// Whether the user has dismissed the iCloud sync banner
/// (`ICloudSyncBanner`) this session.
///
/// Pure UI state that never reaches a repository (CLAUDE.md §4), so it's a
/// small Notifier with nothing persisted: a fresh launch starts at `false`,
/// and the banner comes back if iCloud still isn't syncing.
///
/// **Lifetime: `keepAlive`.** "Hidden for the rest of the session" has to
/// outlive the home screen: auto-dispose would bring the banner back the
/// next time the history is rebuilt (a cold start into `/import` that then
/// goes home, for example). It isn't a family, so it's one `bool` for the
/// app's lifetime.
final class ICloudBannerDismissalProvider
    extends $NotifierProvider<ICloudBannerDismissal, bool> {
  /// Whether the user has dismissed the iCloud sync banner
  /// (`ICloudSyncBanner`) this session.
  ///
  /// Pure UI state that never reaches a repository (CLAUDE.md §4), so it's a
  /// small Notifier with nothing persisted: a fresh launch starts at `false`,
  /// and the banner comes back if iCloud still isn't syncing.
  ///
  /// **Lifetime: `keepAlive`.** "Hidden for the rest of the session" has to
  /// outlive the home screen: auto-dispose would bring the banner back the
  /// next time the history is rebuilt (a cold start into `/import` that then
  /// goes home, for example). It isn't a family, so it's one `bool` for the
  /// app's lifetime.
  ICloudBannerDismissalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'iCloudBannerDismissalProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$iCloudBannerDismissalHash();

  @$internal
  @override
  ICloudBannerDismissal create() => ICloudBannerDismissal();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$iCloudBannerDismissalHash() =>
    r'465bf5c3723fb70cf478800483eb47e84e8fdf3b';

/// Whether the user has dismissed the iCloud sync banner
/// (`ICloudSyncBanner`) this session.
///
/// Pure UI state that never reaches a repository (CLAUDE.md §4), so it's a
/// small Notifier with nothing persisted: a fresh launch starts at `false`,
/// and the banner comes back if iCloud still isn't syncing.
///
/// **Lifetime: `keepAlive`.** "Hidden for the rest of the session" has to
/// outlive the home screen: auto-dispose would bring the banner back the
/// next time the history is rebuilt (a cold start into `/import` that then
/// goes home, for example). It isn't a family, so it's one `bool` for the
/// app's lifetime.

abstract class _$ICloudBannerDismissal extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
