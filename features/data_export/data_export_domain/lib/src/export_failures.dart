import 'package:failures/failures.dart';

/// The export file was built, but handing it to the system share sheet
/// failed (the platform threw, or no share sheet is available).
///
/// Nothing was delivered, so the UI must not report the export as done.
class ExportShareFailure extends Failure {
  /// Creates an [ExportShareFailure] with a human-readable [message] and
  /// the underlying [cause], if any.
  const ExportShareFailure(super.message, {super.cause});
}
