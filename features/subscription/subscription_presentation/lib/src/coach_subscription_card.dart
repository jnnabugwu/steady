import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:subscription_domain/subscription_domain.dart';
import 'package:subscription_presentation/src/paywall_copy.dart';
import 'package:subscription_presentation/src/subscription_controller.dart';
import 'package:ui_kit/ui_kit.dart';

/// The Coach tab's card while the coach needs a subscription
/// (`coachNeedsSubscriptionProvider`): what it includes, and **See plans**
/// ([onPlansRequested], the paywall). The app shows it in place of the
/// coach card; past conversations stay listed below it, readable, lapsed or
/// not.
class CoachSubscriptionCard extends ConsumerWidget {
  /// Creates the card.
  const CoachSubscriptionCard({required this.onPlansRequested, super.key});

  /// Called by "See plans".
  final void Function() onPlansRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lapsed =
        ref.watch(subscriptionStatusControllerProvider).value?.access ==
        SubscriptionAccess.lapsed;
    return GlassCard(
      key: const Key('coachSubscriptionCard'),
      tint: GlassCardTint.coach,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Text(
            lapsed ? 'Your subscription has ended' : 'Talk it through',
            style: SteadyType.cardTitle,
          ),
          Text(
            lapsed
                ? 'Subscribe again to talk with the coach. Your past '
                      'conversations are still here.'
                : PaywallCopy.includes,
            style: SteadyType.body,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 48,
            child: PrimaryButton(
              key: const Key('coachSubscriptionSeePlans'),
              onPressed: onPlansRequested,
              child: const Center(child: Text('See plans')),
            ),
          ),
        ],
      ),
    );
  }
}
