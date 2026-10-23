import 'dart:typed_data';

import 'package:failures/failures.dart';
import 'package:pdf_import_domain/pdf_import_domain.dart';
import 'package:pdf_import_presentation/src/pdf_file_picker.dart';
import 'package:pdf_import_presentation/src/pdf_import_state.dart';
import 'package:pdf_import_presentation/src/providers.dart';
import 'package:pdf_import_presentation/src/sample_export.dart';
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

  /// True while the file picker is open or the sample export is loading.
  /// Not a state of its own: the screen looks the same until the bytes come
  /// back.
  bool _isPicking = false;

  bool get _isBusy =>
      _isPicking ||
      switch (state) {
        PdfImportParsing() || PdfImportCommitted() => true,
        PdfImportPreview(:final isCommitting) => isCommitting,
        PdfImportEmpty() || PdfImportParseFailed() => false,
      };

  /// Domain event: PdfSelected.
  ///
  /// Opens the file picker, then parses the chosen file ([parsePdf]).
  /// Cancelling the picker changes nothing. A picker error becomes
  /// [PdfImportParseFailed]. Ignored while the picker is already open, while
  /// a parse or commit is in flight, or once the import has been committed.
  Future<void> choosePdf() async {
    if (!ref.mounted || _isBusy) return;
    _isPicking = true;
    final Uint8List? bytes;
    try {
      bytes = await ref.read(pdfFilePickerProvider)();
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = PdfImportParseFailed(
        UnknownFailure("Couldn't open that file.", cause: error),
      );
      return;
    } finally {
      _isPicking = false;
    }
    if (bytes == null || !ref.mounted) return;
    await parsePdf(bytes);
  }

  /// Domain event: SampleExportSelected.
  ///
  /// Loads the bundled sample export (seven made-up days, Jan 6-12 2025),
  /// then parses it the same way as a chosen file ([parsePdf]), so the
  /// preview and import that follow are the real flow. A load error becomes
  /// [PdfImportParseFailed]. Ignored whenever [choosePdf] would be.
  Future<void> chooseSamplePdf() async {
    if (!ref.mounted || _isBusy) return;
    _isPicking = true;
    final Uint8List bytes;
    try {
      bytes = await ref.read(sampleExportLoaderProvider)();
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = PdfImportParseFailed(
        UnknownFailure("Couldn't open the sample export.", cause: error),
      );
      return;
    } finally {
      _isPicking = false;
    }
    if (!ref.mounted) return;
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
    Result<List<ParsedDay>> result;
    try {
      result = await ref.read(pdfImportRepositoryProvider).parse(bytes);
    } on Object catch (error) {
      // A repository should return Err, but a throw must not strand the
      // screen in parsing, where every action is ignored.
      result = Err(UnknownFailure("Couldn't read that PDF.", cause: error));
    }
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
    Result<Unit> result;
    try {
      result = await ref
          .read(pdfImportRepositoryProvider)
          .commitDailyTotals(days);
    } on Object catch (error) {
      result = Err(UnknownFailure("Couldn't save the import.", cause: error));
    }
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => PdfImportCommitted(days),
      Err(:final failure) => PdfImportPreview(days, commitFailure: failure),
    };
  }
}
