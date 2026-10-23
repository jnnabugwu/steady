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
