import 'dart:async';

import 'package:analytics/analytics.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_data/health_sync_data.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:onboarding_domain/onboarding_domain.dart';
import 'package:onboarding_domain/testing/in_memory_onboarding_repository.dart';
import 'package:onboarding_presentation/onboarding_presentation.dart';
import 'package:steady/app_router.dart';
import 'package:steady/main.dart';
import 'package:steady/onboarding.dart';
import 'package:steady/providers.dart';
import 'package:steady/today_screen.dart';
import 'package:steady/usage_sharing.dart';

/// Onboarding's app wiring (#161): the launch decision, the flow's
/// callbacks (analytics, Apple Health, the coach's consent) and what Today
/// reads from its answers. Where it shows and leaves to is in
/// `app_router_test.dart`; the file binding in `bootstrap_test.dart`.
void main() {
  group('the analytics codes mirror the onboarding enums', () {
    test('screen 3 sources', () {
      expect(
        OnboardingSource.values.map((s) => s.code).toSet(),
        onboardingSourceCodes,
      );
    });

    test('steps: every screen, plus unknown', () {
      expect(onboardingStepCodes, {
        ...OnboardingStep.values.map((s) => s.name),
        'unknown',
      });
      expect(
        OnboardingStep.values.map((s) => s.name),
        isNot(contains(onboardingStepUnknown)),
      );
    });
  });

  group('shouldShowOnboardingAtLaunch', () {
    Future<bool> decide(InMemoryOnboardingRepository repository) =>
        shouldShowOnboardingAtLaunch(repository);

    test('no record (a first launch, or a 1.0 user) shows it', () async {
      expect(await decide(InMemoryOnboardingRepository()), isTrue);
    });

    test('mid-flow shows it again', () async {
      expect(
        await decide(
          InMemoryOnboardingRepository(
            const OnboardingRecord(step: OnboardingStep.voice),
          ),
        ),
        isTrue,
      );
    });

    test('completed does not', () async {
      expect(
        await decide(
          InMemoryOnboardingRepository(
            const OnboardingRecord(
              completed: true,
              aboutMe: AboutMe(voice: CoachVoice.direct),
            ),
          ),
        ),
        isFalse,
      );
    });

    test('unreadable counts as done', () async {
      expect(
        await decide(InMemoryOnboardingRepository()..makeUnreadable()),
        isFalse,
      );
    });

    test('a storage failure, or a throw, does not show it', () async {
      expect(
        await decide(
          InMemoryOnboardingRepository()
            ..failNextWith = const OnboardingStorageFailure('disk'),
        ),
        isFalse,
      );
      expect(
        await shouldShowOnboardingAtLaunch(_ThrowingRepository()),
        isFalse,
      );
    });
  });

  group('OnboardingLaunchCheck', () {
    test('answers with the record', () async {
      expect(
        await OnboardingLaunchCheck(InMemoryOnboardingRepository()).due,
        isTrue,
      );
    });

    test('a read slower than the limit is a no, even if it answers yes '
        'later', () async {
      final repository = _SlowRepository();
      final check = OnboardingLaunchCheck(
        repository,
        timeout: const Duration(milliseconds: 10),
      );
      expect(await check.due, isFalse);
      repository.reply.complete(const Ok(OnboardingRecord.initial));
      await pumpEventQueue();
      expect(await check.due, isFalse);
    });

    test('cancel is a no', () async {
      final check = OnboardingLaunchCheck(_SlowRepository())..cancel();
      expect(await check.due, isFalse);
    });
  });

  group('in the app', () {
    late _FakePostHogClient postHog;
    late InMemoryHealthKitRepository health;
    late _MemoryConsent consent;

    setUp(() {
      postHog = _FakePostHogClient();
      health = InMemoryHealthKitRepository();
      consent = _MemoryConsent();
    });

    /// The real usage-sharing sink over a fake PostHog client: the gating
    /// (install source, the Settings switch) is the app's own.
    Future<PostHogAnalytics> sharing(InstallSource source) async {
      final analytics = PostHogAnalytics(
        client: postHog,
        installSource: _FixedInstallSource(source),
        store: _OnStore(),
      );
      await analytics.status;
      return analytics;
    }

    /// Pumps the real app on a phone-sized screen, with onboarding and the
    /// coach bound as the iOS list binds them, but to in-memory fakes (file
    /// I/O doesn't run under a widget test's fake clock).
    Future<ProviderContainer> pumpApp(
      WidgetTester tester,
      OnboardingRepository onboarding, {
      PostHogAnalytics? analytics,
    }) async {
      tester.view
        ..physicalSize = const Size(390, 844) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final container = ProviderContainer(
        overrides: [
          ...appProviderOverridesFor(isIOS: false),
          onboardingSupportAvailableProvider.overrideWithValue(true),
          onboardingRepositoryProvider.overrideWithValue(onboarding),
          healthKitRepositoryProvider.overrideWithValue(health),
          if (analytics != null)
            postHogAnalyticsProvider.overrideWithValue(analytics),
          coachSupportAvailableProvider.overrideWithValue(true),
          coachConsentRepositoryProvider.overrideWithValue(consent),
          coachModelProvider.overrideWithValue(_FakeModel()),
          coachRepositoryProvider.overrideWithValue(_MemoryCoachRepository()),
          coachCheckInRepositoryProvider.overrideWith(
            (ref) => ref.watch(checkInRepositoryProvider),
          ),
          coachMetricsRepositoryProvider.overrideWith(
            (ref) => ref.watch(metricsRepositoryProvider),
          ),
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

    Finder byKey(String key) => find.byKey(Key(key));

    Future<void> tapKey(WidgetTester tester, String key) async {
      await tester.ensureVisible(byKey(key));
      await tester.pumpAndSettle();
      await tester.tap(byKey(key));
      await tester.pumpAndSettle();
    }

    testWidgets('the whole flow: the source is sent, screen 4 asks for '
        'Health, screen 8 asks for consent, and finishing sends no exit', (
      tester,
    ) async {
      final onboarding = InMemoryOnboardingRepository();
      final analytics = await sharing(InstallSource.testFlight);
      await pumpApp(tester, onboarding, analytics: analytics);
      expect(find.byType(OnboardingModule), findsOneWidget);
      // Launch didn't ask for Health.
      expect(health.requestAuthorizationCalls, 0);

      // 1. The first stone.
      await tapKey(tester, 'onboardingFirstStone');
      await tapKey(tester, 'onboardingContinue');
      // 2. Tracking: another Health app.
      await tapKey(tester, 'onboardingOption_otherHealthApp');
      await tapKey(tester, 'onboardingContinue');
      // 3. Where they heard about Steady.
      await tapKey(tester, 'onboardingOption_instagram');
      await tapKey(tester, 'onboardingContinue');
      expect(postHog.sent, [
        [
          'onboarding_source',
          {'source': 'instagram'},
        ],
      ]);
      // 4. Apple Health: asks, once.
      await tapKey(tester, 'onboardingContinue');
      expect(health.requestAuthorizationCalls, 1);
      // 5–7 skipped.
      for (var i = 0; i < 3; i++) {
        await tapKey(tester, 'onboardingSkip');
      }
      // 8. "Turn on the coach": the coach's consent screen, over the flow.
      await tapKey(tester, 'onboardingContinue');
      expect(find.byKey(const Key('coachConsentScreen')), findsOneWidget);
      await tapKey(tester, 'coachConsentAllow');
      expect(consent.agreed, CoachConsent.currentVersion);
      expect(find.byKey(const Key('coachConsentScreen')), findsNothing);
      // 9. The first week, then 10. the cairn.
      await tapKey(tester, 'onboardingContinue');
      expect(find.text(OnboardingCopy.goToToday), findsOneWidget);
      await tapKey(tester, 'onboardingContinue');

      expect(find.byType(OnboardingModule), findsNothing);
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(onboarding.record.completed, isTrue);
      // The source and Health's own event only: no `onboarding_exited`.
      expect(
        postHog.captured.map((e) => e.$1),
        isNot(contains('onboarding_exited')),
      );
      // Screen 2's answer hides Today's import button; Health was asked,
      // so Today offers no "Connect Apple Health".
      expect(byKey('importButton_header'), findsNothing);
      expect(byKey('todayConnectHealth'), findsNothing);
    });

    testWidgets('"Not now" sends onboarding_exited with the screen, and '
        'nothing about the unanswered source', (tester) async {
      final analytics = await sharing(InstallSource.testFlight);
      await pumpApp(
        tester,
        InMemoryOnboardingRepository(
          const OnboardingRecord(step: OnboardingStep.source),
        ),
        analytics: analytics,
      );

      await tapKey(tester, 'onboardingNotNow');

      expect(find.byType(TodayScreen), findsOneWidget);
      expect(postHog.sent, [
        [
          'onboarding_exited',
          {'step': 'source'},
        ],
      ]);
    });

    testWidgets('"Not now" after a failed read sends step unknown', (
      tester,
    ) async {
      final analytics = await sharing(InstallSource.testFlight);
      final onboarding = InMemoryOnboardingRepository()
        ..failNextWith = const OnboardingStorageFailure('disk');
      // The launch decision's read fails too, so open the flow by hand.
      final container = await pumpApp(tester, onboarding, analytics: analytics);
      expect(find.byType(OnboardingModule), findsNothing);
      onboarding.failNextWith = const OnboardingStorageFailure('disk');
      container.read(routerProvider).go('/onboarding');
      await tester.pumpAndSettle();
      expect(byKey('onboardingReadFailed'), findsOneWidget);

      await tapKey(tester, 'onboardingNotNow');

      expect(find.byType(TodayScreen), findsOneWidget);
      expect(postHog.sent, [
        [
          'onboarding_exited',
          {'step': 'unknown'},
        ],
      ]);
    });

    testWidgets("an App Store install sends neither event (usage sharing's "
        'gating is unchanged)', (tester) async {
      final analytics = await sharing(InstallSource.appStore);
      await pumpApp(
        tester,
        InMemoryOnboardingRepository(
          const OnboardingRecord(step: OnboardingStep.source),
        ),
        analytics: analytics,
      );
      await tapKey(tester, 'onboardingOption_reddit');
      await tapKey(tester, 'onboardingContinue');
      await tapKey(tester, 'onboardingNotNow');

      expect(find.byType(TodayScreen), findsOneWidget);
      expect(postHog.captured, isEmpty);
    });

    testWidgets("declining the coach's consent moves the flow on", (
      tester,
    ) async {
      await pumpApp(
        tester,
        InMemoryOnboardingRepository(
          const OnboardingRecord(step: OnboardingStep.meetCoach),
        ),
      );
      await tapKey(tester, 'onboardingContinue');
      await tapKey(tester, 'coachConsentNotNow');

      expect(consent.agreed, isNull);
      expect(find.byType(OnboardingModule), findsOneWidget);
      expect(find.text(OnboardingCopy.meetCoachTitle), findsNothing);
    });

    group("Today's empty metrics card follows screen 2", () {
      String emptyText(WidgetTester tester) => tester
          .widget<Text>(
            find.descendant(
              of: byKey('todayMetricsEmpty'),
              matching: find.byType(Text),
            ),
          )
          .data!;

      for (final (tracking, hint) in [
        (FoodTracking.calAi, TodayMetricsEmptyHint.calAiImport),
        (null, TodayMetricsEmptyHint.calAiImport),
        (FoodTracking.otherHealthApp, TodayMetricsEmptyHint.healthApp),
        (FoodTracking.justStarting, TodayMetricsEmptyHint.justStarting),
      ]) {
        testWidgets('${tracking?.name ?? 'unanswered'}: ${hint.name}', (
          tester,
        ) async {
          // Nothing in Health either, so the week is empty.
          health = InMemoryHealthKitRepository(
            status: HealthAuthorizationStatus.requested,
          );
          await pumpApp(
            tester,
            InMemoryOnboardingRepository(
              OnboardingRecord(
                completed: true,
                aboutMe: AboutMe(tracking: tracking),
              ),
            ),
          );
          await tester.ensureVisible(byKey('todayMetricsEmpty'));
          expect(emptyText(tester), hint.text);
        });
      }
    });

    group("Today's import button follows screen 2", () {
      for (final (tracking, shown) in [
        (FoodTracking.calAi, true),
        (null, true),
        (FoodTracking.otherHealthApp, false),
        (FoodTracking.justStarting, false),
      ]) {
        testWidgets('${tracking?.name ?? 'unanswered'}: '
            '${shown ? 'shown' : 'hidden'}, and Week keeps its own', (
          tester,
        ) async {
          await pumpApp(
            tester,
            InMemoryOnboardingRepository(
              OnboardingRecord(
                completed: true,
                aboutMe: AboutMe(tracking: tracking),
              ),
            ),
          );
          expect(find.byType(TodayScreen), findsOneWidget);
          expect(byKey('importButton_header'), shown ? findsOne : findsNothing);

          await tester.tap(find.text('Week'));
          await tester.pumpAndSettle();
          expect(find.byType(MetricsHistoryModule), findsOneWidget);
          expect(byKey('importButton_header'), findsOneWidget);
        });
      }

      testWidgets('an unreadable record shows it', (tester) async {
        await pumpApp(tester, InMemoryOnboardingRepository()..makeUnreadable());
        expect(byKey('importButton_header'), findsOneWidget);
      });
    });

    group('Settings → About me (#172)', () {
      const calAiDone = OnboardingRecord(
        completed: true,
        aboutMe: AboutMe(
          tracking: FoodTracking.calAi,
          voice: CoachVoice.gentle,
        ),
      );

      Future<void> openAboutMe(WidgetTester tester) async {
        await tester.tap(
          find.descendant(
            of: byKey('appTabBar'),
            matching: find.text('Settings'),
          ),
        );
        await tester.pumpAndSettle();
        await tapKey(tester, 'aboutMeSettingsRow');
      }

      Future<void> backToToday(WidgetTester tester) async {
        await tapKey(tester, 'aboutMeBack');
        expect(find.byType(AboutMeModule), findsNothing);
        await tester.tap(
          find.descendant(of: byKey('appTabBar'), matching: find.text('Today')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(TodayScreen), findsOneWidget);
      }

      String emptyText(WidgetTester tester) => tester
          .widget<Text>(
            find.descendant(
              of: byKey('todayMetricsEmpty'),
              matching: find.byType(Text),
            ),
          )
          .data!;

      testWidgets('the "About me" row opens the editor at /settings/about-me, '
          'inside the Settings tab', (tester) async {
        final container = await pumpApp(
          tester,
          InMemoryOnboardingRepository(calAiDone),
        );
        await openAboutMe(tester);

        expect(find.byType(AboutMeModule), findsOneWidget);
        expect(
          container.read(routerProvider).state.matchedLocation,
          '/settings/about-me',
        );
        // Still in the shell, on the Settings tab.
        expect(byKey('appTabBar'), findsOneWidget);
        await tapKey(tester, 'aboutMeBack');
        expect(find.byKey(const Key('aboutMeSettingsRow')), findsOneWidget);
        expect(
          container.read(routerProvider).state.matchedLocation,
          '/settings',
        );
      });

      testWidgets('Today follows a tracking edit straight away: the import '
          'button, the Cal AI card and the empty text', (tester) async {
        // Health asked and empty: a Cal AI tracker gets the Cal AI card,
        // and the week is empty, so the empty text shows.
        health = InMemoryHealthKitRepository(
          status: HealthAuthorizationStatus.requested,
        );
        final onboarding = InMemoryOnboardingRepository(calAiDone);
        await pumpApp(tester, onboarding);
        expect(byKey('importButton_header'), findsOneWidget);
        expect(byKey('calAiHealthCard'), findsOneWidget);
        await tester.ensureVisible(byKey('todayMetricsEmpty'));
        expect(emptyText(tester), TodayMetricsEmptyHint.calAiImport.text);

        // Another Health app: no import button, no Cal AI card, and the
        // empty text says calories come through Apple Health.
        await openAboutMe(tester);
        await tapKey(tester, 'aboutMeOption_otherHealthApp');
        expect(onboarding.record.aboutMe.tracking, FoodTracking.otherHealthApp);
        await backToToday(tester);
        expect(byKey('importButton_header'), findsNothing);
        expect(byKey('calAiHealthCard'), findsNothing);
        await tester.ensureVisible(byKey('todayMetricsEmpty'));
        expect(emptyText(tester), TodayMetricsEmptyHint.healthApp.text);

        // Cleared (back to skipped): Today treats it as no answer, like
        // Cal AI.
        await openAboutMe(tester);
        await tapKey(tester, 'aboutMeOption_otherHealthApp');
        expect(onboarding.record.aboutMe.tracking, isNull);
        await backToToday(tester);
        expect(byKey('importButton_header'), findsOneWidget);
        expect(byKey('calAiHealthCard'), findsOneWidget);
        await tester.ensureVisible(byKey('todayMetricsEmpty'));
        expect(emptyText(tester), TodayMetricsEmptyHint.calAiImport.text);

        // Editing never brought onboarding back, or undid it.
        expect(onboarding.record.completed, isTrue);
        expect(find.byType(OnboardingModule), findsNothing);
      });

      testWidgets('a failed save leaves Today on what is stored', (
        tester,
      ) async {
        final onboarding = InMemoryOnboardingRepository(calAiDone);
        await pumpApp(tester, onboarding);
        await openAboutMe(tester);
        onboarding.failNextWith = const OnboardingStorageFailure('disk');
        await tapKey(tester, 'aboutMeOption_justStarting');
        expect(byKey('onboardingSaveFailed'), findsOneWidget);

        await backToToday(tester);
        expect(byKey('importButton_header'), findsOneWidget);
      });
    });

    group("Today's \"Connect Apple Health\"", () {
      // Another Health app: no Cal AI card, so the pill is the one prompt.
      // (For a Cal AI tracker the card asks instead: cal_ai_health_card_test.)
      Future<void> pumpToday(WidgetTester tester) => pumpApp(
        tester,
        InMemoryOnboardingRepository(
          const OnboardingRecord(
            completed: true,
            aboutMe: AboutMe(tracking: FoodTracking.otherHealthApp),
          ),
        ),
      );

      testWidgets('offered before the sheet, and it asks', (tester) async {
        await pumpToday(tester);
        expect(health.requestAuthorizationCalls, 0);
        expect(byKey('calAiHealthCard'), findsNothing);

        await tapKey(tester, 'todayConnectHealth');

        expect(health.requestAuthorizationCalls, 1);
        expect(byKey('todayConnectHealth'), findsNothing);
      });

      testWidgets('not offered once asked (every 1.0 user)', (tester) async {
        health.status = HealthAuthorizationStatus.requested;
        await pumpToday(tester);
        expect(byKey('todayConnectHealth'), findsNothing);
        expect(health.requestAuthorizationCalls, 0);
      });
    });
  });
}

final class _ThrowingRepository extends InMemoryOnboardingRepository {
  @override
  ResultFuture<OnboardingRecord> read() async =>
      throw StateError('channel gone');
}

final class _SlowRepository extends InMemoryOnboardingRepository {
  final Completer<Result<OnboardingRecord>> reply = Completer();

  @override
  ResultFuture<OnboardingRecord> read() => reply.future;
}

final class _FixedInstallSource implements InstallSourceReader {
  const _FixedInstallSource(this.source);

  final InstallSource source;

  @override
  Future<InstallSource> read() async => source;
}

/// Usage sharing left on.
final class _OnStore implements UsageSharingStore {
  @override
  Future<bool> isOff() async => false;

  @override
  Future<void> setOff({required bool off}) async {}
}

/// Records what would reach PostHog. It mirrors our own assumption that
/// `Posthog().capture` sends these names and properties as given; the SDK
/// itself isn't exercised here.
final class _FakePostHogClient implements PostHogClient {
  final captured = <(String, Map<String, Object>)>[];

  /// The onboarding events captured, as `[name, properties]` lists, which
  /// `equals` compares deeply.
  List<List<Object>> get sent => [
    for (final (name, properties) in captured)
      if (name.startsWith('onboarding_')) [name, properties],
  ];

  @override
  Future<void> setup({required bool optOut}) async {}

  @override
  Future<void> capture(String name, Map<String, Object> properties) async =>
      captured.add((name, properties));

  @override
  Future<void> optIn() async {}

  @override
  Future<void> optOut() async {}
}

class _FakeModel implements CoachModel {
  @override
  ResultFuture<Unit> checkAvailability() async => const Ok(unit);

  @override
  Stream<Result<CoachReplySnapshot>> reply(CoachRequest request) =>
      const Stream.empty();
}

class _MemoryConsent implements CoachConsentRepository {
  int? agreed;

  @override
  ResultFuture<int?> readAgreedVersion() async => Ok(agreed);

  @override
  ResultFuture<Unit> giveConsent(int version) async {
    agreed = version;
    return const Ok(unit);
  }

  @override
  ResultFuture<Unit> withdrawConsent() async {
    agreed = null;
    return const Ok(unit);
  }
}

class _MemoryCoachRepository implements CoachRepository {
  @override
  ResultFuture<List<CoachSession>> listSessions() async => const Ok([]);

  @override
  ResultFuture<CoachSession?> getSession(String id) async => const Ok(null);

  @override
  ResultFuture<Unit> saveSession(CoachSession session) async => const Ok(unit);

  @override
  ResultFuture<Unit> deleteAll() async => const Ok(unit);
}
