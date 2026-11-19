import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_domain/subscription_domain.dart';

/// A way a store call can fail, for the contract to arrange.
enum SubscriptionStoreFault {
  /// The person closed the purchase sheet.
  cancelled,

  /// Ask to Buy, or the bank, hasn't approved it yet.
  pending,

  /// This account isn't allowed to buy (Screen Time).
  notAllowed,

  /// Offline, or the App Store is down.
  outage,
}

/// The store behind a [SubscriptionRepository], as the contract arranges it:
/// the in-memory fake itself, or a fake of the `purchases_flutter` plugin's
/// native side under the real RevenueCat implementation.
///
/// **Both are our model of StoreKit and RevenueCat, not the real thing.**
/// Passing this contract means the two implementations agree with each
/// other and with what we believe the store does; it doesn't show the
/// store does it. What's believed and unconfirmed is listed on
/// `InMemorySubscriptionRepository`; a sandbox account on a real iPhone
/// (#185) is the check.
abstract class SubscriptionContractStore {
  /// The repository under test.
  SubscriptionRepository get repository;

  /// Sells only [plans] from now on, as when Apple hasn't approved one.
  void sellOnly(Set<SubscriptionPlan> plans);

  /// Puts [plan] (paid, no trial) on the Apple Account as if bought on
  /// another device or before a reinstall: not seen until a restore.
  void purchaseElsewhere(SubscriptionPlan plan);

  /// Ends the current subscription now.
  void expire();

  /// Turns renewal off; it stays active until it expires.
  void turnOffRenewal();

  /// Makes the next store call fail with [fault].
  void failNext(SubscriptionStoreFault fault);
}

/// Runs the shared `SubscriptionRepository` contract against whatever
/// [build] constructs, each test on a fresh store whose clock reads a
/// fixed time.
/// Lives under `lib/testing/` so `app/` can import it. Test-only: never
/// import it from `lib/src/`.
void runSubscriptionRepositoryContractTests(
  SubscriptionContractStore Function(DateTime Function() clock) build,
) {
  final now = DateTime.utc(2026, 11, 20, 15);

  T ok<T>(Result<T> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => fail('Expected Ok, got $failure'),
  };

  Failure err<T>(Result<T> result) => switch (result) {
    Ok(:final value) => fail('Expected Err, got $value'),
    Err(:final failure) => failure,
  };

  group('SubscriptionRepository contract', () {
    late SubscriptionContractStore store;
    late SubscriptionRepository repo;
    setUp(() {
      store = build(() => now);
      repo = store.repository;
    });

    test('a new install has no subscription', () async {
      expect(ok(await repo.status()), SubscriptionStatus.none);
    });

    test('the offer has both plans, monthly first, with a free week', () async {
      final offer = ok(await repo.offer());
      expect(offer.plans.map((p) => p.plan), [
        SubscriptionPlan.monthly,
        SubscriptionPlan.yearly,
      ]);
      final monthly = offer.planFor(SubscriptionPlan.monthly)!;
      expect(monthly.price, r'$4.99');
      expect(monthly.amount, 4.99);
      expect(monthly.currencyCode, 'USD');
      expect(monthly.period, SubscriptionPeriod.oneMonth);
      // Only the yearly plan carries a per-month price.
      expect(monthly.monthlyEquivalentPrice, isNull);
      expect(
        monthly.freeTrial,
        const FreeTrial(
          length: SubscriptionPeriod.oneWeek,
          eligibility: TrialEligibility.eligible,
        ),
      );
      final yearly = offer.planFor(SubscriptionPlan.yearly)!;
      expect(yearly.price, r'$39.99');
      expect(yearly.period, SubscriptionPeriod.oneYear);
      expect(yearly.monthlyEquivalentPrice, r'$3.33');
      expect(yearly.freeTrial?.offered, isTrue);
    });

    test('a plan not on sale is left out of the offer', () async {
      store.sellOnly({SubscriptionPlan.yearly});
      final offer = ok(await repo.offer());
      expect(offer.plans.map((p) => p.plan), [SubscriptionPlan.yearly]);
    });

    test('buying a plan not on sale fails as store unavailable', () async {
      store.sellOnly({SubscriptionPlan.yearly});
      expect(
        err(await repo.purchase(SubscriptionPlan.monthly)),
        isA<SubscriptionStoreUnavailableFailure>(),
      );
      expect(ok(await repo.status()), SubscriptionStatus.none);
    });

    test('the first purchase starts the free week', () async {
      final bought = ok(await repo.purchase(SubscriptionPlan.monthly));
      expect(bought.access, SubscriptionAccess.trial);
      expect(bought.isActive, isTrue);
      expect(bought.plan, SubscriptionPlan.monthly);
      expect(bought.willRenew, isTrue);
      expect(
        bought.expiresAt!.isAtSameMomentAs(now.add(const Duration(days: 7))),
        isTrue,
      );
      expect(bought.manageUrl, isNotNull);
      expect(ok(await repo.status()), bought);
    });

    test('after a trial, neither plan offers one (one per group)', () async {
      await repo.purchase(SubscriptionPlan.yearly);
      final offer = ok(await repo.offer());
      for (final plan in offer.plans) {
        expect(plan.freeTrial?.eligibility, TrialEligibility.ineligible);
      }
    });

    test('buying without a trial left is paid from the start', () async {
      await repo.purchase(SubscriptionPlan.monthly);
      store.expire();
      final bought = ok(await repo.purchase(SubscriptionPlan.yearly));
      expect(bought.access, SubscriptionAccess.subscribed);
      expect(bought.plan, SubscriptionPlan.yearly);
      expect(bought.expiresAt!.isAfter(now), isTrue);
    });

    test('an expired subscription is lapsed, and keeps its plan', () async {
      await repo.purchase(SubscriptionPlan.monthly);
      store.expire();
      final lapsed = ok(await repo.status());
      expect(lapsed.access, SubscriptionAccess.lapsed);
      expect(lapsed.isActive, isFalse);
      expect(lapsed.plan, SubscriptionPlan.monthly);
      expect(lapsed.willRenew, isFalse);
    });

    test('renewal turned off stays active, not renewing', () async {
      await repo.purchase(SubscriptionPlan.monthly);
      store.turnOffRenewal();
      final status = ok(await repo.status());
      expect(status.isActive, isTrue);
      expect(status.willRenew, isFalse);
    });

    test(
      'restore with nothing bought is no subscription, not a failure',
      () async {
        expect(ok(await repo.restore()), SubscriptionStatus.none);
      },
    );

    test('restore finds a purchase made elsewhere', () async {
      store.purchaseElsewhere(SubscriptionPlan.yearly);
      expect(ok(await repo.status()), SubscriptionStatus.none);
      final restored = ok(await repo.restore());
      expect(restored.access, SubscriptionAccess.subscribed);
      expect(restored.plan, SubscriptionPlan.yearly);
      expect(ok(await repo.status()), restored);
    });

    group('a failed purchase changes nothing', () {
      for (final (fault, failure) in [
        (SubscriptionStoreFault.cancelled, isA<SubscriptionCancelledFailure>()),
        (SubscriptionStoreFault.pending, isA<SubscriptionPendingFailure>()),
        (
          SubscriptionStoreFault.notAllowed,
          isA<SubscriptionNotAllowedFailure>(),
        ),
        (
          SubscriptionStoreFault.outage,
          isA<SubscriptionStoreUnavailableFailure>(),
        ),
      ]) {
        test(fault.name, () async {
          store.failNext(fault);
          expect(err(await repo.purchase(SubscriptionPlan.monthly)), failure);
          expect(ok(await repo.status()), SubscriptionStatus.none);
          // The trial wasn't used up.
          final offer = ok(await repo.offer());
          expect(
            offer.planFor(SubscriptionPlan.monthly)!.freeTrial!.offered,
            isTrue,
          );
        });
      }
    });

    test('an outage fails status, offer and restore as unavailable', () async {
      store.failNext(SubscriptionStoreFault.outage);
      expect(
        err(await repo.status()),
        isA<SubscriptionStoreUnavailableFailure>(),
      );
      store.failNext(SubscriptionStoreFault.outage);
      expect(
        err(await repo.offer()),
        isA<SubscriptionStoreUnavailableFailure>(),
      );
      store.failNext(SubscriptionStoreFault.outage);
      expect(
        err(await repo.restore()),
        isA<SubscriptionStoreUnavailableFailure>(),
      );
    });
  });
}
