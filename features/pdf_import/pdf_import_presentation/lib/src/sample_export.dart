import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sample_export.g.dart';

/// Loads the bundled sample Cal AI export's bytes.
///
/// May throw if the asset can't be read; `PdfImportController.chooseSamplePdf`
/// maps that to a typed `Failure`.
typedef SampleExportLoader = Future<Uint8List> Function();

/// The bundled sample export: seven made-up days, Jan 6-12 2025, so App
/// Review and testers without a Cal AI export can try the import. Built by
/// `docs/sample/generate.py`; a copy of `docs/sample/cal_ai_sample_export.pdf`.
const sampleExportAsset =
    'packages/pdf_import_presentation/assets/cal_ai_sample_export.pdf';

/// How the import flow reads the sample export.
///
/// A seam so widget and controller tests can supply bytes without the real
/// PDF. The app doesn't need to override it: the default reads
/// [sampleExportAsset] from the root bundle.
///
/// `keepAlive`: a stateless function, recreating it gains nothing.
@Riverpod(keepAlive: true)
SampleExportLoader sampleExportLoader(Ref ref) => loadSampleExportFromBundle;

/// The real [SampleExportLoader]: reads [sampleExportAsset].
Future<Uint8List> loadSampleExportFromBundle() async {
  final data = await rootBundle.load(sampleExportAsset);
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}
