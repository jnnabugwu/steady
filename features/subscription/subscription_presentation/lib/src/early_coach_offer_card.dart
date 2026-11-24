import 'dart:async';

import 'package:failures/failures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:subscription_presentation/src/paywall_copy.dart';
import 'package:subscription_presentation/src/subscription_controller.dart';
import 'package:ui_kit/ui_kit.dart';

/// The paywall's card for people who used the coach on 1.0 (#188): two
/// weeks free through an offer code, shown with the code, **Copy code** and
/// **Redeem code** (Apple's own sheet). After the sheet, **Check again**
/// reads the status; once it's active, [onSubscribed].
class EarlyCoachOfferCard extends ConsumerStatefulWidget {
  /// Creates the card for [code].
  const EarlyCoachOfferCard({
    required this.code,
    required this.onSubscribed,
    super.key,
  });

  /// The offer code, from the build.
  final String code;

  /// Called once the status reads active after a redemption.
  final void Function() onSubscribed;

  @override
  ConsumerState<EarlyCoachOfferCard> createState() =>
      _EarlyCoachOfferCardState();
}

class _EarlyCoachOfferCardState extends ConsumerState<EarlyCoachOfferCard> {
  bool _busy = false;
  bool _redeemed = false;
  String? _message;

  SubscriptionStatusController get _controller =>
      ref.read(subscriptionStatusControllerProvider.notifier);

  Future<void> _redeem() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final result = await _controller.redeemOfferCode();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _redeemed = result is Ok;
      _message = switch (result) {
        Ok() => PaywallCopy.afterRedeem,
        Err(:final failure) => PaywallCopy.failure(failure),
      };
    });
    _subscribedYet();
  }

  Future<void> _checkAgain() async {
    setState(() => _busy = true);
    await _controller.refreshSubscription();
    if (!mounted) return;
    setState(() => _busy = false);
    _subscribedYet();
  }

  void _subscribedYet() {
    final status = ref.read(subscriptionStatusControllerProvider).value;
    if (status != null && status.isActive) widget.onSubscribed();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      key: const Key('earlyCoachOfferCard'),
      tint: GlassCardTint.coach,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Text(
            PaywallCopy.earlyCoachOffer,
            style: SteadyType.body.copyWith(color: SteadyColors.textPrimary),
          ),
          const Text(PaywallCopy.earlyCoachOfferHow, style: SteadyType.body),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: SelectableText(
                  widget.code,
                  key: const Key('earlyCoachOfferCode'),
                  style: SteadyType.cardTitle.copyWith(letterSpacing: 1.5),
                ),
              ),
              GhostButton(
                key: const Key('earlyCoachOfferCopy'),
                leading: const Icon(LucideIcons.copy),
                onPressed: () => unawaited(
                  Clipboard.setData(ClipboardData(text: widget.code)),
                ),
                child: const Text(PaywallCopy.copyCode),
              ),
            ],
          ),
          SizedBox(
            height: 48,
            child: PrimaryButton(
              key: const Key('earlyCoachOfferRedeem'),
              onPressed: _busy ? null : () => unawaited(_redeem()),
              child: const Center(child: Text(PaywallCopy.redeemCode)),
            ),
          ),
          if (_message case final message?)
            Text(
              message,
              key: const Key('earlyCoachOfferMessage'),
              style: SteadyType.body,
            ),
          if (_redeemed)
            SizedBox(
              height: 44,
              child: OutlineButton(
                key: const Key('earlyCoachOfferCheckAgain'),
                onPressed: _busy ? null : () => unawaited(_checkAgain()),
                child: const Center(child: Text('Check again')),
              ),
            ),
        ],
      ),
    );
  }
}
