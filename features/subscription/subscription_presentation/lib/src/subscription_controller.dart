import 'dart:async';

import 'package:failures/failures.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:subscription_domain/subscription_domain.dart';
import 'package:subscription_presentation/src/providers.dart';

part 'subscription_controller.g.dart';

Duration? _retryUnlessFailure(int retryCount, Object error) =>
    error is Failure ? null : ProviderContainer.defaultRetry(retryCount, error);

/// Where this Apple Account stands with the coach's subscription, as every
/// screen reads it: the paywall, the Coach tab, the nudge's way in and
/// Settings.
///
/// `AsyncError` carries a typed `Failure` (`SubscriptionNotConfiguredFailure`,
/// `SubscriptionStoreUnavailableFailure`): the store couldn't say, which is
/// never read as "not subscribed" ([coachNeedsSubscriptionProvider]).
///
/// **A failed purchase or restore doesn't change the state.** Unlike
/// `CheckInController` (CLAUDE.md §4), [purchaseSubscription] and
/// [restoreSubscription] return their `Result` instead of putting a failure
/// in the state: a cancelled purchase sheet says nothing about the
/// subscription, and the paywall shows each failure its own way. Only an
/// `Ok` replaces the state.
///
/// `keepAlive`: app-scoped, like the consent answer; the app re-reads it on
/// every return to the foreground ([refreshSubscription]), since a renewal,
/// a cancellation or a refund happens outside the app.
@Riverpod(keepAlive: true, retry: _retryUnlessFailure)
class SubscriptionStatusController extends _$SubscriptionStatusController {
  @override
  Future<SubscriptionStatus> build() async =>
      switch (await ref.watch(subscriptionRepositoryProvider).status()) {
        Ok(:final value) => value,
        Err(:final failure) => throw failure,
      };

  Future<Result<SubscriptionStatus>>? _inFlight;

  /// Domain event: SubscriptionPurchased. Buys [plan] through the store's
  /// sheet. Only one purchase or restore runs at a time; a second call
  /// while one is in flight gets the same result.
  Future<Result<SubscriptionStatus>> purchaseSubscription(
    SubscriptionPlan plan,
  ) => _once(() => ref.read(subscriptionRepositoryProvider).purchase(plan));

  /// Domain event: SubscriptionRestored. Asks the store for what this Apple
  /// Account already bought. Finding nothing is `Ok`, not a failure.
  Future<Result<SubscriptionStatus>> restoreSubscription() =>
      _once(() => ref.read(subscriptionRepositoryProvider).restore());

  /// Reads the status again, keeping what's shown until the answer comes.
  /// Not a domain event: nothing changed in the app, the store may have.
  Future<void> refreshSubscription() async {
    final result = await ref.read(subscriptionRepositoryProvider).status();
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        state = AsyncData(value);
      case Err(:final failure):
        // Keep a known answer over a passing outage.
        if (!state.hasValue) state = AsyncError(failure, StackTrace.current);
    }
  }

  Future<Result<SubscriptionStatus>> _once(
    Future<Result<SubscriptionStatus>> Function() call,
  ) {
    final running = _inFlight;
    if (running != null) return running;
    return _inFlight = () async {
      try {
        final result = await call();
        if (result case Ok(:final value) when ref.mounted) {
          state = AsyncData(value);
        }
        return result;
      } finally {
        _inFlight = null;
      }
    }();
  }
}

/// Whether the coach has to be bought before it can be used here: `true`
/// only once the store has said this Apple Account has no active
/// subscription (never subscribed, or lapsed).
///
/// `false` while it's being read, and when the store couldn't say (a build
/// with no store key, an outage): the client check is a convenience, and
/// the proxy checks Apple's signed transaction itself (#182), so an
/// unknown answer never locks the coach. `false` where there's no
/// subscription at all ([subscriptionSupportAvailableProvider], the Mac).
@riverpod
bool coachNeedsSubscription(Ref ref) {
  if (!ref.watch(subscriptionSupportAvailableProvider)) return false;
  final status = ref.watch(subscriptionStatusControllerProvider).value;
  return status != null && !status.isActive;
}

/// [coachNeedsSubscriptionProvider] once the status has been read, for an
/// action (a tap) that has to wait for the answer. An error reads as
/// `false`, like the provider.
Future<bool> readCoachNeedsSubscription({
  required bool supported,
  required Future<SubscriptionStatus> status,
}) async {
  if (!supported) return false;
  try {
    return !(await status).isActive;
  } on Object {
    return false;
  }
}

/// The plans on sale now, for the paywall. Auto-disposed with it, so every
/// opening asks the store again (prices and trial eligibility can change).
@Riverpod(retry: _retryUnlessFailure)
Future<SubscriptionOffer> subscriptionOffer(Ref ref) async =>
    switch (await ref.watch(subscriptionRepositoryProvider).offer()) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
