import 'dart:async';

import 'package:failures/failures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:subscription_data/src/revenuecat_config.dart';
import 'package:subscription_domain/subscription_domain.dart';

/// [SubscriptionRepository] on RevenueCat's `purchases_flutter`, which runs
/// StoreKit 2 on iOS.
///
/// Configured once, on first use or when [configure] is called at launch,
/// with an anonymous App User ID (the SDK makes a random
/// `$RCAnonymousID:` and keeps it on the device). It never sets an App
/// User ID, attribution IDs or customer attributes.
///
/// Built with a `null` config (a build with no usable
/// `REVENUECAT_API_KEY`), every call returns
/// `Err(SubscriptionNotConfiguredFailure)` without touching the SDK.
///
/// Every `PlatformException` the SDK throws is mapped to a typed failure
/// here (CLAUDE.md §9); nothing raw reaches the UI.
class RevenueCatSubscriptionRepository implements SubscriptionRepository {
  /// Creates a repository for [config].
  RevenueCatSubscriptionRepository(this.config);

  /// The build's RevenueCat key, or `null` when it has none it can use.
  final RevenueCatConfig? config;

  Future<void>? _configured;

  /// Configures the SDK once. `main.dart` calls it at launch so the first
  /// status read is quick; every other call waits for it too. A failure is
  /// returned, and the next call tries again.
  ResultFuture<Unit> configure() async {
    final config = this.config;
    if (config == null) return const Err(SubscriptionNotConfiguredFailure());
    try {
      await (_configured ??= _setUp(config));
      return const Ok(unit);
    } on Object catch (error) {
      _configured = null;
      return Err(_failureFrom(error, notConfiguredByDefault: true));
    }
  }

  static Future<void> _setUp(RevenueCatConfig config) => Purchases.configure(
    PurchasesConfiguration(config.apiKey)
      // Anonymous: no App User ID of Steady's own (research §2).
      ..appUserID = null
      // Only acts once an attribution ID is set, which Steady never
      // does; off anyway, so nothing device-level is collected for it.
      ..automaticDeviceIdentifierCollectionEnabled = false
      ..diagnosticsEnabled = false,
  );

  @override
  ResultFuture<SubscriptionStatus> status() =>
      _guard(() async => _statusFrom(await Purchases.getCustomerInfo()));

  @override
  ResultFuture<SubscriptionOffer> offer() => _guard(() async {
    final offering = await _currentOffering();
    final packages = _packagesByPlan(offering);
    final ids = [for (final p in packages.values) p.storeProduct.identifier];
    final eligibility = await _eligibility(ids);
    return SubscriptionOffer(
      plans: [
        for (final MapEntry(key: plan, value: package) in packages.entries)
          _planOfferFrom(
            plan,
            package.storeProduct,
            eligibility[package.storeProduct.identifier],
          ),
      ],
    );
  });

  @override
  ResultFuture<SubscriptionStatus> purchase(SubscriptionPlan plan) =>
      _guard(() async {
        final package = _packagesByPlan(await _currentOffering())[plan];
        if (package == null) {
          throw const SubscriptionStoreUnavailableFailure();
        }
        try {
          final result = await Purchases.purchase(
            PurchaseParams.package(package),
          );
          return _statusFrom(result.customerInfo);
        } on PlatformException catch (error) {
          // Already bought on this Apple Account: not a failure, just read
          // where it stands.
          if (PurchasesErrorHelper.getErrorCode(error) ==
              PurchasesErrorCode.productAlreadyPurchasedError) {
            return _statusFrom(await Purchases.getCustomerInfo());
          }
          rethrow;
        }
      });

  @override
  ResultFuture<SubscriptionStatus> restore() =>
      _guard(() async => _statusFrom(await Purchases.restorePurchases()));

  Future<Offering> _currentOffering() async {
    final offering = (await Purchases.getOfferings()).current;
    // No current offering: RevenueCat's dashboard isn't set up, or the
    // store returned no products.
    if (offering == null) throw const SubscriptionStoreUnavailableFailure();
    return offering;
  }

  /// The offering's packages for Steady's plans, monthly first. A package
  /// is left out when Apple hasn't approved its product, so either can be
  /// missing.
  static Map<SubscriptionPlan, Package> _packagesByPlan(Offering offering) => {
    SubscriptionPlan.monthly: ?offering.monthly,
    SubscriptionPlan.yearly: ?offering.annual,
  };

  /// Trial eligibility per product id. If the store can't say, every
  /// product reads as unknown, which the paywall shows without the trial:
  /// it never fails the offer.
  static Future<Map<String, IntroEligibilityStatus>> _eligibility(
    List<String> productIds,
  ) async {
    if (productIds.isEmpty) return const {};
    try {
      final result = await Purchases.checkTrialOrIntroductoryPriceEligibility(
        productIds,
      );
      return result.map((id, e) => MapEntry(id, e.status));
    } on Object {
      return const {};
    }
  }

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    final configured = await configure();
    if (configured case Err(:final failure)) return Err(failure);
    try {
      return Ok(await body());
    } on Object catch (error) {
      return Err(_failureFrom(error));
    }
  }

  /// Maps what the SDK threw to a typed failure.
  static Failure _failureFrom(
    Object error, {
    bool notConfiguredByDefault = false,
  }) {
    if (error is Failure) return error;
    if (error is MissingPluginException) {
      return SubscriptionNotConfiguredFailure(cause: error);
    }
    if (error is! PlatformException) {
      return notConfiguredByDefault
          ? SubscriptionNotConfiguredFailure(cause: error)
          : SubscriptionStoreUnavailableFailure(cause: error);
    }
    return switch (PurchasesErrorHelper.getErrorCode(error)) {
      PurchasesErrorCode.purchaseCancelledError => SubscriptionCancelledFailure(
        cause: error,
      ),
      PurchasesErrorCode.paymentPendingError => SubscriptionPendingFailure(
        cause: error,
      ),
      PurchasesErrorCode.purchaseNotAllowedError ||
      PurchasesErrorCode.insufficientPermissionsError =>
        SubscriptionNotAllowedFailure(cause: error),
      PurchasesErrorCode.configurationError ||
      PurchasesErrorCode.invalidCredentialsError ||
      PurchasesErrorCode.invalidAppleSubscriptionKeyError =>
        SubscriptionNotConfiguredFailure(cause: error),
      _ =>
        notConfiguredByDefault
            ? SubscriptionNotConfiguredFailure(cause: error)
            : SubscriptionStoreUnavailableFailure(cause: error),
    };
  }
}

/// The status RevenueCat's [info] describes, read from the
/// [SteadySubscriptionIds.entitlement] entitlement.
///
/// - No entitlement ever: [SubscriptionStatus.none].
/// - Active, in a free period: [SubscriptionAccess.trial]. RevenueCat's
///   `TRIAL` is the introductory free week; `INTRO` is read as a free
///   period too, since Steady sells no paid introductory price. Which of
///   the two an offer code's free period (#188) reports is not confirmed:
///   check on a sandbox account (#185).
/// - Active otherwise: [SubscriptionAccess.subscribed].
/// - Not active: [SubscriptionAccess.lapsed].
SubscriptionStatus _statusFrom(CustomerInfo info) {
  final entitlement = info.entitlements.all[SteadySubscriptionIds.entitlement];
  if (entitlement == null) return SubscriptionStatus.none;
  final active = entitlement.isActive;
  return SubscriptionStatus(
    access: !active
        ? SubscriptionAccess.lapsed
        : switch (entitlement.periodType) {
            PeriodType.trial || PeriodType.intro => SubscriptionAccess.trial,
            _ => SubscriptionAccess.subscribed,
          },
    plan: _planFor(entitlement.productIdentifier),
    expiresAt: switch (entitlement.expirationDate) {
      final date? => DateTime.tryParse(date)?.toLocal(),
      null => null,
    },
    willRenew: active && entitlement.willRenew,
    manageUrl: switch (info.managementURL) {
      final url? => Uri.tryParse(url),
      null => null,
    },
  );
}

/// Which of Steady's plans [productId] is, or `null` for any other product.
SubscriptionPlan? _planFor(String productId) => switch (productId) {
  SteadySubscriptionIds.monthlyProduct => SubscriptionPlan.monthly,
  SteadySubscriptionIds.yearlyProduct => SubscriptionPlan.yearly,
  _ => null,
};

/// [plan]'s offer from the store's [product] and its trial [eligibility]
/// (`null` when the store couldn't say).
SubscriptionPlanOffer _planOfferFrom(
  SubscriptionPlan plan,
  StoreProduct product,
  IntroEligibilityStatus? eligibility,
) {
  final intro = product.introductoryPrice;
  final freeTrial =
      intro == null ||
          intro.price != 0 ||
          eligibility ==
              IntroEligibilityStatus.introEligibilityStatusNoIntroOfferExists
      ? null
      : switch (_unit(intro.periodUnit)) {
          final unit? => FreeTrial(
            length: _inWeeksWhenWhole(
              SubscriptionPeriod(
                count: intro.periodNumberOfUnits * intro.cycles,
                unit: unit,
              ),
            ),
            eligibility: switch (eligibility) {
              IntroEligibilityStatus.introEligibilityStatusEligible =>
                TrialEligibility.eligible,
              IntroEligibilityStatus.introEligibilityStatusIneligible =>
                TrialEligibility.ineligible,
              _ => TrialEligibility.unknown,
            },
          ),
          null => null,
        };
  return SubscriptionPlanOffer(
    plan: plan,
    productId: product.identifier,
    price: product.priceString,
    amount: product.price,
    currencyCode: product.currencyCode,
    period:
        parseSubscriptionPeriod(product.subscriptionPeriod) ??
        switch (plan) {
          SubscriptionPlan.monthly => SubscriptionPeriod.oneMonth,
          SubscriptionPlan.yearly => SubscriptionPeriod.oneYear,
        },
    freeTrial: freeTrial,
  );
}

/// [period] in weeks when it's a whole number of days divisible by seven
/// (StoreKit can report a one-week trial as seven days), else unchanged, so
/// the paywall says "1 week" either way. An assumption about StoreKit's
/// reporting, not observed: check on a sandbox account (#185).
SubscriptionPeriod _inWeeksWhenWhole(SubscriptionPeriod period) =>
    period.unit == SubscriptionPeriodUnit.day && period.count % 7 == 0
    ? SubscriptionPeriod(
        count: period.count ~/ 7,
        unit: SubscriptionPeriodUnit.week,
      )
    : period;

SubscriptionPeriodUnit? _unit(PeriodUnit unit) => switch (unit) {
  PeriodUnit.day => SubscriptionPeriodUnit.day,
  PeriodUnit.week => SubscriptionPeriodUnit.week,
  PeriodUnit.month => SubscriptionPeriodUnit.month,
  PeriodUnit.year => SubscriptionPeriodUnit.year,
  PeriodUnit.unknown => null,
};

/// An ISO 8601 period with one part ("P1M", "P1Y", "P7D", "P1W"), as the
/// store gives a subscription's length, or `null` for anything else.
@visibleForTesting
SubscriptionPeriod? parseSubscriptionPeriod(String? iso) {
  final match = RegExp(r'^P(\d+)([DWMY])$').firstMatch(iso ?? '');
  if (match == null) return null;
  final count = int.parse(match.group(1)!);
  if (count <= 0) return null;
  return SubscriptionPeriod(
    count: count,
    unit: switch (match.group(2)) {
      'D' => SubscriptionPeriodUnit.day,
      'W' => SubscriptionPeriodUnit.week,
      'M' => SubscriptionPeriodUnit.month,
      _ => SubscriptionPeriodUnit.year,
    },
  );
}
