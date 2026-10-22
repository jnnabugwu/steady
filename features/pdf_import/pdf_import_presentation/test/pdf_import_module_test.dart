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

  setUp(() {
    repository = FakePdfImportRepository();
    picker = FakePdfFilePicker(bytes: pdfBytes);
    completedCount = 0;
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        pdfImportRepositoryProvider.overrideWithValue(repository),
        pdfFilePickerProvider.overrideWithValue(picker.call),
      ],
      child: ShadcnApp(
        theme: steadyTheme,
        home: PdfImportModule(onImportCompleted: () => completedCount++),
      ),
    ),
  );

  final chooseButton = find.byKey(const Key('pdfImport_chooseButton'));
  final importButton = find.byKey(const Key('pdfImport_importButton'));
  final chooseAgainButton = find.byKey(
    const Key('pdfImport_chooseAgainButton'),
  );

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
    expect(tester.widget<OutlineButton>(chooseAgainButton).onPressed, isNull);
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
}
