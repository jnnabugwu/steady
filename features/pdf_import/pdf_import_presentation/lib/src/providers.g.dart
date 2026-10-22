// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The `PdfImportRepository` the upload flow parses and commits through.
///
/// Typed against the domain interface only: this package never depends on
/// `pdf_import_data` (CLAUDE.md §3). `app/lib/providers.dart` overrides it
/// with the real implementation in `appProviderOverrides` (CLAUDE.md §9);
/// tests override it with a fake. Reading it without an override throws.
///
/// `keepAlive`: repositories are cheap and stateless, so recreating one
/// gains nothing (D6).

@ProviderFor(pdfImportRepository)
final pdfImportRepositoryProvider = PdfImportRepositoryProvider._();

/// The `PdfImportRepository` the upload flow parses and commits through.
///
/// Typed against the domain interface only: this package never depends on
/// `pdf_import_data` (CLAUDE.md §3). `app/lib/providers.dart` overrides it
/// with the real implementation in `appProviderOverrides` (CLAUDE.md §9);
/// tests override it with a fake. Reading it without an override throws.
///
/// `keepAlive`: repositories are cheap and stateless, so recreating one
/// gains nothing (D6).

final class PdfImportRepositoryProvider
    extends
        $FunctionalProvider<
          PdfImportRepository,
          PdfImportRepository,
          PdfImportRepository
        >
    with $Provider<PdfImportRepository> {
  /// The `PdfImportRepository` the upload flow parses and commits through.
  ///
  /// Typed against the domain interface only: this package never depends on
  /// `pdf_import_data` (CLAUDE.md §3). `app/lib/providers.dart` overrides it
  /// with the real implementation in `appProviderOverrides` (CLAUDE.md §9);
  /// tests override it with a fake. Reading it without an override throws.
  ///
  /// `keepAlive`: repositories are cheap and stateless, so recreating one
  /// gains nothing (D6).
  PdfImportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pdfImportRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pdfImportRepositoryHash();

  @$internal
  @override
  $ProviderElement<PdfImportRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PdfImportRepository create(Ref ref) {
    return pdfImportRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PdfImportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PdfImportRepository>(value),
    );
  }
}

String _$pdfImportRepositoryHash() =>
    r'6493b22bf672518a6828a275f4f02c0aa9f08625';
