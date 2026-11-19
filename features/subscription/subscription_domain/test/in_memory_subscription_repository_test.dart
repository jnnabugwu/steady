import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_domain/subscription_domain.dart';
import 'package:subscription_domain/testing/in_memory_subscription_repository.dart';

void main() {
  // The fake's own calendar arithmetic: an expiry stays in the clock's
  // zone, so tests don't depend on the runner's time zone.
  for (final (plan, expected) in [
    (SubscriptionPlan.monthly, DateTime.utc(2026, 12, 20, 15, 30, 5, 7)),
    (SubscriptionPlan.yearly, DateTime.utc(2027, 11, 20, 15, 30, 5, 7)),
  ]) {
    test('a paid ${plan.name} period from a UTC clock ends in UTC', () async {
      final now = DateTime.utc(2026, 11, 20, 15, 30, 5, 7);
      final store = InMemorySubscriptionRepository(clock: () => now)
        ..purchaseElsewhere(plan);
      final status = (await store.restore() as Ok<SubscriptionStatus>).value;
      expect(status.expiresAt, expected);
      expect(status.expiresAt!.isUtc, isTrue);
    });
  }

  group("the yearly plan's per-month price", () {
    test('the fake sells yearly with one, as the store gives it', () async {
      final offer =
          (await InMemorySubscriptionRepository().offer()
                  as Ok<SubscriptionOffer>)
              .value;
      expect(
        offer.planFor(SubscriptionPlan.yearly)!.monthlyEquivalentPrice,
        r'$3.33',
      );
      expect(
        offer.planFor(SubscriptionPlan.monthly)!.monthlyEquivalentPrice,
        isNull,
      );
    });

    test('an offer without one comes back without one', () async {
      final sold = SubscriptionOffer(
        plans: [
          for (final p in InMemorySubscriptionRepository.defaultOffer.plans)
            p.copyWith(monthlyEquivalentPrice: null),
        ],
      );
      final offer =
          (await InMemorySubscriptionRepository(offer: sold).offer()
                  as Ok<SubscriptionOffer>)
              .value;
      expect(offer, sold);
      expect(offer.plans.map((p) => p.monthlyEquivalentPrice), [null, null]);
    });

    test('it is part of the value: equality and copyWith', () {
      final yearly = InMemorySubscriptionRepository.defaultOffer.planFor(
        SubscriptionPlan.yearly,
      )!;
      final other = yearly.copyWith(monthlyEquivalentPrice: '3,33 €');
      expect(other, isNot(yearly));
      expect(other.monthlyEquivalentPrice, '3,33 €');
      expect(other.copyWith(monthlyEquivalentPrice: r'$3.33'), yearly);
    });
  });
}
