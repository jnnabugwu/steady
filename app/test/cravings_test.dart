import 'dart:io';

import 'package:cravings_data/cravings_data.dart';
import 'package:cravings_domain/cravings_domain.dart';
import 'package:cravings_presentation/cravings_presentation.dart';
import 'package:data_export_presentation/data_export_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_data/health_sync_data.dart';
import 'package:steady/app_router.dart';
import 'package:steady/main.dart';
import 'package:steady/providers.dart';
import 'package:steady/today_screen.dart';

/// Craving support (#109) in the real app on the real override list:
/// iPhone only (by the injected platform), device-only storage, the
/// `/craving` route, the home entry point and weekly line, and the
/// Settings card.
void main() {
  final entryButton = find.byKey(const Key('cravingEntryButton'));
  final weekLine = find.byKey(const Key('cravingWeekLine'));
  final settingsCard = find.byKey(const Key('cravingSettingsCard'));
  // Pinned so the weekly line is predictable: an evening.
  final now = DateTime(2026, 10, 23, 20);

  group('binding', () {
    test('iOS offers craving support, stored in the device-only file', () {
      final ios = ProviderContainer.test(
        overrides: appProviderOverridesFor(isIOS: true),
      );
      expect(ios.read(cravingSupportAvailableProvider), isTrue);
      expect(ios.read(cravingRepositoryProvider), isA<FileCravingRepository>());
    });

    test('macOS offers nothing and leaves the repository unbound', () {
      final mac = ProviderContainer.test(
        overrides: appProviderOverridesFor(isIOS: false),
      );
      expect(mac.read(cravingSupportAvailableProvider), isFalse);
      expect(
        () => mac.read(cravingRepositoryProvider),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.exception,
            'exception',
            isA<UnimplementedError>(),
          ),
        ),
      );
    });

    test('the iOS file store keeps check-ins across a restart', () async {
      final dir = Directory.systemTemp.createTempSync('steady_cravings');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/cravings.json');
      // The iOS binding, pointed at a temp file instead of the app
      // support directory (no path_provider plugin in a unit test).
      ProviderContainer launch() => ProviderContainer.test(
        overrides: [
          ...appProviderOverridesFor(isIOS: false),
          cravingSupportAvailableProvider.overrideWithValue(true),
          cravingRepositoryProvider.overrideWith(
            (ref) => FileCravingRepository(file),
          ),
        ],
      );

      final event = CravingEvent(
        id: 'a',
        startedAt: now,
        intensityBefore: 3,
        reasons: const {CravingReason.bored},
        tookMinute: true,
        outcome: CravingOutcome.notSure,
      );
      expect(
        await launch().read(cravingRepositoryProvider).save(event),
        isA<Ok<Unit>>(),
      );
      final result = await launch()
          .read(cravingRepositoryProvider)
          .getBetween(DateTime(2026), DateTime(2027));
      expect((result as Ok<List<CravingEvent>>).value, [event]);
    });
  });

  group('in the app', () {
    late _MemoryCravingRepository cravings;

    setUp(() => cravings = _MemoryCravingRepository());

    /// Pumps the real app. [isIOS] is the injected platform.
    ///
    /// With [withStore] (iOS only), the craving repository is the in-memory
    /// [cravings] instead of the file store, which needs `path_provider`.
    /// Overrides can't be stacked on `appProviderOverridesFor(isIOS: true)`
    /// (Riverpod rejects overriding a provider twice), so that case builds
    /// on the macOS list and adds exactly what iOS binds for cravings; the
    /// `binding` tests above check that's the same.
    Future<ProviderContainer> pumpApp(
      WidgetTester tester, {
      required bool isIOS,
      String? coldStartLocation,
      bool withStore = false,
    }) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      if (coldStartLocation != null) {
        tester.platformDispatcher.defaultRouteNameTestValue = coldStartLocation;
        addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
      }
      final container = ProviderContainer(
        overrides: [
          if (isIOS && withStore) ...[
            ...appProviderOverridesFor(isIOS: false),
            healthKitRepositoryProvider.overrideWithValue(
              InMemoryHealthKitRepository(),
            ),
            cravingSupportAvailableProvider.overrideWithValue(true),
            cravingRepositoryProvider.overrideWithValue(cravings),
          ] else
            ...appProviderOverridesFor(isIOS: isIOS),
          cravingClockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SteadyApp(),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('iOS: home shows "Having a craving?"', (tester) async {
      await pumpApp(tester, isIOS: true);
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(entryButton, findsOneWidget);
      expect(find.text('Having a craving?'), findsOneWidget);
      expect(weekLine, findsNothing);
    });

    testWidgets('macOS: no entry point on home', (tester) async {
      await pumpApp(tester, isIOS: false);
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(entryButton, findsNothing);
    });

    testWidgets('the entry point opens /craving; finishing returns home with '
        'the weekly line', (tester) async {
      final container = await pumpApp(tester, isIOS: true, withStore: true);

      await tester.tap(entryButton);
      await tester.pumpAndSettle();
      expect(find.byType(CravingFlowModule), findsOneWidget);
      expect(container.read(routerProvider).state.matchedLocation, '/craving');

      await tester.tap(find.byKey(const Key('cravingIntensityBefore_4')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('cravingReasonsNext')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('cravingNotNow')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('cravingOutcome_havingIt')));
      await tester.pumpAndSettle();
      expect(
        find.text("That's okay. Log it in Cal AI when you're ready."),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('cravingDone')));
      await tester.pumpAndSettle();

      expect(find.byType(CravingFlowModule), findsNothing);
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(find.text('1 craving this week, in the evening'), findsOneWidget);
      expect(cravings.events.single.outcome, CravingOutcome.havingIt);
    });

    testWidgets('closing the flow returns home and records nothing', (
      tester,
    ) async {
      await pumpApp(tester, isIOS: true, withStore: true);
      await tester.tap(entryButton);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cravingCloseButton')));
      await tester.pumpAndSettle();

      expect(find.byType(TodayScreen), findsOneWidget);
      expect(cravings.events, isEmpty);
      expect(weekLine, findsNothing);
    });

    test('CravingRoute.location is /craving', () {
      expect(const CravingRoute().location, '/craving');
    });

    testWidgets('iOS: a cold start at /craving opens the flow, with home '
        'beneath it', (tester) async {
      await pumpApp(tester, isIOS: true, coldStartLocation: '/craving');
      expect(find.byType(CravingFlowModule), findsOneWidget);

      await tester.tap(find.byKey(const Key('cravingCloseButton')));
      await tester.pumpAndSettle();
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('macOS: /craving redirects home', (tester) async {
      final container = await pumpApp(
        tester,
        isIOS: false,
        coldStartLocation: '/craving',
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(CravingFlowModule), findsNothing);
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(container.read(routerProvider).state.matchedLocation, '/');
    });

    testWidgets('iOS: Settings has the Cravings card, and deleting clears '
        "home's weekly line", (tester) async {
      cravings.events.add(
        CravingEvent(
          id: 'a',
          startedAt: now.subtract(const Duration(hours: 1)),
          intensityBefore: 3,
          reasons: const {},
          tookMinute: false,
          outcome: CravingOutcome.passed,
        ),
      );
      // Cold start at /settings: at phone width the test font's wide
      // glyphs push the home header's gear past the screen edge, so it
      // can't be tapped here.
      await pumpApp(
        tester,
        isIOS: true,
        withStore: true,
        coldStartLocation: '/settings',
      );
      expect(find.byType(DataExportModule), findsOneWidget);
      expect(settingsCard, findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('cravingDeleteHistoryButton')),
      );
      await tester.tap(find.byKey(const Key('cravingDeleteHistoryButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cravingDeleteConfirm')));
      await tester.pumpAndSettle();
      expect(cravings.events, isEmpty);
      expect(find.text('Craving history deleted.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('settingsBackButton')));
      await tester.pumpAndSettle();
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(weekLine, findsNothing);
    });

    testWidgets('macOS: Settings has no Cravings card', (tester) async {
      await pumpApp(tester, isIOS: false, coldStartLocation: '/settings');
      expect(find.byType(DataExportModule), findsOneWidget);
      expect(settingsCard, findsNothing);
    });
  });
}

/// An in-memory [CravingRepository] for widget tests (the file store's own
/// tests live in `cravings_data`; real file I/O doesn't run under a widget
/// test's fake clock).
class _MemoryCravingRepository implements CravingRepository {
  final List<CravingEvent> events = [];

  @override
  ResultFuture<Unit> save(CravingEvent event) async {
    events
      ..removeWhere((e) => e.id == event.id)
      ..add(event);
    return const Ok(unit);
  }

  @override
  ResultFuture<List<CravingEvent>> getBetween(
    DateTime start,
    DateTime end,
  ) async => Ok([
    for (final e in events)
      if (!e.startedAt.isBefore(start) && e.startedAt.isBefore(end)) e,
  ]);

  @override
  ResultFuture<Unit> deleteAll() async {
    events.clear();
    return const Ok(unit);
  }
}
