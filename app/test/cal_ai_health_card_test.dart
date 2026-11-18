import 'dart:async';
import 'dart:io';

import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_data/health_sync_data.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:onboarding_domain/onboarding_domain.dart';
import 'package:onboarding_domain/testing/in_memory_onboarding_repository.dart';
import 'package:onboarding_presentation/onboarding_presentation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:steady/cal_ai_health_card.dart';
import 'package:steady/health_access.dart';
import 'package:steady/onboarding.dart';
import 'package:steady/providers.dart';
import 'package:steady/today_screen.dart';
import 'package:ui_kit/ui_kit.dart';

/// Today's "Get calories from Cal AI automatically" card (#138).
void main() {
  final today = DateTime(2026, 10, 27);
  late DateTime clock;
  late InMemoryCalAiCardSnoozeStore snooze;

  setUp(() {
    clock = DateTime(2026, 10, 27, 9);
    snooze = InMemoryCalAiCardSnoozeStore();
  });

  final card = find.byKey(const Key('calAiHealthCard'));
  final allow = find.byKey(const Key('calAiHealthCard_allow'));
  final notNow = find.byKey(const Key('calAiHealthCard_notNow'));

  Future<void> pump(WidgetTester tester, {HealthKitRepository? health}) async {
    final overrides = <Override>[
      ...appProviderOverridesFor(isIOS: false),
      if (health != null) healthKitRepositoryProvider.overrideWithValue(health),
      checkInClockProvider.overrideWithValue(() => clock),
      calAiCardSnoozeStoreProvider.overrideWithValue(snooze),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: ShadcnApp(
          theme: steadyTheme,
          home: Scaffold(
            child: SingleChildScrollView(child: CalAiHealthCard(date: today)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String step(WidgetTester tester, int n) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(Key('calAiHealthCard_step$n')),
          matching: find.byType(Text),
        ),
      )
      .last
      .data!;

  testWidgets('nothing on the Mac (no Health)', (tester) async {
    await pump(tester);
    expect(card, findsNothing);
  });

  testWidgets('before the Health sheet: both steps and "Allow Apple Health", '
      'which asks', (tester) async {
    final health = InMemoryHealthKitRepository();
    await pump(tester, health: health);

    expect(card, findsOneWidget);
    expect(step(tester, 1), calAiConnectStep);
    expect(step(tester, 2), contains('Allow Apple Health'));
    expect(allow, findsOneWidget);

    await tester.tap(allow);
    await tester.pumpAndSettle();
    expect(health.requestAuthorizationCalls, 1);
  });

  testWidgets('after the sheet, with no calories eaten in Health: both steps, '
      'the second in the Health app', (tester) async {
    await pump(
      tester,
      health: InMemoryHealthKitRepository(
        status: HealthAuthorizationStatus.requested,
        days: [HealthDayTotals(date: today, steps: 4000)],
      ),
    );

    expect(card, findsOneWidget);
    expect(step(tester, 2), calAiAllowStep);
    expect(allow, findsNothing);
  });

  testWidgets('gone once Health has calories eaten in the window', (
    tester,
  ) async {
    await pump(
      tester,
      health: InMemoryHealthKitRepository(
        status: HealthAuthorizationStatus.requested,
        days: [
          HealthDayTotals(
            date: today.subtract(const Duration(days: 20)),
            caloriesEaten: 1900,
          ),
        ],
      ),
    );
    expect(card, findsNothing);
  });

  testWidgets('"Not now" hides it for 7 days, remembered in the store', (
    tester,
  ) async {
    await pump(tester, health: InMemoryHealthKitRepository());
    await tester.ensureVisible(notNow);
    await tester.tap(notNow);
    await tester.pumpAndSettle();

    expect(card, findsNothing);
    expect(await snooze.read(), clock);

    // A later launch, six days on: still hidden.
    clock = DateTime(2026, 11, 2, 9);
    await pump(tester, health: InMemoryHealthKitRepository());
    expect(card, findsNothing);

    // Seven days on: back.
    clock = DateTime(2026, 11, 3, 9);
    await pump(tester, health: InMemoryHealthKitRepository());
    expect(card, findsOneWidget);
  });

  group('one Health prompt on Today (todayHealthPromptProvider)', () {
    /// What [todayHealthPromptProvider] should pick: the Cal AI card for a
    /// Cal AI tracker or no answer, not snoozed, and either not asked yet
    /// or asked with no dietary energy; otherwise the pill before the
    /// sheet; otherwise nothing.
    TodayHealthPrompt expected({
      required FoodTracking? tracking,
      required bool asked,
      required bool snoozed,
      required bool dietaryEnergy,
    }) {
      final card =
          (tracking == null || tracking == FoodTracking.calAi) &&
          !snoozed &&
          (!asked || !dietaryEnergy);
      if (card) return TodayHealthPrompt.calAiCard;
      return asked ? TodayHealthPrompt.none : TodayHealthPrompt.connectHealth;
    }

    final pill = find.byKey(const Key('todayConnectHealth'));

    for (final tracking in [null, ...FoodTracking.values]) {
      for (final asked in [false, true]) {
        for (final snoozed in [false, true]) {
          for (final dietaryEnergy in [false, true]) {
            final want = expected(
              tracking: tracking,
              asked: asked,
              snoozed: snoozed,
              dietaryEnergy: dietaryEnergy,
            );
            testWidgets('${tracking?.name ?? 'unanswered'}, '
                '${asked ? 'requested' : 'notDetermined'}, '
                '${snoozed ? 'snoozed' : 'not snoozed'}, '
                '${dietaryEnergy ? 'dietary energy' : 'no dietary energy'}: '
                '${want.name}', (tester) async {
              tester.view
                ..physicalSize = const Size(390, 844) * 3
                ..devicePixelRatio = 3;
              addTearDown(tester.view.reset);
              if (snoozed) {
                await snooze.write(clock.subtract(const Duration(days: 1)));
              }
              // Before the sheet, the fake still returns data (real
              // HealthKit returns nothing); the decision mustn't use it.
              final health = InMemoryHealthKitRepository(
                status: asked
                    ? HealthAuthorizationStatus.requested
                    : HealthAuthorizationStatus.notDetermined,
                days: [
                  HealthDayTotals(
                    date: today,
                    steps: 4000,
                    caloriesEaten: dietaryEnergy ? 1800 : null,
                  ),
                ],
              );
              final container = ProviderContainer(
                overrides: [
                  ...appProviderOverridesFor(isIOS: false),
                  healthKitRepositoryProvider.overrideWithValue(health),
                  checkInClockProvider.overrideWithValue(() => clock),
                  calAiCardSnoozeStoreProvider.overrideWithValue(snooze),
                  onboardingSupportAvailableProvider.overrideWithValue(true),
                  onboardingRepositoryProvider.overrideWithValue(
                    InMemoryOnboardingRepository(
                      OnboardingRecord(
                        completed: true,
                        aboutMe: AboutMe(tracking: tracking),
                      ),
                    ),
                  ),
                ],
              );
              addTearDown(container.dispose);
              await tester.pumpWidget(
                UncontrolledProviderScope(
                  container: container,
                  child: ShadcnApp(
                    theme: steadyTheme,
                    home: TodayScreen(
                      onImportRequested: () {},
                      onOpenAccountSettings: () {},
                      onCravingRequested: () {},
                      onConnectHealthRequested: () {},
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();

              expect(container.read(todayHealthPromptProvider(today)), want);
              // What Today shows agrees with it, and never both.
              expect(
                card,
                want == TodayHealthPrompt.calAiCard
                    ? findsOneWidget
                    : findsNothing,
              );
              expect(
                pill,
                want == TodayHealthPrompt.connectHealth
                    ? findsOneWidget
                    : findsNothing,
              );
            });
          }
        }
      }
    }

    test('an unreadable record counts as unanswered: the card', () async {
      final container = ProviderContainer.test(
        overrides: [
          ...appProviderOverridesFor(isIOS: false),
          healthKitRepositoryProvider.overrideWithValue(
            InMemoryHealthKitRepository(),
          ),
          checkInClockProvider.overrideWithValue(() => clock),
          calAiCardSnoozeStoreProvider.overrideWithValue(snooze),
          onboardingSupportAvailableProvider.overrideWithValue(true),
          onboardingRepositoryProvider.overrideWithValue(
            InMemoryOnboardingRepository()..makeUnreadable(),
          ),
        ],
      );
      final prompt = todayHealthPromptProvider(today);
      container.listen(prompt, (_, _) {});
      await container.read(healthAccessControllerProvider.future);
      await container.read(calAiCardSnoozeProvider.future);
      await container.read(onboardingFoodTrackingProvider.future);
      expect(container.read(prompt), TodayHealthPrompt.calAiCard);
    });

    test('while the record is still loading: the card (unanswered)', () async {
      final record = Completer<Result<OnboardingRecord>>();
      final container = ProviderContainer.test(
        overrides: [
          ...appProviderOverridesFor(isIOS: false),
          healthKitRepositoryProvider.overrideWithValue(
            InMemoryHealthKitRepository(),
          ),
          checkInClockProvider.overrideWithValue(() => clock),
          calAiCardSnoozeStoreProvider.overrideWithValue(snooze),
          onboardingSupportAvailableProvider.overrideWithValue(true),
          onboardingRepositoryProvider.overrideWithValue(
            _PendingOnboardingRepository(record),
          ),
        ],
      );
      final prompt = todayHealthPromptProvider(today);
      container.listen(prompt, (_, _) {});
      await container.read(healthAccessControllerProvider.future);
      await container.read(calAiCardSnoozeProvider.future);
      expect(container.read(prompt), TodayHealthPrompt.calAiCard);

      // The answer arrives: another Health app, so the pill instead.
      record.complete(
        const Ok(
          OnboardingRecord(
            completed: true,
            aboutMe: AboutMe(tracking: FoodTracking.otherHealthApp),
          ),
        ),
      );
      await container.read(onboardingFoodTrackingProvider.future);
      expect(container.read(prompt), TodayHealthPrompt.connectHealth);
    });

    test('nothing on the Mac', () {
      final container = ProviderContainer.test(
        overrides: appProviderOverridesFor(isIOS: false),
      );
      expect(
        container.read(todayHealthPromptProvider(today)),
        TodayHealthPrompt.none,
      );
    });
  });

  group('FileCalAiCardSnoozeStore', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('cal_ai_snooze'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('round-trips the time, and starts empty', () async {
      final file = File('${dir.path}/snooze.txt');
      final store = FileCalAiCardSnoozeStore(() async => file);
      expect(await store.read(), isNull);

      final at = DateTime(2026, 10, 27, 9, 30);
      await store.write(at);
      expect(await FileCalAiCardSnoozeStore(() async => file).read(), at);
    });

    test('unreadable content or a failing lookup is "never tapped"', () async {
      final file = File('${dir.path}/snooze.txt')..writeAsStringSync('?');
      expect(await FileCalAiCardSnoozeStore(() async => file).read(), isNull);

      final broken = FileCalAiCardSnoozeStore(
        () async => throw const FileSystemException('no support directory'),
      );
      expect(await broken.read(), isNull);
      await broken.write(DateTime(2026, 10, 27)); // logged, not thrown
    });
  });
}

/// An onboarding store whose read answers when [reply] completes.
class _PendingOnboardingRepository extends InMemoryOnboardingRepository {
  _PendingOnboardingRepository(this.reply);

  final Completer<Result<OnboardingRecord>> reply;

  @override
  ResultFuture<OnboardingRecord> read() => reply.future;
}
