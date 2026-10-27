import 'dart:async';

import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_import_domain/pdf_import_domain.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fakes.dart';

void main() {
  late FakePdfImportRepository repository;
  late FakePdfFilePicker picker;
  late int completedCount;
  late int backCount;

  setUp(() {
    repository = FakePdfImportRepository();
    picker = FakePdfFilePicker(bytes: pdfBytes);
    completedCount = 0;
    backCount = 0;
  });

  Future<void> pump(WidgetTester tester, {String? pickNote}) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [
            pdfImportRepositoryProvider.overrideWithValue(repository),
            pdfFilePickerProvider.overrideWithValue(picker.call),
            sampleExportLoaderProvider.overrideWithValue(
              () async => sampleBytes,
            ),
          ],
          child: ShadcnApp(
            theme: steadyTheme,
            home: PdfImportModule(
              onImportCompleted: () => completedCount++,
              onBack: () => backCount++,
              pickNote: pickNote,
            ),
          ),
        ),
      );

  final chooseButton = find.byKey(const Key('pdfImport_chooseButton'));
  final sampleButton = find.byKey(const Key('pdfImport_sampleButton'));
  final importButton = find.byKey(const Key('pdfImport_importButton'));
  final chooseAgainButton = find.byKey(
    const Key('pdfImport_chooseAgainButton'),
  );

  testWidgets("the pick step shows the app's note only when given", (
    tester,
  ) async {
    await pump(tester);
    expect(find.byKey(const Key('pdfImport_pickNote')), findsNothing);

    await pump(tester, pickNote: 'No PDF needed.');
    expect(find.text('No PDF needed.'), findsOneWidget);
  });

  testWidgets('the back button calls onBack, on the pick step and the '
      'preview', (tester) async {
    await pump(tester);
    final back = find.byKey(const Key('pdfImport_backButton'));
    expect(
      tester.getSemantics(back),
      matchesSemantics(
        label: 'Back',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );

    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(backCount, 1);

    await tester.tap(chooseButton);
    await tester.pumpAndSettle();
    expect(importButton, findsOneWidget);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(backCount, 2);
    expect(completedCount, 0);
  });

  testWidgets('empty -> preview -> import fires onImportCompleted once', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Choose Cal AI PDF'), findsOneWidget);

    await tester.tap(chooseButton);
    await tester.pumpAndSettle();

    expect(repository.parseCalls, [pdfBytes]);
    expect(find.text('2 days found'), findsOneWidget);
    expect(find.text('Sun, Aug 16 2026 – Mon, Aug 17 2026'), findsOneWidget);
    expect(find.text('Mon, Aug 17 2026'), findsOneWidget);
    expect(find.text('2,150 kcal · 2 entries'), findsOneWidget);
    expect(find.text('Sun, Aug 16 2026'), findsOneWidget);
    expect(find.text('640 kcal · 1 entry'), findsOneWidget);
    expect(find.text('Import 2 days'), findsOneWidget);

    await tester.tap(importButton);
    await tester.pumpAndSettle();

    expect(repository.commitCalls, [sampleDays]);
    expect(completedCount, 1);
    expect(find.text('Imported 2 days'), findsOneWidget);
  });

  testWidgets('shows a spinner while parsing', (tester) async {
    final parse = Completer<Result<List<ParsedDay>>>();
    repository.onParse = (_) => parse.future;

    await pump(tester);
    await tester.tap(chooseButton);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    parse.complete(Ok(sampleDays));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('2 days found'), findsOneWidget);
  });

  testWidgets('a cancelled pick stays on the empty state', (tester) async {
    picker.bytes = null;

    await pump(tester);
    await tester.tap(chooseButton);
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(repository.parseCalls, isEmpty);
    expect(find.text('Choose Cal AI PDF'), findsOneWidget);
  });

  testWidgets('a parse failure shows its message and allows picking again', (
    tester,
  ) async {
    repository.onParse = (_) => const Err(ValidationFailure('Not a PDF'));

    await pump(tester);
    await tester.tap(chooseButton);
    await tester.pumpAndSettle();

    expect(find.text("Couldn't read that PDF"), findsOneWidget);
    expect(find.text('Not a PDF'), findsOneWidget);

    repository.onParse = (_) => Ok(sampleDays);
    await tester.tap(find.text('Choose another PDF'));
    await tester.pumpAndSettle();

    expect(repository.parseCalls, hasLength(2));
    expect(find.text('2 days found'), findsOneWidget);
  });

  testWidgets('zero parsed days shows a clear message and no import', (
    tester,
  ) async {
    repository.onParse = (_) => const Ok([]);

    await pump(tester);
    await tester.tap(chooseButton);
    await tester.pumpAndSettle();

    expect(
      find.text('No days found in this PDF — is it a Cal AI export?'),
      findsOneWidget,
    );
    expect(importButton, findsNothing);
    expect(find.text('Choose another PDF'), findsOneWidget);
  });

  testWidgets(
    'a failed commit shows the message, does not complete, and can retry',
    (tester) async {
      repository.onCommit = (_) => const Err(UnknownFailure('store down'));

      await pump(tester);
      await tester.tap(chooseButton);
      await tester.pumpAndSettle();
      await tester.tap(importButton);
      await tester.pumpAndSettle();

      expect(find.text("Couldn't import: store down"), findsOneWidget);
      expect(completedCount, 0);
      expect(find.text('2 days found'), findsOneWidget);

      repository.onCommit = (_) => const Ok(unit);
      await tester.tap(importButton);
      await tester.pumpAndSettle();

      expect(repository.commitCalls, hasLength(2));
      expect(completedCount, 1);
    },
  );

  testWidgets('buttons are disabled while committing; one completion', (
    tester,
  ) async {
    final commit = Completer<Result<Unit>>();
    repository.onCommit = (_) => commit.future;

    await pump(tester);
    await tester.tap(chooseButton);
    await tester.pumpAndSettle();
    await tester.tap(importButton);
    await tester.pump();

    expect(find.text('Importing…'), findsOneWidget);
    expect(tester.widget<PrimaryButton>(importButton).onPressed, isNull);
    expect(tester.widget<Button>(chooseAgainButton).onPressed, isNull);
    await tester.tap(importButton, warnIfMissed: false);

    commit.complete(const Ok(unit));
    await tester.pumpAndSettle();

    expect(repository.commitCalls, hasLength(1));
    expect(completedCount, 1);
  });

  testWidgets('expanding a day shows its food entries', (tester) async {
    await pump(tester);
    await tester.tap(chooseButton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mon, Aug 17 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Ground Turkey · 780 kcal'), findsOneWidget);
    expect(find.text('Rice Bowl · 1,370 kcal'), findsOneWidget);
  });

  testWidgets('"Try a sample export" sits under the picker with its caption', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Try a sample export'), findsOneWidget);
    expect(
      find.text(
        'Seven made-up days from January 2025, to see how importing works.',
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(sampleButton).dy,
      greaterThan(tester.getTopLeft(chooseButton).dy),
    );
  });

  testWidgets('the sample export runs parse -> preview -> import', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(sampleButton);
    await tester.pumpAndSettle();

    expect(picker.calls, 0);
    expect(repository.parseCalls, [sampleBytes]);
    expect(find.text('2 days found'), findsOneWidget);

    await tester.tap(importButton);
    await tester.pumpAndSettle();

    expect(repository.commitCalls, [sampleDays]);
    // The confirmation stays up with the removal hint until Done.
    expect(completedCount, 0);
    expect(find.text('Imported 2 days'), findsOneWidget);
    expect(
      find.text(
        'These are sample days. Remove them anytime in '
        'Settings → Sample data.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('pdfImport_doneButton')));
    await tester.pump();

    expect(completedCount, 1);
  });

  testWidgets('a chosen file gets no sample hint and completes at once', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(chooseButton);
    await tester.pumpAndSettle();
    await tester.tap(importButton);
    await tester.pumpAndSettle();

    expect(completedCount, 1);
    expect(find.byKey(const Key('pdfImport_sampleHint')), findsNothing);
    expect(find.byKey(const Key('pdfImport_doneButton')), findsNothing);
  });

  testWidgets('the real loader reads the bundled PDF asset', (tester) async {
    final bytes = await tester.runAsync(loadSampleExportFromBundle);

    // "%PDF": the pubspec's assets entry is in place and the file is a PDF.
    expect(bytes!.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]);
  });
}
