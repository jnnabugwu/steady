import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/coach_container.dart';
import 'helpers/fake_coach_model.dart';
import 'helpers/fake_coach_repository.dart';

void main() {
  late FakeCoachModel model;
  late FakeCoachRepository repository;
  late int closed;

  setUp(() {
    model = FakeCoachModel(manualReplies: true);
    repository = FakeCoachRepository();
    closed = 0;
  });

  Future<void> pump(
    WidgetTester tester, {
    bool accessibleNavigation = false,
    bool disableAnimations = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: coachTestOverrides(model: model, repository: repository),
        child: ShadcnApp(
          theme: steadyTheme,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                accessibleNavigation: accessibleNavigation,
                disableAnimations: disableAnimations,
              ),
              child: CoachSessionModule(onClosed: () => closed++),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> send(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('coachMessageField')), text);
    await tester.tap(find.byKey(const Key('coachSend')));
    await tester.pump();
    await tester.pump();
  }

  /// Records screen-reader announcements.
  List<String> recordAnnouncements(WidgetTester tester) {
    final announced = <String>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (message) async {
        final map = message! as Map<Object?, Object?>;
        if (map['type'] == 'announce') {
          announced.add(
            (map['data']! as Map<Object?, Object?>)['message']! as String,
          );
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
            SystemChannels.accessibility,
            null,
          ),
    );
    return announced;
  }

  testWidgets('shows the not-medical-advice note and a hint before the '
      'first message', (tester) async {
    await pump(tester);
    expect(find.text(CoachCopy.notMedicalAdvice), findsOneWidget);
    expect(find.byKey(const Key('coachSessionHint')), findsOneWidget);
    expect(find.byKey(const Key('coachSessionEnd')), findsNothing);
  });

  testWidgets('streams the reply, with dots before the first snapshot', (
    tester,
  ) async {
    await pump(tester);
    await send(tester, 'How was my week?');

    expect(find.text('How was my week?'), findsOneWidget);
    expect(find.byKey(const Key('coachTyping')), findsOneWidget);
    expect(find.byKey(const Key('coachStop')), findsOneWidget);

    model.reply('You logged');
    await tester.pump();
    expect(find.text('You logged'), findsOneWidget);
    expect(find.byKey(const Key('coachTyping')), findsNothing);

    model.reply('You logged five days.');
    await tester.pump();
    expect(find.text('You logged five days.'), findsOneWidget);
    expect(find.text('You logged'), findsNothing);

    await model.finish();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('coachSend')), findsOneWidget);
    expect(find.byKey(const Key('coachReply')), findsNothing);
    expect(find.text('You logged five days.'), findsOneWidget);
    expect(find.byKey(const Key('coachSessionEnd')), findsOneWidget);
  });

  testWidgets('the stop button stops the reply and keeps the words so far', (
    tester,
  ) async {
    await pump(tester);
    await send(tester, 'Tell me about Tuesday.');
    model.reply('Tuesday was a');
    await tester.pump();

    await tester.tap(find.byKey(const Key('coachStop')));
    await tester.pump();
    await tester.pump();
    expect(model.cancelled, isTrue);
    expect(find.text('Tuesday was a'), findsOneWidget);
    expect(find.byKey(const Key('coachSend')), findsOneWidget);
  });

  testWidgets('End writes the summary, shows it, and Done closes', (
    tester,
  ) async {
    model.manualReplies = false;
    await pump(tester);
    await send(tester, 'I skipped Wednesday.');
    await tester.pump();

    await tester.tap(find.byKey(const Key('coachSessionEnd')));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('coachSummary')), findsOneWidget);
    expect(find.text('A short summary.'), findsOneWidget);
    expect(find.byKey(const Key('coachMessageField')), findsNothing);
    expect(repository.sessions.single.summary, 'A short summary.');

    await tester.tap(find.byKey(const Key('coachSessionDone')));
    expect(closed, 1);
  });

  testWidgets('closing ends the session in the background and leaves at '
      'once', (tester) async {
    model.manualReplies = false;
    await pump(tester);
    await send(tester, 'Hi');
    await tester.pump();
    await tester.tap(find.byKey(const Key('coachSessionClose')));
    expect(closed, 1);
    await tester.pump();
    await tester.pump();
    expect(repository.sessions.single.summary, 'A short summary.');
  });

  testWidgets('a guardrail stop shows the help line', (tester) async {
    await pump(tester);
    await send(tester, 'Everything feels out of control.');
    model.fail(
      const CoachInferenceFailure(
        'guardrail',
        reason: CoachInferenceFailureReason.guardrailViolation,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('coachHelpCard')), findsOneWidget);
    expect(find.text(CoachCopy.helpLine), findsOneWidget);
    expect(find.byKey(const Key('coachReplyFailure')), findsOneWidget);
  });

  testWidgets('another failed reply says so, without the help line', (
    tester,
  ) async {
    await pump(tester);
    await send(tester, 'Hi');
    model.fail(
      const CoachInferenceFailure(
        'slow',
        reason: CoachInferenceFailureReason.timeout,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(
      find.text("The coach couldn't reply just now. Try sending it again."),
      findsOneWidget,
    );
    expect(find.byKey(const Key('coachHelpCard')), findsNothing);
  });

  final reasons = {
    const CoachDeviceNotEligibleFailure(): (
      "The coach isn't available on this iPhone",
      'supports Apple Intelligence',
    ),
    const CoachAppleIntelligenceNotEnabledFailure(): (
      'The coach needs Apple Intelligence',
      'Settings → Apple Intelligence & Siri',
    ),
    const CoachModelNotReadyFailure(): (
      'The coach is still getting ready',
      'still setting up',
    ),
    const CoachOsTooOldFailure(): ('The coach needs iOS 26', 'iOS 26 or later'),
  };
  for (final MapEntry(key: failure, value: (title, line)) in reasons.entries) {
    testWidgets('unavailable (${failure.runtimeType}) says why, plainly', (
      tester,
    ) async {
      model.availability = Err(failure);
      await pump(tester);
      expect(find.byKey(const Key('coachUnavailableCard')), findsOneWidget);
      expect(find.text(title), findsOneWidget);
      expect(find.textContaining(line), findsOneWidget);
      expect(find.byKey(const Key('coachMessageField')), findsNothing);
    });
  }

  testWidgets('with a screen reader on, a finished reply is announced once, '
      'never a snapshot', (tester) async {
    final announced = recordAnnouncements(tester);
    await pump(tester, accessibleNavigation: true);
    await send(tester, 'Hi');
    model
      ..reply('Hel')
      ..reply('Hello there.');
    await tester.pump();
    expect(announced, isEmpty);
    await model.finish();
    await tester.pump();
    await tester.pump();
    expect(announced, ['Coach: Hello there.']);
  });

  testWidgets('without a screen reader nothing is announced', (tester) async {
    final announced = recordAnnouncements(tester);
    model.manualReplies = false;
    await pump(tester);
    await send(tester, 'Hi');
    await tester.pump();
    expect(announced, isEmpty);
  });

  testWidgets('the typing dots stay still with Reduce Motion', (tester) async {
    await pump(tester, disableAnimations: true);
    await send(tester, 'Hi');
    // A repeating animation would never settle.
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('coachTyping')), findsOneWidget);
  });

  testWidgets('targets are at least 44pt and labelled', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    expect(
      tester.getSize(find.byKey(const Key('coachSend'))).height,
      greaterThanOrEqualTo(44),
    );
    expect(find.bySemanticsLabel('Send'), findsOneWidget);
    expect(find.bySemanticsLabel('Close'), findsOneWidget);
    await send(tester, 'Hi');
    expect(find.bySemanticsLabel('Stop reply'), findsOneWidget);
    expect(find.bySemanticsLabel('You: Hi'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('uses no red, yellow or green, only the teal and neutral '
      'palette', (tester) async {
    model.manualReplies = false;
    await pump(tester);
    await send(tester, 'Hi');
    await tester.pump();
    for (final box in tester.widgetList<DecoratedBox>(
      find.byType(DecoratedBox),
    )) {
      final decoration = box.decoration;
      if (decoration is BoxDecoration && decoration.color != null) {
        expect(_isTrafficLight(decoration.color!), isFalse);
      }
    }
  });
}

/// Whether [color] reads as red, yellow or green: saturated, in those hue
/// bands. The coach palette is teal (hue ≈ 172°) and near-neutral greys.
bool _isTrafficLight(Color color) {
  final hsv = HSVColor.fromColor(color);
  if (hsv.saturation < 0.35 || hsv.value < 0.25) return false;
  final hue = hsv.hue;
  return hue < 20 ||
      hue > 340 ||
      (hue > 40 && hue < 70) ||
      (hue > 90 && hue < 150);
}
