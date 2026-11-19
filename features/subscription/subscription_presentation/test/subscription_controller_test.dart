import 'dart:async';

import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_domain/subscription_domain.dart';
import 'package:subscription_domain/testing/in_memory_subscription_repository.dart';
import 'package:subscription_presentation/subscription_presentation.dart';

import 'helpers.dart';

void main() {
  late InMemorySubscriptionRepository store;
  setUp(() => store = InMemorySubscriptionRepository(clock: () => testNow));

  ProviderContainer container({bool supported = true}) =>
      ProviderContainer.test(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(store),
          subscriptionSupportAvailableProvider.overrideWithValue(supported),
        ],
      );

  Future<bool> needs(ProviderContainer c) async {
    try {
      await c.read(subscriptionStatusControllerProvider.future);
    } on Object {
      // A failed read is one of the cases.
    }
    final needsIt = c.read(coachNeedsSubscriptionProvider);
    return needsIt;
  }

  group('coachNeedsSubscription', () {
    test('never subscribed: yes', () async {
      expect(await needs(container()), isTrue);
    });

    test('in the free week or paying: no', () async {
      await store.purchase(SubscriptionPlan.monthly);
      expect(await needs(container()), isFalse);
    });

    test('lapsed: yes', () async {
      await store.purchase(SubscriptionPlan.monthly);
      store.expire();
      expect(await needs(container()), isTrue);
    });

    test('the store could not say: no (the proxy is the gate)', () async {
      store.failNextWith = const SubscriptionStoreUnavailableFailure();
      expect(await needs(container()), isFalse);
    });

    test('no store key: no', () async {
      store.failNextWith = const SubscriptionNotConfiguredFailure();
      expect(await needs(container()), isFalse);
    });

    test('where there is no subscription (the Mac): no', () async {
      expect(await needs(container(supported: false)), isFalse);
    });

    test('readCoachNeedsSubscription agrees, for a tap', () async {
      final c = container();
      expect(
        await readCoachNeedsSubscription(
          supported: true,
          status: c.read(subscriptionStatusControllerProvider.future),
        ),
        isTrue,
      );
      expect(
        await readCoachNeedsSubscription(
          supported: true,
          status: Future.error(const SubscriptionStoreUnavailableFailure()),
        ),
        isFalse,
      );
      expect(
        await readCoachNeedsSubscription(
          supported: false,
          status: Future.value(SubscriptionStatus.none),
        ),
        isFalse,
      );
    });
  });

  group('SubscriptionStatusController', () {
    test('a failed status read is a typed AsyncError, not retried', () async {
      store.failNextWith = const SubscriptionStoreUnavailableFailure();
      final c = container();
      await expectLater(
        c.read(subscriptionStatusControllerProvider.future),
        throwsA(isA<SubscriptionStoreUnavailableFailure>()),
      );
    });

    test('a failed purchase leaves the status as it was', () async {
      final c = container();
      await c.read(subscriptionStatusControllerProvider.future);
      store.failNextWith = const SubscriptionCancelledFailure();
      final result = await c
          .read(subscriptionStatusControllerProvider.notifier)
          .purchaseSubscription(SubscriptionPlan.monthly);
      expect((result as Err).failure, isA<SubscriptionCancelledFailure>());
      expect(
        c.read(subscriptionStatusControllerProvider).value,
        SubscriptionStatus.none,
      );
    });

    test('two taps make one purchase', () async {
      final c = container();
      await c.read(subscriptionStatusControllerProvider.future);
      final notifier = c.read(subscriptionStatusControllerProvider.notifier);
      final a = notifier.purchaseSubscription(SubscriptionPlan.monthly);
      final b = notifier.purchaseSubscription(SubscriptionPlan.yearly);
      expect(await a, await b);
      expect(store.purchaseCalls, 1);
    });

    test('refresh picks up a change made outside the app', () async {
      final c = container();
      await c.read(subscriptionStatusControllerProvider.future);
      store.purchaseElsewhere(SubscriptionPlan.monthly);
      await store.restore(); // as if StoreKit had synced it
      await c
          .read(subscriptionStatusControllerProvider.notifier)
          .refreshSubscription();
      expect(
        c.read(subscriptionStatusControllerProvider).value?.access,
        SubscriptionAccess.subscribed,
      );
    });

    test('a refresh that started before a purchase can not undo it', () async {
      final slow = _SlowStatus(store);
      final c = ProviderContainer.test(
        overrides: [subscriptionRepositoryProvider.overrideWithValue(slow)],
      );
      await c.read(subscriptionStatusControllerProvider.future);
      final notifier = c.read(subscriptionStatusControllerProvider.notifier);

      final gate = slow.hold = Completer<void>();
      final refresh = notifier.refreshSubscription(); // reads "none"…
      await Future<void>.delayed(Duration.zero);
      await notifier.purchaseSubscription(SubscriptionPlan.monthly);
      gate.complete(); // …and answers after the purchase.
      await refresh;

      expect(
        c.read(subscriptionStatusControllerProvider).value?.access,
        SubscriptionAccess.trial,
      );
    });

    test('refresh keeps a known answer over a passing outage', () async {
      final c = container();
      await c.read(subscriptionStatusControllerProvider.future);
      store.failNextWith = const SubscriptionStoreUnavailableFailure();
      await c
          .read(subscriptionStatusControllerProvider.notifier)
          .refreshSubscription();
      expect(
        c.read(subscriptionStatusControllerProvider).value,
        SubscriptionStatus.none,
      );
    });
  });

  group('PaywallCopy', () {
    test('status lines', () {
      final until = DateTime(2026, 11, 27);
      expect(
        PaywallCopy.status(
          SubscriptionStatus(
            access: SubscriptionAccess.trial,
            plan: SubscriptionPlan.monthly,
            expiresAt: until,
            willRenew: true,
          ),
        ),
        'Free until Nov 27, then Monthly starts.',
      );
      expect(
        PaywallCopy.status(
          SubscriptionStatus(
            access: SubscriptionAccess.trial,
            expiresAt: until,
          ),
        ),
        'Free until Nov 27. It won’t renew.',
      );
      expect(
        PaywallCopy.status(
          SubscriptionStatus(
            access: SubscriptionAccess.subscribed,
            plan: SubscriptionPlan.yearly,
            expiresAt: until,
            willRenew: true,
          ),
        ),
        'Yearly, renews Nov 27.',
      );
      expect(
        PaywallCopy.status(
          SubscriptionStatus(
            access: SubscriptionAccess.subscribed,
            plan: SubscriptionPlan.monthly,
            expiresAt: until,
          ),
        ),
        'Monthly, ends Nov 27.',
      );
      expect(
        PaywallCopy.status(
          SubscriptionStatus(
            access: SubscriptionAccess.lapsed,
            expiresAt: until,
          ),
        ),
        'Your subscription ended on Nov 27. Past conversations stay readable.',
      );
      expect(
        PaywallCopy.status(SubscriptionStatus.none),
        startsWith('You’re not subscribed.'),
      );
    });

    test('periods and lengths', () {
      expect(PaywallCopy.length(SubscriptionPeriod.oneWeek), '1 week');
      expect(
        PaywallCopy.length(
          const SubscriptionPeriod(count: 3, unit: SubscriptionPeriodUnit.day),
        ),
        '3 days',
      );
      expect(PaywallCopy.per(SubscriptionPeriod.oneYear), 'a year');
      expect(
        PaywallCopy.per(
          const SubscriptionPeriod(
            count: 6,
            unit: SubscriptionPeriodUnit.month,
          ),
        ),
        'every 6 months',
      );
    });
  });
}

/// [store], with `status()` held until [hold] completes, read before it's
/// held (so the status it returns is the one from when it was called).
class _SlowStatus implements SubscriptionRepository {
  _SlowStatus(this.store);

  final InMemorySubscriptionRepository store;
  Completer<void>? hold;

  @override
  ResultFuture<SubscriptionStatus> status() async {
    final answer = await store.status();
    if (hold case final gate?) {
      hold = null;
      await gate.future;
    }
    return answer;
  }

  @override
  ResultFuture<SubscriptionOffer> offer() => store.offer();

  @override
  ResultFuture<SubscriptionStatus> purchase(SubscriptionPlan plan) =>
      store.purchase(plan);

  @override
  ResultFuture<SubscriptionStatus> restore() => store.restore();
}
