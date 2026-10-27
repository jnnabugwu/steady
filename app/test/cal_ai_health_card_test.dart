import 'dart:io';

import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_data/health_sync_data.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:steady/cal_ai_health_card.dart';
import 'package:steady/providers.dart';
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
