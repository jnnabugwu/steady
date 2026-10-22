import 'dart:typed_data';

import 'package:failures/failures.dart';
import 'package:pdf_import_presentation/src/pdf_file_picker.dart';
import 'package:pdf_import_presentation/src/pdf_import_state.dart';
import 'package:pdf_import_presentation/src/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pdf_import_controller.g.dart';

/// The PDF import flow: pick a Cal AI export, preview its days, commit.
///
/// Screen-scoped, so auto-dispose (CLAUDE.md §4): leaving the screen
/// discards the parsed days, which are in-session only and never persisted
/// beyond each day's calorie total (`ParsedDay`).
///
/// State is a [PdfImportState]; see that class for why it isn't an
/// `AsyncValue`. Repository `Result`s are translated here, so every failure
/// the UI sees is a typed [Failure].
@riverpod
class PdfImportController extends _$PdfImportController {
  @override
  PdfImportState build() => const PdfImportEmpty();

  bool get _isBusy => switch (state) {
    PdfImportParsing() || PdfImportCommitted() => true,
    PdfImportPreview(:final isCommitting) => isCommitting,
    PdfImportEmpty() || PdfImportParseFailed() => false,
  };

  /// Domain event: PdfSelected.
  ///
  /// Opens the file picker, then parses the chosen file ([parsePdf]).
  /// Cancelling the picker changes nothing. A picker error becomes
  /// [PdfImportParseFailed]. Ignored while a parse or commit is in flight,
  /// or once the import has been committed.
  Future<void> choosePdf() async {
    if (!ref.mounted || _isBusy) return;
    final Uint8List? bytes;
    try {
      bytes = await ref.read(pdfFilePickerProvider)();
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = PdfImportParseFailed(
        UnknownFailure("Couldn't open that file.", cause: error),
      );
      return;
    }
    if (bytes == null || !ref.mounted) return;
    await parsePdf(bytes);
  }

  /// Domain event: PdfParsed.
  ///
  /// Parses [bytes] as a Cal AI export. Goes [PdfImportParsing], then
  /// [PdfImportPreview] (possibly with no days) or [PdfImportParseFailed].
  /// Ignored while a parse or commit is in flight, or once committed.
  Future<void> parsePdf(Uint8List bytes) async {
    if (!ref.mounted || _isBusy) return;
    state = const PdfImportParsing();
    final result = await ref.read(pdfImportRepositoryProvider).parse(bytes);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => PdfImportPreview(value),
      Err(:final failure) => PdfImportParseFailed(failure),
    };
  }

  /// Domain event: ImportCommitted.
  ///
  /// Writes the previewed days' calorie totals. Goes to [PdfImportPreview]
  /// with `isCommitting`, then [PdfImportCommitted] on success, or back to
  /// the preview with `commitFailure` set so the user can retry (re-running
  /// a partial commit is safe; see `PdfImportRepository.commitDailyTotals`).
  /// Ignored unless there is a non-empty preview with no commit in flight.
  Future<void> commitImport() async {
    if (!ref.mounted) return;
    final current = state;
    if (current is! PdfImportPreview ||
        current.isCommitting ||
        current.days.isEmpty) {
      return;
    }
    final days = current.days;
    state = PdfImportPreview(days, isCommitting: true);
    final result = await ref
        .read(pdfImportRepositoryProvider)
        .commitDailyTotals(days);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => PdfImportCommitted(days),
      Err(:final failure) => PdfImportPreview(days, commitFailure: failure),
    };
  }
}
