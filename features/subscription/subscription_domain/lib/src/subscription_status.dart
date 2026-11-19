import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_status.freezed.dart';

/// The two plans in Steady's one subscription group: $4.99 a month and
/// $39.99 a year (prices come from the store, never from here).
enum SubscriptionPlan {
  /// Billed every month.
  monthly,

  /// Billed every year.
  yearly,
}

/// Where this Apple Account stands with the subscription.
///
/// There's no "unknown" value on purpose: when the store can't say,
/// `SubscriptionRepository.status` returns `Err`, so an unknown answer can
/// never be mistaken for [none].
enum SubscriptionAccess {
  /// Never subscribed, as far as the store knows (Restore may still find a
  /// purchase made on another device or before a reinstall).
  none,

  /// In a free period: the free week, or the free time an offer code gives.
  trial,

  /// Paying, the plan's period is current.
  subscribed,

  /// Had it, and it ended (expired, or refunded). Past coach sessions stay
  /// readable; new ones show the paywall.
  lapsed,
}

/// The subscription's state, as the store reports it.
@freezed
abstract class SubscriptionStatus with _$SubscriptionStatus {
  /// Creates a [SubscriptionStatus].
  const factory SubscriptionStatus({
    /// Where this Apple Account stands.
    required SubscriptionAccess access,

    /// The plan it's on (or was on, when [SubscriptionAccess.lapsed]);
    /// `null` for [SubscriptionAccess.none], or for a product that isn't
    /// one of Steady's two plans.
    SubscriptionPlan? plan,

    /// When the current period ends (the free period's end in a trial), or
    /// when it ended once lapsed. `null` for [SubscriptionAccess.none].
    DateTime? expiresAt,

    /// Whether it renews at [expiresAt]. `false` once the person has turned
    /// renewal off, and for anything not active.
    @Default(false) bool willRenew,

    /// Where the person manages or cancels it (Apple's subscriptions page),
    /// when the store gives one.
    Uri? manageUrl,
  }) = _SubscriptionStatus;

  const SubscriptionStatus._();

  /// Never subscribed.
  static const none = SubscriptionStatus(access: SubscriptionAccess.none);

  /// Whether the coach is unlocked: in a free period or paying.
  bool get isActive =>
      access == SubscriptionAccess.trial ||
      access == SubscriptionAccess.subscribed;
}
