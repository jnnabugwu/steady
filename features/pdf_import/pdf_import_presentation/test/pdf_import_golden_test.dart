import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fakes.dart';
import 'helpers/golden.dart';

/// Each golden: its name, and how to get the screen there from the pick
/// step.
final goldenSteps = <(String, Future<void> Function(WidgetTester))>[
  ('pdf_import_pick', (_) async {}),
  (
    'pdf_import_preview',
    (tester) async {
      await tester.tap(find.byKey(const Key('pdfImport_chooseButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mon, Aug 17 2026'));
      await tester.pumpAndSettle();
    },
  ),
  (
    'pdf_import_sample_done',
    (tester) async {
      await tester.tap(find.byKey(const Key('pdfImport_sampleButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pdfImport_importButton')));
      await tester.pumpAndSettle();
    },
  ),
];

/// Pumps the import screen at the golden size, on the pick step.
Future<void> pumpGoldenScreen(WidgetTester tester) async {
  await loadGoldenFonts();
  useGoldenSurface(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pdfImportRepositoryProvider.overrideWithValue(
          FakePdfImportRepository(),
        ),
        pdfFilePickerProvider.overrideWithValue(
          FakePdfFilePicker(bytes: pdfBytes).call,
        ),
        sampleExportLoaderProvider.overrideWithValue(() async => sampleBytes),
      ],
      child: ShadcnApp(
        theme: steadyTheme,
        home: PdfImportModule(onImportCompleted: () {}, onBack: () {}),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PdfImportModule goldens', () {
    for (final (name, step) in goldenSteps) {
      // A group per golden so its skip reason is reported (testWidgets'
      // `skip` is a bool).
      group(name, skip: goldenSkip(name), () {
        testWidgets('matches goldens/$name.png', (tester) async {
          await pumpGoldenScreen(tester);
          await step(tester);
          await expectLater(
            find.byType(PdfImportModule),
            matchesGoldenFile('goldens/$name.png'),
          );
        });
      });
    }
  });
}
