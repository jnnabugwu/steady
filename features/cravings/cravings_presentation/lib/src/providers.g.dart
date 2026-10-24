// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The `CravingRepository` craving check-ins are stored through.
///
/// Typed against the domain interface only: this package never depends on
/// `cravings_data` (CLAUDE.md §3). `app/lib/providers.dart` binds it on iOS
/// only, to the device-only file store; on macOS it stays unbound, so a Mac
/// path that reads it fails loudly instead of quietly creating a store.
/// Tests override it with a fake. Reading it without an override throws.
///
/// `keepAlive`: repositories are cheap and stateless (D6).

@ProviderFor(cravingRepository)
final cravingRepositoryProvider = CravingRepositoryProvider._();

/// The `CravingRepository` craving check-ins are stored through.
///
/// Typed against the domain interface only: this package never depends on
/// `cravings_data` (CLAUDE.md §3). `app/lib/providers.dart` binds it on iOS
/// only, to the device-only file store; on macOS it stays unbound, so a Mac
/// path that reads it fails loudly instead of quietly creating a store.
/// Tests override it with a fake. Reading it without an override throws.
///
/// `keepAlive`: repositories are cheap and stateless (D6).

final class CravingRepositoryProvider
    extends
        $FunctionalProvider<
          CravingRepository,
          CravingRepository,
          CravingRepository
        >
    with $Provider<CravingRepository> {
  /// The `CravingRepository` craving check-ins are stored through.
  ///
  /// Typed against the domain interface only: this package never depends on
  /// `cravings_data` (CLAUDE.md §3). `app/lib/providers.dart` binds it on iOS
  /// only, to the device-only file store; on macOS it stays unbound, so a Mac
  /// path that reads it fails loudly instead of quietly creating a store.
  /// Tests override it with a fake. Reading it without an override throws.
  ///
  /// `keepAlive`: repositories are cheap and stateless (D6).
  CravingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cravingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cravingRepositoryHash();

  @$internal
  @override
  $ProviderElement<CravingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CravingRepository create(Ref ref) {
    return cravingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CravingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CravingRepository>(value),
    );
  }
}

String _$cravingRepositoryHash() => r'cac885023cb7dbc60ea348e01f915fccff5d6eb4';

/// Whether craving support is offered on this device: `true` on iOS only.
///
/// `false` by default; `app/lib/providers.dart` sets it from the platform
/// (`appProviderOverridesFor(isIOS: ...)`), so tests can cover both. When
/// it's `false` the home entry point and the Settings card render nothing,
/// and the app's `/craving` route sends you home.
///
/// `keepAlive`: a constant for the app's lifetime.

@ProviderFor(cravingSupportAvailable)
final cravingSupportAvailableProvider = CravingSupportAvailableProvider._();

/// Whether craving support is offered on this device: `true` on iOS only.
///
/// `false` by default; `app/lib/providers.dart` sets it from the platform
/// (`appProviderOverridesFor(isIOS: ...)`), so tests can cover both. When
/// it's `false` the home entry point and the Settings card render nothing,
/// and the app's `/craving` route sends you home.
///
/// `keepAlive`: a constant for the app's lifetime.

final class CravingSupportAvailableProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether craving support is offered on this device: `true` on iOS only.
  ///
  /// `false` by default; `app/lib/providers.dart` sets it from the platform
  /// (`appProviderOverridesFor(isIOS: ...)`), so tests can cover both. When
  /// it's `false` the home entry point and the Settings card render nothing,
  /// and the app's `/craving` route sends you home.
  ///
  /// `keepAlive`: a constant for the app's lifetime.
  CravingSupportAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cravingSupportAvailableProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cravingSupportAvailableHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return cravingSupportAvailable(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$cravingSupportAvailableHash() =>
    r'8cff22882821d1e0a1d146fe9068c9e68fc1014d';

/// The clock the craving feature reads "now" from. Defaults to
/// [DateTime.now]; tests pin it.
///
/// `keepAlive`: cheap and stateless (D6).

@ProviderFor(cravingClock)
final cravingClockProvider = CravingClockProvider._();

/// The clock the craving feature reads "now" from. Defaults to
/// [DateTime.now]; tests pin it.
///
/// `keepAlive`: cheap and stateless (D6).

final class CravingClockProvider
    extends $FunctionalProvider<CravingClock, CravingClock, CravingClock>
    with $Provider<CravingClock> {
  /// The clock the craving feature reads "now" from. Defaults to
  /// [DateTime.now]; tests pin it.
  ///
  /// `keepAlive`: cheap and stateless (D6).
  CravingClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cravingClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cravingClockHash();

  @$internal
  @override
  $ProviderElement<CravingClock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CravingClock create(Ref ref) {
    return cravingClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CravingClock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CravingClock>(value),
    );
  }
}

String _$cravingClockHash() => r'37650c806c0d60bbf006f127a569d1d85548c79e';

/// The id generator for new craving events: a random (version 4) UUID by
/// default ([randomCravingId]); tests pin it.
///
/// `keepAlive`: cheap and stateless (D6).

@ProviderFor(cravingIdGenerator)
final cravingIdGeneratorProvider = CravingIdGeneratorProvider._();

/// The id generator for new craving events: a random (version 4) UUID by
/// default ([randomCravingId]); tests pin it.
///
/// `keepAlive`: cheap and stateless (D6).

final class CravingIdGeneratorProvider
    extends
        $FunctionalProvider<
          CravingIdGenerator,
          CravingIdGenerator,
          CravingIdGenerator
        >
    with $Provider<CravingIdGenerator> {
  /// The id generator for new craving events: a random (version 4) UUID by
  /// default ([randomCravingId]); tests pin it.
  ///
  /// `keepAlive`: cheap and stateless (D6).
  CravingIdGeneratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cravingIdGeneratorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cravingIdGeneratorHash();

  @$internal
  @override
  $ProviderElement<CravingIdGenerator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CravingIdGenerator create(Ref ref) {
    return cravingIdGenerator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CravingIdGenerator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CravingIdGenerator>(value),
    );
  }
}

String _$cravingIdGeneratorHash() =>
    r'94366e93cad47388e43431568e095865a8f635c3';

/// How the Settings card opens its help link. Defaults to the system
/// browser through `url_launcher`; tests override it so they never reach
/// the plugin.
///
/// `keepAlive`: cheap and stateless (D6).

@ProviderFor(cravingLinkOpener)
final cravingLinkOpenerProvider = CravingLinkOpenerProvider._();

/// How the Settings card opens its help link. Defaults to the system
/// browser through `url_launcher`; tests override it so they never reach
/// the plugin.
///
/// `keepAlive`: cheap and stateless (D6).

final class CravingLinkOpenerProvider
    extends
        $FunctionalProvider<
          CravingLinkOpener,
          CravingLinkOpener,
          CravingLinkOpener
        >
    with $Provider<CravingLinkOpener> {
  /// How the Settings card opens its help link. Defaults to the system
  /// browser through `url_launcher`; tests override it so they never reach
  /// the plugin.
  ///
  /// `keepAlive`: cheap and stateless (D6).
  CravingLinkOpenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cravingLinkOpenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cravingLinkOpenerHash();

  @$internal
  @override
  $ProviderElement<CravingLinkOpener> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CravingLinkOpener create(Ref ref) {
    return cravingLinkOpener(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CravingLinkOpener value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CravingLinkOpener>(value),
    );
  }
}

String _$cravingLinkOpenerHash() => r'f0d556754141c41dab4db0a46a57588585413c4a';
