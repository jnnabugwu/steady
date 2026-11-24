import 'package:failures/failures.dart';
import 'package:subscription_domain/src/subscription_offer.dart';
import 'package:subscription_domain/src/subscription_status.dart';

/// Reads, buys and restores the coach's subscription through the store.
///
/// The store is the record: nothing here is kept by Steady. Every call may
/// show Apple's own UI ([purchase]'s sheet, [restore]'s sign-in prompt),
/// so [purchase] and [restore] run only from a tap.
///
/// Failures (all typed, from `subscription_failures.dart`):
///
/// - `SubscriptionCancelledFailure`: [purchase] sheet closed without
///   buying. Show nothing.
/// - `SubscriptionPendingFailure`: [purchase] waits on Ask to Buy or the
///   bank.
/// - `SubscriptionNotAllowedFailure`: this account can't buy.
/// - `SubscriptionStoreUnavailableFailure`: the store couldn't answer, or
///   [purchase] was asked for a plan that isn't on sale.
/// - `SubscriptionNotConfiguredFailure`: this build has no purchase setup.
abstract class SubscriptionRepository {
  /// Where this Apple Account stands now. May answer from the SDK's cache
  /// when offline.
  ResultFuture<SubscriptionStatus> status();

  /// The plans on sale now, with the store's localized prices and whether
  /// this account can still get each free trial.
  ResultFuture<SubscriptionOffer> offer();

  /// Buys [plan] through the store's sheet. Returns the status after the
  /// purchase ([SubscriptionAccess.trial] when the free week started).
  ResultFuture<SubscriptionStatus> purchase(SubscriptionPlan plan);

  /// Asks the store for purchases this Apple Account already made (another
  /// device, a reinstall). Finding none isn't a failure: it returns
  /// [SubscriptionStatus.none] (or lapsed, if one ended).
  ResultFuture<SubscriptionStatus> restore();

  /// Opens Apple's offer code sheet, where the person types a code (#188:
  /// two weeks free for people who used the coach on 1.0). Returns once the
  /// sheet is shown, not when a code is redeemed: Apple finishes that on
  /// its own, and the next [status] read shows it.
  ResultFuture<Unit> presentOfferCodeRedemption();
}
