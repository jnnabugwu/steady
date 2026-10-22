import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:failures/failures.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:share_plus/share_plus.dart';

/// Hands a rendered week-card PNG to the system share sheet.
///
/// [fileName] is what the recipient sees (without it share_plus names the
/// file with a random UUID). [origin] is the global rect of the control
/// that started the share: iPad anchors the share popover to it and
/// ignores it elsewhere.
///
/// The seam tests override (via `weekCardSharerProvider`) so they never
/// reach the share_plus plugin. Returns a typed [Failure] instead of
/// throwing, so the UI never sees a raw `PlatformException` (CLAUDE.md §9).
typedef WeekCardSharer = ResultFuture<Unit> Function({
  required Uint8List png,
  required String fileName,
  Rect? origin,
});

/// The real [WeekCardSharer]: `share_plus`'s system share sheet (Messages,
/// Instagram, WhatsApp, Photos, ...).
///
/// A dismissed sheet still counts as `Ok`: the user chose not to share,
/// which is not an error.
ResultFuture<Unit> shareViaSystemSheet({
  required Uint8List png,
  required String fileName,
  Rect? origin,
}) async {
  try {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(png, mimeType: 'image/png')],
        fileNameOverrides: [fileName],
        sharePositionOrigin: origin,
      ),
    );
    return const Ok(unit);
  } on PlatformException catch (e) {
    return Err(
      PlatformChannelFailure(
        e.message ?? 'The share sheet failed to open.',
        code: e.code,
        cause: e,
      ),
    );
  } on Exception catch (e) {
    return Err(UnknownFailure('The share sheet failed to open.', cause: e));
  }
}
