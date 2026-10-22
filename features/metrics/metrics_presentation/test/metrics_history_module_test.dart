import 'dart:async';

import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:metrics_presentation/src/metrics_history_module.dart'
    show formatDay, formatThousands, summaryLine;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fake_metrics_repository.dart';

void main() {
  late FakeMetricsRepository repository;
  late int importRequests;

  setUp(() {
    repository = FakeMetricsRepository();
    importRequests = 0;
  });

  Future<void> pumpInScope(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      overrides: [metricsRepositoryProvider.overrideWithValue(repository)],
      child: ShadcnApp(
        theme: steadyTheme,
        home: MetricsHistoryModule(onImportRequested: () => importRequests++),
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
        DailyMetric(
          date: DateTime(2026, 8, 15),
          caloriesEaten: 1330,
          caloriesBurnedActive: 400,
          caloriesBurnedBasal: 1700,
          steps: 9500,
        ),
        DailyMetric(date: DateTime(2026, 8, 13)),
      ]);

      await pumpInScope(tester);
      await tester.pumpAndSettle();

      expect(find.text('3 days · avg 1,665 kcal eaten'), findsOneWidget);
      expect(find.text('Sat, Aug 15 2026'), findsOneWidget);
      expect(find.text('1,330 kcal eaten'), findsOneWidget);
      expect(find.text('2,100 kcal burned'), findsOneWidget);
      expect(find.text('9,500 steps'), findsOneWidget);
      expect(find.text('Fri, Aug 14 2026'), findsOneWidget);
      expect(find.text('2,000 kcal eaten'), findsOneWidget);
      expect(find.text('Thu, Aug 13 2026'), findsOneWidget);
      // Burned and steps only render where the day has them.
      expect(find.textContaining('kcal burned'), findsOneWidget);
      expect(find.textContaining('steps'), findsOneWidget);

      final sat = tester.getTopLeft(find.text('Sat, Aug 15 2026')).dy;
      final fri = tester.getTopLeft(find.text('Fri, Aug 14 2026')).dy;
      final thu = tester.getTopLeft(find.text('Thu, Aug 13 2026')).dy;
      expect(sat, lessThan(fri));
      expect(fri, lessThan(thu));
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
  });
}
