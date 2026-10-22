// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The `MetricsRepository` the weekly view and metrics history read from.
///
/// Typed against the domain interface only: this package never depends on
/// `metrics_data` (CLAUDE.md §3). `app/lib/providers.dart` overrides it with
/// the real implementation in `appProviderOverrides` (CLAUDE.md §9); tests
/// override it with a fake. Reading it without an override throws.
///
/// `keepAlive`: repositories are cheap and stateless, so recreating one
/// gains nothing (D6).

@ProviderFor(metricsRepository)
final metricsRepositoryProvider = MetricsRepositoryProvider._();

/// The `MetricsRepository` the weekly view and metrics history read from.
///
/// Typed against the domain interface only: this package never depends on
/// `metrics_data` (CLAUDE.md §3). `app/lib/providers.dart` overrides it with
/// the real implementation in `appProviderOverrides` (CLAUDE.md §9); tests
/// override it with a fake. Reading it without an override throws.
///
/// `keepAlive`: repositories are cheap and stateless, so recreating one
/// gains nothing (D6).

final class MetricsRepositoryProvider
    extends
        $FunctionalProvider<
          MetricsRepository,
          MetricsRepository,
          MetricsRepository
        >
    with $Provider<MetricsRepository> {
  /// The `MetricsRepository` the weekly view and metrics history read from.
  ///
  /// Typed against the domain interface only: this package never depends on
  /// `metrics_data` (CLAUDE.md §3). `app/lib/providers.dart` overrides it with
  /// the real implementation in `appProviderOverrides` (CLAUDE.md §9); tests
  /// override it with a fake. Reading it without an override throws.
  ///
  /// `keepAlive`: repositories are cheap and stateless, so recreating one
  /// gains nothing (D6).
  MetricsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'metricsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$metricsRepositoryHash();

  @$internal
  @override
  $ProviderElement<MetricsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MetricsRepository create(Ref ref) {
    return metricsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MetricsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MetricsRepository>(value),
    );
  }
}

String _$metricsRepositoryHash() => r'9e537459c2c38d7bfbb1203b2cdf3354c8da69c0';
