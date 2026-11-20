import 'dart:async';

import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:data_export_presentation/data_export_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:onboarding_domain/onboarding_domain.dart';
import 'package:onboarding_domain/testing/in_memory_onboarding_repository.dart';
import 'package:onboarding_presentation/onboarding_presentation.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:steady/app_router.dart';
import 'package:steady/app_shell.dart';
import 'package:steady/main.dart';
import 'package:steady/onboarding.dart';
import 'package:steady/providers.dart';
import 'package:steady/today_screen.dart';
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

      expect(find.byType(TodayScreen), findsOneWidget);
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
        StatusOptionTile logged() =>
            tester.widget(find.byKey(const Key('checkInButton_logged')));
        expect(logged().selected, isFalse);

        await tester.tap(find.byKey(const Key('checkInButton_logged')));
        await tester.pumpAndSettle();

        expect(logged().selected, isTrue);
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
        expect(find.byType(TodayScreen), findsOneWidget);
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
      expect(find.byType(TodayScreen), findsOneWidget);
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
        tester.element(find.byType(TodayScreen)),
      ).bottom;

      // The content still fills the screen (it scrolls under the bar), but
      // its bottom padding reaches above the bar's top edge.
      expect(tester.getBottomLeft(find.byType(TodayScreen)).dy, screenHeight);
      expect(contentPadding, AppShell.bottomInset(0));
      expect(screenHeight - contentPadding, lessThan(barTop));

      // Today pads its scroll content by that inset rather than sitting in
      // a bottom SafeArea, so its cards scroll under the bar.
      final scroll = tester.widget<SingleChildScrollView>(
        find.byKey(const Key('todayScroll')),
      );
      expect(scroll.padding!.resolve(TextDirection.ltr).bottom, contentPadding);
      expect(
        tester.getBottomLeft(find.byKey(const Key('todayScroll'))).dy,
        screenHeight,
      );
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
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(location(container), '/');
    });
  });

  group('onboarding at launch', () {
    final onboarding = find.byType(OnboardingModule);

    /// Pumps the real app on a phone-sized screen with onboarding bound, as
    /// the iOS list binds it, but to [repository] (in memory: file I/O
    /// doesn't run under a widget test's fake clock; `bootstrap_test.dart`
    /// covers the file binding).
    Future<ProviderContainer> pumpWithOnboarding(
      WidgetTester tester,
      OnboardingRepository repository, {
      String? coldStartLocation,
    }) async {
      tester.view
        ..physicalSize = const Size(390, 844) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      if (coldStartLocation != null) {
        tester.platformDispatcher.defaultRouteNameTestValue = coldStartLocation;
        addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
      }
      final container = ProviderContainer(
        overrides: [
          ...appProviderOverridesFor(isIOS: false),
          onboardingSupportAvailableProvider.overrideWithValue(true),
          onboardingRepositoryProvider.overrideWithValue(repository),
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

    /// Moves around the app and back to the foreground, as a session does.
    Future<void> useTheApp(WidgetTester tester) async {
      await tapTab(tester, 'Week');
      await tapTab(tester, 'Settings');
      await tapTab(tester, 'Today');
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
    }

    testWidgets('a first launch (no record) shows onboarding over no shell', (
      tester,
    ) async {
      final container = await pumpWithOnboarding(
        tester,
        InMemoryOnboardingRepository(),
      );

      expect(onboarding, findsOneWidget);
      expect(location(container), '/onboarding');
      expect(tabBar, findsNothing);
      expect(find.byType(TodayScreen), findsNothing);
    });

    testWidgets('a first launch after a 1.0 install, mid-flow, resumes the '
        'flow', (tester) async {
      await pumpWithOnboarding(
        tester,
        InMemoryOnboardingRepository(
          const OnboardingRecord(step: OnboardingStep.hardParts),
        ),
      );
      expect(onboarding, findsOneWidget);
      expect(find.text(OnboardingCopy.hardPartsTitle), findsOneWidget);
    });

    testWidgets('completed opens Today', (tester) async {
      final container = await pumpWithOnboarding(
        tester,
        InMemoryOnboardingRepository(
          const OnboardingRecord(
            completed: true,
            aboutMe: AboutMe(tracking: FoodTracking.calAi),
          ),
        ),
      );
      expect(onboarding, findsNothing);
      expect(location(container), '/');
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('an unreadable record counts as done: Today', (tester) async {
      final repository = InMemoryOnboardingRepository()..makeUnreadable();
      await pumpWithOnboarding(tester, repository);
      expect(onboarding, findsNothing);
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('a storage failure skips it this launch, without writing', (
      tester,
    ) async {
      final repository = InMemoryOnboardingRepository()
        ..failNextWith = const OnboardingStorageFailure('disk');
      await pumpWithOnboarding(tester, repository);
      expect(onboarding, findsNothing);
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(repository.record, OnboardingRecord.initial);
    });

    testWidgets('a slow read never holds Today back, and skips it this '
        'launch even if it answers later', (tester) async {
      final repository = _SlowOnboardingRepository();
      await pumpWithOnboarding(tester, repository);
      // The first frame is Today, while the read is still out.
      expect(find.byType(TodayScreen), findsOneWidget);

      await tester.pump(onboardingLaunchReadTimeout);
      repository.reply.complete(const Ok(OnboardingRecord.initial));
      await tester.pumpAndSettle();
      expect(onboarding, findsNothing);
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('a /checkin/<date> cold start opens the link, not onboarding', (
      tester,
    ) async {
      final repository = InMemoryOnboardingRepository();
      final container = await pumpWithOnboarding(
        tester,
        repository,
        coldStartLocation: '/checkin/2026-10-19',
      );
      expect(onboarding, findsNothing);
      expect(find.byType(CheckInModule), findsOneWidget);
      expect(location(container), '/checkin/2026-10-19');
      // Still due: it shows on the next ordinary launch.
      expect(repository.record.completed, isFalse);
    });

    testWidgets('"Not now" lands on Today and it never comes back this '
        'session', (tester) async {
      final repository = InMemoryOnboardingRepository();
      final container = await pumpWithOnboarding(tester, repository);

      await tester.tap(find.byKey(const Key('onboardingNotNow')));
      await tester.pumpAndSettle();

      expect(onboarding, findsNothing);
      expect(location(container), '/');
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(tabBar, findsOneWidget);
      expect(repository.record.completed, isTrue);

      await useTheApp(tester);
      container.read(routerProvider).go('/');
      await tester.pumpAndSettle();
      expect(onboarding, findsNothing);
    });

    testWidgets('finishing lands on Today and it never comes back this '
        'session, even if the save failed', (tester) async {
      final repository = InMemoryOnboardingRepository(
        const OnboardingRecord(step: OnboardingStep.cairn),
      );
      final container = await pumpWithOnboarding(tester, repository);
      expect(find.text(OnboardingCopy.goToToday), findsOneWidget);

      // The "done" save fails: the record still says not completed.
      repository.failNextWith = const OnboardingStorageFailure('disk');
      await tester.tap(find.byKey(const Key('onboardingContinue')));
      await tester.pumpAndSettle();

      expect(onboarding, findsNothing);
      expect(location(container), '/');
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(repository.record.completed, isFalse);

      // Only the launch decides: no redirect re-checks the record.
      await useTheApp(tester);
      expect(onboarding, findsNothing);
    });

    testWidgets("a system back on screen 1 doesn't pop to a blank screen", (
      tester,
    ) async {
      final container = await pumpWithOnboarding(
        tester,
        InMemoryOnboardingRepository(),
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(onboarding, findsOneWidget);
      expect(location(container), '/onboarding');
    });

    testWidgets('iPhone: a cold start at /settings/about-me opens About me '
        'in the Settings tab, with Settings beneath it', (tester) async {
      final container = await pumpWithOnboarding(
        tester,
        InMemoryOnboardingRepository(
          const OnboardingRecord(
            completed: true,
            aboutMe: AboutMe(tracking: FoodTracking.calAi),
          ),
        ),
        coldStartLocation: '/settings/about-me',
      );
      expect(onboarding, findsNothing);
      expect(find.byType(AboutMeModule), findsOneWidget);
      expect(location(container), '/settings/about-me');
      expect(selectedTab(tester), 2);

      await tester.tap(find.byKey(const Key('aboutMeBack')));
      await tester.pumpAndSettle();
      expect(find.byType(DataExportModule), findsOneWidget);
      expect(find.byType(AboutMeSettingsCard), findsOneWidget);
      expect(location(container), '/settings');
    });

    testWidgets('unbound (the Mac, most tests) never shows it, even at '
        '/onboarding', (tester) async {
      final container = await pumpApp(tester);
      expect(onboarding, findsNothing);
      expect(find.byType(TodayScreen), findsOneWidget);

      container.read(routerProvider).go(const OnboardingRoute().location);
      await tester.pumpAndSettle();
      expect(onboarding, findsNothing);
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
      expect(find.byType(TodayScreen), findsNothing);
    });

    testWidgets(
      'the Week gear button opens the Settings tab, and back goes to Today',
      (tester) async {
        final container = await pumpApp(tester);
        await tapTab(tester, 'Week');

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
        expect(find.byType(TodayScreen), findsOneWidget);
      },
    );

    test('AboutMeRoute.location is /settings/about-me', () {
      expect(const AboutMeRoute().location, '/settings/about-me');
    });

    testWidgets('unbound (the Mac, most tests): no "About me" row, and '
        '/settings/about-me redirects to /settings', (tester) async {
      final container = await pumpApp(tester);
      await tapTab(tester, 'Settings');
      expect(find.byType(DataExportModule), findsOneWidget);
      expect(find.byType(AboutMeSettingsCard), findsNothing);

      container.read(routerProvider).go(const AboutMeRoute().location);
      await tester.pumpAndSettle();
      expect(find.byType(AboutMeModule), findsNothing);
      expect(find.byType(DataExportModule), findsOneWidget);
      expect(location(container), '/settings');
    });

    testWidgets('unbound: a cold start at /settings/about-me opens Settings', (
      tester,
    ) async {
      final container = await pumpApp(
        tester,
        coldStartLocation: '/settings/about-me',
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(AboutMeModule), findsNothing);
      expect(find.byType(DataExportModule), findsOneWidget);
      expect(location(container), '/settings');
    });

    testWidgets('back from a cold-started /settings returns home', (
      tester,
    ) async {
      await pumpApp(tester, coldStartLocation: '/settings');

      await tester.tap(find.byKey(const Key('settingsBackButton')));
      await tester.pumpAndSettle();

      expect(find.byType(TodayScreen), findsOneWidget);
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

/// An onboarding store whose read answers only when [reply] is completed.
class _SlowOnboardingRepository extends InMemoryOnboardingRepository {
  final Completer<Result<OnboardingRecord>> reply = Completer();

  @override
  ResultFuture<OnboardingRecord> read() => reply.future;
}
