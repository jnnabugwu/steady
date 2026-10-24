import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:steady/main.dart';
import 'package:steady/providers.dart';
import 'package:steady/today_screen.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: appProviderOverrides, child: const SteadyApp()),
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
}
