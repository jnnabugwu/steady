import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_domain/testing/in_memory_subscription_repository.dart';
import 'package:subscription_presentation/subscription_presentation.dart';

void main() {
  test('unbound, the repository throws and support is off', () {
    final container = ProviderContainer.test();
    expect(
      () => container.read(subscriptionRepositoryProvider),
      throwsA(anything),
    );
    expect(container.read(subscriptionSupportAvailableProvider), isFalse);
  });

  test('bound, it is the instance given', () {
    final repo = InMemorySubscriptionRepository();
    final container = ProviderContainer.test(
      overrides: [subscriptionRepositoryProvider.overrideWithValue(repo)],
    );
    expect(container.read(subscriptionRepositoryProvider), same(repo));
  });
}
