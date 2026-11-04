import 'dart:async';

import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/src/coach_consent_controller.dart';
import 'package:coach_presentation/src/coach_history_controller.dart';
import 'package:coach_presentation/src/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// Settings' "Coach" card (iPhone only): the switch that turns the coach on
/// or off, one line on what it sends, where coach conversations are kept,
/// and "Delete coach history" (asks first).
///
/// **The switch** shows whether consent for the current version is given
/// ([coachConsentGivenProvider], [isCoachConsentGiven]). Turning it on
/// opens the consent screen ([onConsentRequested]); nothing changes unless
/// the person allows it there. Turning it off withdraws at once
/// (`withdrawCoachConsent`), which stops every request, a reply in flight
/// included. It never deletes history: "Delete coach history" is separate.
///
/// Renders nothing unless [coachSupportAvailableProvider] is `true`. The
/// app layer composes it into the settings screen's `sections`.
///
/// **No red, yellow or green** (decided 2026-10-25, the coach colour rule
/// from #82): the delete button and the dialog's "Delete" are the teal
/// accent ([SteadyColors.accentTeal]), not the theme's destructive red. The
/// action reads as destructive through its wording ("Delete coach
/// history", "It can’t be undone.") and the confirm dialog, not its colour.
class CoachSettingsCard extends ConsumerWidget {
  /// Creates the card.
  const CoachSettingsCard({required this.onConsentRequested, super.key});

  /// Called when the switch is turned on: open the consent screen. The
  /// switch follows the answer by itself.
  final void Function() onConsentRequested;

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showOverlay<bool>(
      context,
      const DialogConfiguration(),
      builder: (context) => AlertDialog(
        title: const Text('Delete coach history?'),
        content: const Text(
          'This removes every coach conversation and summary on this '
          'iPhone. It can’t be undone.',
        ),
        actions: [
          OutlineButton(
            key: const Key('coachDeleteCancel'),
            onPressed: () => unawaited(closeOverlay<bool>(context, false)),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            key: const Key('coachDeleteConfirm'),
            onPressed: () => unawaited(closeOverlay<bool>(context, true)),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).future;
    if (confirmed != true || !context.mounted) return;
    await ref
        .read(coachHistoryControllerProvider.notifier)
        .deleteCoachHistory();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(coachSupportAvailableProvider)) {
      return const SizedBox.shrink();
    }
    final consent = ref.watch(coachConsentGivenProvider);
    final history = ref.watch(coachHistoryControllerProvider);
    final status = switch (history) {
      AsyncData(value: true) => 'Coach history deleted.',
      AsyncError() => "Couldn't delete coach history. Try again.",
      _ => null,
    };

    return SteadyCard(
      key: const Key('coachSettingsCard'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Coach', style: SteadyType.cardTitle),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Switch(
              key: const Key('coachConsentSwitch'),
              value: isCoachConsentGiven(consent),
              onChanged: consent.isLoading
                  ? null
                  : (on) => on
                        ? onConsentRequested()
                        : unawaited(
                            ref
                                .read(coachConsentGivenProvider.notifier)
                                .withdrawCoachConsent(),
                          ),
              trailing: const Text('Use the coach', style: SteadyType.body),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            CoachConsent.settingsLine,
            key: Key('coachConsentLine'),
            style: SteadyType.body,
          ),
          // A save that didn't work. The coach is off here either way, so
          // the one retry is the safe one: saving "off" again.
          if (consent case AsyncError()) ...[
            const SizedBox(height: 8),
            const Text(
              "Couldn't save that on this iPhone. The coach is off for now; "
              'save it again so it stays off.',
              key: Key('coachConsentError'),
              style: SteadyType.body,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: OutlineButton(
                key: const Key('coachConsentRetry'),
                onPressed: () => unawaited(
                  ref
                      .read(coachConsentGivenProvider.notifier)
                      .withdrawCoachConsent(),
                ),
                child: const Text('Save again'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            "Coach conversations stay on this iPhone. Steady doesn't sync "
            "them. If your iPhone backs up to iCloud, they're included in "
            'that backup, like other app data.',
            key: Key('coachStorageLine'),
            style: SteadyType.body,
          ),
          const SizedBox(height: 16),
          if (history.isLoading)
            const CircularProgressIndicator()
          else
            SizedBox(
              height: 44,
              child: OutlineButton(
                key: const Key('coachDeleteHistoryButton'),
                leading: const Icon(
                  LucideIcons.trash2,
                  color: SteadyColors.accentTeal,
                ),
                onPressed: () => unawaited(_confirmAndDelete(context, ref)),
                child: const Text(
                  'Delete coach history',
                  style: TextStyle(color: SteadyColors.accentTeal),
                ),
              ),
            ),
          if (status != null) ...[
            const SizedBox(height: 8),
            Text(
              status,
              key: const Key('coachDeleteStatus'),
              style: SteadyType.body,
            ),
          ],
        ],
      ),
    );
  }
}
