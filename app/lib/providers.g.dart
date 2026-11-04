// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The store [dailyMetricRepository] is built on. `main.dart` overrides it
/// to [DailyMetricStore.swiftData].

@ProviderFor(dailyMetricStore)
final dailyMetricStoreProvider = DailyMetricStoreProvider._();

/// The store [dailyMetricRepository] is built on. `main.dart` overrides it
/// to [DailyMetricStore.swiftData].

final class DailyMetricStoreProvider
    extends
        $FunctionalProvider<
          DailyMetricStore,
          DailyMetricStore,
          DailyMetricStore
        >
    with $Provider<DailyMetricStore> {
  /// The store [dailyMetricRepository] is built on. `main.dart` overrides it
  /// to [DailyMetricStore.swiftData].
  DailyMetricStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyMetricStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyMetricStoreHash();

  @$internal
  @override
  $ProviderElement<DailyMetricStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DailyMetricStore create(Ref ref) {
    return dailyMetricStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DailyMetricStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DailyMetricStore>(value),
    );
  }
}

String _$dailyMetricStoreHash() => r'b54aeb2c7142d2ca8172dd1f72c40935ced6d480';

/// The single shared `DailyMetricRepository` that checkin, metrics and
/// pdf_import all read and write through, and data_export reads from.
/// Backed by [dailyMetricStore].
///
/// The interim JSON file store is no longer used here; `main.dart` migrates
/// its rows into this repository once (`migrateFileStore`).
///
/// `keepAlive`: disposing it would lose the in-memory data and break the
/// shared-store invariant (D6).

@ProviderFor(dailyMetricRepository)
final dailyMetricRepositoryProvider = DailyMetricRepositoryProvider._();

/// The single shared `DailyMetricRepository` that checkin, metrics and
/// pdf_import all read and write through, and data_export reads from.
/// Backed by [dailyMetricStore].
///
/// The interim JSON file store is no longer used here; `main.dart` migrates
/// its rows into this repository once (`migrateFileStore`).
///
/// `keepAlive`: disposing it would lose the in-memory data and break the
/// shared-store invariant (D6).

final class DailyMetricRepositoryProvider
    extends
        $FunctionalProvider<
          DailyMetricRepository,
          DailyMetricRepository,
          DailyMetricRepository
        >
    with $Provider<DailyMetricRepository> {
  /// The single shared `DailyMetricRepository` that checkin, metrics and
  /// pdf_import all read and write through, and data_export reads from.
  /// Backed by [dailyMetricStore].
  ///
  /// The interim JSON file store is no longer used here; `main.dart` migrates
  /// its rows into this repository once (`migrateFileStore`).
  ///
  /// `keepAlive`: disposing it would lose the in-memory data and break the
  /// shared-store invariant (D6).
  DailyMetricRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyMetricRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyMetricRepositoryHash();

  @$internal
  @override
  $ProviderElement<DailyMetricRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DailyMetricRepository create(Ref ref) {
    return dailyMetricRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DailyMetricRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DailyMetricRepository>(value),
    );
  }
}

String _$dailyMetricRepositoryHash() =>
    r'3c5db3eea70d0d9777f52576e6977ecc9ad0c35a';

/// Apple Health's daily totals, or `null` where Health isn't read: macOS,
/// and tests. `null` by default; [appProviderOverridesFor] binds the
/// `steady/healthkit` channel on iOS only. The one Health source: features
/// that read Health bind their own provider to this one.
///
/// Declared here rather than in a feature package: `health_sync` is
/// headless (no `*_presentation` package).
///
/// `keepAlive`: cheap and stateless (D6).

@ProviderFor(healthKitRepository)
final healthKitRepositoryProvider = HealthKitRepositoryProvider._();

/// Apple Health's daily totals, or `null` where Health isn't read: macOS,
/// and tests. `null` by default; [appProviderOverridesFor] binds the
/// `steady/healthkit` channel on iOS only. The one Health source: features
/// that read Health bind their own provider to this one.
///
/// Declared here rather than in a feature package: `health_sync` is
/// headless (no `*_presentation` package).
///
/// `keepAlive`: cheap and stateless (D6).

final class HealthKitRepositoryProvider
    extends
        $FunctionalProvider<
          HealthKitRepository?,
          HealthKitRepository?,
          HealthKitRepository?
        >
    with $Provider<HealthKitRepository?> {
  /// Apple Health's daily totals, or `null` where Health isn't read: macOS,
  /// and tests. `null` by default; [appProviderOverridesFor] binds the
  /// `steady/healthkit` channel on iOS only. The one Health source: features
  /// that read Health bind their own provider to this one.
  ///
  /// Declared here rather than in a feature package: `health_sync` is
  /// headless (no `*_presentation` package).
  ///
  /// `keepAlive`: cheap and stateless (D6).
  HealthKitRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthKitRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthKitRepositoryHash();

  @$internal
  @override
  $ProviderElement<HealthKitRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HealthKitRepository? create(Ref ref) {
    return healthKitRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthKitRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthKitRepository?>(value),
    );
  }
}

String _$healthKitRepositoryHash() =>
    r'e8c8cdadc90ff969e3423a0b40941dc4a6d33f11';

/// App Attest for the hosted coach (#150), read only by the iOS-bound
/// `coachModelProvider`. Declared here, like [healthKitRepositoryProvider]:
/// the app layer is where `coach_data`'s implementations are chosen.
/// [appProviderOverridesFor] binds it on iOS only, to the `steady/app_attest`
/// channel (`app/ios/Runner/AppAttestChannel.swift`); reading it anywhere
/// else throws, as the coach's own providers do on the Mac.
///
/// `keepAlive`: cheap and stateless (D6).

@ProviderFor(coachAppAttest)
final coachAppAttestProvider = CoachAppAttestProvider._();

/// App Attest for the hosted coach (#150), read only by the iOS-bound
/// `coachModelProvider`. Declared here, like [healthKitRepositoryProvider]:
/// the app layer is where `coach_data`'s implementations are chosen.
/// [appProviderOverridesFor] binds it on iOS only, to the `steady/app_attest`
/// channel (`app/ios/Runner/AppAttestChannel.swift`); reading it anywhere
/// else throws, as the coach's own providers do on the Mac.
///
/// `keepAlive`: cheap and stateless (D6).

final class CoachAppAttestProvider
    extends $FunctionalProvider<AppAttest, AppAttest, AppAttest>
    with $Provider<AppAttest> {
  /// App Attest for the hosted coach (#150), read only by the iOS-bound
  /// `coachModelProvider`. Declared here, like [healthKitRepositoryProvider]:
  /// the app layer is where `coach_data`'s implementations are chosen.
  /// [appProviderOverridesFor] binds it on iOS only, to the `steady/app_attest`
  /// channel (`app/ios/Runner/AppAttestChannel.swift`); reading it anywhere
  /// else throws, as the coach's own providers do on the Mac.
  ///
  /// `keepAlive`: cheap and stateless (D6).
  CoachAppAttestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachAppAttestProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachAppAttestHash();

  @$internal
  @override
  $ProviderElement<AppAttest> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppAttest create(Ref ref) {
    return coachAppAttest(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppAttest value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppAttest>(value),
    );
  }
}

String _$coachAppAttestHash() => r'cfdf8621d41a5a5726bb605db24e0f96cc8e413a';

/// Where the coach's attested key id is kept (#150). [appProviderOverridesFor]
/// binds it on iOS only, to [appAttestKeyFile]; reading it anywhere else
/// throws.
///
/// `keepAlive`: cheap; the file is the state.

@ProviderFor(coachAppAttestKeyStore)
final coachAppAttestKeyStoreProvider = CoachAppAttestKeyStoreProvider._();

/// Where the coach's attested key id is kept (#150). [appProviderOverridesFor]
/// binds it on iOS only, to [appAttestKeyFile]; reading it anywhere else
/// throws.
///
/// `keepAlive`: cheap; the file is the state.

final class CoachAppAttestKeyStoreProvider
    extends
        $FunctionalProvider<
          AppAttestKeyStore,
          AppAttestKeyStore,
          AppAttestKeyStore
        >
    with $Provider<AppAttestKeyStore> {
  /// Where the coach's attested key id is kept (#150). [appProviderOverridesFor]
  /// binds it on iOS only, to [appAttestKeyFile]; reading it anywhere else
  /// throws.
  ///
  /// `keepAlive`: cheap; the file is the state.
  CoachAppAttestKeyStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachAppAttestKeyStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachAppAttestKeyStoreHash();

  @$internal
  @override
  $ProviderElement<AppAttestKeyStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppAttestKeyStore create(Ref ref) {
    return coachAppAttestKeyStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppAttestKeyStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppAttestKeyStore>(value),
    );
  }
}

String _$coachAppAttestKeyStoreHash() =>
    r'b3879343b1bd6ee8462cee9458adab2c13aeab2e';

/// How app-level screens open an external link (Settings' privacy policy).
/// Defaults to the system browser through `url_launcher`; tests override
/// it so they never reach the plugin.
///
/// `keepAlive`: cheap and stateless (D6).

@ProviderFor(appLinkOpener)
final appLinkOpenerProvider = AppLinkOpenerProvider._();

/// How app-level screens open an external link (Settings' privacy policy).
/// Defaults to the system browser through `url_launcher`; tests override
/// it so they never reach the plugin.
///
/// `keepAlive`: cheap and stateless (D6).

final class AppLinkOpenerProvider
    extends $FunctionalProvider<AppLinkOpener, AppLinkOpener, AppLinkOpener>
    with $Provider<AppLinkOpener> {
  /// How app-level screens open an external link (Settings' privacy policy).
  /// Defaults to the system browser through `url_launcher`; tests override
  /// it so they never reach the plugin.
  ///
  /// `keepAlive`: cheap and stateless (D6).
  AppLinkOpenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLinkOpenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLinkOpenerHash();

  @$internal
  @override
  $ProviderElement<AppLinkOpener> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppLinkOpener create(Ref ref) {
    return appLinkOpener(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLinkOpener value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLinkOpener>(value),
    );
  }
}

String _$appLinkOpenerHash() => r'1a821145e4d9aa6a4cfc6ba7d59da001d8277634';
