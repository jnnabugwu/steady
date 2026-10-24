import 'dart:async';

import 'package:cravings_presentation/src/craving_history_controller.dart';
import 'package:cravings_presentation/src/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// ANAD's eating disorders helpline page (US; checked 2026-10-23). The
/// research's "when and how to point to help" names ANAD for the US; NEDA's
/// own helpline closed in 2023.
final Uri anadHelplineUri = Uri.parse(
  'https://anad.org/get-support/eating-disorders-helpline/',
);

/// Settings' "Cravings" card (iPhone only): where craving check-ins are
/// kept, "Delete craving history" (asks first), and a gentle, always-there
/// pointer to help (docs/research/craving_support.md §4). An offer, not a
/// flag: it's shown to everyone, never triggered by what was logged.
///
/// Renders nothing unless [cravingSupportAvailableProvider] is `true`. The
/// app layer composes it into the settings screen's `sections`.
class CravingSettingsCard extends ConsumerStatefulWidget {
  /// Creates the card.
  const CravingSettingsCard({super.key});

  @override
  ConsumerState<CravingSettingsCard> createState() =>
      _CravingSettingsCardState();
}

class _CravingSettingsCardState extends ConsumerState<CravingSettingsCard> {
  // Pure UI state (CLAUDE.md §4): whether the help link failed to open.
  bool _linkFailed = false;

  Future<void> _confirmAndDelete() async {
    final confirmed = await showOverlay<bool>(
      context,
      const DialogConfiguration(),
      builder: (context) => AlertDialog(
        title: const Text('Delete craving history?'),
        content: const Text(
          'This removes every craving check-in on this iPhone. It can’t be '
          'undone.',
        ),
        actions: [
          OutlineButton(
            key: const Key('cravingDeleteCancel'),
            onPressed: () => unawaited(closeOverlay<bool>(context, false)),
            child: const Text('Cancel'),
          ),
          DestructiveButton(
            key: const Key('cravingDeleteConfirm'),
            onPressed: () => unawaited(closeOverlay<bool>(context, true)),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).future;
    if (confirmed != true || !mounted) return;
    await ref
        .read(cravingHistoryControllerProvider.notifier)
        .deleteCravingHistory();
  }

  Future<void> _openHelp() async {
    setState(() => _linkFailed = false);
    bool opened;
    try {
      opened = await ref.read(cravingLinkOpenerProvider)(anadHelplineUri);
    } on Object {
      opened = false;
    }
    if (mounted && !opened) setState(() => _linkFailed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(cravingSupportAvailableProvider)) {
      return const SizedBox.shrink();
    }
    final history = ref.watch(cravingHistoryControllerProvider);
    final destructive = Theme.of(context).colorScheme.destructive;
    final status = switch (history) {
      AsyncData(value: true) => 'Craving history deleted.',
      AsyncError() => "Couldn't delete craving history. Try again.",
      _ => null,
    };

    return SteadyCard(
      key: const Key('cravingSettingsCard'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cravings', style: SteadyType.cardTitle),
          const SizedBox(height: 8),
          const Text(
            "Craving check-ins stay on this iPhone. Steady doesn't sync them. "
            "If your iPhone backs up to iCloud, they're included in that "
            'backup, like other app data.',
            key: Key('cravingStorageLine'),
            style: SteadyType.body,
          ),
          const SizedBox(height: 16),
          if (history.isLoading)
            const CircularProgressIndicator()
          else
            SizedBox(
              height: 44,
              child: OutlineButton(
                key: const Key('cravingDeleteHistoryButton'),
                leading: Icon(LucideIcons.trash2, color: destructive),
                onPressed: () => unawaited(_confirmAndDelete()),
                child: Text(
                  'Delete craving history',
                  style: TextStyle(color: destructive),
                ),
              ),
            ),
          if (status != null) ...[
            const SizedBox(height: 8),
            Text(
              status,
              key: const Key('cravingDeleteStatus'),
              style: SteadyType.body,
            ),
          ],
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            "If food ever feels out of control, you don't have to sort it "
            "out alone. ANAD's free eating disorders helpline is open on "
            'weekdays at 1-888-375-7767.',
            key: Key('cravingHelpLine'),
            style: SteadyType.body,
          ),
          const SizedBox(height: 4),
          const Text('In a crisis, call or text 988.', style: SteadyType.body),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: GhostButton(
              key: const Key('cravingHelpLink'),
              leading: const Icon(LucideIcons.externalLink),
              onPressed: () => unawaited(_openHelp()),
              child: const Text('ANAD helpline'),
            ),
          ),
          if (_linkFailed) ...[
            const SizedBox(height: 8),
            const Text(
              "Couldn't open the link. ANAD's helpline is at anad.org.",
              key: Key('cravingHelpLinkError'),
              style: SteadyType.body,
            ),
          ],
        ],
      ),
    );
  }
}
