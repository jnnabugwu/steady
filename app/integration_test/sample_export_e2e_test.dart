import 'package:daily_metrics_data/testing/daily_metrics_store_test_control.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:steady/main.dart';
import 'package:steady/pdfium.dart';
import 'package:steady/providers.dart';

/// "Try a sample export" end to end in the real app (macOS or iOS): the
/// bundled asset, PDFium parsing, the preview, and the commit to the real
/// SwiftData store (a separate `e2e` test store, never the user's data).
/// Nothing is overridden except the store choice; the file picker throws if
/// it's ever opened, so the bytes can only come from the bundled sample.
///
/// The sample is made up (docs/sample/), so this needs no personal export
/// and never skips. Run with `flutter test integration_test/sample_export_e2e_test.dart -d macos`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('"Try a sample export" imports the seven sample days', (
    tester,
  ) async {
    configurePdfium();
    await DailyMetricsStoreTestControl.useStore('e2e');
    await DailyMetricsStoreTestControl.reset();
    addTearDown(() => DailyMetricsStoreTestControl.useStore(null));

    // docs/sample/generate.py: Mon Jan 6 - Sun Jan 12 2025.
    final expected = {
      DateTime(2025, 1, 6): 1450,
      DateTime(2025, 1, 7): 1625,
      DateTime(2025, 1, 8): 1920,
      DateTime(2025, 1, 9): 230,
      DateTime(2025, 1, 10): 1500,
      DateTime(2025, 1, 11): 1610,
      DateTime(2025, 1, 12): 1070,
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...appProviderOverrides,
          dailyMetricStoreProvider.overrideWithValue(
            DailyMetricStore.swiftData,
          ),
          pdfFilePickerProvider.overrideWithValue(
            () => throw StateError('the file picker must not open'),
          ),
        ],
        child: const SteadyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('importButton_header')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pdfImport_sampleButton')));
    // Loading the asset and parsing on a PDFium worker run outside the
    // fake clock.
    final importButton = find.byKey(const Key('pdfImport_importButton'));
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (importButton.evaluate().isNotEmpty) break;
    }
    expect(find.text('7 days found'), findsOneWidget);
    expect(find.text('Mon, Jan 6 2025 – Sun, Jan 12 2025'), findsOneWidget);
    expect(find.text('230 kcal · 1 entry'), findsOneWidget);
    expect(find.text('Import 7 days'), findsOneWidget);

    await tester.tap(importButton);
    await tester.pumpAndSettle();

    expect(find.byType(PdfImportModule), findsNothing);
    expect(find.byType(MetricsHistoryModule), findsOneWidget);
    expect(find.textContaining('7 days'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SteadyApp)),
    );
    final result = await container
        .read(dailyMetricRepositoryProvider)
        .getRange(DateTime(2000), DateTime(2100));
    final stored = {
      for (final m in (result as Ok<List<DailyMetric>>).value)
        m.date: m.caloriesEaten,
    };
    expect(stored, expected);
    // Surfaced in the run log as evidence of what reached SwiftData.
    // ignore: avoid_print
    print('E2E sample: ${stored.length} days in SwiftData: $stored');
  });
}
