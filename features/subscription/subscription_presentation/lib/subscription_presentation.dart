/// The coach's subscription, for the screens: Steady's own paywall
/// (`PaywallModule`, shadcn / ui_kit, never RevenueCat's native paywall),
/// the status every screen reads (`subscriptionStatusControllerProvider`),
/// the Coach tab's card for when the coach needs a subscription
/// (`CoachSubscriptionCard`), the Settings section
/// (`SubscriptionSettingsCard`) and the providers the app binds.
///
/// Depends on `subscription_domain` only, never `subscription_data`, so no
/// screen ever sees the purchase SDK (CLAUDE.md §3). Knows nothing about
/// routing or the coach: the app decides where each callback goes
/// (CLAUDE.md §5). Sends no analytics events.
library;

export 'src/coach_subscription_card.dart';
export 'src/early_coach_offer_card.dart';
export 'src/paywall_copy.dart';
export 'src/paywall_module.dart';
export 'src/providers.dart';
export 'src/subscription_controller.dart';
export 'src/subscription_settings_card.dart';
