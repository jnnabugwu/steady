import 'dart:async';

import 'package:checkin_domain/checkin_domain.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart'
    show CircularProgressIndicator, Key;
import 'package:steady/main.dart';
import 'package:steady/providers.dart';
import 'package:steady/remote_changes.dart';
import 'package:ui_kit/ui_kit.dart' show MetricTile;

/// #73: a remote-change event (CloudKit importing another device's rows)
/// makes every screen that shows daily metrics re-read the store.
///
/// The store is the in-memory one from [appProviderOverrides]; a row
/// written straight to it, with no screen involved, stands in for an
/// import, and a [StreamController] stands in for the plugin's events.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  late StreamController<void> changes;

  setUp(() => changes = StreamController<void>.broadcast());
  tearDown(() => changes.close());

  List<Override> overrides() => [
    ...appProviderOverrides,
    dailyMetricsRemoteChangeSourceProvider.overrideWithValue(
      () => changes.stream,
    ),
  ];

  /// Writes [caloriesEaten] for today as if another device had synced it.
  Future<void> importRow(ProviderContainer container, int caloriesEaten) =>
      container
          .read(dailyMetricRepositoryProvider)
          .upsert(today, caloriesEaten: caloriesEaten);

  group('the history screen', () {
    // The history is the Week tab (`/week`); Today is checked below.
    Future<ProviderContainer> pumpApp(WidgetTester tester) async {
      tester.platformDispatcher.defaultRouteNameTestValue = '/week';
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
      await tester.pumpWidget(
        ProviderScope(overrides: overrides(), child: const SteadyApp()),
      );
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(tester.element(find.byType(SteadyApp)));
    }

    testWidgets('shows a synced-in row once a change event arrives', (
      tester,
    ) async {
      final container = await pumpApp(tester);
      expect(find.textContaining('No days yet'), findsOneWidget);

      await importRow(container, 1850);
      await tester.pumpAndSettle();
      // Nothing told it to re-read yet: the bug in #73.
      expect(find.textContaining('No days yet'), findsOneWidget);

      changes.add(null);
      await tester.pumpAndSettle();

      expect(find.textContaining('No days yet'), findsNothing);
      expect(find.text('1,850 kcal eaten'), findsOneWidget);
      expect(container.read(dailyMetricsRemoteRefreshProvider), 1);
    });

    testWidgets('keeps showing its rows while it re-reads (no spinner)', (
      tester,
    ) async {
      final container = await pumpApp(tester);
      await importRow(container, 1850);
      changes.add(null);
      await tester.pumpAndSettle();

      await importRow(container, 2100);
      changes.add(null);
      await tester.pump();

      expect(container.read(metricsHistoryControllerProvider).isLoading, true);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('1,850 kcal eaten'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('2,100 kcal eaten'), findsOneWidget);
    });
  });

  testWidgets("Today's metric tiles show a synced-in row", (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: overrides(), child: const SteadyApp()),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SteadyApp)),
    );
    expect(find.byKey(const Key('todayTile_eaten')), findsNothing);

    await importRow(container, 1850);
    changes.add(null);
    await tester.pumpAndSettle();

    expect(
      tester.widget<MetricTile>(find.byKey(const Key('todayTile_eaten'))).value,
      '1,850',
    );
  });

  group('the check-in and week card controllers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer.test(overrides: overrides())
        ..read(dailyMetricsRemoteRefreshProvider);
    });

    Future<void> deliver() async {
      changes.add(null);
      await Future<void>.delayed(Duration.zero);
    }

    test('every check-in day re-reads its status', () async {
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      final todayProvider = checkInControllerProvider(today);
      final yesterdayProvider = checkInControllerProvider(yesterday);
      container
        ..listen(todayProvider, (_, _) {})
        ..listen(yesterdayProvider, (_, _) {});
      expect(await container.read(todayProvider.future), isNull);
      expect(await container.read(yesterdayProvider.future), isNull);

      final repo = container.read(dailyMetricRepositoryProvider);
      await repo.upsert(today, loggingStatus: LoggingStatus.logged);
      await repo.upsert(yesterday, loggingStatus: LoggingStatus.skipped);
      await deliver();

      expect(await container.read(todayProvider.future), CheckInStatus.logged);
      expect(
        await container.read(yesterdayProvider.future),
        CheckInStatus.skipped,
      );
    });

    test('the week card re-reads its week', () async {
      final provider = weekCardControllerProvider(weekCardStart(today));
      container.listen(provider, (_, _) {});
      final before = await container.read(provider.future);
      expect(before.days.every((d) => d.caloriesEaten == null), true);

      await importRow(container, 1850);
      await deliver();

      final after = await container.read(provider.future);
      expect(
        after.days.singleWhere((d) => d.date == today).caloriesEaten,
        1850,
      );
    });

    test("Today's metric tiles re-read their week", () async {
      final provider = todayMetricsProvider(today);
      container.listen(provider, (_, _) {});
      expect(await container.read(provider.future), isEmpty);

      await importRow(container, 1850);
      await deliver();

      final after = await container.read(provider.future);
      expect(after.single.caloriesEaten, 1850);
    });

    test('the in-memory store has no change source of its own', () async {
      final plain = ProviderContainer.test(overrides: appProviderOverrides);
      final events = <void>[];
      final done = Completer<void>();
      plain
          .read(dailyMetricsRemoteChangeSourceProvider)()
          .listen(events.add, onDone: done.complete);

      await done.future;
      expect(events, isEmpty);
    });
  });
}
