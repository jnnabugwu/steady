// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_access.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether Health is available and whether its permission sheet has been
/// shown (never "allowed" or "denied": HealthKit doesn't say), for
/// Settings.
///
/// `keepAlive`: app-scoped, not screen-scoped. It's driven from the app
/// root at launch and on resume, and it holds the in-flight refresh, so a
/// resume while the permission sheet is still open joins it instead of
/// asking twice. Not a family, so nothing piles up.

@ProviderFor(HealthAccessController)
final healthAccessControllerProvider = HealthAccessControllerProvider._();

/// Whether Health is available and whether its permission sheet has been
/// shown (never "allowed" or "denied": HealthKit doesn't say), for
/// Settings.
///
/// `keepAlive`: app-scoped, not screen-scoped. It's driven from the app
/// root at launch and on resume, and it holds the in-flight refresh, so a
/// resume while the permission sheet is still open joins it instead of
/// asking twice. Not a family, so nothing piles up.
final class HealthAccessControllerProvider
    extends
        $AsyncNotifierProvider<
          HealthAccessController,
          HealthAuthorizationStatus
        > {
  /// Whether Health is available and whether its permission sheet has been
  /// shown (never "allowed" or "denied": HealthKit doesn't say), for
  /// Settings.
  ///
  /// `keepAlive`: app-scoped, not screen-scoped. It's driven from the app
  /// root at launch and on resume, and it holds the in-flight refresh, so a
  /// resume while the permission sheet is still open joins it instead of
  /// asking twice. Not a family, so nothing piles up.
  HealthAccessControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: _retryUnlessFailure,
        name: r'healthAccessControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthAccessControllerHash();

  @$internal
  @override
  HealthAccessController create() => HealthAccessController();
}

String _$healthAccessControllerHash() =>
    r'd460f703757413a4d31a80e5e381d60cd241e2d4';

/// Whether Health is available and whether its permission sheet has been
/// shown (never "allowed" or "denied": HealthKit doesn't say), for
/// Settings.
///
/// `keepAlive`: app-scoped, not screen-scoped. It's driven from the app
/// root at launch and on resume, and it holds the in-flight refresh, so a
/// resume while the permission sheet is still open joins it instead of
/// asking twice. Not a family, so nothing piles up.

abstract class _$HealthAccessController
    extends $AsyncNotifier<HealthAuthorizationStatus> {
  FutureOr<HealthAuthorizationStatus> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<HealthAuthorizationStatus>,
              HealthAuthorizationStatus
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<HealthAuthorizationStatus>,
                HealthAuthorizationStatus
              >,
              AsyncValue<HealthAuthorizationStatus>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Whether Today offers "Connect Apple Health" under its metric tiles: only
/// on an iPhone whose Health permission sheet hasn't been shown yet
/// (`notDetermined`). Someone who was already asked (every 1.0 user) never
/// sees it; after that the switch is in the Health app (Settings → Apple
/// Health says where).

@ProviderFor(healthConnectOffered)
final healthConnectOfferedProvider = HealthConnectOfferedProvider._();

/// Whether Today offers "Connect Apple Health" under its metric tiles: only
/// on an iPhone whose Health permission sheet hasn't been shown yet
/// (`notDetermined`). Someone who was already asked (every 1.0 user) never
/// sees it; after that the switch is in the Health app (Settings → Apple
/// Health says where).

final class HealthConnectOfferedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether Today offers "Connect Apple Health" under its metric tiles: only
  /// on an iPhone whose Health permission sheet hasn't been shown yet
  /// (`notDetermined`). Someone who was already asked (every 1.0 user) never
  /// sees it; after that the switch is in the Health app (Settings → Apple
  /// Health says where).
  HealthConnectOfferedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthConnectOfferedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthConnectOfferedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return healthConnectOffered(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$healthConnectOfferedHash() =>
    r'9e6197bc5381c5d687a3fec1da6a1e77015e005d';
