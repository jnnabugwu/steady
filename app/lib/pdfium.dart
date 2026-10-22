import 'dart:ffi';
import 'dart:io';

import 'package:pdfrx_engine/pdfrx_engine.dart';

/// Makes sure `pdfrx_engine` can find PDFium on iOS and macOS.
///
/// Under Flutter on iOS and macOS, `pdfium_dart` assumes PDFium is already
/// linked into the process and looks it up with `DynamicLibrary.process()`.
/// `pdfium_flutter` (a dependency of `pdf_import_data`) is what makes that
/// true: it links its PDFium XCFramework into the app on both platforms
/// (iOS has no other source, since `pdfium_dart`'s build hook skips PDFium
/// there). So normally this is a no-op.
///
/// The fallback is the macOS-only fix from before `pdfium_flutter` (#38): if
/// the process doesn't export PDFium, point the module path at the
/// `Contents/Frameworks/pdfium.framework` that `pdfium_dart` bundles, so it
/// `dlopen`s that instead. Must run before the first parse.
void configurePdfium() {
  if (!Platform.isIOS && !Platform.isMacOS) return;
  if (DynamicLibrary.process().providesSymbol('FPDF_InitLibrary')) return;
  if (!Platform.isMacOS) return;
  final contents = File(Platform.resolvedExecutable).parent.parent.path;
  final module = '$contents/Frameworks/pdfium.framework/pdfium';
  if (File(module).existsSync()) {
    Pdfrx.pdfiumModulePath ??= module;
  }
}
