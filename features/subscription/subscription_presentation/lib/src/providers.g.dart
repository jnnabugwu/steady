// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(subscriptionRepository)
final subscriptionRepositoryProvider = SubscriptionRepositoryProvider._();

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

final class SubscriptionRepositoryProvider
    extends
        $FunctionalProvider<
          SubscriptionRepository,
          SubscriptionRepository,
          SubscriptionRepository
        >
    with $Provider<SubscriptionRepository> {
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
  SubscriptionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionRepositoryHash();

  @$internal
  @override
  $ProviderElement<SubscriptionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubscriptionRepository create(Ref ref) {
    return subscriptionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubscriptionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubscriptionRepository>(value),
    );
  }
}

String _$subscriptionRepositoryHash() =>
    r'f844b88e3f75229a058e07849e6261626a83d388';

/// Whether the person on this iPhone used the coach on Steady 1.0, decided
/// once at the first 1.1.0 launch (#188), or `null` where it isn't bound
/// (no offer). `app/lib/providers.dart` binds it on iOS only, to the
/// device-only file next to `coach_consent.json`.
///
/// `keepAlive`: the file store serializes its own reads and writes (D6).

@ProviderFor(earlyCoachUserRepository)
final earlyCoachUserRepositoryProvider = EarlyCoachUserRepositoryProvider._();

/// Whether the person on this iPhone used the coach on Steady 1.0, decided
/// once at the first 1.1.0 launch (#188), or `null` where it isn't bound
/// (no offer). `app/lib/providers.dart` binds it on iOS only, to the
/// device-only file next to `coach_consent.json`.
///
/// `keepAlive`: the file store serializes its own reads and writes (D6).

final class EarlyCoachUserRepositoryProvider
    extends
        $FunctionalProvider<
          EarlyCoachUserRepository?,
          EarlyCoachUserRepository?,
          EarlyCoachUserRepository?
        >
    with $Provider<EarlyCoachUserRepository?> {
  /// Whether the person on this iPhone used the coach on Steady 1.0, decided
  /// once at the first 1.1.0 launch (#188), or `null` where it isn't bound
  /// (no offer). `app/lib/providers.dart` binds it on iOS only, to the
  /// device-only file next to `coach_consent.json`.
  ///
  /// `keepAlive`: the file store serializes its own reads and writes (D6).
  EarlyCoachUserRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'earlyCoachUserRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$earlyCoachUserRepositoryHash();

  @$internal
  @override
  $ProviderElement<EarlyCoachUserRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EarlyCoachUserRepository? create(Ref ref) {
    return earlyCoachUserRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EarlyCoachUserRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EarlyCoachUserRepository?>(value),
    );
  }
}

String _$earlyCoachUserRepositoryHash() =>
    r'f297387ec31b6c3ce398f5e5abedef5c2603d983';

/// The offer code that gives 1.0's coach users two weeks free (#188), from
/// `--dart-define=EARLY_COACH_OFFER_CODE`, never the repo; blank where the
/// build has none, and then the offer isn't shown.
///
/// `keepAlive`: a constant for the app's lifetime.

@ProviderFor(earlyCoachOfferCode)
final earlyCoachOfferCodeProvider = EarlyCoachOfferCodeProvider._();

/// The offer code that gives 1.0's coach users two weeks free (#188), from
/// `--dart-define=EARLY_COACH_OFFER_CODE`, never the repo; blank where the
/// build has none, and then the offer isn't shown.
///
/// `keepAlive`: a constant for the app's lifetime.

final class EarlyCoachOfferCodeProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// The offer code that gives 1.0's coach users two weeks free (#188), from
  /// `--dart-define=EARLY_COACH_OFFER_CODE`, never the repo; blank where the
  /// build has none, and then the offer isn't shown.
  ///
  /// `keepAlive`: a constant for the app's lifetime.
  EarlyCoachOfferCodeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'earlyCoachOfferCodeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$earlyCoachOfferCodeHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return earlyCoachOfferCode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$earlyCoachOfferCodeHash() =>
    r'68e414137c0e55e8854189dcff63f337aa07d11b';

/// Whether this device sells the coach's subscription at all: `true` on iOS
/// only, where the coach is. A platform fact, not whether the build has a
/// store key or the store answers (`SubscriptionNotConfiguredFailure`,
/// `SubscriptionStoreUnavailableFailure`). `false` by default;
/// `app/lib/providers.dart` sets it with the repository.
///
/// `keepAlive`: a constant for the app's lifetime.

@ProviderFor(subscriptionSupportAvailable)
final subscriptionSupportAvailableProvider =
    SubscriptionSupportAvailableProvider._();

/// Whether this device sells the coach's subscription at all: `true` on iOS
/// only, where the coach is. A platform fact, not whether the build has a
/// store key or the store answers (`SubscriptionNotConfiguredFailure`,
/// `SubscriptionStoreUnavailableFailure`). `false` by default;
/// `app/lib/providers.dart` sets it with the repository.
///
/// `keepAlive`: a constant for the app's lifetime.

final class SubscriptionSupportAvailableProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether this device sells the coach's subscription at all: `true` on iOS
  /// only, where the coach is. A platform fact, not whether the build has a
  /// store key or the store answers (`SubscriptionNotConfiguredFailure`,
  /// `SubscriptionStoreUnavailableFailure`). `false` by default;
  /// `app/lib/providers.dart` sets it with the repository.
  ///
  /// `keepAlive`: a constant for the app's lifetime.
  SubscriptionSupportAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionSupportAvailableProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionSupportAvailableHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return subscriptionSupportAvailable(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$subscriptionSupportAvailableHash() =>
    r'db7fa3b76dc4266caf368fced1c447cd98e437be';
