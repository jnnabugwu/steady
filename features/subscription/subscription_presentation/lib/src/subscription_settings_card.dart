import 'dart:async';

import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:subscription_domain/subscription_domain.dart';
import 'package:subscription_presentation/src/paywall_copy.dart';
import 'package:subscription_presentation/src/providers.dart';
import 'package:subscription_presentation/src/subscription_controller.dart';
import 'package:ui_kit/ui_kit.dart';

/// Settings → Subscription (#183): the subscription's state in one line,
/// **Manage subscription** (Apple's page, from the store's link),
/// **See plans** when it isn't active ([onPlansRequested], the paywall) and
/// **Restore purchases**. Renders nothing where there's no subscription
/// (`subscriptionSupportAvailableProvider`, the Mac).
class SubscriptionSettingsCard extends ConsumerStatefulWidget {
  /// Creates the card.
  const SubscriptionSettingsCard({
    required this.onPlansRequested,
    required this.onLinkRequested,
    super.key,
  });

  /// Called by "See plans".
  final void Function() onPlansRequested;

  /// Opens a link (the store's manage page).
  final void Function(Uri uri) onLinkRequested;

  @override
  ConsumerState<SubscriptionSettingsCard> createState() =>
      _SubscriptionSettingsCardState();
}

class _SubscriptionSettingsCardState
    extends ConsumerState<SubscriptionSettingsCard> {
  bool _restoring = false;
  String? _message;

  Future<void> _restore() async {
    setState(() {
      _restoring = true;
      _message = null;
    });
    final result = await ref
        .read(subscriptionStatusControllerProvider.notifier)
        .restoreSubscription();
    if (!mounted) return;
    setState(() {
      _restoring = false;
      _message = switch (result) {
        Ok(:final value) when value.isActive => 'Restored.',
        // The status line already says it ended.
        Ok(:final value) when value.access == SubscriptionAccess.lapsed => null,
        Ok() => PaywallCopy.nothingToRestore,
        Err(:final failure) => PaywallCopy.failure(failure),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(subscriptionSupportAvailableProvider)) {
      return const SizedBox.shrink();
    }
    final status = ref.watch(subscriptionStatusControllerProvider);
    final value = status.value;
    final notConfigured =
        value == null && status.error is SubscriptionNotConfiguredFailure;

    return SteadyCard(
      key: const Key('subscriptionSettingsCard'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Subscription', style: SteadyType.cardTitle),
          const SizedBox(height: 8),
          switch (status) {
            _ when value != null => Text(
              PaywallCopy.status(value),
              key: const Key('subscriptionStatusLine'),
              style: SteadyType.body,
            ),
            AsyncError() => Text(
              notConfigured
                  ? PaywallCopy.failure(
                      const SubscriptionNotConfiguredFailure(),
                    )!
                  : 'Couldn’t check your subscription just now.',
              key: const Key('subscriptionStatusError'),
              style: SteadyType.body,
            ),
            _ => const Align(
              alignment: Alignment.centerLeft,
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(),
              ),
            ),
          },
          if (!notConfigured) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (value != null && !value.isActive)
                  OutlineButton(
                    key: const Key('subscriptionSeePlans'),
                    onPressed: widget.onPlansRequested,
                    child: const Text('See plans'),
                  ),
                if (value != null &&
                    value.access != SubscriptionAccess.none &&
                    value.manageUrl != null)
                  OutlineButton(
                    key: const Key('subscriptionManage'),
                    leading: const Icon(LucideIcons.externalLink),
                    onPressed: () => widget.onLinkRequested(value.manageUrl!),
                    child: const Text('Manage subscription'),
                  ),
                if (status case AsyncError() when value == null)
                  OutlineButton(
                    key: const Key('subscriptionRetry'),
                    onPressed: () => unawaited(
                      ref
                          .read(subscriptionStatusControllerProvider.notifier)
                          .refreshSubscription(),
                    ),
                    child: const Text('Try again'),
                  ),
                OutlineButton(
                  key: const Key('subscriptionRestore'),
                  onPressed: _restoring ? null : () => unawaited(_restore()),
                  child: const Text(PaywallCopy.restore),
                ),
              ],
            ),
          ],
          if (_message case final message?) ...[
            const SizedBox(height: 10),
            Text(
              message,
              key: const Key('subscriptionRestoreMessage'),
              style: SteadyType.body,
            ),
          ],
        ],
      ),
    );
  }
}
