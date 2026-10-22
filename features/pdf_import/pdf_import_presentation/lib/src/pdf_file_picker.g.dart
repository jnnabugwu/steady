// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdf_file_picker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The file picker the import flow uses.
///
/// A seam so widget and controller tests can supply bytes (or a cancel)
/// without touching `file_selector`'s platform channel. The app doesn't need
/// to override it: the default is the real picker, [pickPdfWithFileSelector].
///
/// `keepAlive`: a stateless function, recreating it gains nothing.

@ProviderFor(pdfFilePicker)
final pdfFilePickerProvider = PdfFilePickerProvider._();

/// The file picker the import flow uses.
///
/// A seam so widget and controller tests can supply bytes (or a cancel)
/// without touching `file_selector`'s platform channel. The app doesn't need
/// to override it: the default is the real picker, [pickPdfWithFileSelector].
///
/// `keepAlive`: a stateless function, recreating it gains nothing.

final class PdfFilePickerProvider
    extends $FunctionalProvider<PdfFilePicker, PdfFilePicker, PdfFilePicker>
    with $Provider<PdfFilePicker> {
  /// The file picker the import flow uses.
  ///
  /// A seam so widget and controller tests can supply bytes (or a cancel)
  /// without touching `file_selector`'s platform channel. The app doesn't need
  /// to override it: the default is the real picker, [pickPdfWithFileSelector].
  ///
  /// `keepAlive`: a stateless function, recreating it gains nothing.
  PdfFilePickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pdfFilePickerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pdfFilePickerHash();

  @$internal
  @override
  $ProviderElement<PdfFilePicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PdfFilePicker create(Ref ref) {
    return pdfFilePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PdfFilePicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PdfFilePicker>(value),
    );
  }
}

String _$pdfFilePickerHash() => r'4643d7395e40b0b81706a4b61489d8815eb65ae8';
