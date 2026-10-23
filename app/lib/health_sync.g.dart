// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The clock [HealthSyncController] reads "now" from. Defaults to
/// [DateTime.now].
///
/// `keepAlive`: cheap and stateless (D6).

@ProviderFor(healthSyncClock)
final healthSyncClockProvider = HealthSyncClockProvider._();

/// The clock [HealthSyncController] reads "now" from. Defaults to
/// [DateTime.now].
///
/// `keepAlive`: cheap and stateless (D6).

final class HealthSyncClockProvider
    extends
        $FunctionalProvider<HealthSyncClock, HealthSyncClock, HealthSyncClock>
    with $Provider<HealthSyncClock> {
  /// The clock [HealthSyncController] reads "now" from. Defaults to
  /// [DateTime.now].
  ///
  /// `keepAlive`: cheap and stateless (D6).
  HealthSyncClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthSyncClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthSyncClockHash();

  @$internal
  @override
  $ProviderElement<HealthSyncClock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HealthSyncClock create(Ref ref) {
    return healthSyncClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthSyncClock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthSyncClock>(value),
    );
  }
}

String _$healthSyncClockHash() => r'598077e320b71a657123b6b68399b1e5be31a494';

/// Runs the Health sync and holds its latest outcome.
///
/// `keepAlive`: app-scoped, not screen-scoped. It's driven from the app
/// root at launch and on resume, and it holds the in-flight sync, so a
/// resume while a sync (or the permission sheet) is still open joins it
/// instead of starting a second one. Not a family, so nothing piles up.

@ProviderFor(HealthSyncController)
final healthSyncControllerProvider = HealthSyncControllerProvider._();

/// Runs the Health sync and holds its latest outcome.
///
/// `keepAlive`: app-scoped, not screen-scoped. It's driven from the app
/// root at launch and on resume, and it holds the in-flight sync, so a
/// resume while a sync (or the permission sheet) is still open joins it
/// instead of starting a second one. Not a family, so nothing piles up.
final class HealthSyncControllerProvider
    extends $AsyncNotifierProvider<HealthSyncController, HealthSyncState> {
  /// Runs the Health sync and holds its latest outcome.
  ///
  /// `keepAlive`: app-scoped, not screen-scoped. It's driven from the app
  /// root at launch and on resume, and it holds the in-flight sync, so a
  /// resume while a sync (or the permission sheet) is still open joins it
  /// instead of starting a second one. Not a family, so nothing piles up.
  HealthSyncControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: _retryUnlessFailure,
        name: r'healthSyncControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthSyncControllerHash();

  @$internal
  @override
  HealthSyncController create() => HealthSyncController();
}

String _$healthSyncControllerHash() =>
    r'8b0b2bb3340913b82c54e2994528e61645ab05a9';

/// Runs the Health sync and holds its latest outcome.
///
/// `keepAlive`: app-scoped, not screen-scoped. It's driven from the app
/// root at launch and on resume, and it holds the in-flight sync, so a
/// resume while a sync (or the permission sheet) is still open joins it
/// instead of starting a second one. Not a family, so nothing piles up.

abstract class _$HealthSyncController extends $AsyncNotifier<HealthSyncState> {
  FutureOr<HealthSyncState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<HealthSyncState>, HealthSyncState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HealthSyncState>, HealthSyncState>,
              AsyncValue<HealthSyncState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
