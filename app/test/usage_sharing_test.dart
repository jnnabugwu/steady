import 'package:analytics/analytics.dart';
import 'package:coach_domain/coach_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_data/health_sync_data.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:steady/health_access.dart';
import 'package:steady/main.dart';
import 'package:steady/providers.dart';
import 'package:steady/usage_sharing.dart';

/// Usage sharing (TestFlight only): PostHog is set up only on a TestFlight
/// or debug install, events wait for that answer, the Settings switch turns
/// it off for good, and the app-level events carry yes/nos and labels only.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePostHogClient client;
  late _FakeUsageSharingStore store;

  setUp(() {
    client = _FakePostHogClient();
    store = _FakeUsageSharingStore();
  });

  PostHogAnalytics analyticsFrom(InstallSource source) => PostHogAnalytics(
    client: client,
    installSource: _FixedInstallSource(source),
    store: store,
  );

  group('PostHogAnalytics', () {
    test(
      'a TestFlight install sets PostHog up and sends what waited',
      () async {
        final analytics = analyticsFrom(InstallSource.testFlight)
          ..record(AnalyticsEvent.cravingFlowFinished);
        expect(client.captured, isEmpty);

        expect(await analytics.status, UsageSharingStatus.on);
        analytics.record(AnalyticsEvent.checkInLogged(status: 'logged'));

        expect(client.setups, [false]);
        expect(client.sent, [
          ['craving_flow_finished', <String, Object>{}],
          [
            'check_in_logged',
            {'status': 'logged'},
          ],
        ]);
      },
    );

    test('a debug install is offered too', () async {
      expect(
        await analyticsFrom(InstallSource.development).status,
        UsageSharingStatus.on,
      );
    });

    for (final source in [InstallSource.appStore, InstallSource.unknown]) {
      test('$source never sets PostHog up and drops every event', () async {
        final analytics = analyticsFrom(source)
          ..record(AnalyticsEvent.cravingFlowFinished);

        expect(await analytics.status, UsageSharingStatus.notOffered);
        analytics.record(AnalyticsEvent.cravingFlowFinished);

        expect(client.setups, isEmpty);
        expect(client.captured, isEmpty);
      });
    }

    test('turned off before: set up opted out, and nothing is sent', () async {
      store.off = true;
      final analytics = analyticsFrom(InstallSource.testFlight)
        ..record(AnalyticsEvent.cravingFlowFinished);

      expect(await analytics.status, UsageSharingStatus.off);
      analytics.record(AnalyticsEvent.cravingFlowFinished);

      expect(client.setups, [true]);
      expect(client.captured, isEmpty);
    });

    test('turning it off stops sending and is remembered', () async {
      final analytics = analyticsFrom(InstallSource.testFlight);
      await analytics.status;

      expect(await analytics.share(on: false), UsageSharingStatus.off);
      analytics.record(AnalyticsEvent.cravingFlowFinished);
      expect(store.off, isTrue);
      expect(client.optOuts, 1);
      expect(client.captured, isEmpty);

      expect(await analytics.share(on: true), UsageSharingStatus.on);
      analytics.record(AnalyticsEvent.cravingFlowFinished);
      expect(store.off, isFalse);
      expect(client.optIns, 1);
      expect(client.captured, hasLength(1));
    });

    test('a choice that fails to save leaves sharing as it was', () async {
      final analytics = analyticsFrom(InstallSource.testFlight);
      await analytics.status;
      store.failWrites = true;

      await expectLater(analytics.share(on: false), throwsA(anything));
      analytics.record(AnalyticsEvent.cravingFlowFinished);

      expect(client.optOuts, 0);
      expect(client.captured, hasLength(1));
    });

    test('where it is not offered, the switch changes nothing', () async {
      final analytics = analyticsFrom(InstallSource.appStore);
      expect(await analytics.share(on: true), UsageSharingStatus.notOffered);
      expect(store.off, isFalse);
      expect(client.optIns, 0);
    });

    test('a failed setup sends nothing', () async {
      client.failSetup = true;
      final analytics = analyticsFrom(InstallSource.testFlight)
        ..record(AnalyticsEvent.cravingFlowFinished);

      expect(await analytics.status, UsageSharingStatus.notOffered);
      expect(client.captured, isEmpty);
    });
  });

  group('wiring', () {
    test('the app list sends nothing unless main.dart built a sink', () {
      final container = ProviderContainer.test(overrides: appProviderOverrides);
      expect(container.read(analyticsProvider), isA<NoAnalytics>());
    });

    test('with a sink, features record through it', () {
      final analytics = analyticsFrom(InstallSource.testFlight);
      final container = ProviderContainer.test(
        overrides: [
          ...appProviderOverrides,
          postHogAnalyticsProvider.overrideWithValue(analytics),
        ],
      );
      expect(container.read(analyticsProvider), same(analytics));
    });
  });

  test('coachAvailabilityReason maps each unavailable failure', () {
    expect(
      coachAvailabilityReason(const Ok(CoachModelInfo(contextSize: 4096))),
      CoachAvailabilityReason.available,
    );
    expect(
      coachAvailabilityReason(const Err(CoachDeviceNotEligibleFailure())),
      CoachAvailabilityReason.deviceNotEligible,
    );
    expect(
      coachAvailabilityReason(
        const Err(CoachAppleIntelligenceNotEnabledFailure()),
      ),
      CoachAvailabilityReason.appleIntelligenceNotEnabled,
    );
    expect(
      coachAvailabilityReason(const Err(CoachModelNotReadyFailure())),
      CoachAvailabilityReason.modelNotReady,
    );
    expect(
      coachAvailabilityReason(const Err(CoachOsTooOldFailure())),
      CoachAvailabilityReason.osTooOld,
    );
    expect(
      coachAvailabilityReason(const Err(UnknownFailure('channel down'))),
      CoachAvailabilityReason.unknown,
    );
  });

  group('health_connected', () {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    Future<ProviderContainer> refreshWith(
      InMemoryHealthKitRepository health, {
      required PostHogAnalytics analytics,
    }) async {
      await analytics.status;
      final container = ProviderContainer.test(
        overrides: [
          ...appProviderOverridesFor(isIOS: false),
          healthKitRepositoryProvider.overrideWithValue(health),
          postHogAnalyticsProvider.overrideWithValue(analytics),
        ],
      );
      final controller = container.read(
        healthAccessControllerProvider.notifier,
      );
      await controller.refreshHealthData();
      await controller.refreshHealthData();
      return container;
    }

    test('sent once per launch, with yes/nos and never the numbers', () async {
      await refreshWith(
        InMemoryHealthKitRepository(
          days: [HealthDayTotals(date: yesterday, steps: 8123)],
        ),
        analytics: analyticsFrom(InstallSource.testFlight),
      );

      expect(client.sent, [
        [
          'health_connected',
          {'steps': true, 'calories_eaten': false},
        ],
      ]);
    });

    test('no data back reads as not connected', () async {
      await refreshWith(
        InMemoryHealthKitRepository(),
        analytics: analyticsFrom(InstallSource.testFlight),
      );

      expect(client.sent, [
        [
          'health_connected',
          {'steps': false, 'calories_eaten': false},
        ],
      ]);
    });

    test('where nothing is sent, Health is not read for it', () async {
      final health = InMemoryHealthKitRepository(
        status: HealthAuthorizationStatus.requested,
      );
      await refreshWith(
        health,
        analytics: analyticsFrom(InstallSource.appStore),
      );

      expect(health.dailyTotalsCalls, 0);
      expect(client.captured, isEmpty);
    });
  });

  group('UsageSharingCard', () {
    final card = find.byKey(const Key('usageSharingCard'));
    final toggle = find.byKey(const Key('usageSharingSwitch'));

    Future<void> pumpSettings(
      WidgetTester tester, {
      PostHogAnalytics? analytics,
    }) async {
      tester.platformDispatcher.defaultRouteNameTestValue = '/settings';
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
      final container = ProviderContainer(
        overrides: [
          ...appProviderOverrides,
          if (analytics != null)
            postHogAnalyticsProvider.overrideWithValue(analytics),
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
    }

    testWidgets('hidden where sharing is not offered', (tester) async {
      await pumpSettings(tester);
      expect(card, findsNothing);
    });

    testWidgets('on TestFlight, the switch turns sharing off', (tester) async {
      final analytics = analyticsFrom(InstallSource.testFlight);
      await pumpSettings(tester, analytics: analytics);
      await tester.scrollUntilVisible(toggle, 200);
      expect(card, findsOneWidget);

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(store.off, isTrue);
      expect(client.optOuts, 1);
    });
  });
}

final class _FixedInstallSource implements InstallSourceReader {
  const _FixedInstallSource(this.source);

  final InstallSource source;

  @override
  Future<InstallSource> read() async => source;
}

final class _FakeUsageSharingStore implements UsageSharingStore {
  bool off = false;
  bool failWrites = false;

  @override
  Future<bool> isOff() async => off;

  @override
  Future<void> setOff({required bool off}) async {
    if (failWrites) throw const UnknownFailure('disk full');
    this.off = off;
  }
}

final class _FakePostHogClient implements PostHogClient {
  final setups = <bool>[];
  final captured = <(String, Map<String, Object>)>[];

  /// [captured] as `[name, properties]` lists, which `equals` compares
  /// deeply (a record compares its map by identity).
  List<List<Object>> get sent => [
    for (final (name, properties) in captured) [name, properties],
  ];
  int optIns = 0;
  int optOuts = 0;
  bool failSetup = false;

  @override
  Future<void> setup({required bool optOut}) async {
    if (failSetup) throw StateError('no network');
    setups.add(optOut);
  }

  @override
  Future<void> capture(String name, Map<String, Object> properties) async =>
      captured.add((name, properties));

  @override
  Future<void> optIn() async => optIns++;

  @override
  Future<void> optOut() async => optOuts++;
}
