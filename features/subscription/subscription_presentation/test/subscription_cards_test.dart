import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:subscription_domain/subscription_domain.dart';
import 'package:subscription_domain/testing/in_memory_subscription_repository.dart';
import 'package:subscription_presentation/subscription_presentation.dart';

import 'helpers.dart';

void main() {
  late InMemorySubscriptionRepository store;
  late int plans;
  late List<Uri> links;

  setUp(() {
    store = InMemorySubscriptionRepository(clock: () => testNow);
    plans = 0;
    links = [];
  });

  Future<void> pumpSettings(WidgetTester tester, {bool supported = true}) =>
      pumpWithStore(
        tester,
        store,
        SingleChildScrollView(
          child: SubscriptionSettingsCard(
            onPlansRequested: () => plans++,
            onLinkRequested: links.add,
          ),
        ),
        supported: supported,
      );

  group('SubscriptionSettingsCard', () {
    testWidgets('not subscribed: See plans and Restore, no Manage', (
      tester,
    ) async {
      await pumpSettings(tester);
      expect(find.byKey(const Key('subscriptionSeePlans')), findsOneWidget);
      expect(find.byKey(const Key('subscriptionRestore')), findsOneWidget);
      expect(find.byKey(const Key('subscriptionManage')), findsNothing);
      await tapKey(tester, 'subscriptionSeePlans');
      expect(plans, 1);
    });

    testWidgets('subscribed: its state and Manage, which opens the store '
        'page', (tester) async {
      await store.purchase(SubscriptionPlan.monthly);
      await pumpSettings(tester);
      expect(
        find.text('Free until Nov 27, then Monthly starts.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('subscriptionSeePlans')), findsNothing);
      await tapKey(tester, 'subscriptionManage');
      expect(links, [InMemorySubscriptionRepository.manageUrl]);
    });

    testWidgets('lapsed: See plans again, and Manage', (tester) async {
      await store.purchase(SubscriptionPlan.monthly);
      store.expire();
      await pumpSettings(tester);
      expect(find.byKey(const Key('subscriptionSeePlans')), findsOneWidget);
      expect(find.byKey(const Key('subscriptionManage')), findsOneWidget);
      expect(
        find.textContaining('Past conversations stay readable'),
        findsOneWidget,
      );
    });

    testWidgets('Restore finds a purchase made elsewhere', (tester) async {
      store.purchaseElsewhere(SubscriptionPlan.yearly);
      await pumpSettings(tester);
      await tapKey(tester, 'subscriptionRestore');
      expect(find.text('Restored.'), findsOneWidget);
      expect(find.textContaining('Yearly, renews'), findsOneWidget);
    });

    testWidgets('Restore with nothing says so', (tester) async {
      await pumpSettings(tester);
      await tapKey(tester, 'subscriptionRestore');
      expect(find.text(PaywallCopy.nothingToRestore), findsOneWidget);
    });

    testWidgets('a failed read can be tried again', (tester) async {
      store.failNextWith = const SubscriptionStoreUnavailableFailure();
      await pumpSettings(tester);
      expect(find.byKey(const Key('subscriptionStatusError')), findsOneWidget);
      await tapKey(tester, 'subscriptionRetry');
      expect(find.byKey(const Key('subscriptionStatusLine')), findsOneWidget);
    });

    testWidgets('no store key: says so, no buttons', (tester) async {
      store.failNextWith = const SubscriptionNotConfiguredFailure();
      await pumpSettings(tester);
      expect(
        find.text('Subscriptions aren’t available in this version of Steady.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('subscriptionRestore')), findsNothing);
    });

    testWidgets('renders nothing where there is no subscription', (
      tester,
    ) async {
      await pumpSettings(tester, supported: false);
      expect(find.byKey(const Key('subscriptionSettingsCard')), findsNothing);
    });
  });

  group('CoachSubscriptionCard', () {
    Future<void> pumpCard(WidgetTester tester) => pumpWithStore(
      tester,
      store,
      CoachSubscriptionCard(onPlansRequested: () => plans++),
    );

    testWidgets('never subscribed: what it includes, and See plans', (
      tester,
    ) async {
      await pumpCard(tester);
      expect(find.text(PaywallCopy.includes), findsOneWidget);
      await tapKey(tester, 'coachSubscriptionSeePlans');
      expect(plans, 1);
    });

    testWidgets('lapsed: says it ended, and past conversations stay', (
      tester,
    ) async {
      await store.purchase(SubscriptionPlan.monthly);
      store.expire();
      await pumpCard(tester);
      expect(find.text('Your subscription has ended'), findsOneWidget);
      expect(find.textContaining('past conversations'), findsOneWidget);
    });
  });
}
