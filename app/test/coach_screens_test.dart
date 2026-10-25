import 'package:checkin_domain/checkin_domain.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:steady/app_router.dart';
import 'package:steady/main.dart';
import 'package:steady/providers.dart';
import 'package:steady/today_screen.dart';
import 'package:ui_kit/ui_kit.dart';

/// The coach's screens in the real app (#80): a Coach tab on the iPhone,
/// and no coach UI or reachable coach route on the Mac.
void main() {
  final tabBar = find.byKey(const Key('appTabBar'));

  List<String> tabLabels(WidgetTester tester) => [
    for (final item in tester.widget<GlassTabBar>(tabBar).items) item.label,
  ];

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.descendant(of: tabBar, matching: find.text(label)));
    await tester.pumpAndSettle();
  }

  /// Pumps the real app. [isIOS] is the injected platform; on iOS the
  /// coach's model and store are fakes ([model], [repository]), bound on
  /// the Mac list exactly as `appProviderOverridesFor(isIOS: true)` binds
  /// the real ones (`coach_binding_test.dart` checks that wiring).
  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    required bool isIOS,
    _FakeModel? model,
    _MemoryRepository? repository,
    String? coldStart,
    DateTime? now,
    int checkInsLastWeek = 0,
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    if (coldStart != null) {
      tester.platformDispatcher.defaultRouteNameTestValue = coldStart;
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    }
    final container = ProviderContainer(
      overrides: [
        ...appProviderOverridesFor(isIOS: false),
        if (isIOS) ...[
          coachSupportAvailableProvider.overrideWithValue(true),
          coachModelProvider.overrideWithValue(model ?? _FakeModel()),
          coachRepositoryProvider.overrideWithValue(
            repository ?? _MemoryRepository(),
          ),
          coachCheckInRepositoryProvider.overrideWith(
            (ref) => ref.watch(checkInRepositoryProvider),
          ),
          coachMetricsRepositoryProvider.overrideWith(
            (ref) => ref.watch(metricsRepositoryProvider),
          ),
        ],
        if (now != null) ...[
          coachClockProvider.overrideWithValue(() => now),
          checkInClockProvider.overrideWithValue(() => now),
        ],
      ],
    );
    addTearDown(container.dispose);
    // Check-ins on the first days of the week the weekly session looks
    // back on, through the app's shared store.
    if (now != null) {
      final first = coachWeeklyWindow(now).first;
      for (var i = 0; i < checkInsLastWeek; i++) {
        await container
            .read(checkInRepositoryProvider)
            .logCheckIn(
              DateTime(first.year, first.month, first.day + i),
              CheckInStatus.logged,
            );
      }
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SteadyApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  String location(ProviderContainer container) =>
      container.read(routerProvider).state.matchedLocation;

  group('macOS', () {
    testWidgets('the bar has no Coach tab, and no tab shows coach UI', (
      tester,
    ) async {
      await pumpApp(tester, isIOS: false);
      expect(tabLabels(tester), ['Today', 'Week', 'Settings']);
      for (final tab in ['Week', 'Settings', 'Today']) {
        await tapTab(tester, tab);
        expect(find.byType(CoachHomeModule), findsNothing);
        expect(find.byType(CoachSessionModule), findsNothing);
      }
      expect(tester.widget<GlassTabBar>(tabBar).selectedIndex, 0);
    });

    testWidgets('Today has no coach nudge, even on a Friday with a full '
        'week', (tester) async {
      await pumpApp(
        tester,
        isIOS: false,
        now: DateTime(2026, 10, 23, 20),
        checkInsLastWeek: 7,
      );
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(find.byKey(const Key('coachNudgeCard')), findsNothing);
    });

    for (final path in [
      '/coach',
      '/coach/chat',
      '/coach/sessions/abc',
      '/weekly-check-in',
    ]) {
      testWidgets('a cold start at $path goes home', (tester) async {
        final container = await pumpApp(tester, isIOS: false, coldStart: path);
        expect(location(container), '/');
        expect(find.byType(TodayScreen), findsOneWidget);
        expect(find.byType(CoachHomeModule), findsNothing);
        expect(find.byType(CoachSessionModule), findsNothing);
        expect(find.byType(CoachTranscriptModule), findsNothing);
      });
    }
  });

  group('iOS', () {
    testWidgets('the bar has Today, Week, Coach and Settings', (tester) async {
      await pumpApp(tester, isIOS: true);
      expect(tabLabels(tester), ['Today', 'Week', 'Coach', 'Settings']);

      await tapTab(tester, 'Coach');
      expect(find.byType(CoachHomeModule), findsOneWidget);
      expect(tester.widget<GlassTabBar>(tabBar).selectedIndex, 2);

      await tapTab(tester, 'Settings');
      expect(tester.widget<GlassTabBar>(tabBar).selectedIndex, 3);
      expect(find.byKey(const Key('coachSettingsCard')), findsOneWidget);
    });

    testWidgets('an unavailable model says why on the Coach tab; the rest '
        'of the app is unaffected', (tester) async {
      final model = _FakeModel()
        ..availability = const Err(CoachAppleIntelligenceNotEnabledFailure());
      await pumpApp(tester, isIOS: true, model: model);
      expect(find.byType(TodayScreen), findsOneWidget);

      await tapTab(tester, 'Coach');
      expect(find.text('The coach needs Apple Intelligence'), findsOneWidget);
      expect(find.byKey(const Key('coachStartChat')), findsNothing);

      await tapTab(tester, 'Week');
      await tapTab(tester, 'Today');
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('a chat opens over the shell, is saved with its summary, '
        'and shows in the history with its transcript', (tester) async {
      final repository = _MemoryRepository();
      final container = await pumpApp(
        tester,
        isIOS: true,
        repository: repository,
      );
      await tapTab(tester, 'Coach');
      await tester.tap(find.byKey(const Key('coachStartChat')));
      await tester.pumpAndSettle();

      expect(location(container), '/coach/chat');
      expect(find.byType(CoachSessionModule), findsOneWidget);
      // Presented over the shell: no tab bar under the message box.
      expect(tabBar.hitTestable(), findsNothing);

      await tester.enterText(
        find.byKey(const Key('coachMessageField')),
        'How was my week?',
      );
      await tester.tap(find.byKey(const Key('coachSend')));
      await tester.pumpAndSettle();
      expect(find.text('Coach reply.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('coachSessionClose')));
      await tester.pumpAndSettle();
      expect(location(container), '/coach');

      final stored = repository.sessions.single;
      expect(stored.summary, 'A short summary.');
      expect(stored.messages.map((m) => m.text), [
        'How was my week?',
        'Coach reply.',
      ]);

      final tile = find.byKey(Key('coachSession_${stored.id}'));
      // Clear of the floating tab bar.
      await tester.scrollUntilVisible(
        tile,
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('coachHomeScroll')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.drag(
        find.byKey(const Key('coachHomeScroll')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(location(container), '/coach/sessions/${stored.id}');
      expect(find.byType(CoachTranscriptModule), findsOneWidget);
      expect(find.text('How was my week?'), findsOneWidget);
      // Inside the Coach tab: the bar is still there.
      expect(tabBar.hitTestable(), findsOneWidget);
    });

    testWidgets("Friday: Today's nudge offers the weekly check-in, and Talk "
        'now opens it over the shell', (tester) async {
      final repository = _MemoryRepository();
      final container = await pumpApp(
        tester,
        isIOS: true,
        repository: repository,
        now: DateTime(2026, 10, 23, 20),
        checkInsLastWeek: 4,
      );
      final nudge = find.byKey(const Key('coachNudgeCard'));
      await tester.scrollUntilVisible(
        nudge,
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('todayScroll')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.textContaining('Oct 16 – 22 is ready'), findsOneWidget);

      await tester.drag(
        find.byKey(const Key('todayScroll')),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('coachNudgeTalkNow')));
      await tester.pumpAndSettle();
      expect(location(container), '/weekly-check-in');
      expect(find.text('Look back on Oct 16 – 22'), findsOneWidget);

      await tester.tap(find.byKey(const Key('coachWeeklyBegin')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('coachMessageField')),
        'It went fine.',
      );
      await tester.tap(find.byKey(const Key('coachSend')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('coachSessionEnd')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('coachSessionDone')));
      await tester.pumpAndSettle();

      expect(location(container), '/');
      expect(repository.sessions.single.kind, CoachSessionKind.weekly);
      // Done for this week: the nudge is gone.
      expect(nudge, findsNothing);
    });

    testWidgets('a week with three check-ins: no nudge', (tester) async {
      await pumpApp(
        tester,
        isIOS: true,
        now: DateTime(2026, 10, 23, 20),
        checkInsLastWeek: 3,
      );
      expect(find.byKey(const Key('coachNudgeCard')), findsNothing);
    });

    testWidgets('deleting coach history in Settings empties the Coach tab', (
      tester,
    ) async {
      final repository = _MemoryRepository()
        ..sessions.add(
          CoachSession(
            id: 'old',
            kind: CoachSessionKind.chat,
            startedAt: DateTime(2026, 10, 20, 20),
            summary: 'An old chat.',
          ),
        );
      await pumpApp(tester, isIOS: true, repository: repository);
      await tapTab(tester, 'Coach');
      expect(find.text('An old chat.'), findsOneWidget);

      await tapTab(tester, 'Settings');
      final delete = find.byKey(const Key('coachDeleteHistoryButton'));
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('coachDeleteConfirm')));
      await tester.pumpAndSettle();

      await tapTab(tester, 'Coach');
      expect(find.text('An old chat.'), findsNothing);
      expect(find.byKey(const Key('coachHistoryEmpty')), findsOneWidget);
    });
  });
}

/// A model that's available and answers at once.
class _FakeModel implements CoachModel {
  Result<CoachModelInfo> availability = const Ok(
    CoachModelInfo(contextSize: 4096),
  );
  var _next = 0;

  @override
  ResultFuture<CoachModelInfo> checkAvailability() async => availability;

  @override
  ResultFuture<CoachModelSession> startSession({
    required String instructions,
  }) async => Ok(CoachModelSession(id: 's${_next++}'));

  @override
  Stream<Result<String>> streamResponse(
    CoachModelSession session,
    String prompt,
  ) => Stream.fromIterable([
    Ok(
      prompt.startsWith(CoachInstructions.summaryRequest)
          ? 'A short summary.'
          : 'Coach reply.',
    ),
  ]);

  @override
  ResultFuture<Unit> cancelResponse(CoachModelSession session) async =>
      const Ok(unit);

  @override
  ResultFuture<Unit> endSession(CoachModelSession session) async =>
      const Ok(unit);
}

/// An in-memory coach store (the file store's own tests are in
/// `coach_data`; file I/O doesn't run under a widget test's fake clock).
class _MemoryRepository implements CoachRepository {
  final List<CoachSession> sessions = [];

  @override
  ResultFuture<List<CoachSession>> listSessions() async =>
      Ok([...sessions]..sort(compareCoachSessionsNewestFirst));

  @override
  ResultFuture<CoachSession?> getSession(String id) async =>
      Ok(sessions.where((s) => s.id == id).firstOrNull);

  @override
  ResultFuture<Unit> saveSession(CoachSession session) async {
    sessions
      ..removeWhere((s) => s.id == session.id)
      ..add(session);
    return const Ok(unit);
  }

  @override
  ResultFuture<Unit> deleteAll() async {
    sessions.clear();
    return const Ok(unit);
  }
}
