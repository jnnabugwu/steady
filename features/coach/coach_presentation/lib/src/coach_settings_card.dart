import 'dart:async';

import 'package:coach_presentation/src/coach_history_controller.dart';
import 'package:coach_presentation/src/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// Settings' "Coach" card (iPhone only): where coach conversations are
/// kept, and "Delete coach history" (asks first).
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
  const CoachSettingsCard({super.key});

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
