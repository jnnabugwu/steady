import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:subscription_domain/src/subscription_status.dart';

part 'subscription_offer.freezed.dart';

/// A unit of a subscription period.
enum SubscriptionPeriodUnit {
  /// Days.
  day,

  /// Weeks.
  week,

  /// Months.
  month,

  /// Years.
  year,
}

/// A length of time, such as "1 month" or "7 days", as the store gives it.
@freezed
abstract class SubscriptionPeriod with _$SubscriptionPeriod {
  /// Creates a [SubscriptionPeriod] of [count] [unit]s.
  const factory SubscriptionPeriod({
    required int count,
    required SubscriptionPeriodUnit unit,
  }) = _SubscriptionPeriod;

  /// One month.
  static const oneMonth = SubscriptionPeriod(
    count: 1,
    unit: SubscriptionPeriodUnit.month,
  );

  /// One year.
  static const oneYear = SubscriptionPeriod(
    count: 1,
    unit: SubscriptionPeriodUnit.year,
  );

  /// One week, the free week.
  static const oneWeek = SubscriptionPeriod(
    count: 1,
    unit: SubscriptionPeriodUnit.week,
  );
}

/// Whether this Apple Account can still get a plan's free trial.
enum TrialEligibility {
  /// It can: the store will start with the free period.
  eligible,

  /// It can't: it already had an introductory offer in this subscription
  /// group (Apple allows one per Apple Account per group).
  ineligible,

  /// The store couldn't say. The paywall then shows the price without the
  /// trial, so it never promises a free week the store won't give.
  unknown,
}

/// A plan's free introductory period, as set up in App Store Connect.
@freezed
abstract class FreeTrial with _$FreeTrial {
  /// Creates a [FreeTrial].
  const factory FreeTrial({
    /// How long it is (one week for Steady's free week).
    required SubscriptionPeriod length,

    /// Whether this Apple Account can get it.
    required TrialEligibility eligibility,
  }) = _FreeTrial;

  const FreeTrial._();

  /// Whether the paywall may offer it: only when the store says
  /// [TrialEligibility.eligible].
  bool get offered => eligibility == TrialEligibility.eligible;
}

/// One plan as the store sells it right now, in the person's storefront.
@freezed
abstract class SubscriptionPlanOffer with _$SubscriptionPlanOffer {
  /// Creates a [SubscriptionPlanOffer].
  const factory SubscriptionPlanOffer({
    /// Which of Steady's plans this is.
    required SubscriptionPlan plan,

    /// The App Store product id.
    required String productId,

    /// The billed price, localized by the store ("$4.99", "39,99 €"). The
    /// paywall shows this as the largest price (App Store 3.1.2).
    required String price,

    /// The billed price as a number, in [currencyCode].
    required double amount,

    /// The ISO 4217 currency code of [amount].
    required String currencyCode,

    /// How often it bills.
    required SubscriptionPeriod period,

    /// Its free trial, or `null` if it has none. A paid introductory price
    /// isn't something Steady sells, so it's left out rather than shown as
    /// a trial.
    FreeTrial? freeTrial,
  }) = _SubscriptionPlanOffer;
}

/// What the paywall can sell: the plans the store has on sale now.
///
/// Prices and trials always come from the store, never from the app. A
/// plan Apple hasn't approved yet is missing from [plans] (the store leaves
/// it out), so never assume both are here.
@freezed
abstract class SubscriptionOffer with _$SubscriptionOffer {
  /// Creates a [SubscriptionOffer].
  const factory SubscriptionOffer({
    /// On sale now, monthly first.
    required List<SubscriptionPlanOffer> plans,
  }) = _SubscriptionOffer;

  const SubscriptionOffer._();

  /// [plan]'s offer, or `null` if it isn't on sale.
  SubscriptionPlanOffer? planFor(SubscriptionPlan plan) {
    for (final offer in plans) {
      if (offer.plan == plan) return offer;
    }
    return null;
  }
}
