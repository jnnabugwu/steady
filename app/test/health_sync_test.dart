import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_data/health_sync_data.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:pdf_import_domain/pdf_import_domain.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:steady/apple_health_card.dart';
import 'package:steady/health_sync.dart';
import 'package:steady/providers.dart';
import 'package:ui_kit/ui_kit.dart';

/// The Apple Health wiring (#75): bound on iOS only, syncing into the one
/// shared store, and the Settings card on both platforms.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 10, 23, 8, 15);
  final yesterday = DateTime(2026, 10, 22);

  group('binding', () {
    test('iOS binds the steady/healthkit channel', () {
      final container = ProviderContainer.test(
        overrides: appProviderOverridesFor(isIOS: true),
      );
      expect(
        container.read(healthKitRepositoryProvider),
        isA<MethodChannelHealthKitRepository>(),
      );
    });

    test('macOS leaves Health unbound', () {
      final container = ProviderContainer.test(
        overrides: appProviderOverridesFor(isIOS: false),
      );
      expect(container.read(healthKitRepositoryProvider), isNull);
    });

    test('appProviderOverrides follows the host platform (not iOS here)', () {
      final container = ProviderContainer.test(overrides: appProviderOverrides);
      expect(container.read(healthKitRepositoryProvider), isNull);
    });
  });

  group('HealthSyncController', () {
    late InMemoryHealthKitRepository health;
    late ProviderContainer container;

    setUp(() {
      health = InMemoryHealthKitRepository(
        days: [
          HealthDayTotals(
            date: yesterday,
            steps: 8123,
            caloriesBurnedActive: 412,
            caloriesBurnedBasal: 1650,
          ),
        ],
      );
      container = ProviderContainer.test(
        overrides: [
          // The real wiring, with Health bound to a fake (the iOS binding
          // is the channel, tested above) and the clock pinned.
          ...appProviderOverridesFor(isIOS: false),
          healthKitRepositoryProvider.overrideWithValue(health),
          healthSyncClockProvider.overrideWithValue(() => now),
        ],
      );
    });

    Future<void> sync() =>
        container.read(healthSyncControllerProvider.notifier).syncHealthData();

    Future<DailyMetric?> row(DateTime date) async =>
        ((await container.read(dailyMetricRepositoryProvider).getByDate(date))
                as Ok<DailyMetric?>)
            .value;

    test('asks for permission once, then syncs into the shared store, '
        'leaving PDF-imported calories alone', () async {
      await container.read(pdfImportRepositoryProvider).commitDailyTotals([
        ParsedDay(date: yesterday, caloriesEaten: 1850, foodEntries: const []),
      ]);

      await sync();
      await sync();

      expect(health.requestAuthorizationCalls, 1);
      expect(
        await row(yesterday),
        DailyMetric(
          date: yesterday,
          caloriesEaten: 1850,
          steps: 8123,
          caloriesBurnedActive: 412,
          caloriesBurnedBasal: 1650,
        ),
      );
      // metrics reads the same rows: the shared-store invariant.
      final range = await container
          .read(metricsRepositoryProvider)
          .getRange(yesterday, yesterday);
      expect((range as Ok<List<DailyMetric>>).value.single.steps, 8123);

      final state = container.read(healthSyncControllerProvider).value!;
      expect(state.authorization, HealthAuthorizationStatus.requested);
      // The second sync found nothing new to write.
      expect(
        state.lastSync,
        const HealthSyncReport(daysUpdated: 0, daysWithData: 1),
      );
    });

    test('an overlapping call joins the running sync', () async {
      await Future.wait([sync(), sync()]);
      expect(health.requestAuthorizationCalls, 1);
      expect(health.dailyTotalsCalls, 1);
    });

    test('never asks again once the sheet was shown', () async {
      health.status = HealthAuthorizationStatus.requested;
      await sync();
      expect(health.requestAuthorizationCalls, 0);
      expect((await row(yesterday))?.steps, 8123);
    });

    test('unavailable Health reads nothing', () async {
      health.status = HealthAuthorizationStatus.unavailable;
      await sync();
      expect(health.dailyTotalsCalls, 0);
      expect(
        container.read(healthSyncControllerProvider).value?.authorization,
        HealthAuthorizationStatus.unavailable,
      );
    });

    test(
      'a failure becomes AsyncError with the Failure, not a throw',
      () async {
        health
          ..status = HealthAuthorizationStatus.requested
          ..failure = const PlatformChannelFailure(
            'locked',
            code: 'queryFailed',
          );
        await sync();
        final state = container.read(healthSyncControllerProvider);
        expect(
          state.error,
          const PlatformChannelFailure('locked', code: 'queryFailed'),
        );
      },
    );

    test('refreshes the history when a day changed', () async {
      var builds = 0;
      container.listen(
        metricsHistoryControllerProvider,
        (_, next) => builds++,
        fireImmediately: true,
      );
      await container.read(metricsHistoryControllerProvider.future);
      final before = builds;

      await sync();
      await container.read(metricsHistoryControllerProvider.future);

      expect(builds, greaterThan(before));
    });
  });

  test('without Health bound (macOS), syncHealthData does nothing', () async {
    final container = ProviderContainer.test(
      overrides: appProviderOverridesFor(isIOS: false),
    );
    await container
        .read(healthSyncControllerProvider.notifier)
        .syncHealthData();
    final state = await container.read(healthSyncControllerProvider.future);
    expect(state.authorization, HealthAuthorizationStatus.unavailable);
    expect(state.lastSync, isNull);
  });

  group('AppleHealthCard', () {
    Future<void> pump(WidgetTester tester, List<Override> overrides) =>
        tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: const ShadcnApp(
              theme: steadyTheme,
              home: Scaffold(child: AppleHealthCard()),
            ),
          ),
        );

    String status(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const Key('appleHealthStatus'))).data!;

    testWidgets('macOS says the data comes from the iPhone', (tester) async {
      await pump(tester, appProviderOverridesFor(isIOS: false));
      await tester.pumpAndSettle();
      expect(
        status(tester),
        startsWith(
          'Steps and burned calories come from '
          'your iPhone.',
        ),
      );
      expect(find.byKey(const Key('connectAppleHealthButton')), findsNothing);
    });

    testWidgets('iOS: Connect asks, syncs and shows Connected', (tester) async {
      final health = InMemoryHealthKitRepository(
        days: [HealthDayTotals(date: yesterday, steps: 10)],
      );
      await pump(tester, [
        ...appProviderOverridesFor(isIOS: false),
        healthKitRepositoryProvider.overrideWithValue(health),
        healthSyncClockProvider.overrideWithValue(() => now),
      ]);
      await tester.pumpAndSettle();
      expect(status(tester), 'Not connected');
      expect(find.text('Connect Apple Health'), findsOneWidget);

      await tester.tap(find.byKey(const Key('connectAppleHealthButton')));
      await tester.pumpAndSettle();

      expect(health.requestAuthorizationCalls, 1);
      expect(status(tester), 'Connected');
      expect(find.text('Sync now'), findsOneWidget);
    });

    testWidgets('iOS: no data after asking reads as not allowed or empty', (
      tester,
    ) async {
      final health = InMemoryHealthKitRepository(
        status: HealthAuthorizationStatus.requested,
      );
      await pump(tester, [
        ...appProviderOverridesFor(isIOS: false),
        healthKitRepositoryProvider.overrideWithValue(health),
        healthSyncClockProvider.overrideWithValue(() => now),
      ]);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('connectAppleHealthButton')));
      await tester.pumpAndSettle();

      expect(status(tester), 'Not allowed, or no data yet');
    });
  });
}
