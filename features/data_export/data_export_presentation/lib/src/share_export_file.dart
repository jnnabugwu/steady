import 'package:data_export_domain/data_export_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Hands an [ExportFile] to the system share sheet and reports what the
/// user did with it.
///
/// The seam between the Notifier and the `share_plus` plugin: production
/// uses [shareExportFileViaSharePlus], tests override
/// `exportFileSharerProvider` with a fake so they never reach the plugin.
///
/// [sharePositionOrigin] is the global rect of the button that triggered
/// the export, where the share sheet's popover anchors on macOS and iPad.
typedef ExportFileSharer = ResultFuture<ExportShareOutcome> Function(
  ExportFile file, {
  Rect? sharePositionOrigin,
});

/// The production [ExportFileSharer]: shares [file] through `share_plus`
/// (the system share sheet, which includes Save to Files).
///
/// The bytes go in as `XFile.fromData` with [ExportFile.fileName] as the
/// file name override, so the saved file is named
/// `steady-export-<yyyy-MM-dd>.<ext>` rather than a temp name.
///
/// A platform exception becomes `Err(ExportShareFailure)`; it is never
/// reported as a successful export.
Future<Result<ExportShareOutcome>> shareExportFileViaSharePlus(
  ExportFile file, {
  Rect? sharePositionOrigin,
}) async {
  try {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            file.bytes,
            mimeType: file.mimeType,
            name: file.fileName,
          ),
        ],
        fileNameOverrides: [file.fileName],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
    return Ok(switch (result.status) {
      ShareResultStatus.dismissed => ExportShareOutcome.dismissed,
      // `unavailable`: the sheet was shown but this platform can't report
      // the user's choice.
      ShareResultStatus.success ||
      ShareResultStatus.unavailable => ExportShareOutcome.shared,
    });
  } on Exception catch (e) {
    return Err(ExportShareFailure('Could not open the share sheet', cause: e));
  }
}
