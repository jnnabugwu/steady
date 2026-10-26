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
    expect(
      tester.widget<Text>(find.byKey(const Key('exportStorageLine'))).data,
      'Steady keeps your data in your iCloud account. Save a copy so you '
      'keep it even if you lose access to that account.',
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
    // Coach history isn't in iCloud storage: say where it is.
    expect(
      tester.widget<Text>(find.byKey(const Key('exportStorageLine'))).data,
      'Steady keeps your daily metrics and check-ins in your iCloud account, '
      'and coach conversations only on this iPhone. Save a copy so you keep '
      'them even if you lose access to that account or this iPhone.',
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

  group('coach history in the export (iPhone)', () {
    final session = CoachSession(
      id: 'w1',
      kind: CoachSessionKind.weekly,
      startedAt: DateTime(2026, 10, 23, 19),
      summary: 'Calm week.',
    );
    const leftOut =
        "Coach history couldn't be read, so it was left out. You can delete "
        'it in Settings → Coach.';

    testWidgets('sessions read: the receipt is the usual one', (tester) async {
      await pumpModule(
        tester,
        coach: FakeCoachRepository(onList: () => Ok([session])),
      );
      await tester.tap(button(ExportFormat.json));
      await tester.pumpAndSettle();

      expect(
        find.text('Exported 2 days to steady-export-2026-10-22.json.'),
        findsOneWidget,
      );
      expect(find.textContaining('left out'), findsNothing);
    });

    testWidgets('no sessions yet: the receipt is the usual one', (
      tester,
    ) async {
      await pumpModule(tester, coach: FakeCoachRepository());
      await tester.tap(button(ExportFormat.json));
      await tester.pumpAndSettle();

      expect(
        find.text('Exported 2 days to steady-export-2026-10-22.json.'),
        findsOneWidget,
      );
    });

    testWidgets('unreadable: the JSON is still shared, and the screen says '
        'the coach was left out and where to delete it', (tester) async {
      await pumpModule(
        tester,
        coach: FakeCoachRepository(
          onList: () => const Err(CoachHistoryUnreadableFailure('corrupt')),
        ),
      );
      await tester.tap(button(ExportFormat.json));
      await tester.pumpAndSettle();

      expect(sharer.sharedFiles, hasLength(1));
      expect(
        find.text('Exported 2 days to steady-export-2026-10-22.json. $leftOut'),
        findsOneWidget,
      );
      expect(DataExportModule.coachUnreadableNote, leftOut);
    });

    testWidgets('a read error (not a corrupt file): the JSON is still shared, '
        'and the screen says to export again, not to delete', (tester) async {
      await pumpModule(
        tester,
        coach: FakeCoachRepository(
          onList: () => const Err(CoachHistoryStorageFailure('locked')),
        ),
      );
      await tester.tap(button(ExportFormat.json));
      await tester.pumpAndSettle();

      expect(sharer.sharedFiles, hasLength(1));
      expect(
        find.text(
          'Exported 2 days to steady-export-2026-10-22.json. '
          "Coach history couldn't be read just now, so it was left out. "
          'Export again to include it.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('delete'), findsNothing);
    });

    testWidgets('unreadable, CSV: nothing to leave out, so no note', (
      tester,
    ) async {
      await pumpModule(
        tester,
        coach: FakeCoachRepository(
          onList: () => const Err(CoachHistoryUnreadableFailure('corrupt')),
        ),
      );
      await tester.tap(button(ExportFormat.csv));
      await tester.pumpAndSettle();

      expect(
        find.text('Exported 2 days to steady-export-2026-10-22.csv.'),
        findsOneWidget,
      );
    });
  });
}
