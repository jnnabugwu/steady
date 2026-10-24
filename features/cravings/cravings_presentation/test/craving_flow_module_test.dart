import 'package:cravings_domain/cravings_domain.dart';
import 'package:cravings_presentation/cravings_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fake_craving_repository.dart';

/// Words the flow must never show (docs/research/craving_support.md §4).
final _forbidden = RegExp(
  'calor|kcal|streak|score|resist|willpower|give in|gave in|slip|cheat|'
  'great job|well done|proud|success|fail|stay strong|junk|treat',
  caseSensitive: false,
);

void main() {
  late FakeCravingRepository repository;
  late int closed;
  late int finished;

  setUp(() {
    repository = FakeCravingRepository();
    closed = 0;
    finished = 0;
  });

  Future<void> pump(
    WidgetTester tester, {
    bool disableAnimations = false,
    bool accessibleNavigation = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cravingRepositoryProvider.overrideWithValue(repository),
          cravingClockProvider.overrideWithValue(
            () => DateTime(2026, 10, 23, 20),
          ),
          cravingIdGeneratorProvider.overrideWithValue(() => 'id-1'),
        ],
        child: ShadcnApp(
          theme: steadyTheme,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: disableAnimations,
                accessibleNavigation: accessibleNavigation,
              ),
              child: CravingFlowModule(
                onClosed: () => closed++,
                onFinished: () => finished++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  void expectNoForbiddenCopy(WidgetTester tester) {
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      final data = text.data ?? '';
      expect(_forbidden.hasMatch(data), isFalse, reason: data);
    }
  }

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pump();
  }

  testWidgets('the full path with the minute, ending at "It passed"', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Having a craving?'), findsOneWidget);
    expect(find.text('How strong is it?'), findsOneWidget);
    expectNoForbiddenCopy(tester);

    await tap(tester, 'cravingIntensityBefore_4');
    expect(find.text("What's behind it?"), findsOneWidget);
    for (final label in [
      'Hungry',
      'Bored',
      'Stressed',
      'Tired',
      'Habit / saw it',
      'Not sure',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    await tap(tester, 'cravingReason_stressed');
    await tap(tester, 'cravingReason_tired');
    expectNoForbiddenCopy(tester);
    await tap(tester, 'cravingReasonsNext');

    expect(find.text('Want to take a minute with it?'), findsOneWidget);
    expectNoForbiddenCopy(tester);
    await tap(tester, 'cravingTakeMinute');

    expect(find.byType(CravingMinute), findsOneWidget);
    expect(find.text(CravingMinute.prompts.first), findsOneWidget);
    expect(find.text('1:15'), findsOneWidget);
    await tester.pump(const Duration(seconds: 16));
    expect(find.text(CravingMinute.prompts[1]), findsOneWidget);
    expect(find.text('0:59'), findsOneWidget);
    expectNoForbiddenCopy(tester);

    // It ends on its own.
    await tester.pump(const Duration(seconds: 60));
    await tester.pump();
    expect(find.byType(CravingMinute), findsNothing);
    expect(find.text('Still want it?'), findsOneWidget);
    expect(find.text('How strong is it now?'), findsOneWidget);

    await tap(tester, 'cravingIntensityAfter_2');
    await tap(tester, 'cravingOutcome_passed');
    await tester.pump();

    expect(find.text('Noted.'), findsOneWidget);
    expectNoForbiddenCopy(tester);
    final saved = repository.events.single;
    expect(saved.intensityBefore, 4);
    expect(saved.intensityAfter, 2);
    expect(saved.reasons, {CravingReason.stressed, CravingReason.tired});
    expect(saved.tookMinute, isTrue);
    expect(saved.outcome, CravingOutcome.passed);

    // No close button at an ending; Done finishes.
    expect(find.byKey(const Key('cravingCloseButton')), findsNothing);
    await tap(tester, 'cravingDone');
    expect(finished, 1);
    expect(closed, 0);
  });

  testWidgets('hungry ends with "eating something is a good call", no wait', (
    tester,
  ) async {
    await pump(tester);
    await tap(tester, 'cravingIntensityBefore_3');
    await tap(tester, 'cravingReason_hungry');
    await tap(tester, 'cravingReasonsNext');
    await tester.pump();

    expect(
      find.text(
        'Sounds like you might actually be hungry. Eating something is a '
        'good call.',
      ),
      findsOneWidget,
    );
    expect(find.text('Want to take a minute with it?'), findsNothing);
    expect(repository.events.single.outcome, CravingOutcome.hungry);
    await tap(tester, 'cravingDone');
    expect(finished, 1);
  });

  testWidgets('"Not now" skips the minute', (tester) async {
    await pump(tester);
    await tap(tester, 'cravingIntensityBefore_2');
    await tap(tester, 'cravingReasonsNext');
    await tap(tester, 'cravingNotNow');

    expect(find.text('Still want it?'), findsOneWidget);
    await tap(tester, 'cravingOutcome_havingIt');
    await tester.pump();

    expect(
      find.text("That's okay. Log it in Cal AI when you're ready."),
      findsOneWidget,
    );
    expect(repository.events.single.tookMinute, isFalse);
    expect(repository.events.single.reasons, isEmpty);
  });

  testWidgets('"Not sure" has its own neutral line', (tester) async {
    await pump(tester);
    await tap(tester, 'cravingIntensityBefore_5');
    await tap(tester, 'cravingReasonsNext');
    await tap(tester, 'cravingNotNow');
    await tap(tester, 'cravingOutcome_notSure');
    await tester.pump();
    expect(
      find.text("That's fine. You can check back in anytime."),
      findsOneWidget,
    );
  });

  for (final key in ['cravingMinuteSkip', 'cravingMinuteDoneEarly']) {
    testWidgets('$key ends the minute early', (tester) async {
      await pump(tester);
      await tap(tester, 'cravingIntensityBefore_3');
      await tap(tester, 'cravingReasonsNext');
      await tap(tester, 'cravingTakeMinute');
      await tester.pump(const Duration(seconds: 5));

      await tap(tester, key);
      expect(find.text('Still want it?'), findsOneWidget);
      // The timer is gone: nothing fires later.
      await tester.pump(const Duration(seconds: 90));
      expect(find.text('Still want it?'), findsOneWidget);
    });
  }

  testWidgets('closing partway records nothing', (tester) async {
    await pump(tester);
    await tap(tester, 'cravingIntensityBefore_3');
    await tap(tester, 'cravingCloseButton');
    expect(closed, 1);
    expect(repository.saveCalls, isEmpty);
  });

  testWidgets('a failed save says so gently and can be retried', (
    tester,
  ) async {
    repository.onSave = (_) async =>
        const Err<Unit>(UnknownFailure('disk full'));
    await pump(tester);
    await tap(tester, 'cravingIntensityBefore_3');
    await tap(tester, 'cravingReasonsNext');
    await tap(tester, 'cravingNotNow');
    await tap(tester, 'cravingOutcome_passed');
    await tester.pump();

    expect(find.textContaining("couldn't be saved"), findsOneWidget);
    repository.onSave = null;
    await tap(tester, 'cravingRetrySave');
    await tester.pump();
    expect(find.textContaining("couldn't be saved"), findsNothing);
    expect(repository.events, hasLength(1));
  });

  testWidgets('every control has a label and a 44pt target', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    expect(find.bySemanticsLabel('1 of 5, mild'), findsOneWidget);
    expect(find.bySemanticsLabel('5 of 5, strong'), findsOneWidget);
    expect(find.bySemanticsLabel('Close'), findsOneWidget);
    for (var i = 1; i <= 5; i++) {
      final size = tester.getSize(find.byKey(Key('cravingIntensityBefore_$i')));
      expect(size.height, greaterThanOrEqualTo(44));
      expect(size.width, greaterThanOrEqualTo(44));
    }
    await tap(tester, 'cravingIntensityBefore_3');
    for (final reason in CravingReason.values) {
      final size = tester.getSize(
        find.byKey(Key('cravingReason_${reason.name}')),
      );
      expect(size.height, greaterThanOrEqualTo(44));
    }
    await tap(tester, 'cravingReason_bored');
    expect(
      tester.getSemantics(find.byKey(const Key('cravingReason_bored'))),
      matchesSemantics(
        label: 'Bored',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        isEnabled: true,
        hasEnabledState: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    semantics.dispose();
  });

  group('the minute', () {
    Future<void> openMinute(
      WidgetTester tester, {
      bool disableAnimations = false,
      bool accessibleNavigation = false,
    }) async {
      await pump(
        tester,
        disableAnimations: disableAnimations,
        accessibleNavigation: accessibleNavigation,
      );
      await tap(tester, 'cravingIntensityBefore_3');
      await tap(tester, 'cravingReasonsNext');
      await tap(tester, 'cravingTakeMinute');
    }

    double circleScale(WidgetTester tester) => tester
        .widget<ScaleTransition>(
          find.ancestor(
            of: find.byKey(const Key('cravingMinuteCircle')),
            matching: find.byType(ScaleTransition),
          ),
        )
        .scale
        .value;

    testWidgets('the circle pulses slowly', (tester) async {
      await openMinute(tester);
      final first = circleScale(tester);
      await tester.pump(const Duration(milliseconds: 2500));
      expect(circleScale(tester), isNot(first));
    });

    testWidgets('with reduced motion the circle is still', (tester) async {
      await openMinute(tester, disableAnimations: true);
      final first = circleScale(tester);
      await tester.pump(const Duration(milliseconds: 2500));
      expect(circleScale(tester), first);
      // The last prompt doesn't ask you to follow a still circle.
      await tester.pump(const Duration(seconds: 61));
      expect(find.text(CravingMinute.stillLastPrompt), findsOneWidget);
    });

    testWidgets('the countdown reads a calm estimate, not every second', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await openMinute(tester);
      expect(find.bySemanticsLabel('About 75 seconds left'), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
      // 68 seconds left still reads as 75: it moves in 15-second steps.
      expect(find.bySemanticsLabel('About 75 seconds left'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('with a screen reader on, prompts are announced sparingly', (
      tester,
    ) async {
      final announced = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (
            message,
          ) async {
            final map = message! as Map<Object?, Object?>;
            if (map['type'] == 'announce') {
              announced.add(
                (map['data']! as Map<Object?, Object?>)['message']! as String,
              );
            }
            return null;
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
              SystemChannels.accessibility,
              null,
            ),
      );

      await openMinute(tester, accessibleNavigation: true);
      await tester.pump(const Duration(seconds: 74));

      expect(announced, [
        CravingMinute.prompts[0],
        CravingMinute.prompts[1],
        CravingMinute.prompts[2],
        // The fourth prompt arrives with 30 seconds left: one announcement.
        '${CravingMinute.prompts[3]} About 30 seconds left.',
        CravingMinute.prompts[4],
      ]);
    });

    testWidgets('without a screen reader nothing is announced', (tester) async {
      final announced = <Object?>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (
            message,
          ) async {
            announced.add(message);
            return null;
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
              SystemChannels.accessibility,
              null,
            ),
      );
      await openMinute(tester);
      await tester.pump(const Duration(seconds: 40));
      expect(
        announced.whereType<Map<Object?, Object?>>().where(
          (m) => m['type'] == 'announce',
        ),
        isEmpty,
      );
    });
  });
}
