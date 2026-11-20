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
