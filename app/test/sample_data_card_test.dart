import 'dart:async';
import 'dart:typed_data';

import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:pdf_import_domain/pdf_import_domain.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart'
    show CircularProgressIndicator, Scaffold, ShadcnApp;
import 'package:steady/main.dart';
import 'package:steady/providers.dart';
import 'package:steady/sample_data_card.dart';
import 'package:ui_kit/ui_kit.dart';

/// Settings' "Sample data" card (#105), in the real app on the real
/// override list (in-memory store): hidden unless the sample export's days
/// are in the store, and "Remove sample days" removes only those, then
/// refreshes the history.
void main() {
  final card = find.byKey(const Key('sampleDataCard'));
  final removeButton = find.byKey(const Key('removeSampleDaysButton'));

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    String? coldStartLocation,
    Future<void> Function(ProviderContainer)? seed,
  }) async {
    if (coldStartLocation != null) {
      tester.platformDispatcher.defaultRouteNameTestValue = coldStartLocation;
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    }
    final container = ProviderContainer(overrides: appProviderOverrides);
    addTearDown(container.dispose);
    await seed?.call(container);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SteadyApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> importSample(ProviderContainer container) async {
    final result = await container
        .read(pdfImportRepositoryProvider)
        .commitDailyTotals([
          for (final MapEntry(key: date, value: kcal)
              in sampleExportDailyTotals.entries)
            ParsedDay(date: date, caloriesEaten: kcal, foodEntries: const []),
        ]);
    expect(result, isA<Ok<Unit>>());
  }

  testWidgets('is hidden when no sample days are in the store', (tester) async {
    await pumpApp(
      tester,
      coldStartLocation: '/settings',
      // A real day on a sample date, with its own total: not a sample row.
      seed: (c) => c
          .read(dailyMetricRepositoryProvider)
          .upsert(DateTime(2025, 1, 9), caloriesEaten: 2100),
    );

    expect(find.text('Export your data'), findsOneWidget);
    expect(card, findsNothing);
    expect(find.text('Sample data'), findsNothing);
  });

  testWidgets('removes only the sample days, keeps a check-in, refreshes the '
      'history, then hides', (tester) async {
    final jan6 = DateTime(2025, 1, 6);
    final container = await pumpApp(
      tester,
      coldStartLocation: '/week',
      seed: (c) async {
        await importSample(c);
        await c
            .read(dailyMetricRepositoryProvider)
            .upsert(jan6, loggingStatus: LoggingStatus.logged);
      },
    );
    expect(find.byType(MetricsHistoryModule), findsOneWidget);
    expect(find.textContaining('7 days'), findsOneWidget);

    await tester.tap(find.byKey(const Key('openSettingsButton')));
    await tester.pumpAndSettle();

    expect(card, findsOneWidget);
    expect(find.text('Sample data'), findsOneWidget);
    expect(
      find.text('7 sample days from January 2025 are in your history.'),
      findsOneWidget,
    );

    await tester.ensureVisible(removeButton);
    await tester.pumpAndSettle();
    await tester.tap(removeButton);
    await tester.pumpAndSettle();

    expect(card, findsNothing);
    final rows = await container
        .read(dailyMetricRepositoryProvider)
        .getRange(DateTime(2000), DateTime(2100));
    expect((rows as Ok<List<DailyMetric>>).value, [
      DailyMetric(date: jan6, loggingStatus: LoggingStatus.logged),
    ]);

    // The history was re-read, not left showing the sample. Back from
    // Settings goes to Today; the history is the Week tab.
    await tester.tap(find.byKey(const Key('settingsBackButton')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('appTabBar')),
        matching: find.text('Week'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MetricsHistoryModule), findsOneWidget);
    expect(find.textContaining('7 days'), findsNothing);
  });

  testWidgets('shows a spinner while removing, and says so if it fails', (
    tester,
  ) async {
    final repository = _GatedPdfImportRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [pdfImportRepositoryProvider.overrideWithValue(repository)],
        child: const ShadcnApp(
          theme: steadyTheme,
          home: Scaffold(child: SampleDataCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('3 sample days from January 2025 are in your history.'),
      findsOneWidget,
    );

    await tester.tap(removeButton);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(removeButton, findsNothing);

    repository.remove.complete(const Err(UnknownFailure('store down')));
    await tester.pumpAndSettle();

    expect(card, findsOneWidget);
    expect(find.byKey(const Key('sampleDataError')), findsOneWidget);
    expect(removeButton, findsOneWidget);
  });
}

/// Counts 3 sample days; [removeSampleDays] waits on [remove].
class _GatedPdfImportRepository implements PdfImportRepository {
  final Completer<Result<int>> remove = Completer();

  @override
  ResultFuture<int> countSampleDays() async => const Ok(3);

  @override
  ResultFuture<int> removeSampleDays() => remove.future;

  @override
  ResultFuture<List<ParsedDay>> parse(Uint8List pdfBytes) async => const Ok([]);

  @override
  ResultFuture<Unit> commitDailyTotals(List<ParsedDay> days) async =>
      const Ok(unit);
}
