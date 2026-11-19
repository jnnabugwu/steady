import 'dart:async';

import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:subscription_domain/subscription_domain.dart';
import 'package:subscription_presentation/src/paywall_copy.dart';
import 'package:subscription_presentation/src/subscription_controller.dart';
import 'package:ui_kit/ui_kit.dart';

/// Steady's own paywall (#183): Steady's subscription, which is what the
/// coach needs. Built from `shadcn_flutter` and `ui_kit` only, never
/// RevenueCat's native paywall.
///
/// What App Store 3.1.2 and Schedule 2 §3.8(b) ask for, all from the store
/// ([subscriptionOfferProvider]), never hard-coded: each plan's billed
/// price as its most prominent price, the free trial's length and the price
/// after it (shown only when the store says this Apple Account can get
/// it), what renews and when, "Cancel anytime", **Restore purchases**, and
/// links to the Terms of Use (Apple's standard EULA) and [privacyPolicyUrl].
/// The words are [PaywallCopy]'s.
///
/// Shown before the coach's consent screen, so nobody agrees to send data
/// for a feature they haven't chosen. Knows nothing about routing or the
/// coach (CLAUDE.md §5): [onSubscribed] after a purchase or restore that
/// left the subscription active, [onNotNow] for "Not now" or the close
/// button, [onLinkRequested] to open a link. Sends no analytics events.
class PaywallModule extends ConsumerStatefulWidget {
  /// Creates the paywall.
  const PaywallModule({
    required this.onSubscribed,
    required this.onNotNow,
    required this.onLinkRequested,
    required this.privacyPolicyUrl,
    super.key,
  });

  /// Called once the subscription is active (bought or restored).
  final void Function() onSubscribed;

  /// Called by "Not now" or the close button. Nothing was changed.
  final void Function() onNotNow;

  /// Opens a link (the Terms of Use, the privacy policy).
  final void Function(Uri uri) onLinkRequested;

  /// Steady's privacy policy.
  final Uri privacyPolicyUrl;

  /// Keeps the text phone-width on a wide window.
  static const double maxWidth = 480;

  @override
  ConsumerState<PaywallModule> createState() => _PaywallModuleState();
}

class _PaywallModuleState extends ConsumerState<PaywallModule> {
  SubscriptionPlan _chosen = SubscriptionPlan.monthly;
  bool _busy = false;
  String? _message;

  Future<void> _run(
    Future<Result<SubscriptionStatus>> Function(SubscriptionStatusController)
    call, {
    required bool isRestore,
  }) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final result = await call(
      ref.read(subscriptionStatusControllerProvider.notifier),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = switch (result) {
        Ok(:final value) when value.isActive => null,
        Ok(:final value) when isRestore =>
          value.access == SubscriptionAccess.lapsed
              ? PaywallCopy.restoredLapsed
              : PaywallCopy.nothingToRestore,
        Ok() => null,
        Err(:final failure) => PaywallCopy.failure(failure),
      };
    });
    if (result case Ok(:final value) when value.isActive) {
      widget.onSubscribed();
    }
  }

  void _buy(SubscriptionPlan plan) =>
      unawaited(_run((c) => c.purchaseSubscription(plan), isRestore: false));

  void _restore() =>
      unawaited(_run((c) => c.restoreSubscription(), isRestore: true));

  @override
  Widget build(BuildContext context) {
    // Read up front, so a purchase updates a status that's already loaded.
    ref.watch(subscriptionStatusControllerProvider);
    final offer = ref.watch(subscriptionOfferProvider);
    final plans = offer.value?.plans ?? const <SubscriptionPlanOffer>[];
    final chosen =
        offer.value?.planFor(_chosen) ?? (plans.isEmpty ? null : plans.first);

    return Scaffold(
      headers: [
        AppBar(
          leading: [
            Semantics(
              label: 'Close',
              button: true,
              child: IconButton.ghost(
                key: const Key('paywallClose'),
                icon: const Icon(LucideIcons.x),
                onPressed: _busy ? null : widget.onNotNow,
              ),
            ),
          ],
          title: const Text('Coach'),
        ),
      ],
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          key: const Key('paywallScroll'),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: PaywallModule.maxWidth,
              ),
              child: Column(
                key: const Key('paywallScreen'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: const Text(
                      PaywallCopy.title,
                      style: SteadyType.headline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    PaywallCopy.includes,
                    key: const Key('paywallIncludes'),
                    style: SteadyType.body.copyWith(
                      color: SteadyColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(PaywallCopy.staysFree, style: SteadyType.body),
                  const SizedBox(height: 22),
                  ...switch (offer) {
                    AsyncData() when plans.isEmpty => [
                      const Text(
                        PaywallCopy.noPlans,
                        key: Key('paywallNoPlans'),
                        style: SteadyType.body,
                      ),
                    ],
                    AsyncData() => [
                      for (final plan in plans) ...[
                        _PlanTile(
                          offer: plan,
                          selected: plan.plan == chosen?.plan,
                          onPressed: _busy
                              ? null
                              : () => setState(() => _chosen = plan.plan),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (chosen != null)
                        Text(
                          PaywallCopy.smallPrint(chosen),
                          key: const Key('paywallSmallPrint'),
                          style: SteadyType.body.copyWith(fontSize: 13),
                        ),
                    ],
                    AsyncError(:final error) => [
                      Text(
                        error is SubscriptionNotConfiguredFailure
                            ? PaywallCopy.failure(error)!
                            : PaywallCopy.offerUnavailable,
                        key: const Key('paywallOfferError'),
                        style: SteadyType.body,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 44,
                        child: OutlineButton(
                          key: const Key('paywallRetry'),
                          onPressed: () =>
                              ref.invalidate(subscriptionOfferProvider),
                          child: const Center(child: Text('Try again')),
                        ),
                      ),
                    ],
                    _ => [
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  },
                  const SizedBox(height: 22),
                  if (_message case final message?) ...[
                    Text(
                      message,
                      key: const Key('paywallMessage'),
                      style: SteadyType.body,
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    height: 52,
                    child: PrimaryButton(
                      key: const Key('paywallBuy'),
                      onPressed: _busy || chosen == null
                          ? null
                          : () => _buy(chosen.plan),
                      child: Center(
                        child: _busy
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(),
                              )
                            : Text(
                                chosen?.freeTrial?.offered ?? false
                                    ? PaywallCopy.startTrial
                                    : PaywallCopy.subscribe,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: OutlineButton(
                      key: const Key('paywallNotNow'),
                      onPressed: _busy ? null : widget.onNotNow,
                      child: const Center(child: Text(PaywallCopy.notNow)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(PaywallCopy.cancelAnytime, style: SteadyType.body),
                  const SizedBox(height: 8),
                  const Text(PaywallCopy.pastSessions, style: SteadyType.body),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    children: [
                      GhostButton(
                        key: const Key('paywallRestore'),
                        onPressed: _busy ? null : _restore,
                        child: const Text(PaywallCopy.restore),
                      ),
                      GhostButton(
                        key: const Key('paywallTerms'),
                        onPressed: () =>
                            widget.onLinkRequested(PaywallCopy.termsOfUseUrl),
                        child: const Text(PaywallCopy.terms),
                      ),
                      GhostButton(
                        key: const Key('paywallPrivacy'),
                        onPressed: () =>
                            widget.onLinkRequested(widget.privacyPolicyUrl),
                        child: const Text(PaywallCopy.privacy),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One plan: its name and trial line on the left, the billed price on the
/// right in the largest type on the screen's prices. The yearly plan adds
/// the store's per-month price under its trial line ("about $3.33 a
/// month"), smaller and dimmer than the billed price, never in its place
/// (App Store 3.1.2). Selected, it takes the coach card's teal tint, like a
/// chosen check-in option.
class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.offer,
    required this.selected,
    required this.onPressed,
  });

  final SubscriptionPlanOffer offer;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final name = PaywallCopy.planName(offer.plan);
    final detail = PaywallCopy.planDetail(offer);
    final perMonth = switch (offer.monthlyEquivalentPrice) {
      final price? => PaywallCopy.monthlyEquivalent(price),
      null => null,
    };
    return Semantics(
      button: true,
      selected: selected,
      // excludeSemantics drops the GestureDetector's action, so it goes here.
      onTap: onPressed,
      label: [
        '$name, ${PaywallCopy.billed(offer)}. $detail',
        ?perMonth,
      ].join(', '),
      excludeSemantics: true,
      child: GestureDetector(
        key: Key('paywallPlan_${offer.plan.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? SteadyColors.coachCardFill
                : SteadyColors.glassFill,
            borderRadius: BorderRadius.circular(SteadyRadii.option),
            border: Border.all(
              color: selected
                  ? SteadyColors.accentTeal
                  : SteadyColors.glassBorder,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(name, style: SteadyType.cardTitle),
                      Text(
                        detail,
                        style: SteadyType.body.copyWith(fontSize: 13),
                      ),
                      if (perMonth != null)
                        Text(
                          perMonth,
                          key: Key('paywallPerMonth_${offer.plan.name}'),
                          style: SteadyType.body.copyWith(
                            fontSize: 13,
                            color: SteadyColors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      offer.price,
                      key: Key('paywallPrice_${offer.plan.name}'),
                      style: SteadyType.headline.copyWith(fontSize: 24),
                    ),
                    Text(
                      PaywallCopy.per(offer.period),
                      style: SteadyType.body.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
