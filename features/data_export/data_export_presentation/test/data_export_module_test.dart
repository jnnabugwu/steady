import 'dart:async';

import 'package:coach_domain/coach_domain.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:data_export_domain/data_export_domain.dart';
import 'package:data_export_presentation/data_export_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fakes.dart';

void main() {
  final now = DateTime(2026, 10, 22, 9, 30);
  final rows = [
    DailyMetric(date: DateTime(2026, 10, 19), caloriesEaten: 1850),
    DailyMetric(date: DateTime(2026, 10, 20), steps: 4000),
  ];

  late FakeDailyMetricRepository repository;
  late FakeExportSharer sharer;
  late int backCount;

  setUp(() {
    repository = FakeDailyMetricRepository(onGetRange: () => Ok(rows));
    sharer = FakeExportSharer();
    backCount = 0;
  });

  Future<void> pumpModule(
    WidgetTester tester, {
    List<Widget> sections = const [],
    CoachRepository? coach,
  }) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        exportDailyMetricRepositoryProvider.overrideWithValue(repository),
        if (coach != null)
          exportCoachRepositoryProvider.overrideWithValue(coach),
        exportFileSharerProvider.overrideWithValue(sharer.call),
        exportClockProvider.overrideWithValue(() => now),
      ],
      child: ShadcnApp(
        theme: steadyTheme,
        home: DataExportModule(onBack: () => backCount++, sections: sections),
      ),
    ),
  );

  Finder button(ExportFormat format) =>
      find.byKey(Key('exportButton_${format.name}'));

  VoidCallback? onPressed(WidgetTester tester, ExportFormat format) =>
      switch (format) {
        ExportFormat.csv =>
          tester.widget<PrimaryButton>(button(format)).onPressed,
        ExportFormat.json => tester.widget<Button>(button(format)).onPressed,
      };

  testWidgets('shows the app-composed sections above the export', (
    tester,
  ) async {
    await pumpModule(
      tester,
      sections: const [Text('Another setting', key: Key('otherSection'))],
    );

    final section = tester.getTopLeft(find.byKey(const Key('otherSection')));
    final export = tester.getTopLeft(find.text('Export your data'));
    expect(section.dy, lessThan(export.dy));
  });

  testWidgets('starts idle with both export buttons enabled', (tester) async {
    await pumpModule(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Export your data'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('Export JSON'), findsOneWidget);
    // No coach on this device (the Mac): the export doesn't mention it.
    expect(
      tester.widget<Text>(find.byKey(const Key('exportContentsLine'))).data,
      'Includes daily metrics and check-ins.',
    );
    for (final format in ExportFormat.values) {
      expect(onPressed(tester, format), isNotNull);
    }
    expect(find.textContaining('Export'), findsNWidgets(3));
    expect(repository.getRangeCalls, isEmpty);
  });

  testWidgets('with the coach (iPhone), says the JSON has session summaries '
      'but not the conversation', (tester) async {
    await pumpModule(tester, coach: FakeCoachRepository());

    expect(
      tester.widget<Text>(find.byKey(const Key('exportContentsLine'))).data,
      'Includes daily metrics and check-ins. The JSON file also includes '
      "each coach session's date, type and summary, but not the "
      'conversation itself.',
    );
  });

  testWidgets('tapping Export CSV shares the dated file and confirms it', (
    tester,
  ) async {
    await pumpModule(tester);
    final buttonRect = tester.getRect(button(ExportFormat.csv));

    await tester.tap(button(ExportFormat.csv));
    await tester.pumpAndSettle();

    expect(sharer.sharedFiles.single.fileName, 'steady-export-2026-10-22.csv');
    // Anchored to the tapped button, for the macOS/iPad popover.
    expect(sharer.origins.single, buttonRect);
    expect(
      find.text('Exported 2 days to steady-export-2026-10-22.csv.'),
      findsOneWidget,
    );
  });

  testWidgets('one day is singular', (tester) async {
    repository.onGetRange = () => Ok([rows.first]);
    await pumpModule(tester);

    await tester.tap(button(ExportFormat.json));
    await tester.pumpAndSettle();

    expect(
      find.text('Exported 1 day to steady-export-2026-10-22.json.'),
      findsOneWidget,
    );
  });

  testWidgets('a dismissed share sheet says nothing was saved', (tester) async {
    sharer.onShare = (_) => const Ok(ExportShareOutcome.dismissed);
    await pumpModule(tester);

    await tester.tap(button(ExportFormat.csv));
    await tester.pumpAndSettle();

    expect(find.text('Export cancelled. Nothing was saved.'), findsOneWidget);
  });

  testWidgets(
    'a repository Failure is shown, and no file reaches the share sheet',
    (tester) async {
      repository.onGetRange = () =>
          const Err(PlatformChannelFailure('store down'));
      await pumpModule(tester);

      await tester.tap(button(ExportFormat.csv));
      await tester.pumpAndSettle();

      expect(
        find.text('Export failed: store down. Nothing was exported.'),
        findsOneWidget,
      );
      expect(sharer.sharedFiles, isEmpty);
      expect(find.textContaining('Exported'), findsNothing);
    },
  );

  testWidgets(
    'buttons are disabled and a spinner shows while an export is in flight',
    (tester) async {
      final share = Completer<Result<ExportShareOutcome>>();
      sharer.onShare = (_) => share.future;
      await pumpModule(tester);

      await tester.tap(button(ExportFormat.csv));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      for (final format in ExportFormat.values) {
        expect(onPressed(tester, format), isNull);
      }
      await tester.tap(button(ExportFormat.json), warnIfMissed: false);

      share.complete(const Ok(ExportShareOutcome.shared));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(sharer.sharedFiles, hasLength(1));
      for (final format in ExportFormat.values) {
        expect(onPressed(tester, format), isNotNull);
      }
    },
  );

  testWidgets('the back button calls onBack', (tester) async {
    await pumpModule(tester);

    await tester.tap(find.byKey(const Key('settingsBackButton')));
    await tester.pump();

    expect(backCount, 1);
  });
}
