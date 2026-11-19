import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_data/subscription_data.dart';

// The StoreKit configuration file (app/ios/Products.storekit, for Xcode
// runs and the Simulator, #181) has to match what the app looks for and
// what App Store Connect sells (#180). It's a local stand-in: Xcode reads
// it only when the scheme points at it, and nothing it signs is accepted
// by the proxy (docs/research/revenuecat_paywall.md §8).
void main() {
  final config = jsonDecode(
    File('ios/Products.storekit').readAsStringSync(),
  ) as Map<String, Object?>;
  final groups = config['subscriptionGroups']! as List<Object?>;

  test('one subscription group with the two plans', () {
    expect(groups, hasLength(1));
    final subs = (groups.single! as Map)['subscriptions'] as List;
    expect(subs.map((s) => (s as Map)['productID']), [
      SteadySubscriptionIds.monthlyProduct,
      SteadySubscriptionIds.yearlyProduct,
    ]);
  });

  test('a two-week free offer code on both plans, for 1.0 coach users '
      '(#188)', () {
    for (final s in (groups.single! as Map)['subscriptions'] as List) {
      final offers = (s as Map)['codeOffers'] as List;
      expect(offers, hasLength(1));
      expect(offers.single, containsPair('paymentMode', 'free'));
      expect(offers.single, containsPair('subscriptionPeriod', 'P2W'));
    }
  });

  test(r'$4.99 a month and $39.99 a year, a free week on both, Family '
      'Sharing off', () {
    final subs = [
      for (final s in (groups.single! as Map)['subscriptions'] as List)
        s as Map,
    ];
    expect(subs.map((s) => s['displayPrice']), ['4.99', '39.99']);
    expect(subs.map((s) => s['recurringSubscriptionPeriod']), ['P1M', 'P1Y']);
    for (final s in subs) {
      expect(s['familyShareable'], isFalse);
      expect(s['introductoryOffer'], {
        'internalID': isA<String>(),
        'paymentMode': 'free',
        'subscriptionPeriod': 'P1W',
      });
    }
  });
}
