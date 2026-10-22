import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:steady/main.dart';
import 'package:steady/pdfium.dart';
import 'package:steady/providers.dart';

/// End-to-end PDF import in the real macOS app: PDFium loading, parsing,
/// committing to the file-backed store, and reading it back after a
/// simulated restart. Only the native file dialog is replaced.
///
/// Needs a Cal AI export at `<app support>/e2e_export.pdf` inside the
/// app's sandbox container (personal data, never committed); skips
/// otherwise. Run with `flutter test integration_test -d macos`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('import a Cal AI PDF and still see it after a restart', (
    tester,
  ) async {
    configurePdfium();
    final support = await getApplicationSupportDirectory();
    final pdf = File('${support.path}/e2e_export.pdf');
    if (!pdf.existsSync()) {
      markTestSkipped('No export at ${pdf.path}');
      return;
    }
    final store = File('${support.path}/e2e_daily_metrics.json');
    if (store.existsSync()) store.deleteSync();
    final bytes = pdf.readAsBytesSync();

    Widget app() => ProviderScope(
      overrides: [
        ...appProviderOverrides,
        dailyMetricsFileProvider.overrideWithValue(store),
        pdfFilePickerProvider.overrideWithValue(() async => bytes),
      ],
      child: const SteadyApp(),
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('importButton_header')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pdfImport_chooseButton')));
    // Parsing runs on a PDFium worker, outside the fake clock.
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const Key('pdfImport_importButton'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    await tester.tap(find.byKey(const Key('pdfImport_importButton')));
    await tester.pumpAndSettle();

    expect(find.byType(PdfImportModule), findsNothing);
    expect(find.byType(MetricsHistoryModule), findsOneWidget);
    expect(store.existsSync(), isTrue);
    final firstRun = find.textContaining(' days');

    // Restart: a fresh ProviderScope over the same file.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(firstRun, findsWidgets);
    // Surfaced in the run log as evidence of where the store landed.
    // ignore: avoid_print
    print('E2E: ${store.lengthSync()} bytes stored at ${store.path}');
  });
}
