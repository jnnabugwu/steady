// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdf_import_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The PDF import flow: pick a Cal AI export, preview its days, commit.
///
/// Screen-scoped, so auto-dispose (CLAUDE.md §4): leaving the screen
/// discards the parsed days, which are in-session only and never persisted
/// beyond each day's calorie total (`ParsedDay`).
///
/// State is a [PdfImportState]; see that class for why it isn't an
/// `AsyncValue`. Repository `Result`s are translated here, so every failure
/// the UI sees is a typed [Failure].

@ProviderFor(PdfImportController)
final pdfImportControllerProvider = PdfImportControllerProvider._();

/// The PDF import flow: pick a Cal AI export, preview its days, commit.
///
/// Screen-scoped, so auto-dispose (CLAUDE.md §4): leaving the screen
/// discards the parsed days, which are in-session only and never persisted
/// beyond each day's calorie total (`ParsedDay`).
///
/// State is a [PdfImportState]; see that class for why it isn't an
/// `AsyncValue`. Repository `Result`s are translated here, so every failure
/// the UI sees is a typed [Failure].
final class PdfImportControllerProvider
    extends $NotifierProvider<PdfImportController, PdfImportState> {
  /// The PDF import flow: pick a Cal AI export, preview its days, commit.
  ///
  /// Screen-scoped, so auto-dispose (CLAUDE.md §4): leaving the screen
  /// discards the parsed days, which are in-session only and never persisted
  /// beyond each day's calorie total (`ParsedDay`).
  ///
  /// State is a [PdfImportState]; see that class for why it isn't an
  /// `AsyncValue`. Repository `Result`s are translated here, so every failure
  /// the UI sees is a typed [Failure].
  PdfImportControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pdfImportControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pdfImportControllerHash();

  @$internal
  @override
  PdfImportController create() => PdfImportController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PdfImportState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PdfImportState>(value),
    );
  }
}

String _$pdfImportControllerHash() =>
    r'7f694e508d692fbafd1a18c644dbd3d47074c736';

/// The PDF import flow: pick a Cal AI export, preview its days, commit.
///
/// Screen-scoped, so auto-dispose (CLAUDE.md §4): leaving the screen
/// discards the parsed days, which are in-session only and never persisted
/// beyond each day's calorie total (`ParsedDay`).
///
/// State is a [PdfImportState]; see that class for why it isn't an
/// `AsyncValue`. Repository `Result`s are translated here, so every failure
/// the UI sees is a typed [Failure].

abstract class _$PdfImportController extends $Notifier<PdfImportState> {
  PdfImportState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PdfImportState, PdfImportState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PdfImportState, PdfImportState>,
              PdfImportState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
