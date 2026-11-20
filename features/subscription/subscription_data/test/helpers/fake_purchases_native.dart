import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:subscription_data/subscription_data.dart';
import 'package:subscription_data/testing/subscription_repository_contract.dart';
import 'package:subscription_domain/subscription_domain.dart';

/// A fake of the `purchases_flutter` plugin's **native** side: it answers
/// the plugin's method channel with maps in the shape the SDK's own Dart
/// models parse (`CustomerInfo.fromJson`, `Offerings.fromJson`, ...), so
/// `RevenueCatSubscriptionRepository` runs against the real `Purchases`
/// API and the real parsing, as the SDK's own tests do.
///
/// **It encodes our assumptions, twice over.** The map shapes are read
/// from the SDK's Dart source (11.0.3), not recorded from a device, and
/// the behaviour (one trial per group, a reinstall needing Restore, an
/// error's numeric code being its `PurchasesErrorCode` index) is our
/// reading of RevenueCat and StoreKit. A real sandbox run (#185) is what
/// confirms them.
class FakePurchasesNative implements SubscriptionContractStore {
  /// Installs the fake on the plugin's channel. [clock] is "now".
  FakePurchasesNative({
    DateTime Function()? clock,
    RevenueCatConfig? config = const RevenueCatConfig(apiKey: 'appl_test'),
  }) : _clock = clock ?? DateTime.now {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, _handle);
    repository = RevenueCatSubscriptionRepository(config);
  }

  static const _channel = MethodChannel('purchases_flutter');

  final DateTime Function() _clock;

  @override
  late final RevenueCatSubscriptionRepository repository;

  /// Every method the SDK called, in order.
  final List<MethodCall> calls = [];

  Set<SubscriptionPlanId> _sold = {
    SubscriptionPlanId.monthly,
    SubscriptionPlanId.yearly,
  };

  _Entitlement? _onAccount;
  bool _seenHere = false;
  bool _trialUsed = false;
  SubscriptionStoreFault? _fault;
  PlatformException? _rawFault;
  String? _rawFaultMethod;

  /// When `true`, the next `setupPurchases` throws a configuration error.
  bool failSetup = false;

  /// When `false`, eligibility checks throw (the store couldn't say).
  bool eligibilityAnswers = true;

  /// The period type the next purchase's entitlement reports, when set
  /// (e.g. `INTRO` for an offer code's free period; unconfirmed).
  String? nextPeriodType;

  /// Overrides the introductory price of every product, when set.
  Map<String, Object?>? introPriceOverride;

  /// Removes the fake from the channel.
  void dispose() => TestDefaultBinaryMessengerBinding
      .instance
      .defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, null);

  @override
  void sellOnly(Set<SubscriptionPlan> plans) =>
      _sold = {for (final p in plans) SubscriptionPlanId.of(p)};

  @override
  void purchaseElsewhere(SubscriptionPlan plan) {
    final id = SubscriptionPlanId.of(plan);
    _onAccount = _Entitlement(
      id.productId,
      periodType: 'NORMAL',
      expiresAt: id.end(_clock()),
    );
    _seenHere = false;
  }

  @override
  void expire() {
    _onAccount
      ?..expiresAt = _clock().subtract(const Duration(seconds: 1))
      ..willRenew = false;
  }

  @override
  void turnOffRenewal() => _onAccount?.willRenew = false;

  @override
  void failNext(SubscriptionStoreFault fault) => _fault = fault;

  /// Makes the next call to [method] throw [code] as the native side
  /// would.
  void throwOn(String method, PurchasesErrorCode code) {
    _rawFaultMethod = method;
    _rawFault = PlatformException(code: '${code.index}', message: code.name);
  }

  Future<Object?> _handle(MethodCall call) async {
    calls.add(call);
    if (call.method == 'setupPurchases') {
      if (failSetup) {
        failSetup = false;
        throw PlatformException(
          code: '${PurchasesErrorCode.configurationError.index}',
        );
      }
      return null;
    }
    if (_rawFault case final fault? when call.method == _rawFaultMethod) {
      _rawFault = null;
      throw fault;
    }
    // Payment faults belong to the purchase call itself; an outage hits
    // whichever store call comes next.
    if (_fault case final fault?
        when fault == SubscriptionStoreFault.outage ||
            call.method == 'purchasePackage') {
      _fault = null;
      throw PlatformException(
        code: '${_codeFor(fault).index}',
        message: fault.name,
      );
    }
    switch (call.method) {
      case 'getCustomerInfo':
        return _customerInfo();
      case 'restorePurchases':
        _seenHere = true;
        return _customerInfo();
      case 'getOfferings':
        return _offerings();
      case 'checkTrialOrIntroductoryPriceEligibility':
        if (!eligibilityAnswers) {
          throw PlatformException(
            code: '${PurchasesErrorCode.unknownError.index}',
          );
        }
        final ids = (call.arguments as Map)['productIdentifiers'] as List;
        return {
          for (final id in ids)
            id: {
              'status':
                  (_trialUsed
                          ? IntroEligibilityStatus
                                .introEligibilityStatusIneligible
                          : IntroEligibilityStatus
                                .introEligibilityStatusEligible)
                      .index,
              'description': '',
            },
        };
      case 'purchasePackage':
        final packageId = (call.arguments as Map)['packageIdentifier'];
        final id = SubscriptionPlanId.values.firstWhere(
          (p) => p.packageId == packageId,
        );
        if (_onAccount case final e? when _active(e)) {
          throw PlatformException(
            code: '${PurchasesErrorCode.productAlreadyPurchasedError.index}',
          );
        }
        final trial = !_trialUsed;
        _onAccount = _Entitlement(
          id.productId,
          periodType: nextPeriodType ?? (trial ? 'TRIAL' : 'NORMAL'),
          expiresAt: trial
              ? _clock().add(const Duration(days: 7))
              : id.end(_clock()),
        );
        nextPeriodType = null;
        _trialUsed |= trial;
        _seenHere = true;
        return {
          'customerInfo': _customerInfo(),
          'transaction': {
            'transactionIdentifier': '2000000000000001',
            'productIdentifier': id.productId,
            'purchaseDate': _clock().toUtc().toIso8601String(),
          },
        };
    }
    throw MissingPluginException(call.method);
  }

  static PurchasesErrorCode _codeFor(SubscriptionStoreFault fault) =>
      switch (fault) {
        SubscriptionStoreFault.cancelled =>
          PurchasesErrorCode.purchaseCancelledError,
        SubscriptionStoreFault.pending =>
          PurchasesErrorCode.paymentPendingError,
        SubscriptionStoreFault.notAllowed =>
          PurchasesErrorCode.purchaseNotAllowedError,
        SubscriptionStoreFault.outage => PurchasesErrorCode.networkError,
      };

  bool _active(_Entitlement e) => _clock().isBefore(e.expiresAt);

  Map<String, Object?> _customerInfo() {
    final e = _seenHere ? _onAccount : null;
    final entitlement = e == null
        ? null
        : {
            'identifier': SteadySubscriptionIds.entitlement,
            'isActive': _active(e),
            'willRenew': _active(e) && e.willRenew,
            'latestPurchaseDate': _clock().toUtc().toIso8601String(),
            'originalPurchaseDate': _clock().toUtc().toIso8601String(),
            'productIdentifier': e.productId,
            'isSandbox': true,
            'ownershipType': 'PURCHASED',
            'store': 'APP_STORE',
            'periodType': e.periodType,
            'expirationDate': e.expiresAt.toUtc().toIso8601String(),
            'unsubscribeDetectedAt': null,
            'billingIssueDetectedAt': null,
            'verification': 'NOT_REQUESTED',
          };
    return {
      'originalAppUserId': r'$RCAnonymousID:0000',
      'entitlements': {
        'all': {SteadySubscriptionIds.entitlement: ?entitlement},
        'active': {
          if (e != null && _active(e))
            SteadySubscriptionIds.entitlement: entitlement,
        },
        'verification': 'NOT_REQUESTED',
      },
      'activeSubscriptions': [if (e != null && _active(e)) e.productId],
      'latestExpirationDate': e?.expiresAt.toUtc().toIso8601String(),
      'allExpirationDates': {
        if (e != null) e.productId: e.expiresAt.toUtc().toIso8601String(),
      },
      'allPurchasedProductIdentifiers': [?e?.productId],
      'firstSeen': _clock().toUtc().toIso8601String(),
      'requestDate': _clock().toUtc().toIso8601String(),
      'allPurchaseDates': <String, Object?>{},
      'originalApplicationVersion': '1.0',
      'nonSubscriptionTransactions': <Object?>[],
      'managementURL': 'https://apps.apple.com/account/subscriptions',
    };
  }

  Map<String, Object?> _offerings() {
    const context = {'offeringIdentifier': 'default'};
    Map<String, Object?> package(SubscriptionPlanId id) => {
      'identifier': id.packageId,
      'packageType': id.packageType,
      'presentedOfferingContext': context,
      'product': {
        'identifier': id.productId,
        'description': 'The coach',
        'title': 'Steady',
        'price': id.price,
        'priceString': id.priceString,
        'currencyCode': 'USD',
        'subscriptionPeriod': id.isoPeriod,
        'productCategory': 'SUBSCRIPTION',
        'introPrice':
            introPriceOverride ??
            {
              'price': 0,
              'priceString': r'$0.00',
              'period': 'P1W',
              'cycles': 1,
              'periodUnit': 'WEEK',
              'periodNumberOfUnits': 1,
            },
        'presentedOfferingContext': context,
      },
    };
    final sold = [
      for (final id in SubscriptionPlanId.values)
        if (_sold.contains(id)) id,
    ];
    final offering = {
      'identifier': 'default',
      'serverDescription': 'Steady',
      'metadata': <String, Object?>{},
      'availablePackages': [for (final id in sold) package(id)],
      for (final id in sold) id.offeringKey: package(id),
    };
    return {
      'all': {'default': offering},
      'current': offering,
    };
  }
}

class _Entitlement {
  _Entitlement(
    this.productId, {
    required this.periodType,
    required this.expiresAt,
  });

  final String productId;
  final String periodType;
  DateTime expiresAt;
  bool willRenew = true;
}

/// Steady's two products as RevenueCat's offering carries them.
enum SubscriptionPlanId {
  /// $4.99 a month.
  monthly(
    productId: SteadySubscriptionIds.monthlyProduct,
    packageId: r'$rc_monthly',
    packageType: 'MONTHLY',
    offeringKey: 'monthly',
    price: 4.99,
    priceString: r'$4.99',
    isoPeriod: 'P1M',
  ),

  /// $39.99 a year.
  yearly(
    productId: SteadySubscriptionIds.yearlyProduct,
    packageId: r'$rc_annual',
    packageType: 'ANNUAL',
    offeringKey: 'annual',
    price: 39.99,
    priceString: r'$39.99',
    isoPeriod: 'P1Y',
  );

  SubscriptionPlanId({
    required this.productId,
    required this.packageId,
    required this.packageType,
    required this.offeringKey,
    required this.price,
    required this.priceString,
    required this.isoPeriod,
  });

  /// The plan's id for [plan].
  static SubscriptionPlanId of(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.monthly => monthly,
    SubscriptionPlan.yearly => yearly,
  };

  final String productId;
  final String packageId;
  final String packageType;
  final String offeringKey;
  final double price;
  final String priceString;
  final String isoPeriod;

  /// When a paid period starting at [start] ends.
  DateTime end(DateTime start) => switch (this) {
    monthly => start.add(const Duration(days: 30)),
    yearly => start.add(const Duration(days: 365)),
  };
}
