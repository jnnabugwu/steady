import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'icloud_banner_dismissal.g.dart';

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
@Riverpod(keepAlive: true)
class ICloudBannerDismissal extends _$ICloudBannerDismissal {
  @override
  bool build() => false;

  /// Domain event: ICloudBannerDismissed.
  ///
  /// Hides the banner until the app is launched again.
  void dismissICloudBanner() => state = true;
}
