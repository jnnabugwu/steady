import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:subscription_domain/subscription_domain.dart';

part 'providers.g.dart';

/// The `SubscriptionRepository` the coach's subscription is read, bought
/// and restored through.
///
/// Typed against the domain interface only: this package never depends on
/// `subscription_data` (CLAUDE.md §3). `app/lib/providers.dart` binds it on
/// iOS only, to `RevenueCatSubscriptionRepository`; on the parked Mac it
/// stays unbound, so a path that reads it there fails loudly. Tests
/// override it with `InMemorySubscriptionRepository`. Reading it without an
/// override throws.
///
/// `keepAlive`: it owns the SDK's one-time setup (D6).
@Riverpod(keepAlive: true)
SubscriptionRepository subscriptionRepository(Ref ref) =>
    throw UnimplementedError(
      'Override subscriptionRepositoryProvider in app/ (iOS only)',
    );

/// Whether this device sells the coach's subscription at all: `true` on iOS
/// only, where the coach is. A platform fact, not whether the build has a
/// store key or the store answers (`SubscriptionNotConfiguredFailure`,
/// `SubscriptionStoreUnavailableFailure`). `false` by default;
/// `app/lib/providers.dart` sets it with the repository.
///
/// `keepAlive`: a constant for the app's lifetime.
@Riverpod(keepAlive: true)
bool subscriptionSupportAvailable(Ref ref) => false;
