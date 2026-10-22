import 'dart:io';

import 'package:pdfrx_engine/pdfrx_engine.dart';

/// Points `pdfrx_engine` at the PDFium library bundled into the macOS app.
///
/// Under Flutter on macOS, `pdfium_dart` assumes PDFium is already linked
/// into the process and looks it up with `DynamicLibrary.process()`. The
/// macOS build only bundles it as `Contents/Frameworks/pdfium.framework`
/// without linking it, so that lookup fails and every PDF parse throws
/// (#38). Setting the module path makes it `dlopen` the bundled framework
/// instead. Must run before the first parse.
///
/// iOS is not handled yet (#44): its build hook ships no PDFium at all.
void configurePdfium() {
  if (!Platform.isMacOS) return;
  final contents = File(Platform.resolvedExecutable).parent.parent.path;
  final module = '$contents/Frameworks/pdfium.framework/pdfium';
  if (File(module).existsSync()) {
    Pdfrx.pdfiumModulePath ??= module;
  }
}
