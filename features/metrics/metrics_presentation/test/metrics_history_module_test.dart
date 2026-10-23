import 'dart:async';

import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:metrics_presentation/src/metrics_history_module.dart'
    show formatDay, formatThousands, summaryLine;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fake_health_kit_repository.dart';
import 'helpers/fake_metrics_repository.dart';

void main() {
  late FakeMetricsRepository repository;
  late int importRequests;
  late int settingsRequests;

  setUp(() {
    repository = FakeMetricsRepository();
    importRequests = 0;
    settingsRequests = 0;
  });

  Future<void> pumpInScope(
    WidgetTester tester, {
    HealthKitRepository? health,
  }) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        metricsRepositoryProvider.overrideWithValue(repository),
        if (health != null)
          metricsHealthKitRepositoryProvider.overrideWithValue(health),
      ],
      child: ShadcnApp(
        theme: steadyTheme,
        home: MetricsHistoryModule(
          onImportRequested: () => importRequests++,
          onOpenSettings: () => settingsRequests++,
        ),
      ),
    ),
  );

  group('MetricsHistoryModule', () {
    testWidgets('shows a spinner while loading', (tester) async {
      final completer = Completer<Result<List<DailyMetric>>>();
      repository.onGetRange = (_, _) => completer.future;

      await pumpInScope(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Steady'), findsOneWidget);

      completer.complete(const Ok([]));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('the gear button calls onOpenSettings', (tester) async {
      await pumpInScope(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('openSettingsButton')));
      await tester.pump();

      expect(settingsRequests, 1);
      expect(importRequests, 0);
      expect(find.bySemanticsLabel('Settings'), findsOneWidget);
    });

    testWidgets('empty state offers the import button', (tester) async {
      await pumpInScope(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('No days yet — import a Cal AI PDF to get started'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('importButton_empty')));
      await tester.pump();
      expect(importRequests, 1);
    });

    testWidgets('renders one row per day, newest first, with a summary', (
      tester,
    ) async {
      repository.onGetRange = (_, _) => Ok([
        DailyMetric(date: DateTime(2026, 8, 14), caloriesEaten: 2000),
        DailyMetric(date: DateTime(2026, 8, 15), caloriesEaten: 1330),
        DailyMetric(date: DateTime(2026, 8, 13)),
      ]);

      await pumpInScope(tester);
      await tester.pumpAndSettle();

      expect(find.text('3 days · avg 1,665 kcal eaten'), findsOneWidget);
      expect(find.text('Sat, Aug 15 2026'), findsOneWidget);
      expect(find.text('1,330 kcal eaten'), findsOneWidget);
      expect(find.text('Fri, Aug 14 2026'), findsOneWidget);
      expect(find.text('2,000 kcal eaten'), findsOneWidget);
      expect(find.text('Thu, Aug 13 2026'), findsOneWidget);
      expect(find.text('No calories logged'), findsOneWidget);

      final sat = tester.getTopLeft(find.text('Sat, Aug 15 2026')).dy;
      final fri = tester.getTopLeft(find.text('Fri, Aug 14 2026')).dy;
      final thu = tester.getTopLeft(find.text('Thu, Aug 13 2026')).dy;
      expect(sat, lessThan(fri));
      expect(fri, lessThan(thu));
    });

    group('live Apple Health', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      final twoDaysAgo = DateTime(today.year, today.month, today.day - 2);

      testWidgets('merges live steps and burned into the stored days, and '
          'shows a Health-only day', (tester) async {
        repository.onGetRange = (_, _) => Ok([
          DailyMetric(date: yesterday, caloriesEaten: 1800),
          DailyMetric(date: twoDaysAgo, caloriesEaten: 2000),
        ]);
        final health = FakeHealthKitRepository(
          days: [
            HealthDayTotals(
              date: today,
              steps: 4000,
              caloriesBurnedBasal: 1600,
            ),
            HealthDayTotals(
              date: yesterday,
              steps: 9500,
              caloriesBurnedActive: 400,
              caloriesBurnedBasal: 1700,
            ),
          ],
        );

        await pumpInScope(tester, health: health);
        await tester.pumpAndSettle();

        // Today has Health data but no stored row, and still shows.
        expect(
          find.text(
            '3 days · avg 1,900 kcal eaten · '
            'last 30 days: avg 1,850 burned · 6,750 steps',
          ),
          findsOneWidget,
        );
        expect(find.text('2,100 kcal burned'), findsOneWidget);
        expect(find.text('9,500 steps'), findsOneWidget);
        expect(find.text('1,600 kcal burned'), findsOneWidget);
        expect(find.text('4,000 steps'), findsOneWidget);
        expect(find.text(formatDay(today)), findsOneWidget);
        // The window is the last healthHistoryDays days, ending today.
        final window = healthHistoryWindow(now);
        expect(health.dailyTotalsCalls, [(window.start, window.end)]);
      });

      testWidgets('a Health-only history is not the empty state', (
        tester,
      ) async {
        await pumpInScope(
          tester,
          health: FakeHealthKitRepository(
            days: [HealthDayTotals(date: today, steps: 42)],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('No days yet'), findsNothing);
        expect(find.text('1 day · last 30 days: avg 42 steps'), findsOneWidget);
      });

      testWidgets('ignores Health fields an older build stored in the row', (
        tester,
      ) async {
        repository.onGetRange = (_, _) => Ok([
          DailyMetric(
            date: yesterday,
            caloriesEaten: 1800,
            steps: 1111,
            caloriesBurnedBasal: 2222,
          ),
        ]);

        await pumpInScope(tester);
        await tester.pumpAndSettle();

        expect(find.text('1 day · avg 1,800 kcal eaten'), findsOneWidget);
        expect(find.textContaining('steps'), findsNothing);
        expect(find.textContaining('burned'), findsNothing);
      });

      testWidgets('a Health failure leaves the stored days showing', (
        tester,
      ) async {
        repository.onGetRange = (_, _) =>
            Ok([DailyMetric(date: yesterday, caloriesEaten: 1800)]);
        final health = FakeHealthKitRepository()
          ..failure = const PlatformChannelFailure('locked');

        await pumpInScope(tester, health: health);
        await tester.pumpAndSettle();

        expect(find.text('1 day · avg 1,800 kcal eaten'), findsOneWidget);
        expect(find.textContaining('Something went wrong'), findsNothing);
      });
    });

    testWidgets('the header import button calls onImportRequested', (
      tester,
    ) async {
      repository.onGetRange = (_, _) =>
          Ok([DailyMetric(date: DateTime(2026, 8, 15), caloriesEaten: 1330)]);

      await pumpInScope(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('importButton_header')));
      await tester.pump();

      expect(importRequests, 1);
    });

    testWidgets('renders the Failure and retries on tap', (tester) async {
      repository.onGetRange = (_, _) =>
          const Err(PlatformChannelFailure('channel down'));

      await pumpInScope(tester);
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong: channel down'), findsOneWidget);

      repository.onGetRange = (_, _) =>
          Ok([DailyMetric(date: DateTime(2026, 8, 15), caloriesEaten: 1330)]);
      await tester.tap(find.byKey(const Key('retryButton')));
      await tester.pumpAndSettle();

      expect(repository.getRangeCalls, hasLength(2));
      expect(find.text('Sat, Aug 15 2026'), findsOneWidget);
    });
  });

  group('formatting', () {
    test('formatDay', () {
      expect(formatDay(DateTime(2026, 8, 15)), 'Sat, Aug 15 2026');
      expect(formatDay(DateTime(2026, 1, 5)), 'Mon, Jan 5 2026');
    });

    test('formatThousands', () {
      expect(formatThousands(0), '0');
      expect(formatThousands(999), '999');
      expect(formatThousands(1330), '1,330');
      expect(formatThousands(1234567), '1,234,567');
      expect(formatThousands(-4200), '-4,200');
    });

    test('summaryLine averages only days with caloriesEaten', () {
      expect(summaryLine([DailyMetric(date: DateTime(2026, 8, 15))]), '1 day');
      expect(
        summaryLine([
          DailyMetric(date: DateTime(2026, 8, 15), caloriesEaten: 1000),
          DailyMetric(date: DateTime(2026, 8, 14)),
        ]),
        '2 days · avg 1,000 kcal eaten',
      );
    });

    test('summaryLine adds burned and steps when Health data is there', () {
      expect(
        summaryLine([
          DailyMetric(
            date: DateTime(2026, 8, 15),
            caloriesEaten: 2000,
            caloriesBurnedActive: 500,
            caloriesBurnedBasal: 1700,
            steps: 9000,
          ),
          DailyMetric(
            date: DateTime(2026, 8, 14),
            caloriesEaten: 1800,
            caloriesBurnedActive: 300,
            caloriesBurnedBasal: 1700,
            steps: 5000,
          ),
          // Eaten only: doesn't drag the burned or steps averages down.
          DailyMetric(date: DateTime(2026, 8, 13), caloriesEaten: 1900),
        ]),
        '3 days · avg 1,900 kcal eaten · '
        'last 30 days: avg 2,100 burned · 7,000 steps',
      );
      expect(
        summaryLine([
          DailyMetric(
            date: DateTime(2026, 8, 15),
            caloriesBurnedBasal: 1700,
            steps: 1234,
          ),
        ]),
        '1 day · last 30 days: avg 1,700 kcal burned · 1,234 steps',
      );
      expect(
        summaryLine([DailyMetric(date: DateTime(2026, 8, 15), steps: 42)]),
        '1 day · last 30 days: avg 42 steps',
      );
    });
  });
}
