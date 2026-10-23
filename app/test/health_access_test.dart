import 'dart:async';

import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_data/health_sync_data.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:steady/apple_health_card.dart';
import 'package:steady/health_access.dart';
import 'package:steady/main.dart';
import 'package:steady/providers.dart';
import 'package:ui_kit/ui_kit.dart';

/// The Apple Health wiring (#75): bound on iOS only, read live and **never
/// written** to the shared, iCloud-synced store (App Store 5.1.3(ii)), and
/// the Settings card on both platforms.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  final window = healthHistoryWindow(now);

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

  group('HealthAccessController', () {
    late InMemoryHealthKitRepository health;
    late ProviderContainer container;

    setUp(() {
      health = InMemoryHealthKitRepository(
        days: [HealthDayTotals(date: yesterday, steps: 8123)],
      );
      container = ProviderContainer.test(
        overrides: [
          // The real wiring, with Health bound to a fake (the iOS binding
          // is the channel, tested above).
          ...appProviderOverridesFor(isIOS: false),
          healthKitRepositoryProvider.overrideWithValue(health),
        ],
      );
    });

    Future<void> refresh() => container
        .read(healthAccessControllerProvider.notifier)
        .refreshHealthData();

    test('asks for permission once', () async {
      await refresh();
      await refresh();

      expect(health.requestAuthorizationCalls, 1);
      expect(
        container.read(healthAccessControllerProvider).value,
        HealthAuthorizationStatus.requested,
      );
    });

    test('an overlapping call joins the running one', () async {
      await Future.wait([refresh(), refresh()]);
      expect(health.requestAuthorizationCalls, 1);
    });

    test('never asks again once the sheet was shown', () async {
      health.status = HealthAuthorizationStatus.requested;
      await refresh();
      expect(health.requestAuthorizationCalls, 0);
    });

    test('a refresh makes the live Health read read Health again', () async {
      health.status = HealthAuthorizationStatus.requested;
      final totals = healthDayTotalsProvider(window.start, window.end);
      container.listen(totals, (_, _) {});
      expect((await container.read(totals.future))[yesterday]?.steps, 8123);
      final before = health.dailyTotalsCalls;

      health.days[yesterday] = HealthDayTotals(date: yesterday, steps: 9000);
      await refresh();

      expect((await container.read(totals.future))[yesterday]?.steps, 9000);
      expect(health.dailyTotalsCalls, before + 1);
    });

    test('unavailable Health reads nothing', () async {
      health.status = HealthAuthorizationStatus.unavailable;
      // A screen showing Health is listening, so a read would happen if the
      // refresh invalidated it.
      final totals = healthDayTotalsProvider(window.start, window.end);
      container.listen(totals, (_, _) {});
      await container.read(totals.future);
      final before = health.dailyTotalsCalls;

      await refresh();
      await container.read(totals.future);

      expect(health.dailyTotalsCalls, before);
      expect(
        container.read(healthAccessControllerProvider).value,
        HealthAuthorizationStatus.unavailable,
      );
    });

    test(
      'a failure becomes AsyncError with the Failure, not a throw',
      () async {
        health.failure = const PlatformChannelFailure(
          'locked',
          code: 'queryFailed',
        );
        await refresh();
        expect(
          container.read(healthAccessControllerProvider).error,
          const PlatformChannelFailure('locked', code: 'queryFailed'),
        );
      },
    );
  });

  test(
    'without Health bound (macOS), refreshHealthData does nothing',
    () async {
      final container = ProviderContainer.test(
        overrides: appProviderOverridesFor(isIOS: false),
      );
      await container
          .read(healthAccessControllerProvider.notifier)
          .refreshHealthData();
      expect(
        await container.read(healthAccessControllerProvider.future),
        HealthAuthorizationStatus.unavailable,
      );
      expect(
        await container.read(
          healthDayTotalsProvider(window.start, window.end).future,
        ),
        isEmpty,
      );
    },
  );

  group('no Health code path writes the shared store (5.1.3(ii))', () {
    late _WriteForbiddenDailyMetricRepository store;
    late InMemoryHealthKitRepository health;

    setUp(() async {
      // A PDF-imported day, written before the spy starts watching.
      final inner = InMemoryDailyMetricRepository();
      await inner.upsert(yesterday, caloriesEaten: 1850);
      store = _WriteForbiddenDailyMetricRepository(inner);
      health = InMemoryHealthKitRepository(
        days: [
          HealthDayTotals(
            date: yesterday,
            steps: 8123,
            caloriesBurnedActive: 412,
            caloriesBurnedBasal: 1650,
          ),
          // A day with steps but no PDF import.
          HealthDayTotals(date: today, steps: 4000),
        ],
      );
    });

    List<Override> overrides() => [
      ...appProviderOverridesFor(isIOS: false),
      healthKitRepositoryProvider.overrideWithValue(health),
      dailyMetricRepositoryProvider.overrideWithValue(store),
    ];

    testWidgets('launch, resume and Settings "Refresh" show live Health in '
        'the history and write nothing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(overrides: overrides(), child: const SteadyApp()),
      );
      await tester.pumpAndSettle();

      // Launch: asked once, and the history merges the live values in.
      expect(health.requestAuthorizationCalls, 1);
      expect(find.text('1,850 kcal eaten'), findsOneWidget);
      expect(find.text('2,062 kcal burned'), findsOneWidget);
      expect(find.text('8,123 steps'), findsOneWidget);
      expect(find.text('4,000 steps'), findsOneWidget);
      expect(
        find.text(
          '2 days · avg 1,850 kcal eaten · '
          'last 30 days: avg 2,062 burned · 6,062 steps',
        ),
        findsOneWidget,
      );

      // Resume: today's steps are read again.
      health.days[today] = HealthDayTotals(date: today, steps: 5000);
      final beforeResume = health.dailyTotalsCalls;
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(health.dailyTotalsCalls, greaterThan(beforeResume));
      expect(find.text('5,000 steps'), findsOneWidget);

      // Settings: "Refresh" reads Health again.
      await tester.tap(find.byKey(const Key('openSettingsButton')));
      await tester.pumpAndSettle();
      expect(find.text('Refresh'), findsOneWidget);
      final beforeRefresh = health.dailyTotalsCalls;
      await tester.tap(find.byKey(const Key('connectAppleHealthButton')));
      await tester.pumpAndSettle();
      expect(health.dailyTotalsCalls, greaterThan(beforeRefresh));
      expect(
        tester.widget<Text>(find.byKey(const Key('appleHealthStatus'))).data,
        'Connected',
      );

      expect(store.writes, isEmpty);
      // The stored row is still only what the PDF import wrote.
      final row = await store.getByDate(yesterday);
      expect(
        (row as Ok<DailyMetric?>).value,
        DailyMetric(date: yesterday, caloriesEaten: 1850),
      );
    });

    test('every Health provider and the controller write nothing', () async {
      final container = ProviderContainer.test(overrides: overrides());
      final notifier = container.read(healthAccessControllerProvider.notifier);
      final totals = healthDayTotalsProvider(window.start, window.end);
      container
        ..listen(totals, (_, _) {})
        ..listen(metricsHistoryControllerProvider, (_, _) {});

      await notifier.refreshHealthData(); // launch (asks)
      await container.read(totals.future);
      await container.read(metricsHistoryControllerProvider.future);
      await notifier.refreshHealthData(); // resume
      await notifier.refreshHealthData(); // "Refresh"
      await container.read(totals.future);

      expect(store.writes, isEmpty);
    });

    test('the launch cleanup only removes Health fields an older build '
        'stored; Health paths still write nothing', () async {
      // A row as an older build left it: Health values next to PDF data.
      await store._inner.upsert(
        yesterday,
        steps: 1111,
        caloriesBurnedBasal: 2222,
      );
      store.allowLegacyHealthClears = true;
      final cleared = await clearLegacyHealthFields(store);
      store.allowLegacyHealthClears = false;

      expect((cleared as Ok<int>).value, 1);
      expect(store.legacyHealthClears, {
        yesterday: {
          DailyMetricField.steps,
          DailyMetricField.caloriesBurnedBasal,
        },
      });
      expect(
        ((await store.getByDate(yesterday)) as Ok<DailyMetric?>).value,
        DailyMetric(date: yesterday, caloriesEaten: 1850),
      );

      final container = ProviderContainer.test(overrides: overrides());
      final notifier = container.read(healthAccessControllerProvider.notifier);
      final totals = healthDayTotalsProvider(window.start, window.end);
      container.listen(totals, (_, _) {});
      await notifier.refreshHealthData();
      await container.read(totals.future);
      expect(store.writes, isEmpty);
    });
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
        'Steps and burned calories come from Apple Health on your iPhone '
        "and stay there; they don't sync to this Mac.",
      );
      expect(find.byKey(const Key('connectAppleHealthButton')), findsNothing);
    });

    testWidgets('iOS: Connect asks, reads and shows Connected', (tester) async {
      final health = InMemoryHealthKitRepository(
        days: [HealthDayTotals(date: yesterday, steps: 10)],
      );
      await pump(tester, [
        ...appProviderOverridesFor(isIOS: false),
        healthKitRepositoryProvider.overrideWithValue(health),
      ]);
      await tester.pumpAndSettle();
      expect(status(tester), 'Not connected');
      expect(find.text('Connect Apple Health'), findsOneWidget);

      await tester.tap(find.byKey(const Key('connectAppleHealthButton')));
      await tester.pumpAndSettle();

      expect(health.requestAuthorizationCalls, 1);
      expect(status(tester), 'Connected');
      expect(find.text('Refresh'), findsOneWidget);
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
      ]);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('connectAppleHealthButton')));
      await tester.pumpAndSettle();

      expect(status(tester), 'Not allowed, or no data yet');
    });

    testWidgets('iOS: still reading Health says checking, not Connected', (
      tester,
    ) async {
      final health = _HangingHealthKitRepository();
      await pump(tester, [
        ...appProviderOverridesFor(isIOS: false),
        healthKitRepositoryProvider.overrideWithValue(health),
      ]);
      await tester.pump();
      await tester.pump();

      expect(health.dailyTotalsCalls, 1);
      expect(status(tester), 'Checking Apple Health…');

      health.reply.complete(const Ok([]));
      await tester.pumpAndSettle();
    });

    testWidgets('iOS: a failed read shows fixed copy, not the Failure', (
      tester,
    ) async {
      final health = InMemoryHealthKitRepository(
        status: HealthAuthorizationStatus.requested,
      )..failure = const PlatformChannelFailure('raw native detail');
      await pump(tester, [
        ...appProviderOverridesFor(isIOS: false),
        healthKitRepositoryProvider.overrideWithValue(health),
      ]);
      await tester.pumpAndSettle();

      expect(
        status(tester),
        "Couldn't read Apple Health right now. Try Refresh.",
      );
      expect(find.textContaining('raw native detail'), findsNothing);
      expect(find.text('Connect Apple Health'), findsOneWidget);
    });
  });
}

/// Health that has been asked, whose `dailyTotals` waits on [reply].
class _HangingHealthKitRepository extends InMemoryHealthKitRepository {
  _HangingHealthKitRepository()
    : super(status: HealthAuthorizationStatus.requested);

  final Completer<Result<List<HealthDayTotals>>> reply = Completer();

  @override
  ResultFuture<List<HealthDayTotals>> dailyTotals(
    DateTime start,
    DateTime end,
  ) {
    dailyTotalsCalls++;
    return reply.future;
  }
}

/// The shared store, wrapped so every write is recorded and fails the test:
/// reads go to [_inner], and no Health path may call a write at all.
///
/// The one exception is the launch cleanup (`clearLegacyHealthFields`),
/// which removes Health values an older build stored: while
/// [allowLegacyHealthClears] is set, a `clearFields` of Health fields only
/// is recorded in [legacyHealthClears] and forwarded. Any other write still
/// fails, and the flag is off for every Health path under test.
class _WriteForbiddenDailyMetricRepository implements DailyMetricRepository {
  _WriteForbiddenDailyMetricRepository(this._inner);

  final DailyMetricRepository _inner;

  /// Every write attempted, by method name.
  final List<String> writes = [];

  /// Whether the launch cleanup's `clearFields` of Health fields may pass.
  bool allowLegacyHealthClears = false;

  /// The launch cleanup's clears, by day.
  final Map<DateTime, Set<DailyMetricField>> legacyHealthClears = {};

  Never _write(String method) {
    writes.add(method);
    fail('Health must never write the shared store, but called $method');
  }

  @override
  ResultFuture<DailyMetric?> getByDate(DateTime date) => _inner.getByDate(date);

  @override
  ResultFuture<List<DailyMetric>> getRange(DateTime start, DateTime end) =>
      _inner.getRange(start, end);

  @override
  ResultFuture<DailyMetric> upsert(
    DateTime date, {
    int? caloriesEaten,
    int? caloriesBurnedActive,
    int? caloriesBurnedBasal,
    int? steps,
    LoggingStatus? loggingStatus,
  }) => _write('upsert');

  @override
  ResultFuture<Unit> clearFields(DateTime date, Set<DailyMetricField> fields) {
    if (allowLegacyHealthClears && legacyHealthFields.containsAll(fields)) {
      legacyHealthClears[date] = fields;
      return _inner.clearFields(date, fields);
    }
    return _write('clearFields');
  }

  @override
  ResultFuture<Unit> delete(DateTime date) => _write('delete');
}
