import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_domain/subscription_domain.dart';

void main() {
  group('SubscriptionStatus.isActive', () {
    for (final (access, active) in [
      (SubscriptionAccess.none, false),
      (SubscriptionAccess.trial, true),
      (SubscriptionAccess.subscribed, true),
      (SubscriptionAccess.lapsed, false),
    ]) {
      test('${access.name} is ${active ? '' : 'not '}active', () {
        expect(SubscriptionStatus(access: access).isActive, active);
      });
    }
  });

  group('FreeTrial.offered', () {
    for (final (eligibility, offered) in [
      (TrialEligibility.eligible, true),
      (TrialEligibility.ineligible, false),
      // The store couldn't say: show the price without the trial.
      (TrialEligibility.unknown, false),
    ]) {
      test('${eligibility.name}: $offered', () {
        expect(
          FreeTrial(
            length: SubscriptionPeriod.oneWeek,
            eligibility: eligibility,
          ).offered,
          offered,
        );
      });
    }
  });

  test('SubscriptionOffer.planFor finds a plan, or null', () {
    const monthly = SubscriptionPlanOffer(
      plan: SubscriptionPlan.monthly,
      productId: 'm',
      price: r'$4.99',
      amount: 4.99,
      currencyCode: 'USD',
      period: SubscriptionPeriod.oneMonth,
    );
    const offer = SubscriptionOffer(plans: [monthly]);
    expect(offer.planFor(SubscriptionPlan.monthly), monthly);
    expect(offer.planFor(SubscriptionPlan.yearly), isNull);
  });
}
