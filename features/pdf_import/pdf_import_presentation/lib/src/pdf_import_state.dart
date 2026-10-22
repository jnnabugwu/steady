import 'package:failures/failures.dart';
import 'package:pdf_import_domain/pdf_import_domain.dart';

/// Where the PDF import flow is: one subclass per screen state.
///
/// A hand-written sealed class rather than `AsyncValue<List<ParsedDay>?>`.
/// The flow has two separate async operations (parse, then commit) whose
/// failures recover differently: a parse failure sends the user back to
/// pick another file, while a commit failure must keep the parsed days on
/// screen so "Import" can be retried. `AsyncValue` could only tell those
/// apart through `hasValue` combinations (loading-with-value = committing,
/// error-with-value = commit failed), which a reader has to decode. Here
/// each state is named. Failures are still the repository's typed
/// [Failure], translated from `Result` at the Notifier boundary
/// (CLAUDE.md §4, §9).
sealed class PdfImportState {
  const PdfImportState();
}

/// Nothing chosen yet. The screen offers the file picker.
final class PdfImportEmpty extends PdfImportState {
  /// Creates the initial state.
  const PdfImportEmpty();
}

/// A PDF was chosen and is being parsed.
final class PdfImportParsing extends PdfImportState {
  /// Creates the parsing state.
  const PdfImportParsing();
}

/// Opening or parsing the PDF failed. The user can pick another file.
final class PdfImportParseFailed extends PdfImportState {
  /// Creates a parse-failure state carrying [failure].
  const PdfImportParseFailed(this.failure);

  /// Why opening or parsing failed.
  final Failure failure;
}

/// The PDF parsed; [days] are shown for review before committing.
///
/// [days] may be empty (the PDF had no Cal AI day sections). While
/// [isCommitting] the import is in flight. [commitFailure] is set when the
/// last commit attempt failed, and the user can retry.
final class PdfImportPreview extends PdfImportState {
  /// Creates a preview of [days].
  ///
  /// [isCommitting] and [commitFailure] are mutually exclusive: a retry
  /// clears the previous failure when it starts.
  const PdfImportPreview(
    this.days, {
    this.isCommitting = false,
    this.commitFailure,
  }) : assert(
         !isCommitting || commitFailure == null,
         'A commit in flight has no failure yet',
       );

  /// The parsed days, in the order the PDF listed them.
  final List<ParsedDay> days;

  /// Whether `commitDailyTotals` is in flight.
  final bool isCommitting;

  /// The failure from the last commit attempt, if it failed.
  final Failure? commitFailure;
}

/// The parsed days' totals were committed. Terminal for this flow.
final class PdfImportCommitted extends PdfImportState {
  /// Creates the committed state for [days].
  const PdfImportCommitted(this.days);

  /// The days that were committed.
  final List<ParsedDay> days;
}
