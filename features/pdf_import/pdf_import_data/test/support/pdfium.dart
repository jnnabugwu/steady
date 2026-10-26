import 'dart:convert';
import 'dart:io';

import 'package:pdfrx_engine/pdfrx_engine.dart';

/// Points pdfrx at the PDFium library `flutter test` built for this host.
///
/// pdfium_dart 0.4.0 finds the bundled PDFium via
/// `.dart_tool/native_assets.yaml`, which `flutter test` doesn't write, so
/// loading fails with "Native assets file not found". `flutter test` does
/// build the library, though, and lists it in
/// `build/native_assets/<os>/native_assets.json` (#38). Reading the path
/// from that manifest, rather than hard-coding `macos/libpdfium.dylib`,
/// makes this work on the Linux CI runner too.
void usePdfiumBuiltByFlutterTest() {
  final manifest = File(
    'build/native_assets/${Platform.operatingSystem}/native_assets.json',
  );
  if (!manifest.existsSync()) return;

  final json = jsonDecode(manifest.readAsStringSync()) as Map<String, dynamic>;
  final targets = json['native-assets'] as Map<String, dynamic>? ?? {};
  for (final assets in targets.values) {
    final entry =
        (assets as Map<String, dynamic>)['package:pdfium_dart/libpdfium'];
    if (entry is List && entry.length == 2 && entry[0] == 'absolute') {
      final path = entry[1] as String;
      if (File(path).existsSync()) {
        Pdfrx.pdfiumModulePath = path;
        return;
      }
    }
  }
}
