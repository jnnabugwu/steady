import 'package:failures/failures.dart';

/// The person closed the store's purchase sheet without buying. Not an
/// error to show: the paywall just stays as it was.
class SubscriptionCancelledFailure extends Failure {
  /// Creates a [SubscriptionCancelledFailure].
  const SubscriptionCancelledFailure({super.cause})
    : super('The purchase was cancelled');
}

/// The purchase is waiting on someone else, such as a parent approving Ask
/// to Buy, or on the bank. Nothing is unlocked yet; it unlocks once the
/// store says so (the next status read).
class SubscriptionPendingFailure extends Failure {
  /// Creates a [SubscriptionPendingFailure].
  const SubscriptionPendingFailure({super.cause})
    : super('The purchase is waiting for approval');
}

/// This Apple Account isn't allowed to buy, for example Screen Time's
/// in-app purchase restriction. Trying again won't help until that
/// changes.
class SubscriptionNotAllowedFailure extends Failure {
  /// Creates a [SubscriptionNotAllowedFailure].
  const SubscriptionNotAllowedFailure({super.cause})
    : super('Purchases are not allowed on this device');
}

/// The store couldn't be reached or couldn't answer: offline, an App Store
/// outage, or a plan that isn't on sale yet (Apple leaves out products it
/// hasn't approved). Nothing changed; trying again may work.
class SubscriptionStoreUnavailableFailure extends Failure {
  /// Creates a [SubscriptionStoreUnavailableFailure].
  const SubscriptionStoreUnavailableFailure({super.cause})
    : super('The App Store is not available right now');
}

/// This build has no purchase setup: no store key (`REVENUECAT_API_KEY`),
/// or one that can't be used in this build type. Nothing can be bought or
/// read; the coach treats it like the proxy being off.
class SubscriptionNotConfiguredFailure extends Failure {
  /// Creates a [SubscriptionNotConfiguredFailure].
  const SubscriptionNotConfiguredFailure({super.cause})
    : super('Purchases are not set up in this build');
}
