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
/// Pass 02 ("Native Glass", issue #68): a [GlassCard] with a teal
/// cloud-off badge, an eyebrow, the headline and body, a glass "Open
/// Settings" pill and a round [GlassIconButton] to dismiss. This banner is
/// the whole iCloud UI: there's no sign-in screen (CLAUDE.md §7).
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
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(18, 14, 10, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: _CloudBadge(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('iCloud sync'.toUpperCase(), style: SteadyType.eyebrow),
                  const SizedBox(height: 4),
                  Text(
                    _headline(status),
                    key: const Key('iCloudBanner_title'),
                    style: const TextStyle(
                      fontFamily: SteadyType.fontFamily,
                      fontFamilyFallback: SteadyType.fontFamilyFallback,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: SteadyColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Your data stays on this device and won't sync to your "
                    'other devices.',
                    key: const Key('iCloudBanner_body'),
                    style: SteadyType.body.copyWith(
                      fontSize: 14,
                      color: SteadyColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: Button(
                      key: const Key('iCloudBannerButton_openSettings'),
                      style: _glassPillStyle,
                      onPressed: onOpenSettings,
                      child: const Text(
                        'Open Settings',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            GlassIconButton(
              key: const Key('iCloudBannerButton_dismiss'),
              icon: LucideIcons.x,
              semanticLabel: 'Dismiss',
              onPressed: () => ref
                  .read(iCloudBannerDismissalProvider.notifier)
                  .dismissICloudBanner(),
            ),
          ],
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

/// The Pass 02 secondary pill ("Not tonight" on the artboard): shadcn's
/// secondary button on the glass control fill and border.
final AbstractButtonStyle _glassPillStyle = const ButtonStyle.secondary()
    .withBackgroundColor(
      color: SteadyColors.glassControlFill,
      hoverColor: SteadyColors.glassControlBorder,
    )
    .withBorder(border: Border.all(color: SteadyColors.glassControlBorder));

/// A 32px round badge holding the cloud-off glyph, tinted teal like the
/// coach avatar on the Pass 02 artboard. Decorative: the title says it.
class _CloudBadge extends StatelessWidget {
  const _CloudBadge();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SteadyColors.accentTealTint(0.16),
          shape: BoxShape.circle,
          border: Border.all(color: SteadyColors.coachCardBorder),
        ),
        child: const SizedBox.square(
          dimension: 32,
          child: Icon(
            LucideIcons.cloudOff,
            size: 16,
            color: SteadyColors.accentTealHover,
          ),
        ),
      ),
    );
  }
}
