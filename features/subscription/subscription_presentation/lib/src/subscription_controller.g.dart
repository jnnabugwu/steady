// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(SubscriptionStatusController)
final subscriptionStatusControllerProvider =
    SubscriptionStatusControllerProvider._();

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
final class SubscriptionStatusControllerProvider
    extends
        $AsyncNotifierProvider<
          SubscriptionStatusController,
          SubscriptionStatus
        > {
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
  SubscriptionStatusControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: _retryUnlessFailure,
        name: r'subscriptionStatusControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionStatusControllerHash();

  @$internal
  @override
  SubscriptionStatusController create() => SubscriptionStatusController();
}

String _$subscriptionStatusControllerHash() =>
    r'a9072d430163fe307f210f4e28fed264d8729584';

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

abstract class _$SubscriptionStatusController
    extends $AsyncNotifier<SubscriptionStatus> {
  FutureOr<SubscriptionStatus> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SubscriptionStatus>, SubscriptionStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SubscriptionStatus>, SubscriptionStatus>,
              AsyncValue<SubscriptionStatus>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
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

@ProviderFor(coachNeedsSubscription)
final coachNeedsSubscriptionProvider = CoachNeedsSubscriptionProvider._();

/// Whether the coach has to be bought before it can be used here: `true`
/// only once the store has said this Apple Account has no active
/// subscription (never subscribed, or lapsed).
///
/// `false` while it's being read, and when the store couldn't say (a build
/// with no store key, an outage): the client check is a convenience, and
/// the proxy checks Apple's signed transaction itself (#182), so an
/// unknown answer never locks the coach. `false` where there's no
/// subscription at all ([subscriptionSupportAvailableProvider], the Mac).

final class CoachNeedsSubscriptionProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the coach has to be bought before it can be used here: `true`
  /// only once the store has said this Apple Account has no active
  /// subscription (never subscribed, or lapsed).
  ///
  /// `false` while it's being read, and when the store couldn't say (a build
  /// with no store key, an outage): the client check is a convenience, and
  /// the proxy checks Apple's signed transaction itself (#182), so an
  /// unknown answer never locks the coach. `false` where there's no
  /// subscription at all ([subscriptionSupportAvailableProvider], the Mac).
  CoachNeedsSubscriptionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachNeedsSubscriptionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachNeedsSubscriptionHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return coachNeedsSubscription(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$coachNeedsSubscriptionHash() =>
    r'2b52e483a003d1b0da491125e545f2839ad97dde';

/// The plans on sale now, for the paywall. Auto-disposed with it, so every
/// opening asks the store again (prices and trial eligibility can change).

@ProviderFor(subscriptionOffer)
final subscriptionOfferProvider = SubscriptionOfferProvider._();

/// The plans on sale now, for the paywall. Auto-disposed with it, so every
/// opening asks the store again (prices and trial eligibility can change).

final class SubscriptionOfferProvider
    extends
        $FunctionalProvider<
          AsyncValue<SubscriptionOffer>,
          SubscriptionOffer,
          FutureOr<SubscriptionOffer>
        >
    with
        $FutureModifier<SubscriptionOffer>,
        $FutureProvider<SubscriptionOffer> {
  /// The plans on sale now, for the paywall. Auto-disposed with it, so every
  /// opening asks the store again (prices and trial eligibility can change).
  SubscriptionOfferProvider._()
    : super(
        from: null,
        argument: null,
        retry: _retryUnlessFailure,
        name: r'subscriptionOfferProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionOfferHash();

  @$internal
  @override
  $FutureProviderElement<SubscriptionOffer> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SubscriptionOffer> create(Ref ref) {
    return subscriptionOffer(ref);
  }
}

String _$subscriptionOfferHash() => r'392b1521d0041162f4e5d82653abc15cf170d01b';
