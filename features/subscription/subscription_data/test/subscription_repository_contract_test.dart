import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_data/testing/subscription_repository_contract.dart';
import 'package:subscription_domain/subscription_domain.dart';
import 'package:subscription_domain/testing/in_memory_subscription_repository.dart';

import 'helpers/fake_purchases_native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RevenueCatSubscriptionRepository over the plugin channel', () {
    FakePurchasesNative? native;
    tearDown(() => native?.dispose());
    runSubscriptionRepositoryContractTests(
      (clock) => native = FakePurchasesNative(clock: clock),
    );
  });

  group('InMemorySubscriptionRepository', () {
    runSubscriptionRepositoryContractTests(_InMemoryStore.new);
  });
}

class _InMemoryStore implements SubscriptionContractStore {
  _InMemoryStore(DateTime Function() clock)
    : repository = InMemorySubscriptionRepository(clock: clock);

  @override
  final InMemorySubscriptionRepository repository;

  @override
  void sellOnly(Set<SubscriptionPlan> plans) => repository.sellOnly(plans);

  @override
  void purchaseElsewhere(SubscriptionPlan plan) =>
      repository.purchaseElsewhere(plan);

  @override
  void expire() => repository.expire();

  @override
  void turnOffRenewal() => repository.turnOffRenewal();

  @override
  void failNext(
    SubscriptionStoreFault fault,
  ) => repository.failNextWith = switch (fault) {
    SubscriptionStoreFault.cancelled => const SubscriptionCancelledFailure(),
    SubscriptionStoreFault.pending => const SubscriptionPendingFailure(),
    SubscriptionStoreFault.notAllowed => const SubscriptionNotAllowedFailure(),
    SubscriptionStoreFault.outage =>
      const SubscriptionStoreUnavailableFailure(),
  };
}
