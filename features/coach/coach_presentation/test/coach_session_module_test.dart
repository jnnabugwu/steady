import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/coach_container.dart';
import 'helpers/fake_coach_consent_repository.dart';
import 'helpers/fake_coach_model.dart';
import 'helpers/fake_coach_repository.dart';

void main() {
  late FakeCoachModel model;
  late FakeCoachRepository repository;
  late int closed;
  late int consentAsks;
  FakeCoachConsentRepository? consent;

  setUp(() {
    model = FakeCoachModel(manualReplies: true);
    repository = FakeCoachRepository();
    closed = 0;
    consentAsks = 0;
    consent = null;
  });

  Future<void> pump(
    WidgetTester tester, {
    bool accessibleNavigation = false,
    bool disableAnimations = false,
    bool consentGiven = true,
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: coachTestOverrides(
          model: model,
          repository: repository,
          consentGiven: consentGiven,
          consent: consent,
        ),
        child: ShadcnApp(
          theme: steadyTheme,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                accessibleNavigation: accessibleNavigation,
                disableAnimations: disableAnimations,
              ),
              child: CoachSessionModule(
                onClosed: () => closed++,
                onConsentRequested: () => consentAsks++,
              ),
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

    model.say('You logged');
    await tester.pump();
    expect(find.text('You logged'), findsOneWidget);
    expect(find.byKey(const Key('coachTyping')), findsNothing);

    model.say('You logged five days.');
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
    model.say('Tuesday was a');
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

  testWidgets('a refusal shows the help line, and the partial reply goes', (
    tester,
  ) async {
    await pump(tester);
    await send(tester, 'Everything feels out of control.');
    model.say('Something the coach');
    await tester.pump();
    expect(find.text('Something the coach'), findsOneWidget);
    model.fail(const CoachRefusalFailure());
    await tester.pump();
    await tester.pump();
    expect(find.text('Something the coach'), findsNothing);
    expect(find.byKey(const Key('coachHelpCard')), findsOneWidget);
    expect(find.text(CoachCopy.helpLine), findsOneWidget);
    expect(find.byKey(const Key('coachReplyFailure')), findsOneWidget);
  });

  final replyFailures = <Failure, String>{
    const CoachServerFailure():
        "The coach couldn't reply just now. Try sending it again.",
    const CoachOfflineFailure():
        "Couldn't reach the coach. Check your connection and try sending it "
        'again.',
    const CoachRateLimitedFailure(retryAfter: Duration(hours: 5)):
        'The coach has reached its limit for today. Try again in about 5 '
        'hours.',
  };
  for (final MapEntry(key: failure, value: line) in replyFailures.entries) {
    testWidgets('a failed reply (${failure.runtimeType}) says so, without '
        'the help line', (tester) async {
      await pump(tester);
      await send(tester, 'Hi');
      model.fail(failure);
      await tester.pump();
      await tester.pump();
      expect(find.text(line), findsOneWidget);
      expect(find.byKey(const Key('coachHelpCard')), findsNothing);
      expect(find.byKey(const Key('coachMessageField')), findsOneWidget);
    });
  }

  final reasons = <CoachUnavailableFailure, (String, String)>{
    const CoachConsentNotGivenFailure(): (
      'The coach is off',
      'It asks before it sends anything',
    ),
    const CoachTurnedOffFailure(): ('The coach is off right now', 'later'),
    const CoachDeviceNotVerifiedFailure(): (
      "The coach can't run on this iPhone",
      'couldn’t verify this iPhone',
    ),
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

  testWidgets('without consent: "The coach is off", no message box, no '
      'Check again, and nothing sent', (tester) async {
    await pump(tester, consentGiven: false);
    expect(find.text('The coach is off'), findsOneWidget);
    expect(find.byKey(const Key('coachMessageField')), findsNothing);
    expect(find.byKey(const Key('coachCheckAgain')), findsNothing);
    expect(model.requests, isEmpty);
    expect(model.availabilityChecks, 0);
  });

  testWidgets('without consent, "Turn on the coach" asks for it; once given, '
      'the session starts by itself', (tester) async {
    consent = FakeCoachConsentRepository();
    await pump(tester);
    await tester.tap(find.byKey(const Key('coachTurnOn')));
    expect(consentAsks, 1);
    expect(model.requests, isEmpty);

    // What the app's consent screen does on "Allow and continue".
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CoachSessionModule)),
    );
    await container.read(coachConsentGivenProvider.notifier).giveCoachConsent();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('coachUnavailableCard')), findsNothing);
    expect(find.byKey(const Key('coachMessageField')), findsOneWidget);
    expect(model.requests, isEmpty);
  });

  testWidgets('turned off mid-reply: the reply stops, its text goes, and the '
      'conversation stays with "Turn on the coach"', (tester) async {
    consent = FakeCoachConsentRepository(agreed: CoachConsent.currentVersion);
    await pump(tester);
    await send(tester, 'Hi');
    model.say('Tuesday was');
    await tester.pump();
    expect(find.textContaining('Tuesday was'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(CoachSessionModule)),
    );
    await container
        .read(coachConsentGivenProvider.notifier)
        .withdrawCoachConsent();
    await tester.pump();
    await tester.pump();
    expect(model.cancelled, isTrue);
    expect(find.textContaining('Tuesday was'), findsNothing);
    expect(find.text('The coach is off'), findsOneWidget);
    expect(find.byKey(const Key('coachTurnOn')), findsOneWidget);
    // What the person said is still there.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is CoachMessageBubble &&
            w.role == CoachMessageRole.user &&
            w.text == 'Hi',
      ),
      findsOneWidget,
    );
    expect(model.replyRequests, hasLength(1));
  });

  testWidgets('"Check again" on the session screen starts the coach once it '
      'can', (tester) async {
    model.availability = const Err(CoachTurnedOffFailure());
    await pump(tester);
    expect(find.byKey(const Key('coachMessageField')), findsNothing);

    model.availability = const Ok(unit);
    await tester.tap(find.byKey(const Key('coachCheckAgain')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('coachUnavailableCard')), findsNothing);
    expect(find.byKey(const Key('coachMessageField')), findsOneWidget);
  });

  testWidgets('a start that fails offers Try again, which starts the coach', (
    tester,
  ) async {
    model.availability = const Err(UnknownFailure('boom'));
    await pump(tester);
    expect(find.byKey(const Key('coachFailedToStart')), findsOneWidget);

    model.availability = const Ok(unit);
    await tester.tap(find.byKey(const Key('coachRetryStart')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('coachMessageField')), findsOneWidget);
  });

  testWidgets('the coach turned off mid-conversation keeps the conversation '
      'on screen, with Check again and End', (tester) async {
    await pump(tester);
    model.failNext = const CoachTurnedOffFailure();
    await send(tester, 'Hello');
    expect(find.byKey(const Key('coachUnavailableCard')), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
    expect(find.byKey(const Key('coachSessionEnd')), findsOneWidget);

    await tester.tap(find.byKey(const Key('coachCheckAgain')));
    await tester.pump();
    await tester.pump();
    model.say('Still here.');
    await model.finish();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('coachUnavailableCard')), findsNothing);
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Still here.'), findsOneWidget);
  });

  testWidgets('a reply cut off at the token limit is shown as it came and '
      'offers Keep going, which asks the coach to carry on', (tester) async {
    model
      ..manualReplies = false
      ..replyFor = ((_) => 'You logged five days. On Friday you')
      ..stopReasonNext = CoachStopReason.maxTokens;
    await pump(tester);
    await send(tester, 'How was my week?');
    expect(find.text('You logged five days. On Friday you'), findsOneWidget);
    final keepGoing = find.byKey(const Key('coachKeepGoing'));
    expect(keepGoing, findsOneWidget);
    expect(tester.getSize(keepGoing).height, greaterThanOrEqualTo(44));

    model.replyFor = (_) => 'On Friday you logged partly.';
    await tester.tap(keepGoing);
    await tester.pump();
    await tester.pump();
    expect(find.text('Keep going'), findsOneWidget); // the person's turn
    expect(find.text('On Friday you logged partly.'), findsOneWidget);
    expect(keepGoing, findsNothing);
  });

  testWidgets('no "Check again" where it could never help', (tester) async {
    model.availability = const Err(CoachDeviceNotVerifiedFailure());
    await pump(tester);
    expect(find.byKey(const Key('coachCheckAgain')), findsNothing);
  });

  testWidgets('with a screen reader on, a finished reply is announced once, '
      'never a snapshot', (tester) async {
    final announced = recordAnnouncements(tester);
    await pump(tester, accessibleNavigation: true);
    await send(tester, 'Hi');
    model
      ..say('Hel')
      ..say('Hello there.');
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
