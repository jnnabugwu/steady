import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_data/health_sync_data.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:steady/main.dart';
import 'package:steady/providers.dart';
import 'package:steady/today_screen.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  // Thursday 2026-10-22 at 21:00, the artboard's evening; its week starts
  // Friday Oct 16.
  final now = DateTime(2026, 10, 22, 21);
  final today = DateTime(2026, 10, 22);

  /// What the pinned clock says; a test moves it to cross midnight.
  late DateTime clock;
  setUp(() => clock = now);

  /// The real app at `/`, with the real override list and the clock pinned.
  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    Future<void> Function(ProviderContainer)? seed,
    HealthKitRepository? health,
  }) async {
    final container = ProviderContainer(
      overrides: [
        ...appProviderOverrides,
        checkInClockProvider.overrideWithValue(() => clock),
        if (health != null)
          healthKitRepositoryProvider.overrideWithValue(health),
      ],
    );
    addTearDown(container.dispose);
    await seed?.call(container);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SteadyApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('greetingFor', () {
    test('follows the time of day', () {
      String at(int hour) => greetingFor(DateTime(2026, 10, 22, hour));
      expect(at(5), 'Good morning');
      expect(at(11), 'Good morning');
      expect(at(12), 'Good afternoon');
      expect(at(16), 'Good afternoon');
      expect(at(17), 'Good evening');
      expect(at(23), 'Good evening');
      expect(at(2), 'Good evening');
    });
  });

  testWidgets("on an iPhone the cairn shows Health's calories eaten, "
      "winning over an import's", (tester) async {
    await pumpApp(
      tester,
      seed: (container) async {
        await container
            .read(dailyMetricRepositoryProvider)
            .upsert(DateTime(2026, 10, 20), caloriesEaten: 2100);
        await container
            .read(dailyMetricRepositoryProvider)
            .upsert(DateTime(2026, 10, 21), caloriesEaten: 1900);
      },
      health: InMemoryHealthKitRepository(
        status: HealthAuthorizationStatus.requested,
        days: [
          HealthDayTotals(date: DateTime(2026, 10, 21), caloriesEaten: 1650),
        ],
      ),
    );
    final cairn = tester.widget<CairnWeek>(
      find.byKey(const Key('checkInCairn')),
    );
    // Fri Oct 16 → Thu Oct 22: the 20th imported, the 21st Health's.
    expect(cairn.days.map((d) => d.caloriesEaten), [
      null, null, null, null, 2100, 1650, null, //
    ]);
  });

  test('todayDateLine names the weekday and date', () {
    expect(todayDateLine(now), 'Thursday, Oct 22');
  });

  group('TodayScreen in the app', () {
    testWidgets('renders every section with appProviderOverrides', (
      tester,
    ) async {
      await pumpApp(
        tester,
        seed: (c) async {
          final store = c.read(dailyMetricRepositoryProvider);
          await store.upsert(
            DateTime(2026, 10, 20),
            caloriesEaten: 2100,
            loggingStatus: LoggingStatus.logged,
          );
          await store.upsert(today, caloriesEaten: 1840);
        },
      );

      expect(find.byType(TodayScreen), findsOneWidget);
      expect(find.text('Thursday, Oct 22'), findsOneWidget);
      expect(find.text('Good evening'), findsOneWidget);
      expect(find.byKey(const Key('importButton_header')), findsOneWidget);

      // Tonight's check-in, the week and today's metrics.
      expect(find.byType(CheckInCard), findsOneWidget);
      expect(find.text("TONIGHT'S CHECK-IN"), findsOneWidget);
      expect(find.byType(StatusOptionTile), findsNWidgets(3));
      expect(find.byType(CairnWeekCard), findsOneWidget);
      expect(find.text('1 of 1 day logged'), findsOneWidget);
      expect(find.byType(TodayMetricTiles), findsOneWidget);
      expect(
        tester
            .widget<MetricTile>(find.byKey(const Key('todayTile_eaten')))
            .value,
        '1,840',
      );
      // No Health in tests (the Mac's case): eaten only.
      expect(find.byKey(const Key('todayTile_steps')), findsNothing);

      // No coach nudge until the coach has something to say, and no
      // cravings entry off the iPhone.
      expect(find.text('Talk now'), findsNothing);
      expect(find.text('Continue on Mac'), findsNothing);
      expect(find.byKey(const Key('cravingEntryButton')), findsNothing);
    });

    testWidgets("logging tonight's check-in writes today and stacks it", (
      tester,
    ) async {
      final container = await pumpApp(tester);
      expect(find.text('No days checked in yet'), findsOneWidget);

      await tester.tap(find.byKey(const Key('checkInButton_partial')));
      await tester.pumpAndSettle();

      final stored = await container
          .read(dailyMetricRepositoryProvider)
          .getByDate(today);
      expect(
        (stored as Ok<DailyMetric?>).value?.loggingStatus,
        LoggingStatus.partial,
      );
      expect(find.text('Added to this week’s stack'), findsOneWidget);
      expect(find.text('1 of 1 day logged'), findsOneWidget);
    });

    testWidgets('left open across midnight, it moves to the new day', (
      tester,
    ) async {
      clock = DateTime(2026, 10, 22, 23, 30);
      await pumpApp(tester);
      expect(find.text('Thursday, Oct 22'), findsOneWidget);
      expect(tester.widget<CheckInCard>(find.byType(CheckInCard)).date, today);

      // The root's midnight timer fires 30 minutes later.
      clock = DateTime(2026, 10, 23, 0, 0, 1);
      await tester.pump(const Duration(minutes: 30));
      await tester.pumpAndSettle();

      final friday = DateTime(2026, 10, 23);
      expect(find.text('Friday, Oct 23'), findsOneWidget);
      expect(tester.widget<CheckInCard>(find.byType(CheckInCard)).date, friday);
      expect(
        tester.widget<CairnWeekCard>(find.byType(CairnWeekCard)).date,
        friday,
      );
      expect(
        tester.widget<TodayMetricTiles>(find.byType(TodayMetricTiles)).date,
        friday,
      );
      // Friday starts a new Friday-Thursday week.
      expect(find.text('No days checked in yet'), findsOneWidget);
    });

    testWidgets('returning to the foreground on a later day moves to it', (
      tester,
    ) async {
      await pumpApp(tester);

      clock = DateTime(2026, 10, 24, 8);
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('Saturday, Oct 24'), findsOneWidget);
      expect(find.text('Good morning'), findsOneWidget);
      expect(
        tester.widget<CheckInCard>(find.byType(CheckInCard)).date,
        DateTime(2026, 10, 24),
      );
    });

    testWidgets('the header import button opens the import flow', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(find.byKey(const Key('importButton_header')));
      await tester.pumpAndSettle();

      expect(find.byType(PdfImportModule), findsOneWidget);
    });
  });

  testWidgets('the coach nudge slot shows what it is given', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...appProviderOverrides,
          checkInClockProvider.overrideWithValue(() => now),
        ],
        child: ShadcnApp(
          theme: steadyTheme,
          home: TodayScreen(
            onImportRequested: () {},
            onOpenAccountSettings: () {},
            onCravingRequested: () {},
            coachNudge: const Text('coach slot', key: Key('coachSlot')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('coachSlot')), findsOneWidget);
    // Below the metrics.
    expect(
      tester.getTopLeft(find.byKey(const Key('coachSlot'))).dy,
      greaterThan(tester.getTopLeft(find.byType(TodayMetricTiles)).dy),
    );
  });
}
