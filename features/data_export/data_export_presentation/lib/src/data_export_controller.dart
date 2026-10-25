import 'dart:async';

import 'package:data_export_domain/data_export_domain.dart';
import 'package:data_export_presentation/src/providers.dart';
import 'package:failures/failures.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'data_export_controller.g.dart';

/// The data export screen's state: `null` until the first export finishes,
/// then the latest [ExportReceipt].
///
/// Screen-scoped, so auto-dispose (CLAUDE.md §4). A failed export is an
/// `AsyncError` carrying a typed [Failure]: the repository's own, or
/// [ExportShareFailure] if the share sheet couldn't be opened.
@riverpod
class DataExportController extends _$DataExportController {
  @override
  FutureOr<ExportReceipt?> build() => null;

  /// Domain event: DataExported.
  ///
  /// Reads every `DailyMetric` row (and, on the iPhone, every coach
  /// session's date, kind and summary), builds a dated [format] file and hands
  /// it to the share sheet, anchored at [sharePositionOrigin] on macOS and
  /// iPad. On success the state becomes `AsyncData` with the receipt
  /// (including whether the user dismissed the sheet); on failure it
  /// becomes an `AsyncError` carrying the [Failure].
  ///
  /// A failed read of the daily rows never reaches the share sheet, so no
  /// partial or empty file is ever presented as a complete export. The one
  /// exception is coach history that can't be read: the export goes ahead
  /// without it, and for JSON the receipt's `coachHistoryLeftOut` is set so
  /// the screen says so (see `readExportBundle`).
  ///
  /// Ignored while another export is in flight (including while its share
  /// sheet is still open), so double taps can't start two, and after the
  /// provider has been disposed. If the provider is disposed while the read
  /// is in flight (the user left Settings), the share sheet never opens.
  Future<void> exportData(
    ExportFormat format, {
    Rect? sharePositionOrigin,
  }) async {
    if (!ref.mounted || state.isLoading) return;
    state = const AsyncLoading();
    final result = await _export(format, sharePositionOrigin);
    if (result == null || !ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => AsyncData(value),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }

  /// Returns `null` if the provider was disposed during the read, so no
  /// share sheet opens for a screen the user has already left.
  Future<Result<ExportReceipt>?> _export(
    ExportFormat format,
    Rect? sharePositionOrigin,
  ) async {
    final read = await readExportBundle(
      ref.read(exportDailyMetricRepositoryProvider),
      exportedAt: ref.read(exportClockProvider)(),
      coachRepository: ref.read(exportCoachRepositoryProvider),
    );
    final ExportBundle bundle;
    switch (read) {
      case Ok(:final value):
        bundle = value;
      case Err(:final failure):
        return Err(failure);
    }
    if (!ref.mounted) return null;

    final file = bundle.toFile(format);
    final shared = await ref.read(exportFileSharerProvider)(
      file,
      sharePositionOrigin: sharePositionOrigin,
    );
    return switch (shared) {
      Ok(value: final outcome) => Ok(
        ExportReceipt(
          format: format,
          fileName: file.fileName,
          dayCount: bundle.dailyMetrics.length,
          outcome: outcome,
          coachHistoryLeftOut:
              format == ExportFormat.json && bundle.coachHistoryUnreadable,
        ),
      ),
      Err(:final failure) => Err(failure),
    };
  }
}
