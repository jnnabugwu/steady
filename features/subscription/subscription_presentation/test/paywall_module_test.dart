import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:subscription_domain/subscription_domain.dart';
import 'package:subscription_domain/testing/in_memory_subscription_repository.dart';
import 'package:subscription_presentation/subscription_presentation.dart';

import 'helpers.dart';

// Against InMemorySubscriptionRepository: what the screen does with the
// store's answers. Whether StoreKit gives those answers is #185's to check.
void main() {
  late InMemorySubscriptionRepository store;
  late int subscribed;
  late int notNow;
  late List<Uri> links;
  final privacy = Uri.parse('https://example.com/privacy');

  setUp(() {
    store = InMemorySubscriptionRepository(clock: () => testNow);
    subscribed = 0;
    notNow = 0;
    links = [];
  });

  Future<void> pump(WidgetTester tester) => pumpWithStore(
    tester,
    store,
    PaywallModule(
      onSubscribed: () => subscribed++,
      onNotNow: () => notNow++,
      onLinkRequested: links.add,
      privacyPolicyUrl: privacy,
    ),
  );

  testWidgets('shows what Apple requires, from the store', (tester) async {
    await pump(tester);
    final text = allText(tester);
    // What it includes, and what stays free.
    expect(text, contains(PaywallCopy.includes));
    expect(text, contains(PaywallCopy.staysFree));
    // Both plans, the store's prices, the trial and the price after it.
    expect(find.byKey(const Key('paywallPrice_monthly')), findsOneWidget);
    expect(text, contains(r'$4.99'));
    expect(text, contains(r'$39.99'));
    expect(text, contains(r'1 week free, then $4.99 a month'));
    expect(text, contains(r'1 week free, then $39.99 a year'));
    expect(
      text,
      contains(
        r'Free for 1 week, then $4.99 a month, charged to your Apple '
        'Account. It renews automatically until you cancel.',
      ),
    );
    // Cancel anytime, Restore, Terms and Privacy.
    expect(text, contains(PaywallCopy.cancelAnytime));
    expect(find.byKey(const Key('paywallRestore')), findsOneWidget);
    expect(find.byKey(const Key('paywallTerms')), findsOneWidget);
    expect(find.byKey(const Key('paywallPrivacy')), findsOneWidget);
    expect(find.text(PaywallCopy.startTrial), findsOneWidget);
  });

  testWidgets('the billed price is the largest price on the screen', (
    tester,
  ) async {
    await pump(tester);
    final price = tester.widget<Text>(
      find.byKey(const Key('paywallPrice_monthly')),
    );
    final trial = tester.widget<Text>(
      find.text(r'1 week free, then $4.99 a month'),
    );
    final small = tester.widget<Text>(
      find.byKey(const Key('paywallSmallPrint')),
    );
    expect(price.style!.fontSize, greaterThan(trial.style!.fontSize!));
    expect(price.style!.fontSize, greaterThan(small.style!.fontSize!));
  });

  testWidgets("it's Steady: never Plus, Steady+ or upgrade", (tester) async {
    await pump(tester);
    final raw = allText(tester);
    final text = raw.toLowerCase();
    // "plus your weekly coach check-in" is the decided copy; "Plus" as a
    // name is what's ruled out.
    expect(raw, isNot(contains(RegExp(r'\bPlus\b'))));
    expect(text, isNot(contains('steady plus')));
    expect(text, isNot(contains('steady+')));
    expect(text, isNot(contains('upgrade')));
    // The free daily check-in and the paid weekly coach check-in are
    // named apart.
    expect(text, contains('weekly coach check-in'));
    expect(text, contains('daily check-in'));
  });

  testWidgets('starting the free week subscribes and calls onSubscribed', (
    tester,
  ) async {
    await pump(tester);
    await tapKey(tester, 'paywallBuy');
    expect(subscribed, 1);
    expect(store.purchaseCalls, 1);
    final status = (await store.status() as Ok<SubscriptionStatus>).value;
    expect(status.access, SubscriptionAccess.trial);
    expect(status.plan, SubscriptionPlan.monthly);
  });

  testWidgets('choosing yearly buys yearly', (tester) async {
    await pump(tester);
    await tapKey(tester, 'paywallPlan_yearly');
    expect(allText(tester), contains(r'Free for 1 week, then $39.99 a year'));
    await tapKey(tester, 'paywallBuy');
    final status = (await store.status() as Ok<SubscriptionStatus>).value;
    expect(status.plan, SubscriptionPlan.yearly);
  });

  testWidgets('with no trial left, it says Subscribe and shows no free week', (
    tester,
  ) async {
    await store.purchase(SubscriptionPlan.monthly);
    store.expire();
    await pump(tester);
    final text = allText(tester);
    expect(find.text(PaywallCopy.subscribe), findsOneWidget);
    expect(text, isNot(contains('week free')));
    expect(text, isNot(contains('Free for')));
    expect(text, contains(r'$4.99 a month, charged to your Apple Account'));
  });

  testWidgets('an unknown trial eligibility shows the price without it', (
    tester,
  ) async {
    store = InMemorySubscriptionRepository(
      clock: () => testNow,
      offer: SubscriptionOffer(
        plans: [
          for (final p in InMemorySubscriptionRepository.defaultOffer.plans)
            p.copyWith(
              freeTrial: p.freeTrial!.copyWith(
                eligibility: TrialEligibility.unknown,
              ),
            ),
        ],
      ),
    );
    await pump(tester);
    expect(find.text(PaywallCopy.subscribe), findsOneWidget);
    expect(allText(tester), isNot(contains('free, then')));
  });

  testWidgets('a cancelled purchase says nothing and stays', (tester) async {
    await pump(tester);
    store.failNextWith = const SubscriptionCancelledFailure();
    await tapKey(tester, 'paywallBuy');
    expect(subscribed, 0);
    expect(find.byKey(const Key('paywallMessage')), findsNothing);
  });

  for (final (failure, words) in [
    (const SubscriptionPendingFailure(), 'Waiting for approval'),
    (const SubscriptionNotAllowedFailure(), 'Screen Time'),
    (const SubscriptionStoreUnavailableFailure(), 'Couldn’t reach the App'),
  ]) {
    testWidgets('a ${failure.runtimeType} says so and stays', (tester) async {
      await pump(tester);
      store.failNextWith = failure;
      await tapKey(tester, 'paywallBuy');
      expect(subscribed, 0);
      final message = tester.widget<Text>(
        find.byKey(const Key('paywallMessage')),
      );
      expect(message.data, contains(words));
    });
  }

  testWidgets('restore with nothing to restore says so', (tester) async {
    await pump(tester);
    await tapKey(tester, 'paywallRestore');
    expect(subscribed, 0);
    expect(find.text(PaywallCopy.nothingToRestore), findsOneWidget);
  });

  testWidgets('restore that finds an ended subscription says it ended', (
    tester,
  ) async {
    await store.purchase(SubscriptionPlan.monthly);
    store.expire();
    await pump(tester);
    await tapKey(tester, 'paywallRestore');
    expect(subscribed, 0);
    expect(find.text(PaywallCopy.restoredLapsed), findsOneWidget);
    expect(find.text(PaywallCopy.nothingToRestore), findsNothing);
  });

  testWidgets('VoiceOver can choose a plan', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    final yearly = find.byKey(const Key('paywallPlan_yearly'));
    await tester.ensureVisible(yearly);
    await tester.pumpAndSettle();
    // The tile's one node (its children are excluded) has the tap action.
    tester.semantics.tap(find.semantics.byLabel(RegExp('^Yearly, ')));
    await tester.pumpAndSettle();
    expect(allText(tester), contains(r'Free for 1 week, then $39.99 a year'));
    handle.dispose();
  });

  testWidgets('restore that finds a subscription calls onSubscribed', (
    tester,
  ) async {
    store.purchaseElsewhere(SubscriptionPlan.yearly);
    await pump(tester);
    await tapKey(tester, 'paywallRestore');
    expect(subscribed, 1);
    expect(store.restoreCalls, 1);
  });

  testWidgets('Not now and the close button change nothing', (tester) async {
    await pump(tester);
    await tapKey(tester, 'paywallNotNow');
    await tapKey(tester, 'paywallClose');
    expect(notNow, 2);
    expect(store.purchaseCalls, 0);
  });

  testWidgets("Terms of Use is Apple's standard EULA; Privacy is ours", (
    tester,
  ) async {
    await pump(tester);
    await tapKey(tester, 'paywallTerms');
    await tapKey(tester, 'paywallPrivacy');
    expect(links, [PaywallCopy.termsOfUseUrl, privacy]);
    expect(
      PaywallCopy.termsOfUseUrl.toString(),
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
    );
  });

  testWidgets('an offer that fails to load can be tried again', (tester) async {
    store.failNextOfferWith = const SubscriptionStoreUnavailableFailure();
    await pump(tester);
    expect(find.byKey(const Key('paywallOfferError')), findsOneWidget);
    expect(
      tester
          .widget<PrimaryButton>(find.byKey(const Key('paywallBuy')))
          .onPressed,
      isNull,
    );
    await tapKey(tester, 'paywallRetry');
    expect(find.byKey(const Key('paywallPrice_monthly')), findsOneWidget);
  });

  testWidgets('only the plans on sale are shown', (tester) async {
    store.sellOnly({SubscriptionPlan.yearly});
    await pump(tester);
    expect(find.byKey(const Key('paywallPlan_monthly')), findsNothing);
    expect(find.byKey(const Key('paywallPlan_yearly')), findsOneWidget);
    await tapKey(tester, 'paywallBuy');
    expect(subscribed, 1);
  });

  testWidgets('nothing on sale says so and can not be bought', (tester) async {
    store.sellOnly({});
    await pump(tester);
    expect(find.byKey(const Key('paywallNoPlans')), findsOneWidget);
    expect(
      tester
          .widget<PrimaryButton>(find.byKey(const Key('paywallBuy')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('no store key: says subscriptions are not available', (
    tester,
  ) async {
    store.failNextOfferWith = const SubscriptionNotConfiguredFailure();
    await pump(tester);
    expect(
      allText(tester),
      contains('Subscriptions aren’t available in this version of Steady.'),
    );
  });

  test('a purchase updates the shared status', () async {
    final container = ProviderContainer.test(
      overrides: [subscriptionRepositoryProvider.overrideWithValue(store)],
    );
    expect(
      await container.read(subscriptionStatusControllerProvider.future),
      SubscriptionStatus.none,
    );
    await container
        .read(subscriptionStatusControllerProvider.notifier)
        .purchaseSubscription(SubscriptionPlan.monthly);
    expect(
      container.read(subscriptionStatusControllerProvider).value?.access,
      SubscriptionAccess.trial,
    );
  });
}
