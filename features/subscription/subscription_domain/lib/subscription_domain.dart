/// The coach's subscription (docs/technical_decisions.md, "The coach is
/// paid; everything on the phone is free"): whether this Apple Account has
/// it, what the store offers, and the repository that buys and restores it.
///
/// No purchase SDK here. `subscription_data` implements
/// `SubscriptionRepository` over RevenueCat's `purchases_flutter`, the only
/// package that imports it; the coach reads this package for its gate, the
/// same FFCA boundary as every other feature (CLAUDE.md §3).
///
/// Nothing about the subscription is stored by Steady: the store (StoreKit,
/// through RevenueCat) is the record. The app's answer is a convenience for
/// the screens; the proxy checks Apple's signed transaction itself (#182).
///
/// Also: whether this iPhone's person used the coach on Steady 1.0
/// (`EarlyCoachUserRepository`, #188), decided once, device-only.
///
/// `lib/testing/` has in-memory repositories for tests
/// (`in_memory_subscription_repository.dart`, and
/// `in_memory_early_coach_user_repository.dart` for the flag);
/// `subscription_data` runs the same contracts against them and its own
/// implementations.
library;

export 'src/early_coach_user_repository.dart';
export 'src/subscription_failures.dart';
export 'src/subscription_offer.dart';
export 'src/subscription_repository.dart';
export 'src/subscription_status.dart';
