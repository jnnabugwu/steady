import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_data/health_sync_data.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:steady/main.dart';
import 'package:steady/providers.dart';
import 'package:steady/today_screen.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    String? coldStart,
    List<Override> overrides = const [],
  }) async {
    if (coldStart != null) {
      tester.platformDispatcher.defaultRouteNameTestValue = coldStart;
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...appProviderOverrides, ...overrides],
        child: const SteadyApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the home import action opens the import screen', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('importButton_header')));
    await tester.pumpAndSettle();

    expect(find.byType(PdfImportModule), findsOneWidget);
  });

  testWidgets('completing an import returns to the Today screen', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('importButton_header')));
    await tester.pumpAndSettle();

    tester
        .widget<PdfImportModule>(find.byType(PdfImportModule))
        .onImportCompleted();
    await tester.pumpAndSettle();

    expect(find.byType(PdfImportModule), findsNothing);
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('the back button returns to the Today screen', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('importButton_header')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pdfImport_backButton')));
    await tester.pumpAndSettle();

    expect(find.byType(PdfImportModule), findsNothing);
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('back from a cold start at /import goes to Today', (
    tester,
  ) async {
    await pumpApp(tester, coldStart: '/import');
    expect(find.byType(PdfImportModule), findsOneWidget);

    await tester.tap(find.byKey(const Key('pdfImport_backButton')));
    await tester.pumpAndSettle();

    expect(find.byType(PdfImportModule), findsNothing);
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  final note = find.byKey(const Key('pdfImport_pickNote'));

  testWidgets('without Health (the Mac) the import has no Health note', (
    tester,
  ) async {
    await pumpApp(tester, coldStart: '/import');
    expect(note, findsNothing);
  });

  testWidgets('on an iPhone the import says Cal AI can go through Health', (
    tester,
  ) async {
    await pumpApp(
      tester,
      coldStart: '/import',
      overrides: [
        healthKitRepositoryProvider.overrideWithValue(
          InMemoryHealthKitRepository(),
        ),
      ],
    );
    expect(note, findsOneWidget);
  });
}
