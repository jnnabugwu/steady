import 'package:account_domain/account_domain.dart';
import 'package:account_presentation/src/account_status_controller.dart';
import 'package:account_presentation/src/icloud_banner_dismissal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// A dismissible banner saying iCloud isn't syncing this device's data.
///
/// iCloud is optional (CLAUDE.md §7): Steady never blocks on the account
/// status. When it [AccountStatus.blocksSync] (`noAccount`, `restricted`,
/// `temporarilyUnavailable`), this says so and offers "Open Settings";
/// otherwise, and while the status is still unknown, it renders nothing.
/// It goes away by itself when the status changes, for example on the
/// app-root re-check after the user signs in from Settings and comes back.
///
/// The close button fires the ICloudBannerDismissed domain event on
/// [iCloudBannerDismissalProvider], which hides it for the rest of the
/// session.
///
/// Knows nothing about routing or which screen it sits on (CLAUDE.md §5):
/// the app layer places it (above the history) and decides what
/// [onOpenSettings] does. It carries its own outer padding, so a hidden
/// banner takes no space.
///
/// Built from `shadcn_flutter` and `ui_kit` widgets only.
class ICloudSyncBanner extends ConsumerWidget {
  /// Creates the iCloud sync banner.
  const ICloudSyncBanner({required this.onOpenSettings, super.key});

  /// Called when the user taps "Open Settings".
  final void Function() onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The last known status, also while a re-check is loading, so the
    // banner doesn't flicker on every return to the foreground.
    final status = ref.watch(accountStatusControllerProvider).value;
    final dismissed = ref.watch(iCloudBannerDismissalProvider);
    if (dismissed || status == null || !status.blocksSync) {
      return const SizedBox.shrink();
    }

    return Padding(
      key: const Key('iCloudBanner'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Alert(
        leading: const Icon(LucideIcons.cloudOff),
        title: Text(
          _headline(status),
          key: const Key('iCloudBanner_title'),
          style: SteadyType.cardTitle,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            const Text(
              "Your data stays on this device and won't sync to your other "
              'devices.',
              key: Key('iCloudBanner_body'),
              style: SteadyType.body,
            ),
            const SizedBox(height: 12),
            OutlineButton(
              key: const Key('iCloudBannerButton_openSettings'),
              onPressed: onOpenSettings,
              child: const Text('Open Settings'),
            ),
          ],
        ),
        trailing: Semantics(
          label: 'Dismiss',
          button: true,
          child: IconButton.ghost(
            key: const Key('iCloudBannerButton_dismiss'),
            icon: const Icon(LucideIcons.x),
            onPressed: () => ref
                .read(iCloudBannerDismissalProvider.notifier)
                .dismissICloudBanner(),
          ),
        ),
      ),
    );
  }

  /// The first sentence, which names what's actually wrong. Only called
  /// for statuses that [AccountStatus.blocksSync].
  static String _headline(AccountStatus status) => switch (status) {
    AccountStatus.restricted => 'iCloud is turned off on this device.',
    AccountStatus.temporarilyUnavailable => "iCloud isn't available right now.",
    _ => 'Not signed into iCloud.',
  };
}
