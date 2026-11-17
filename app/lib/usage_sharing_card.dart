import 'dart:async';

import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:steady/usage_sharing.dart';
import 'package:ui_kit/ui_kit.dart';

/// Settings' "Usage sharing" section, on a TestFlight build only: what
/// usage sharing sends, and the switch that turns it off
/// ([UsageSharingController]). Renders nothing where sharing isn't offered
/// (the App Store, the Mac, a build without a PostHog key), while the
/// status is loading, and if it couldn't be read.
class UsageSharingCard extends ConsumerWidget {
  /// Creates the card.
  const UsageSharingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharing = ref.watch(usageSharingControllerProvider);
    final status = sharing.value;
    if (status == null || status == UsageSharingStatus.notOffered) {
      return const SizedBox.shrink();
    }
    final controller = ref.read(usageSharingControllerProvider.notifier);
    return SteadyCard(
      key: const Key('usageSharingCard'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Usage sharing', style: SteadyType.cardTitle),
          const SizedBox(height: 8),
          const Text(
            'This TestFlight beta sends anonymous events to PostHog, like '
            'a check-in being saved or an import finishing, so the developer '
            "can see what's used. Never your numbers, Health data, cravings "
            'or coach conversations. App Store versions send nothing.',
            style: SteadyType.body,
          ),
          const SizedBox(height: 16),
          Switch(
            key: const Key('usageSharingSwitch'),
            value: status == UsageSharingStatus.on,
            onChanged: sharing.isLoading
                ? null
                : (on) => unawaited(
                    on
                        ? controller.turnOnUsageSharing()
                        : controller.turnOffUsageSharing(),
                  ),
            trailing: const Text(
              'Share anonymous usage',
              style: SteadyType.body,
            ),
          ),
          if (sharing case AsyncError(error: final Failure failure)) ...[
            const SizedBox(height: 12),
            Text(
              "Couldn't save that: ${failure.message}",
              key: const Key('usageSharingError'),
              style: SteadyType.body,
            ),
          ],
        ],
      ),
    );
  }
}
