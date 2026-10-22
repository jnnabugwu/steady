import 'dart:io';

import 'package:daily_metrics_data/testing/daily_metrics_store_test_control.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_import_data/pdf_import_data.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:steady/main.dart';
import 'package:steady/pdfium.dart';
import 'package:steady/providers.dart';

/// Host path of a Cal AI export, passed with
/// `--dart-define=E2E_PDF_PATH=/abs/path.pdf`. The iOS simulator can read
/// host paths; the macOS sandbox can't, so there it falls back to the
/// container copy.
const _e2ePdfPath = String.fromEnvironment('E2E_PDF_PATH');

/// End-to-end PDF import in the real app (macOS or iOS): PDFium loading,
/// parsing, committing to the real SwiftData store (a separate `e2e` test
/// store, never the user's data), and reading it back after a simulated
/// restart that also reopens the store from disk. Only the native file
/// dialog is replaced.
///
/// The export (personal data, never committed) comes from `E2E_PDF_PATH`
/// when it's set, and the test fails if that file is unreadable (no
/// fallback, so it can't pass against a different export). Without the
/// define it uses `<app support>/e2e_export.pdf` inside the app's
/// container, and skips if that's missing. Run with
/// `flutter test integration_test -d macos`, or
/// `flutter test integration_test -d SIMULATOR_ID
/// --dart-define=E2E_PDF_PATH=/abs/path.pdf`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('import a Cal AI PDF and still see it after a restart', (
    tester,
  ) async {
    configurePdfium();
    final support = await getApplicationSupportDirectory();
    final File pdf;
    if (_e2ePdfPath.isNotEmpty) {
      // Explicitly requested: never fall back to a different export.
      final requested = _readable(_e2ePdfPath);
      if (requested == null) fail('E2E_PDF_PATH=$_e2ePdfPath is unreadable');
      pdf = requested;
    } else {
      pdf = File('${support.path}/e2e_export.pdf');
      if (!pdf.existsSync()) {
        markTestSkipped('No export at ${pdf.path}');
        return;
      }
    }
    await DailyMetricsStoreTestControl.useStore('e2e');
    await DailyMetricsStoreTestControl.reset();
    addTearDown(() => DailyMetricsStoreTestControl.useStore(null));
    final bytes = pdf.readAsBytesSync();
    // The expected rows come from the parser directly, so the test checks
    // what the app stored against what's actually in this export.
    final days = await CalAIParser().parse(bytes);
    final expected = {
      for (final d in days)
        DateTime(d.date.year, d.date.month, d.date.day): d.caloriesEaten,
    };
    expect(expected, isNotEmpty);
    final entries = days.fold(0, (n, d) => n + d.foodEntries.length);
    // Surfaced in the run log as evidence of what was parsed.
    // ignore: avoid_print
    print(
      'E2E: parsed ${expected.length} days, $entries entries from ${pdf.path}',
    );
    final summary = '${expected.length} days';

    Future<Map<DateTime, int?>> stored(ProviderContainer container) async {
      final result = await container
          .read(dailyMetricRepositoryProvider)
          .getRange(DateTime(2000), DateTime(2100));
      return {
        for (final m in (result as Ok<List<DailyMetric>>).value)
          m.date: m.caloriesEaten,
      };
    }

    ProviderContainer container() =>
        ProviderScope.containerOf(tester.element(find.byType(SteadyApp)));

    Widget app() => ProviderScope(
      overrides: [
        ...appProviderOverrides,
        dailyMetricStoreProvider.overrideWithValue(DailyMetricStore.swiftData),
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
    expect(find.textContaining(summary), findsOneWidget);
    expect(await stored(container()), expected);

    // Restart: a fresh ProviderScope, and the store reopened from disk.
    await tester.pumpWidget(const SizedBox());
    await DailyMetricsStoreTestControl.useStore('e2e');
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.textContaining(summary), findsOneWidget);
    expect(await stored(container()), expected);
    // Surfaced in the run log as evidence of what reached SwiftData.
    // ignore: avoid_print
    print('E2E: ${expected.length} days read back from SwiftData');
  });
}

/// [path] as a file if it's set and this process can read it.
File? _readable(String path) {
  if (path.isEmpty) return null;
  try {
    final file = File(path);
    file.openSync().closeSync();
    return file;
  } on FileSystemException {
    return null;
  }
}
