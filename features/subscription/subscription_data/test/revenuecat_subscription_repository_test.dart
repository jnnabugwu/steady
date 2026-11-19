import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:subscription_data/subscription_data.dart';
import 'package:subscription_domain/subscription_domain.dart';

import 'helpers/fake_purchases_native.dart';

// What's specific to RevenueCat, beyond the shared contract. Every case
// here runs the real `Purchases` API against FakePurchasesNative, so it
// checks our mapping of the SDK's answers, not that RevenueCat or StoreKit
// gives those answers (see FakePurchasesNative).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.utc(2026, 11, 20, 15);
  late FakePurchasesNative native;
  late RevenueCatSubscriptionRepository repo;

  setUp(() {
    native = FakePurchasesNative(clock: () => now);
    repo = native.repository;
  });
  tearDown(() => native.dispose());

  T ok<T>(Result<T> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => fail('Expected Ok, got $failure'),
  };
  Failure err<T>(Result<T> result) => switch (result) {
    Ok(:final value) => fail('Expected Err, got $value'),
    Err(:final failure) => failure,
  };

  group('configuration', () {
    test('configures once, anonymously, with device ids off', () async {
      await repo.configure();
      await repo.status();
      await repo.offer();
      final setups = native.calls.where((c) => c.method == 'setupPurchases');
      expect(setups, hasLength(1));
      final args = setups.single.arguments as Map;
      expect(args['apiKey'], 'appl_test');
      expect(args['appUserId'], isNull);
      expect(args['automaticDeviceIdentifierCollectionEnabled'], isFalse);
      expect(args['diagnosticsEnabled'], isFalse);
    });

    test(
      'a failed setup is NotConfigured, and the next call retries',
      () async {
        native.failSetup = true;
        expect(
          err(await repo.status()),
          isA<SubscriptionNotConfiguredFailure>(),
        );
        expect(ok(await repo.status()), SubscriptionStatus.none);
        expect(
          native.calls.where((c) => c.method == 'setupPurchases'),
          hasLength(2),
        );
      },
    );

    test(
      'with no key, every call is NotConfigured and the SDK is untouched',
      () async {
        native.dispose();
        native = FakePurchasesNative(clock: () => now, config: null);
        repo = native.repository;
        expect(
          err(await repo.configure()),
          isA<SubscriptionNotConfiguredFailure>(),
        );
        expect(
          err(await repo.status()),
          isA<SubscriptionNotConfiguredFailure>(),
        );
        expect(
          err(await repo.offer()),
          isA<SubscriptionNotConfiguredFailure>(),
        );
        expect(
          err(await repo.purchase(SubscriptionPlan.monthly)),
          isA<SubscriptionNotConfiguredFailure>(),
        );
        expect(
          err(await repo.restore()),
          isA<SubscriptionNotConfiguredFailure>(),
        );
        expect(native.calls, isEmpty);
      },
    );
  });

  group('error codes', () {
    for (final (code, failure) in [
      (
        PurchasesErrorCode.insufficientPermissionsError,
        isA<SubscriptionNotAllowedFailure>(),
      ),
      (
        PurchasesErrorCode.configurationError,
        isA<SubscriptionNotConfiguredFailure>(),
      ),
      (
        PurchasesErrorCode.invalidCredentialsError,
        isA<SubscriptionNotConfiguredFailure>(),
      ),
      (
        PurchasesErrorCode.storeProblemError,
        isA<SubscriptionStoreUnavailableFailure>(),
      ),
      (
        PurchasesErrorCode.offlineConnectionError,
        isA<SubscriptionStoreUnavailableFailure>(),
      ),
      (
        PurchasesErrorCode.unknownError,
        isA<SubscriptionStoreUnavailableFailure>(),
      ),
    ]) {
      test('${code.name} on a purchase', () async {
        native.throwOn('purchasePackage', code);
        expect(err(await repo.purchase(SubscriptionPlan.monthly)), failure);
        expect(native.calls.map((c) => c.method), contains('purchasePackage'));
      });
    }

    test('already purchased reads the status instead of failing', () async {
      ok(await repo.purchase(SubscriptionPlan.monthly));
      // The fake throws productAlreadyPurchasedError for a second purchase
      // while active.
      final again = ok(await repo.purchase(SubscriptionPlan.monthly));
      expect(again.access, SubscriptionAccess.trial);
    });
  });

  group('the offer', () {
    test('when eligibility can not be read, the trial is unknown', () async {
      native.eligibilityAnswers = false;
      final offer = ok(await repo.offer());
      for (final plan in offer.plans) {
        expect(plan.freeTrial?.eligibility, TrialEligibility.unknown);
        expect(plan.freeTrial?.offered, isFalse);
      }
    });

    test('a paid introductory price is not shown as a trial', () async {
      native.introPriceOverride = {
        'price': 0.99,
        'priceString': r'$0.99',
        'period': 'P1M',
        'cycles': 1,
        'periodUnit': 'MONTH',
        'periodNumberOfUnits': 1,
      };
      final offer = ok(await repo.offer());
      expect(offer.plans.every((p) => p.freeTrial == null), isTrue);
    });

    test('a trial reported as seven days reads as one week', () async {
      native.introPriceOverride = {
        'price': 0,
        'priceString': r'$0.00',
        'period': 'P7D',
        'cycles': 1,
        'periodUnit': 'DAY',
        'periodNumberOfUnits': 7,
      };
      final offer = ok(await repo.offer());
      expect(
        offer.planFor(SubscriptionPlan.monthly)!.freeTrial!.length,
        SubscriptionPeriod.oneWeek,
      );
    });

    test('a three-day trial stays in days', () async {
      native.introPriceOverride = {
        'price': 0,
        'priceString': r'$0.00',
        'period': 'P3D',
        'cycles': 1,
        'periodUnit': 'DAY',
        'periodNumberOfUnits': 3,
      };
      final offer = ok(await repo.offer());
      expect(
        offer.planFor(SubscriptionPlan.yearly)!.freeTrial!.length,
        const SubscriptionPeriod(count: 3, unit: SubscriptionPeriodUnit.day),
      );
    });
  });

  group('the status', () {
    test('an INTRO period reads as a free period (unconfirmed for offer '
        'codes, #185)', () async {
      native.nextPeriodType = 'INTRO';
      final bought = ok(await repo.purchase(SubscriptionPlan.monthly));
      expect(bought.access, SubscriptionAccess.trial);
    });

    test('a PREPAID or NORMAL period is subscribed', () async {
      native.nextPeriodType = 'PREPAID';
      final bought = ok(await repo.purchase(SubscriptionPlan.monthly));
      expect(bought.access, SubscriptionAccess.subscribed);
    });

    test('expiry is read in local time, at the same moment', () async {
      final bought = ok(await repo.purchase(SubscriptionPlan.monthly));
      expect(bought.expiresAt!.isUtc, isFalse);
      expect(
        bought.expiresAt!.isAtSameMomentAs(now.add(const Duration(days: 7))),
        isTrue,
      );
    });
  });

  group('RevenueCatConfig.fromKey', () {
    test('a blank key is no config', () {
      expect(RevenueCatConfig.fromKey(''), isNull);
      expect(RevenueCatConfig.fromKey('  '), isNull);
    });

    test('an App Store key is used, trimmed', () {
      expect(
        RevenueCatConfig.fromKey(' appl_abc ', debugBuild: false)?.apiKey,
        'appl_abc',
      );
    });

    test('a Test Store key only in a debug build (it crashes release)', () {
      expect(
        // Explicit, though tests run as a debug build.
        // ignore: avoid_redundant_argument_values
        RevenueCatConfig.fromKey('test_abc', debugBuild: true)?.apiKey,
        'test_abc',
      );
      expect(RevenueCatConfig.fromKey('test_abc', debugBuild: false), isNull);
    });
  });

  group('parseSubscriptionPeriod', () {
    for (final (iso, period) in [
      ('P1M', SubscriptionPeriod.oneMonth),
      ('P1Y', SubscriptionPeriod.oneYear),
      ('P1W', SubscriptionPeriod.oneWeek),
      (
        'P3D',
        const SubscriptionPeriod(count: 3, unit: SubscriptionPeriodUnit.day),
      ),
    ]) {
      test(iso, () => expect(parseSubscriptionPeriod(iso), period));
    }
    for (final bad in [null, '', 'P0M', 'P1M2D', '1M', 'PT1H']) {
      test('$bad is null', () => expect(parseSubscriptionPeriod(bad), isNull));
    }
  });
}
