/// The coach's subscription, for the screens: the providers the app binds
/// (`subscriptionRepositoryProvider`, `subscriptionSupportAvailableProvider`).
///
/// Depends on `subscription_domain` only, never `subscription_data`, so no
/// screen ever sees the purchase SDK (CLAUDE.md §3).
library;

export 'src/providers.dart';
