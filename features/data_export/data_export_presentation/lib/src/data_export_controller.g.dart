// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_export_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The data export screen's state: `null` until the first export finishes,
/// then the latest [ExportReceipt].
///
/// Screen-scoped, so auto-dispose (CLAUDE.md §4). A failed export is an
/// `AsyncError` carrying a typed [Failure]: the repository's own, or
/// [ExportShareFailure] if the share sheet couldn't be opened.

@ProviderFor(DataExportController)
final dataExportControllerProvider = DataExportControllerProvider._();

/// The data export screen's state: `null` until the first export finishes,
/// then the latest [ExportReceipt].
///
/// Screen-scoped, so auto-dispose (CLAUDE.md §4). A failed export is an
/// `AsyncError` carrying a typed [Failure]: the repository's own, or
/// [ExportShareFailure] if the share sheet couldn't be opened.
final class DataExportControllerProvider
    extends $AsyncNotifierProvider<DataExportController, ExportReceipt?> {
  /// The data export screen's state: `null` until the first export finishes,
  /// then the latest [ExportReceipt].
  ///
  /// Screen-scoped, so auto-dispose (CLAUDE.md §4). A failed export is an
  /// `AsyncError` carrying a typed [Failure]: the repository's own, or
  /// [ExportShareFailure] if the share sheet couldn't be opened.
  DataExportControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataExportControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataExportControllerHash();

  @$internal
  @override
  DataExportController create() => DataExportController();
}

String _$dataExportControllerHash() =>
    r'6cda5b189c40691d7bde32446c04d0442ad160af';

/// The data export screen's state: `null` until the first export finishes,
/// then the latest [ExportReceipt].
///
/// Screen-scoped, so auto-dispose (CLAUDE.md §4). A failed export is an
/// `AsyncError` carrying a typed [Failure]: the repository's own, or
/// [ExportShareFailure] if the share sheet couldn't be opened.

abstract class _$DataExportController extends $AsyncNotifier<ExportReceipt?> {
  FutureOr<ExportReceipt?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ExportReceipt?>, ExportReceipt?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ExportReceipt?>, ExportReceipt?>,
              AsyncValue<ExportReceipt?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
