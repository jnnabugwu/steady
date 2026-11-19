/// The coach's subscription on RevenueCat: `RevenueCatSubscriptionRepository`
/// over `purchases_flutter` (StoreKit 2, Swift Package Manager), and its
/// build-time configuration (`RevenueCatConfig`).
///
/// The only package in Steady that imports the purchase SDK
/// (docs/technical_decisions.md, "The coach is paid", item 10). Anonymous
/// RevenueCat IDs, no sign-in, and no attribution IDs or customer
/// attributes, so no App Tracking Transparency prompt and no health data
/// in RevenueCat.
///
/// `package:subscription_data/testing/subscription_repository_contract.dart`
/// is the shared contract, run here against the RevenueCat implementation
/// and the domain's in-memory fake.
library;

export 'src/file_early_coach_user_repository.dart';
export 'src/revenuecat_config.dart';
export 'src/revenuecat_subscription_repository.dart';
