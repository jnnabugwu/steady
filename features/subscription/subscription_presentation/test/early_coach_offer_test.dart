import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:subscription_domain/subscription_domain.dart';
import 'package:subscription_domain/testing/in_memory_early_coach_user_repository.dart';
import 'package:subscription_domain/testing/in_memory_subscription_repository.dart';
import 'package:subscription_presentation/subscription_presentation.dart';

import 'helpers.dart';

// The paywall's offer for people who used the coach on 1.0 (#188). The
// redemption itself is Apple's sheet; InMemorySubscriptionRepository's
// redeemOfferCode stands in for Apple finishing it, and whether StoreKit
// reports the free time as a trial is #185's to check.
void main() {
  late InMemorySubscriptionRepository store;
  late int subscribed;

  setUp(() {
    store = InMemorySubscriptionRepository(clock: () => testNow);
    subscribed = 0;
  });

  Future<void> pump(
    WidgetTester tester, {
    bool? usedCoach,
    String code = 'STEADYCOACH',
  }) => pumpWithStore(
    tester,
    store,
    PaywallModule(
      onSubscribed: () => subscribed++,
      onNotNow: () {},
      onLinkRequested: (_) {},
      privacyPolicyUrl: Uri.parse('https://example.com/privacy'),
    ),
    overrides: [
      earlyCoachUserRepositoryProvider.overrideWithValue(
        InMemoryEarlyCoachUserRepository(decided: usedCoach),
      ),
      earlyCoachOfferCodeProvider.overrideWithValue(code),
    ],
  );

  final card = find.byKey(const Key('earlyCoachOfferCard'));

  testWidgets('used the coach on 1.0: the offer, with the code, above the '
      'normal plans', (tester) async {
    await pump(tester, usedCoach: true);
    expect(card, findsOneWidget);
    expect(find.text(PaywallCopy.earlyCoachOffer), findsOneWidget);
    expect(
      tester
          .widget<SelectableText>(find.byKey(const Key('earlyCoachOfferCode')))
          .data,
      'STEADYCOACH',
    );
    // The normal plans are still there, below it.
    final plans = find.byKey(const Key('paywallPlan_monthly'));
    expect(plans, findsOneWidget);
    expect(tester.getTopLeft(card).dy, lessThan(tester.getTopLeft(plans).dy));
  });

  for (final (label, usedCoach, code) in [
    ('did not use the coach on 1.0', false, 'STEADYCOACH'),
    ('not decided yet', null, 'STEADYCOACH'),
    ('used it, but the build has no code', true, ''),
    ('used it, but the code is blank', true, '   '),
  ]) {
    testWidgets('$label: no offer', (tester) async {
      await pump(tester, usedCoach: usedCoach, code: code);
      expect(card, findsNothing);
      expect(find.byKey(const Key('paywallPlan_monthly')), findsOneWidget);
    });
  }

  testWidgets('Redeem opens Apple’s sheet; once Apple confirms, Check '
      'again opens the coach', (tester) async {
    await pump(tester, usedCoach: true);
    await tapKey(tester, 'earlyCoachOfferRedeem');
    expect(store.offerCodeSheetCalls, 1);
    expect(find.text(PaywallCopy.afterRedeem), findsOneWidget);
    expect(subscribed, 0);

    store.redeemOfferCode(SubscriptionPlan.monthly);
    await tapKey(tester, 'earlyCoachOfferCheckAgain');
    expect(subscribed, 1);
  });

  testWidgets('a sheet that fails to open says so', (tester) async {
    await pump(tester, usedCoach: true);
    store.failNextWith = const SubscriptionStoreUnavailableFailure();
    await tapKey(tester, 'earlyCoachOfferRedeem');
    expect(find.byKey(const Key('earlyCoachOfferCheckAgain')), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const Key('earlyCoachOfferMessage'))).data,
      contains('Couldn’t reach the App Store'),
    );
  });

  testWidgets('a failed read of the flag is no offer', (tester) async {
    final flag = InMemoryEarlyCoachUserRepository(decided: true)
      ..failNextWith = const EarlyCoachUserStorageFailure('disk');
    await pumpWithStore(
      tester,
      store,
      PaywallModule(
        onSubscribed: () {},
        onNotNow: () {},
        onLinkRequested: (_) {},
        privacyPolicyUrl: Uri.parse('https://example.com/privacy'),
      ),
      overrides: [
        earlyCoachUserRepositoryProvider.overrideWithValue(flag),
        earlyCoachOfferCodeProvider.overrideWithValue('STEADYCOACH'),
      ],
    );
    expect(card, findsNothing);
  });

  test('the offer copy is Steady, never Plus or upgrade', () {
    for (final line in [
      PaywallCopy.earlyCoachOffer,
      PaywallCopy.earlyCoachOfferHow,
      PaywallCopy.afterRedeem,
    ]) {
      expect(line.toLowerCase(), isNot(contains('plus')));
      expect(line.toLowerCase(), isNot(contains('upgrade')));
    }
  });
}
