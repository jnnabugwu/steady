import 'dart:async';

import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:data_export_presentation/data_export_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:steady/app_router.dart';
import 'package:steady/app_shell.dart';
import 'package:steady/main.dart';
import 'package:steady/providers.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  /// Pumps the real app, with the real override list. If
  /// [coldStartLocation] is given, it is the platform's initial route, which
  /// is how the OS hands a deep link to a cold-started app.
  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    String? coldStartLocation,
  }) async {
    if (coldStartLocation != null) {
      tester.platformDispatcher.defaultRouteNameTestValue = coldStartLocation;
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    }
    await tester.pumpWidget(
      ProviderScope(overrides: appProviderOverrides, child: const SteadyApp()),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(SteadyApp)));
  }

  Future<LoggingStatus?> storedStatus(
    ProviderContainer container,
    DateTime day,
  ) async {
    final result = await container
        .read(dailyMetricRepositoryProvider)
        .getByDate(day);
    return (result as Ok<DailyMetric?>).value?.loggingStatus;
  }

  DateTime moduleDay(WidgetTester tester) {
    final date = tester.widget<CheckInModule>(find.byType(CheckInModule)).date;
    return DateTime(date.year, date.month, date.day);
  }

  final tabBar = find.byKey(const Key('appTabBar'));

  int selectedTab(WidgetTester tester) =>
      tester.widget<GlassTabBar>(tabBar).selectedIndex;

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.descendant(of: tabBar, matching: find.text(label)));
    await tester.pumpAndSettle();
  }

  String location(ProviderContainer container) =>
      container.read(routerProvider).state.matchedLocation;

  group('cold start', () {
    testWidgets('/ shows the home screen', (tester) async {
      await pumpApp(tester);

      expect(find.byType(MetricsHistoryModule), findsOneWidget);
      expect(find.byType(CheckInModule), findsNothing);
    });

    testWidgets(
      '/checkin/2026-10-19 opens that day and logs to the shared store',
      (tester) async {
        final day = DateTime(2026, 10, 19);
        final container = await pumpApp(
          tester,
          coldStartLocation: '/checkin/2026-10-19',
        );

        expect(find.byType(CheckInModule), findsOneWidget);
        expect(moduleDay(tester), day);
        expect(find.text('Not checked in yet'), findsOneWidget);

        await tester.tap(find.byKey(const Key('checkInButton_logged')));
        await tester.pumpAndSettle();

        expect(find.text('Status: Logged'), findsOneWidget);
        expect(await storedStatus(container, day), LoggingStatus.logged);
      },
    );

    testWidgets('a time component resolves to the same calendar day', (
      tester,
    ) async {
      final day = DateTime(2026, 10, 19);
      final container = await pumpApp(
        tester,
        coldStartLocation: '/checkin/2026-10-19T21:30:00',
      );

      expect(find.byType(CheckInModule), findsOneWidget);
      expect(moduleDay(tester), day);

      await tester.tap(find.byKey(const Key('checkInButton_partial')));
      await tester.pumpAndSettle();

      expect(await storedStatus(container, day), LoggingStatus.partial);
    });

    testWidgets('a UTC offset does not move the date across midnight', (
      tester,
    ) async {
      // 23:30 at -05:00 is already the 20th in UTC (and in any zone east of
      // -05:00); the path's leading date is what counts.
      final day = DateTime(2026, 10, 19);
      final container = await pumpApp(
        tester,
        coldStartLocation: '/checkin/2026-10-19T23:30:00-05:00',
      );

      expect(find.byType(CheckInModule), findsOneWidget);
      expect(moduleDay(tester), day);

      await tester.tap(find.byKey(const Key('checkInButton_skipped')));
      await tester.pumpAndSettle();

      expect(await storedStatus(container, day), LoggingStatus.skipped);
    });

    for (final path in ['/checkin/garbage', '/checkin/2026-02-30']) {
      testWidgets('malformed $path redirects to Today in the shell', (
        tester,
      ) async {
        final container = await pumpApp(tester, coldStartLocation: path);

        expect(tester.takeException(), isNull);
        expect(location(container), '/');
        expect(tabBar, findsOneWidget);
        expect(selectedTab(tester), 0);
        expect(find.byType(MetricsHistoryModule), findsOneWidget);
        expect(find.byType(CheckInModule), findsNothing);
      });
    }
  });

  group('app shell', () {
    testWidgets('shows Today, Week and Settings, with Today selected', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(tabBar, findsOneWidget);
      expect(tester.widget<GlassTabBar>(tabBar).items.map((i) => i.label), [
        'Today',
        'Week',
        'Settings',
      ]);
      expect(selectedTab(tester), 0);
    });

    testWidgets('tabs switch between Today, Week and Settings', (tester) async {
      final container = await pumpApp(tester);

      await tapTab(tester, 'Week');
      expect(location(container), '/week');
      expect(selectedTab(tester), 1);
      expect(find.byType(MetricsHistoryModule), findsOneWidget);

      await tapTab(tester, 'Settings');
      expect(location(container), '/settings');
      expect(selectedTab(tester), 2);
      expect(find.byType(DataExportModule), findsOneWidget);

      await tapTab(tester, 'Today');
      expect(location(container), '/');
      expect(selectedTab(tester), 0);
      expect(find.byType(MetricsHistoryModule), findsOneWidget);
    });

    testWidgets('each tab keeps its own stack', (tester) async {
      final container = await pumpApp(tester);

      unawaited(
        container
            .read(routerProvider)
            .push<void>(CheckInRoute(date: DateTime(2026, 10, 19)).location),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CheckInModule), findsOneWidget);

      await tapTab(tester, 'Week');
      expect(find.byType(CheckInModule), findsNothing);

      await tapTab(tester, 'Today');
      expect(find.byType(CheckInModule), findsOneWidget);
      expect(location(container), '/checkin/2026-10-19');

      // Re-tapping the current tab pops back to its root.
      await tapTab(tester, 'Today');
      expect(find.byType(CheckInModule), findsNothing);
      expect(location(container), '/');
    });

    testWidgets('content gets bottom padding clear of the floating bar', (
      tester,
    ) async {
      await pumpApp(tester);

      final barTop = tester.getTopLeft(find.byType(GlassTabBar)).dy;
      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final contentPadding = MediaQuery.paddingOf(
        tester.element(find.byType(MetricsHistoryModule)),
      ).bottom;

      // The content still fills the screen (it scrolls under the bar), but
      // its bottom padding reaches above the bar's top edge.
      expect(
        tester.getBottomLeft(find.byType(MetricsHistoryModule)).dy,
        screenHeight,
      );
      expect(contentPadding, AppShell.bottomInset(0));
      expect(screenHeight - contentPadding, lessThan(barTop));
    });

    testWidgets("a check-in's buttons stay above the bar", (tester) async {
      await pumpApp(tester, coldStartLocation: '/checkin/2026-10-19');

      final barTop = tester.getTopLeft(find.byType(GlassTabBar)).dy;
      for (final status in ['logged', 'partial', 'skipped']) {
        final button = find.byKey(Key('checkInButton_$status'));
        expect(tester.getBottomLeft(button).dy, lessThan(barTop));
      }
    });

    testWidgets('the import flow is presented over the shell', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byKey(const Key('importButton_header')));
      await tester.pumpAndSettle();

      expect(find.byType(PdfImportModule), findsOneWidget);
      expect(tabBar, findsNothing);
    });

    testWidgets('cold start at /checkin/<date> opens in the Today tab', (
      tester,
    ) async {
      final container = await pumpApp(
        tester,
        coldStartLocation: '/checkin/2026-10-19',
      );

      expect(find.byType(CheckInModule), findsOneWidget);
      expect(moduleDay(tester), DateTime(2026, 10, 19));
      expect(tabBar, findsOneWidget);
      expect(selectedTab(tester), 0);

      // Today is beneath the check-in: tapping it returns there.
      await tapTab(tester, 'Today');
      expect(find.byType(CheckInModule), findsNothing);
      expect(find.byType(MetricsHistoryModule), findsOneWidget);
      expect(location(container), '/');
    });
  });

  group('settings', () {
    test('SettingsRoute.location is /settings', () {
      expect(const SettingsRoute().location, '/settings');
    });

    testWidgets('cold start at /settings opens the data export screen', (
      tester,
    ) async {
      await pumpApp(tester, coldStartLocation: '/settings');

      expect(tester.takeException(), isNull);
      expect(find.byType(DataExportModule), findsOneWidget);
      expect(find.byType(MetricsHistoryModule), findsNothing);
    });

    testWidgets(
      'the home gear button opens the Settings tab, and back returns',
      (tester) async {
        final container = await pumpApp(tester);

        await tester.tap(find.byKey(const Key('openSettingsButton')));
        await tester.pumpAndSettle();

        expect(find.byType(DataExportModule), findsOneWidget);
        expect(
          container.read(routerProvider).state.matchedLocation,
          '/settings',
        );
        expect(selectedTab(tester), 2);

        await tester.tap(find.byKey(const Key('settingsBackButton')));
        await tester.pumpAndSettle();

        expect(find.byType(DataExportModule), findsNothing);
        expect(find.byType(MetricsHistoryModule), findsOneWidget);
      },
    );

    testWidgets('back from a cold-started /settings returns home', (
      tester,
    ) async {
      await pumpApp(tester, coldStartLocation: '/settings');

      await tester.tap(find.byKey(const Key('settingsBackButton')));
      await tester.pumpAndSettle();

      expect(find.byType(MetricsHistoryModule), findsOneWidget);
    });
  });

  group('CheckInRoute.location', () {
    test('encodes the calendar date only, as yyyy-MM-dd', () {
      expect(
        CheckInRoute(date: DateTime(2026, 10, 19)).location,
        '/checkin/2026-10-19',
      );
      expect(
        CheckInRoute(date: DateTime(2026, 10, 19, 21, 30, 15)).location,
        '/checkin/2026-10-19',
      );
      expect(
        CheckInRoute(date: DateTime(2026, 1, 5)).location,
        '/checkin/2026-01-05',
      );
    });

    testWidgets('round-trips back to the same day through the router', (
      tester,
    ) async {
      final day = DateTime(2026, 1, 5);
      final container = await pumpApp(tester);

      container
          .read(routerProvider)
          .go(CheckInRoute(date: DateTime(2026, 1, 5, 23, 59)).location);
      await tester.pumpAndSettle();

      expect(find.byType(CheckInModule), findsOneWidget);
      expect(moduleDay(tester), day);
    });
  });
}
