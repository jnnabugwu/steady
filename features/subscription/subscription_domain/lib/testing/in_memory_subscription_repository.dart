import 'package:failures/failures.dart';
import 'package:subscription_domain/subscription_domain.dart';

/// An Apple Account's purchase, as the fake store holds it.
class _Purchase {
  _Purchase(this.plan, {required this.trial, required this.expiresAt});

  final SubscriptionPlan plan;
  final bool trial;
  DateTime expiresAt;
  bool willRenew = true;
}

/// A [SubscriptionRepository] held in memory, for tests.
///
/// It lives in the domain package (under `lib/testing/`, not exported from
/// `subscription_domain.dart`) so presentation tests can use it without
/// depending on `subscription_data`, which FFCA doesn't allow.
/// `subscription_data`'s tests run the shared contract against this and
/// `RevenueCatSubscriptionRepository` (over a fake of the plugin's native
/// side) alike. Test-only: never bind it in the app.
///
/// **What it models is our reading of StoreKit, not StoreKit.** These are
/// assumptions, checked against a sandbox account on a real iPhone only
/// (#185), not by any test here:
///
/// - one free trial per Apple Account per subscription group: after either
///   plan's trial, both plans are [TrialEligibility.ineligible];
/// - a purchase made on another device, or before a reinstall, isn't seen
///   by this install until [restore] ([purchaseElsewhere]);
/// - buying while already active changes nothing (no plan switching).
class InMemorySubscriptionRepository implements SubscriptionRepository {
  /// Creates a store selling [offer] (both plans, $4.99 and $39.99, each
  /// with a free week, by default), reading the time from [clock].
  InMemorySubscriptionRepository({
    SubscriptionOffer offer = defaultOffer,
    DateTime Function()? clock,
  }) : _sold = offer,
       _clock = clock ?? DateTime.now;

  /// Steady's two plans as App Store Connect is meant to sell them (#180),
  /// in US dollars, with the free week on both.
  static const defaultOffer = SubscriptionOffer(
    plans: [
      SubscriptionPlanOffer(
        plan: SubscriptionPlan.monthly,
        productId: 'steady_monthly',
        price: r'$4.99',
        amount: 4.99,
        currencyCode: 'USD',
        period: SubscriptionPeriod.oneMonth,
        freeTrial: FreeTrial(
          length: SubscriptionPeriod.oneWeek,
          eligibility: TrialEligibility.eligible,
        ),
      ),
      SubscriptionPlanOffer(
        plan: SubscriptionPlan.yearly,
        productId: 'steady_yearly',
        price: r'$39.99',
        amount: 39.99,
        currencyCode: 'USD',
        period: SubscriptionPeriod.oneYear,
        freeTrial: FreeTrial(
          length: SubscriptionPeriod.oneWeek,
          eligibility: TrialEligibility.eligible,
        ),
      ),
    ],
  );

  /// Apple's subscriptions page, which a real store gives as the manage
  /// link.
  static final Uri manageUrl = Uri.parse(
    'https://apps.apple.com/account/subscriptions',
  );

  SubscriptionOffer _sold;
  final DateTime Function() _clock;

  _Purchase? _onAccount;
  bool _seenHere = false;
  bool _trialUsed = false;

  /// When set, the next call returns `Err` of this failure and changes
  /// nothing, and this is cleared.
  Failure? failNextWith;

  /// How many times [purchase] reached the store, failures included.
  int purchaseCalls = 0;

  /// How many times [restore] reached the store, failures included.
  int restoreCalls = 0;

  /// Sells only [plans] from now on (a product Apple hasn't approved is
  /// left out of the offer).
  void sellOnly(Set<SubscriptionPlan> plans) => _sold = SubscriptionOffer(
    plans: [
      for (final p in _sold.plans)
        if (plans.contains(p.plan)) p,
    ],
  );

  /// Puts [plan] on the Apple Account as if bought on another device or
  /// before a reinstall: [status] doesn't show it until [restore].
  void purchaseElsewhere(SubscriptionPlan plan, {bool trial = false}) {
    final offer = _planOffer(plan) ?? defaultOffer.planFor(plan)!;
    _onAccount = _Purchase(
      plan,
      trial: trial,
      expiresAt: _end(trial ? offer.freeTrial!.length : offer.period),
    );
    if (trial) _trialUsed = true;
    _seenHere = false;
  }

  /// Ends the current subscription now, as an expiry or a refund does.
  void expire() {
    final purchase = _onAccount;
    if (purchase == null) return;
    purchase
      ..expiresAt = _clock().subtract(const Duration(seconds: 1))
      ..willRenew = false;
  }

  /// Turns renewal off, as cancelling in Apple's settings does; it stays
  /// active until it expires.
  void turnOffRenewal() => _onAccount?.willRenew = false;

  @override
  ResultFuture<SubscriptionStatus> status() async =>
      _failure<SubscriptionStatus>() ?? Ok(_status());

  @override
  ResultFuture<SubscriptionOffer> offer() async {
    if (_failure<SubscriptionOffer>() case final failure?) return failure;
    return Ok(
      SubscriptionOffer(
        plans: [
          for (final p in _sold.plans)
            if (p.freeTrial case final trial?)
              p.copyWith(
                freeTrial: trial.copyWith(
                  eligibility: _trialUsed
                      ? TrialEligibility.ineligible
                      : trial.eligibility,
                ),
              )
            else
              p,
        ],
      ),
    );
  }

  @override
  ResultFuture<SubscriptionStatus> purchase(SubscriptionPlan plan) async {
    purchaseCalls++;
    if (_failure<SubscriptionStatus>() case final failure?) return failure;
    final offer = _planOffer(plan);
    if (offer == null) {
      return const Err(SubscriptionStoreUnavailableFailure());
    }
    if (_status().isActive) return Ok(_status());
    final trial = offer.freeTrial;
    final withTrial =
        trial != null &&
        !_trialUsed &&
        trial.eligibility == TrialEligibility.eligible;
    _onAccount = _Purchase(
      plan,
      trial: withTrial,
      expiresAt: _end(withTrial ? trial.length : offer.period),
    );
    if (withTrial) _trialUsed = true;
    _seenHere = true;
    return Ok(_status());
  }

  @override
  ResultFuture<SubscriptionStatus> restore() async {
    restoreCalls++;
    if (_failure<SubscriptionStatus>() case final failure?) return failure;
    _seenHere = true;
    return Ok(_status());
  }

  SubscriptionStatus _status() {
    final purchase = _onAccount;
    if (purchase == null || !_seenHere) return SubscriptionStatus.none;
    final active = _clock().isBefore(purchase.expiresAt);
    return SubscriptionStatus(
      access: !active
          ? SubscriptionAccess.lapsed
          : purchase.trial
          ? SubscriptionAccess.trial
          : SubscriptionAccess.subscribed,
      plan: purchase.plan,
      expiresAt: purchase.expiresAt,
      willRenew: active && purchase.willRenew,
      manageUrl: manageUrl,
    );
  }

  SubscriptionPlanOffer? _planOffer(SubscriptionPlan plan) =>
      _sold.planFor(plan);

  DateTime _end(SubscriptionPeriod period) {
    final now = _clock();
    return switch (period.unit) {
      SubscriptionPeriodUnit.day => now.add(Duration(days: period.count)),
      SubscriptionPeriodUnit.week => now.add(Duration(days: 7 * period.count)),
      SubscriptionPeriodUnit.month => DateTime(
        now.year,
        now.month + period.count,
        now.day,
        now.hour,
        now.minute,
        now.second,
      ),
      SubscriptionPeriodUnit.year => DateTime(
        now.year + period.count,
        now.month,
        now.day,
        now.hour,
        now.minute,
        now.second,
      ),
    };
  }

  Err<T>? _failure<T>() {
    final failure = failNextWith;
    if (failure == null) return null;
    failNextWith = null;
    return Err(failure);
  }
}
