import 'package:data_export_domain/src/export_bundle.dart';
import 'package:data_export_domain/src/export_format.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'export_receipt.freezed.dart';

/// What the user did with the share sheet once the export file was handed
/// to it.
enum ExportShareOutcome {
  /// The user picked a destination (Save to Files, AirDrop, Mail, ...).
  ///
  /// Also used when the platform showed the sheet but can't report the
  /// choice (`share_plus`'s `unavailable` result).
  shared,

  /// The user closed the share sheet without picking a destination, so
  /// nothing was saved.
  dismissed,
}

/// The result of one completed export: which file was built, how many days
/// it holds, and what the user did with the share sheet.
@freezed
abstract class ExportReceipt with _$ExportReceipt {
  /// Creates an export receipt.
  const factory ExportReceipt({
    /// The format that was exported.
    required ExportFormat format,

    /// The dated file name handed to the share sheet.
    required String fileName,

    /// How many days (rows) the file holds. `0` is a real, complete export
    /// of an empty store, not a failure.
    required int dayCount,

    /// What the user did with the share sheet.
    required ExportShareOutcome outcome,

    /// Why the coach history was left out of this JSON file
    /// (`ExportBundle.coachHistoryLeftOut`), or `null` if nothing was.
    /// Always `null` for CSV, which never holds coach sessions.
    CoachHistoryLeftOut? coachHistoryLeftOut,
  }) = _ExportReceipt;
}
