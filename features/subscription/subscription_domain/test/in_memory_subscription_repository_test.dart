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
}
