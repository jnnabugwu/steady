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

/// Whether the person on this iPhone used the coach on Steady 1.0, decided
/// once at the first 1.1.0 launch (#188), or `null` where it isn't bound
/// (no offer). `app/lib/providers.dart` binds it on iOS only, to the
/// device-only file next to `coach_consent.json`.
///
/// `keepAlive`: the file store serializes its own reads and writes (D6).
@Riverpod(keepAlive: true)
EarlyCoachUserRepository? earlyCoachUserRepository(Ref ref) => null;

/// The offer code that gives 1.0's coach users two weeks free (#188), from
/// `--dart-define=EARLY_COACH_OFFER_CODE`, never the repo; blank where the
/// build has none, and then the offer isn't shown.
///
/// `keepAlive`: a constant for the app's lifetime.
@Riverpod(keepAlive: true)
String earlyCoachOfferCode(Ref ref) => '';

/// Whether this device sells the coach's subscription at all: `true` on iOS
/// only, where the coach is. A platform fact, not whether the build has a
/// store key or the store answers (`SubscriptionNotConfiguredFailure`,
/// `SubscriptionStoreUnavailableFailure`). `false` by default;
/// `app/lib/providers.dart` sets it with the repository.
///
/// `keepAlive`: a constant for the app's lifetime.
@Riverpod(keepAlive: true)
bool subscriptionSupportAvailable(Ref ref) => false;
