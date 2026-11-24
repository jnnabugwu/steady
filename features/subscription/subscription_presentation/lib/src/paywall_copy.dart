import 'package:subscription_domain/subscription_domain.dart';

/// The paywall's words, in one place (docs/technical_decisions.md, "The
/// coach is paid", items 4 and 7).
///
/// It's **Steady**: never "Steady+", "Plus" or "upgrade". The daily
/// check-in (free) and the weekly coach check-in (paid) are always named
/// apart, since both are called "check-in". The tone is the consent
/// screen's: calm, plain, no pressure.
abstract final class PaywallCopy {
  /// The screen's title. No price in it: the billed price is the most
  /// prominent price on the screen (App Store 3.1.2).
  static const title = 'The coach is part of Steady’s subscription';

  /// What the subscription includes, word for word from the decision.
  static const includes =
      'Up to 15 coach messages a day, plus your weekly coach check-in, '
      'every week.';

  /// What stays free, so nobody thinks the app itself is being sold.
  static const staysFree =
      'Everything else stays free: your daily check-in, Today, the Week '
      'tab, Cal AI imports, craving support and export.';

  /// What happens to past conversations if the subscription ends.
  static const pastSessions =
      'Your conversations stay on this iPhone, and you can still read them '
      'if you stop.';

  /// The offer for people who used the coach on 1.0 (#188), word for word
  /// from the ticket.
  static const earlyCoachOffer =
      'You used the coach before it became part of the subscription, so '
      'your first two weeks are free.';

  /// How to use the code.
  static const earlyCoachOfferHow =
      'Redeem this code with Apple, then pick your plan there.';

  /// Redeeming the code.
  static const redeemCode = 'Redeem code';

  /// Copying the code.
  static const copyCode = 'Copy code';

  /// After the redemption sheet: Apple finishes on its own time.
  static const afterRedeem =
      'Once Apple confirms the code, your two weeks start. Tap Check again '
      'if the coach hasn’t opened.';

  /// The button, when a free trial is offered.
  static const startTrial = 'Start free week';

  /// The button, when no free trial is offered.
  static const subscribe = 'Subscribe';

  /// Leaving without subscribing.
  static const notNow = 'Not now';

  /// Restore Purchases (App Store 3.1.1).
  static const restore = 'Restore purchases';

  /// The Terms of Use link (Apple's standard EULA).
  static const terms = 'Terms of Use';

  /// The privacy policy link.
  static const privacy = 'Privacy Policy';

  /// Cancel anytime, said plainly (a common App Review rejection when
  /// missing).
  static const cancelAnytime =
      'Cancel anytime in your Apple Account settings, at least a day before '
      'it renews.';

  /// Restore found nothing.
  static const nothingToRestore =
      'No subscription was found for this Apple Account.';

  /// Restore found a subscription, but it has ended.
  static const restoredLapsed =
      'Your subscription has ended, so there’s nothing to restore. You can '
      'subscribe again here.';

  /// The offer couldn't be loaded.
  static const offerUnavailable =
      'Couldn’t reach the App Store just now. Try again in a moment.';

  /// The store has no plans on sale.
  static const noPlans = 'The subscription isn’t available right now.';

  /// Apple's standard EULA, which the paywall and the App Store listing
  /// link to as the Terms of Use (decided, "The coach is paid").
  static final Uri termsOfUseUrl = Uri.parse(
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
  );

  /// The message for a failed purchase or restore, or `null` when there's
  /// nothing to say (the person cancelled).
  static String? failure(Object failure) => switch (failure) {
    SubscriptionCancelledFailure() => null,
    SubscriptionPendingFailure() =>
      'Waiting for approval. The coach opens once it’s approved.',
    SubscriptionNotAllowedFailure() =>
      'Purchases aren’t allowed on this iPhone. Check Screen Time’s '
          'content and privacy settings.',
    SubscriptionNotConfiguredFailure() =>
      'Subscriptions aren’t available in this version of Steady.',
    _ => 'Couldn’t reach the App Store just now. Try again in a moment.',
  };

  /// A period as a word or phrase: "month", "year", "week", "3 days".
  static String period(SubscriptionPeriod period) {
    final unit = switch (period.unit) {
      SubscriptionPeriodUnit.day => 'day',
      SubscriptionPeriodUnit.week => 'week',
      SubscriptionPeriodUnit.month => 'month',
      SubscriptionPeriodUnit.year => 'year',
    };
    return period.count == 1 ? unit : '${period.count} ${unit}s';
  }

  /// The billed price and how often: "$4.99 a month", "$39.99 every
  /// 6 months".
  static String billed(SubscriptionPlanOffer offer) => offer.period.count == 1
      ? '${offer.price} a ${period(offer.period)}'
      : '${offer.price} every ${period(offer.period)}';

  /// A plan's per-month price, under its billed price: "about $3.33 a
  /// month". [price] is the store's, already localized; it's "about"
  /// because the store rounds it, and it's never what's charged.
  static String monthlyEquivalent(String price) => 'about $price a month';

  /// How often, after a price: "a month", "every 6 months".
  static String per(SubscriptionPeriod period) => period.count == 1
      ? 'a ${PaywallCopy.period(period)}'
      : 'every ${PaywallCopy.period(period)}';

  /// A date as the status lines print it: "Nov 27".
  static String date(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// The subscription's state in one line, for Settings.
  static String status(SubscriptionStatus status) {
    final plan = status.plan == null ? null : planName(status.plan!);
    final until = status.expiresAt == null ? null : date(status.expiresAt!);
    return switch (status.access) {
      SubscriptionAccess.none =>
        'You’re not subscribed. The coach is part of '
            'Steady’s subscription; everything else is free.',
      SubscriptionAccess.trial =>
        until == null
            ? 'Free week.'
            : status.willRenew
            ? 'Free until $until, then ${plan ?? 'your plan'} starts.'
            : 'Free until $until. It won’t renew.',
      SubscriptionAccess.subscribed => switch ((plan, until)) {
        (final plan?, final until?) =>
          '$plan, ${status.willRenew ? 'renews' : 'ends'} $until.',
        (final plan?, null) => '$plan.',
        (null, final until?) =>
          'Subscribed, ${status.willRenew ? 'renews' : 'ends'} $until.',
        (null, null) => 'Subscribed.',
      },
      SubscriptionAccess.lapsed =>
        until == null
            ? 'Your subscription ended. Past conversations stay readable.'
            : 'Your subscription ended on $until. Past conversations stay '
                  'readable.',
    };
  }

  /// The plan's name: "Monthly", "Yearly".
  static String planName(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.monthly => 'Monthly',
    SubscriptionPlan.yearly => 'Yearly',
  };

  /// A length with its count: "1 week", "3 days", "1 month".
  static String length(SubscriptionPeriod period) => period.count == 1
      ? '1 ${PaywallCopy.period(period)}'
      : PaywallCopy.period(period);

  /// The line under a plan: its trial and the price after it when a trial
  /// is offered ("1 week free, then $4.99 a month"), else just the billed
  /// price ("$4.99 a month").
  static String planDetail(SubscriptionPlanOffer offer) =>
      switch (offer.freeTrial) {
        final trial? when trial.offered =>
          '${length(trial.length)} free, then ${billed(offer)}',
        _ => billed(offer),
      };

  /// The small print under the button for the chosen plan: exactly what's
  /// charged, when, and that it renews.
  static String smallPrint(SubscriptionPlanOffer offer) {
    final charge = switch (offer.freeTrial) {
      final trial? when trial.offered =>
        'Free for ${length(trial.length)}, then ${billed(offer)}',
      _ => billed(offer),
    };
    return '$charge, charged to your Apple Account. It renews automatically '
        'until you cancel.';
  }
}
