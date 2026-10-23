// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sample_export.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How the import flow reads the sample export.
///
/// A seam so widget and controller tests can supply bytes without the real
/// PDF. The app doesn't need to override it: the default reads
/// [sampleExportAsset] from the root bundle.
///
/// `keepAlive`: a stateless function, recreating it gains nothing.

@ProviderFor(sampleExportLoader)
final sampleExportLoaderProvider = SampleExportLoaderProvider._();

/// How the import flow reads the sample export.
///
/// A seam so widget and controller tests can supply bytes without the real
/// PDF. The app doesn't need to override it: the default reads
/// [sampleExportAsset] from the root bundle.
///
/// `keepAlive`: a stateless function, recreating it gains nothing.

final class SampleExportLoaderProvider
    extends
        $FunctionalProvider<
          SampleExportLoader,
          SampleExportLoader,
          SampleExportLoader
        >
    with $Provider<SampleExportLoader> {
  /// How the import flow reads the sample export.
  ///
  /// A seam so widget and controller tests can supply bytes without the real
  /// PDF. The app doesn't need to override it: the default reads
  /// [sampleExportAsset] from the root bundle.
  ///
  /// `keepAlive`: a stateless function, recreating it gains nothing.
  SampleExportLoaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sampleExportLoaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sampleExportLoaderHash();

  @$internal
  @override
  $ProviderElement<SampleExportLoader> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SampleExportLoader create(Ref ref) {
    return sampleExportLoader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SampleExportLoader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SampleExportLoader>(value),
    );
  }
}

String _$sampleExportLoaderHash() =>
    r'feb33adbf06edce64ebd49e2ec90a6509e3f2a13';
