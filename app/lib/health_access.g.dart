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
    r'c13fc5a29f3e8321a7f927c39026871232165217';

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
