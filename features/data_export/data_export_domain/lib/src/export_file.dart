import 'dart:convert';
import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'export_file.freezed.dart';

/// A finished export, ready to hand to the share sheet: its dated
/// [fileName], [mimeType] and full text [contents].
@freezed
abstract class ExportFile with _$ExportFile {
  /// Creates an export file.
  const factory ExportFile({
    /// e.g. `steady-export-2026-10-22.csv`.
    required String fileName,

    /// e.g. `text/csv`.
    required String mimeType,

    /// The whole file, as text.
    required String contents,
  }) = _ExportFile;

  const ExportFile._();

  /// [contents] encoded as UTF-8.
  Uint8List get bytes => utf8.encode(contents);
}
