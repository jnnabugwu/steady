import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pdf_file_picker.g.dart';

/// Opens the platform file picker and returns the chosen PDF's bytes, or
/// `null` if the user cancelled.
///
/// May throw if the platform picker fails; `PdfImportController.choosePdf`
/// maps that to a typed `Failure`.
typedef PdfFilePicker = Future<Uint8List?> Function();

/// The file picker the import flow uses.
///
/// A seam so widget and controller tests can supply bytes (or a cancel)
/// without touching `file_selector`'s platform channel. The app doesn't need
/// to override it: the default is the real picker, [pickPdfWithFileSelector].
///
/// `keepAlive`: a stateless function, recreating it gains nothing.
@Riverpod(keepAlive: true)
PdfFilePicker pdfFilePicker(Ref ref) => pickPdfWithFileSelector;

/// The real [PdfFilePicker], backed by `file_selector`. Accepts PDFs only.
Future<Uint8List?> pickPdfWithFileSelector() async {
  const pdf = XTypeGroup(
    label: 'PDF',
    extensions: ['pdf'],
    uniformTypeIdentifiers: ['com.adobe.pdf'],
  );
  final file = await openFile(acceptedTypeGroups: const [pdf]);
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  return bytes;
}
