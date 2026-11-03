import 'dart:async';

import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/coach_container.dart';
import 'helpers/fake_coach_model.dart';
import 'helpers/fake_coach_repository.dart';

void main() {
  late FakeCoachModel model;
  late FakeCoachRepository repository;
  late ProviderContainer container;
  final provider = coachSessionControllerProvider(
    CoachSessionKind.chat,
    'session-1',
  );

  setUp(() {
    model = FakeCoachModel();
    repository = FakeCoachRepository();
  });

  /// A container with the session's provider listened to, after its start
  /// has settled.
  Future<CoachSessionController> start({bool consentGiven = true}) async {
    container = ProviderContainer.test(
      overrides: coachTestOverrides(
        model: model,
        repository: repository,
        consentGiven: consentGiven,
      ),
    )..listen(provider, (_, _) {});
    await pumpEventQueue();
    // The lint takes the notifier for a Future; it isn't one.
    // ignore: async_return_with_no_await
    return container.read(provider.notifier);
  }

  CoachSessionState state() => container.read(provider);

  group('starting', () {
    test('without consent: unavailable, and the model is never asked or '
        'sent anything', () async {
      final controller = await start(consentGiven: false);
      expect(state().phase, CoachSessionPhase.unavailable);
      expect(state().failure, isA<CoachConsentNotGivenFailure>());
      expect(model.availabilityChecks, 0);

      await controller.sendCoachMessage('Hi');
      await controller.retryCoachStart();
      expect(state().failure, isA<CoachConsentNotGivenFailure>());
      expect(model.requests, isEmpty);
    });

    final reasons = <CoachUnavailableFailure>[
      const CoachTurnedOffFailure(),
      const CoachDeviceNotVerifiedFailure(),
    ];
    for (final reason in reasons) {
      test(
        'unavailable (${reason.runtimeType}): says why, sends nothing',
        () async {
          model.availability = Err(reason);
          await start();
          expect(state().phase, CoachSessionPhase.unavailable);
          expect(state().failure, reason);
          expect(model.requests, isEmpty);
        },
      );
    }

    test('any other failure to start says so', () async {
      model.availability = const Err(UnknownFailure('boom'));
      await start();
      expect(state().phase, CoachSessionPhase.failedToStart);
    });

    test('is ready without sending anything', () async {
      await start();
      expect(state().phase, CoachSessionPhase.ready);
      expect(model.requests, isEmpty);
      expect(state().session.startedAt, coachTestNow);
    });

    test('nothing is stored before the person says something', () async {
      await start();
      expect(repository.sessions, isEmpty);
    });
  });

  group('sendCoachMessage', () {
    test("sends the chat kind, the week's data and the message", () async {
      final controller = await start();
      await controller.sendCoachMessage('  How was my week?  ');
      final request = model.requests.single;
      expect(request.kind, CoachRequestKind.chat);
      expect(
        request.weekContext,
        contains('Sat Oct 24: logged fully; ate 1800 kcal'),
      );
      expect(request.weekContext!.length, lessThanOrEqualTo(1200));
      expect(request.turns, const [CoachTurn.person('How was my week?')]);
    });

    test('streams the reply snapshot by snapshot, then saves it', () async {
      model.manualReplies = true;
      final controller = await start();
      unawaited(controller.sendCoachMessage('How was my week?'));
      await pumpEventQueue();

      expect(state().phase, CoachSessionPhase.replying);
      expect(state().session.messages.single.text, 'How was my week?');
      // Saved as soon as the person said it.
      expect(repository.sessions.single.messages, hasLength(1));

      model.say('You logged');
      await pumpEventQueue();
      expect(state().reply, 'You logged');
      model.say('You logged Saturday.');
      await pumpEventQueue();
      expect(state().reply, 'You logged Saturday.');

      await model.finish();
      await pumpEventQueue();
      expect(state().phase, CoachSessionPhase.ready);
      expect(state().reply, isNull);
      expect(state().session.messages.last.role, CoachMessageRole.coach);
      expect(state().session.messages.last.text, 'You logged Saturday.');
      expect(repository.sessions.single.messages, hasLength(2));
    });

    test('every request carries the whole conversation so far', () async {
      model.replyFor = (request) => 'Reply ${request.turns.length}.';
      final controller = await start();
      await controller.sendCoachMessage('One');
      await controller.sendCoachMessage('Two');
      await controller.sendCoachMessage('Three');
      expect(model.requests.last.turns, const [
        CoachTurn.person('One'),
        CoachTurn.coach('Reply 1.'),
        CoachTurn.person('Two'),
        CoachTurn.coach('Reply 3.'),
        CoachTurn.person('Three'),
      ]);
      expect(state().session.messages, hasLength(6));
    });

    test(
      'is ignored while the coach replies, and for an empty message',
      () async {
        model.manualReplies = true;
        final controller = await start();
        await controller.sendCoachMessage('   ');
        expect(model.requests, isEmpty);

        unawaited(controller.sendCoachMessage('One'));
        await pumpEventQueue();
        await controller.sendCoachMessage('Two');
        expect(model.requests, hasLength(1));
        expect(state().session.messages, hasLength(1));
      },
    );

    test('a message is cut to the cap', () async {
      final controller = await start();
      await controller.sendCoachMessage('x' * 5000);
      expect(
        model.requests.single.turns.single,
        CoachTurn.person('x' * coachMaxMessageChars),
      );
    });

    test('a refusal shows the help line and drops the partial reply, from '
        'the screen and from what the coach is sent next', () async {
      model.manualReplies = true;
      final controller = await start();
      unawaited(controller.sendCoachMessage('Hard day.'));
      await pumpEventQueue();
      model.say('Something it');
      await pumpEventQueue();
      model.fail(const CoachRefusalFailure());
      await pumpEventQueue();

      expect(state().phase, CoachSessionPhase.ready);
      expect(state().replyRefused, isTrue);
      expect(state().reply, isNull);
      expect(state().session.messages.single.text, 'Hard day.');

      // The next message clears it, and the refused text never went back.
      model.manualReplies = false;
      await controller.sendCoachMessage('Thanks.');
      expect(state().failure, isNull);
      expect(state().replyRefused, isFalse);
      expect(model.requests.last.turns, const [
        CoachTurn.person('Hard day.'),
        CoachTurn.person('Thanks.'),
      ]);
    });

    for (final failure in <Failure>[
      const CoachOfflineFailure(),
      const CoachServerFailure(),
      const CoachRateLimitedFailure(retryAfter: Duration(hours: 2)),
    ]) {
      test('a failed reply (${failure.runtimeType}) keeps the conversation '
          'ready, with the failure', () async {
        final controller = await start();
        model.failNext = failure;
        await controller.sendCoachMessage('Hi');
        expect(state().phase, CoachSessionPhase.ready);
        expect(state().failure, failure);
        expect(state().replyRefused, isFalse);
        expect(state().session.messages.single.text, 'Hi');
      });
    }

    test('the coach turned off mid-conversation keeps what was said, and '
        '"Check again" sends the last turn again', () async {
      final controller = await start();
      await controller.sendCoachMessage('Hello');
      model.failNext = const CoachTurnedOffFailure();
      await controller.sendCoachMessage('Still there?');
      expect(state().phase, CoachSessionPhase.unavailable);
      expect(state().failure, isA<CoachTurnedOffFailure>());
      expect(state().session.messages.map((m) => m.text), [
        'Hello',
        'Coach reply.',
        'Still there?',
      ]);

      await controller.retryCoachStart();
      expect(state().phase, CoachSessionPhase.ready);
      expect(state().failure, isNull);
      expect(state().session.messages.last.text, 'Coach reply.');
      // Sent again once, as it was: no second copy of the person's turn.
      expect(model.requests.last.turns, const [
        CoachTurn.person('Hello'),
        CoachTurn.coach('Coach reply.'),
        CoachTurn.person('Still there?'),
      ]);
    });

    test('a failed save is shown, and retrying saves again', () async {
      final controller = await start();
      repository.onSave = (_) async =>
          const Err(CoachHistoryStorageFailure('disk'));
      await controller.sendCoachMessage('Hi');
      expect(state().saveFailed, isTrue);

      repository.onSave = null;
      await controller.retryCoachSave();
      expect(state().saveFailed, isFalse);
      expect(repository.sessions.single.messages, hasLength(2));
    });
  });

  group('stopCoachReply', () {
    test('stops the stream and keeps what was said so far, in the '
        'transcript and in what the coach is sent next', () async {
      model.manualReplies = true;
      final controller = await start();
      unawaited(controller.sendCoachMessage('Tell me about Tuesday.'));
      await pumpEventQueue();
      model.say('Tuesday was');
      await pumpEventQueue();

      await controller.stopCoachReply();
      await pumpEventQueue();
      expect(model.cancelled, isTrue);
      expect(state().phase, CoachSessionPhase.ready);
      expect(state().session.messages.last.text, 'Tuesday was');
      // Saved too, not only on screen.
      expect(repository.sessions.single.messages.map((m) => m.text), [
        'Tell me about Tuesday.',
        'Tuesday was',
      ]);

      model.manualReplies = false;
      await controller.sendCoachMessage('Go on.');
      expect(model.requests.last.turns, const [
        CoachTurn.person('Tell me about Tuesday.'),
        CoachTurn.coach('Tuesday was'),
        CoachTurn.person('Go on.'),
      ]);
    });

    test('a stop before any snapshot adds no coach message', () async {
      model.manualReplies = true;
      final controller = await start();
      unawaited(controller.sendCoachMessage('Hi'));
      await pumpEventQueue();
      await controller.stopCoachReply();
      await pumpEventQueue();
      expect(state().session.messages, hasLength(1));
      expect(state().phase, CoachSessionPhase.ready);
    });

    test('is ignored when nothing is replying', () async {
      final controller = await start();
      await controller.stopCoachReply();
      expect(state().phase, CoachSessionPhase.ready);
    });
  });

  group('a reply cut off at the token limit ("Keep going")', () {
    const cut = 'You logged five days. Steps were steady. On Friday you';

    test('max_tokens: stored as it came, and Keep going is offered', () async {
      model
        ..replyFor = ((_) => cut)
        ..stopReasonNext = CoachStopReason.maxTokens;
      final controller = await start();
      await controller.sendCoachMessage('How was my week?');

      expect(state().replyCutOff, isTrue);
      expect(state().session.messages.last.text, cut);
      expect(repository.sessions.single.messages.last.text, cut);
    });

    test('end_turn is never cut off, however it ends', () async {
      model.replyFor = (_) => cut;
      final controller = await start();
      await controller.sendCoachMessage('How was my week?');
      expect(state().replyCutOff, isFalse);
    });

    test('a reply the person stopped is never "cut off"', () async {
      model.manualReplies = true;
      final controller = await start();
      unawaited(controller.sendCoachMessage('Tell me about Tuesday.'));
      await pumpEventQueue();
      model.say(cut);
      await pumpEventQueue();
      await controller.stopCoachReply();
      await pumpEventQueue();
      expect(state().replyCutOff, isFalse);
      expect(state().session.messages.last.text, cut);
    });

    test('Keep going: the person\'s turn reads "Keep going", the coach is '
        'asked to carry on, and the offer goes away', () async {
      model
        ..replyFor = ((_) => cut)
        ..stopReasonNext = CoachStopReason.maxTokens;
      final controller = await start();
      await controller.sendCoachMessage('How was my week?');
      model.replyFor = (_) => 'logged partly. That counts.';

      await controller.keepGoing();
      expect(
        model.requests.last.turns.last,
        const CoachTurn.person(CoachKeepGoing.prompt),
      );
      final texts = state().session.messages.map((m) => m.text).toList();
      expect(texts.sublist(texts.length - 2), [
        CoachKeepGoing.message,
        'logged partly. That counts.',
      ]);
      expect(state().replyCutOff, isFalse);
    });

    test('Keep going is ignored when the last reply was complete', () async {
      final controller = await start();
      await controller.sendCoachMessage('Hi');
      final sent = model.requests.length;
      await controller.keepGoing();
      expect(model.requests, hasLength(sent));
    });
  });

  group('endCoachSession', () {
    test('asks for the summary in one summary request over the transcript, '
        'then stores it with the end time', () async {
      final controller = await start();
      await controller.sendCoachMessage('I skipped Wednesday.');
      await controller.endCoachSession();

      expect(state().phase, CoachSessionPhase.ended);
      final summary = model.requests.last;
      expect(summary.kind, CoachRequestKind.summary);
      expect(summary.weekContext, isNull);
      expect(summary.turns, const [
        CoachTurn.person('I skipped Wednesday.'),
        CoachTurn.coach('Coach reply.'),
      ]);

      final stored = repository.sessions.single;
      expect(stored.summary, 'A short summary.');
      expect(stored.endedAt, coachTestNow);
    });

    test('a session where nothing was said stores nothing, and sends '
        'nothing', () async {
      final controller = await start();
      await controller.endCoachSession();
      expect(state().phase, CoachSessionPhase.ended);
      expect(repository.sessions, isEmpty);
      expect(model.requests, isEmpty);
    });

    test('a failed summary still ends and stores the session', () async {
      final controller = await start();
      await controller.sendCoachMessage('Hi');
      model.failNext = const CoachServerFailure();
      await controller.endCoachSession();
      expect(state().phase, CoachSessionPhase.ended);
      expect(repository.sessions.single.summary, isNull);
      expect(repository.sessions.single.endedAt, isNotNull);
    });

    test('ending mid-reply keeps the partial reply first', () async {
      model.manualReplies = true;
      final controller = await start();
      unawaited(controller.sendCoachMessage('Hi'));
      await pumpEventQueue();
      model.say('Hello th');
      await pumpEventQueue();
      await controller.endCoachSession();
      expect(model.cancelled, isTrue);
      expect(state().phase, CoachSessionPhase.ended);
      expect(repository.sessions.single.messages.map((m) => m.text), [
        'Hi',
        'Hello th',
      ]);
      expect(
        model.summaryRequests.single.turns.last,
        const CoachTurn.coach('Hello th'),
      );
    });

    test('finishes after its screen is gone (keeps itself alive)', () async {
      container = ProviderContainer.test(
        overrides: coachTestOverrides(model: model, repository: repository),
      );
      final sub = container.listen(provider, (_, _) {});
      await pumpEventQueue();
      final controller = container.read(provider.notifier);
      await controller.sendCoachMessage('Hi');

      final ending = controller.endCoachSession();
      // The screen closes: nothing listens any more.
      sub.close();
      await ending;
      await pumpEventQueue();
      expect(repository.sessions.single.summary, 'A short summary.');
    });

    test('closing while the first message is still saving asks for no '
        'reply, and ends with the summary', () async {
      final controller = await start();
      final saving = Completer<void>();
      repository.onSave = (session) async {
        await saving.future;
        repository.onSave = null;
        return await repository.saveSession(session);
      };
      unawaited(controller.sendCoachMessage('Hi'));
      await pumpEventQueue();
      expect(state().phase, CoachSessionPhase.replying);

      final ending = controller.endCoachSession();
      await pumpEventQueue();
      // Nothing is summarised while the turn is still saving.
      expect(model.requests, isEmpty);
      saving.complete();
      await ending;
      await pumpEventQueue();

      // The turn stopped after its save: the only request is the summary.
      expect(model.requests.single.kind, CoachRequestKind.summary);
      expect(state().phase, CoachSessionPhase.ended);
      expect(repository.sessions.single.messages.single.text, 'Hi');
      expect(repository.sessions.single.summary, 'A short summary.');
    });

    test('ending mid-reply and closing the screen at once still stores the '
        'summary (the keep-alive comes first)', () async {
      model.manualReplies = true;
      container = ProviderContainer.test(
        overrides: coachTestOverrides(model: model, repository: repository),
      );
      final sub = container.listen(provider, (_, _) {});
      await pumpEventQueue();
      final controller = container.read(provider.notifier);
      unawaited(controller.sendCoachMessage('Hi'));
      await pumpEventQueue();
      model.say('Hello th');
      await pumpEventQueue();

      final ending = controller.endCoachSession();
      sub.close();
      await ending;
      await pumpEventQueue();

      final stored = repository.sessions.single;
      expect(stored.messages.map((m) => m.text), ['Hi', 'Hello th']);
      expect(stored.summary, 'A short summary.');
      expect(stored.endedAt, isNotNull);
    });

    test('a session finishing in the background after "Delete coach '
        'history" saves nothing more', () async {
      final controller = await start();
      await controller.sendCoachMessage('Hi');
      expect(repository.sessions, hasLength(1));

      // Hold the summary while the history is deleted.
      final summarising = Completer<void>();
      model.beforeReply = () {
        model.beforeReply = null;
        return summarising.future;
      };
      final ending = controller.endCoachSession();
      await pumpEventQueue();
      container.listen(coachHistoryControllerProvider, (_, _) {});
      await container.read(coachHistoryControllerProvider.future);
      await container
          .read(coachHistoryControllerProvider.notifier)
          .deleteCoachHistory();
      expect(repository.sessions, isEmpty);

      summarising.complete();
      await ending;
      await pumpEventQueue();
      expect(state().phase, CoachSessionPhase.ended);
      expect(repository.sessions, isEmpty);
    });

    test('a delete that fails leaves an open session saving', () async {
      final controller = await start();
      await controller.sendCoachMessage('Hi');
      container.listen(coachHistoryControllerProvider, (_, _) {});
      await container.read(coachHistoryControllerProvider.future);
      repository.onDeleteAll = () async =>
          const Err(CoachHistoryStorageFailure('locked'));
      await container
          .read(coachHistoryControllerProvider.notifier)
          .deleteCoachHistory();

      await controller.sendCoachMessage('Still here');
      expect(
        repository.sessions.single.messages.map((m) => m.text),
        contains('Still here'),
      );
    });

    test('a session opened after a delete saves as usual', () async {
      await start();
      container.listen(coachHistoryControllerProvider, (_, _) {});
      await container.read(coachHistoryControllerProvider.future);
      await container
          .read(coachHistoryControllerProvider.notifier)
          .deleteCoachHistory();

      final next = coachSessionControllerProvider(
        CoachSessionKind.chat,
        'session-2',
      );
      container.listen(next, (_, _) {});
      await pumpEventQueue();
      await container.read(next.notifier).sendCoachMessage('Hi again');
      expect(repository.sessions.single.id, 'session-2');
    });

    test('is ignored once ended', () async {
      final controller = await start();
      await controller.sendCoachMessage('Hi');
      await controller.endCoachSession();
      final requests = model.requests.length;
      await controller.endCoachSession();
      expect(model.requests, hasLength(requests));
    });
  });

  group('retryCoachStart', () {
    test('after an unavailable start, checks again and starts', () async {
      model.availability = const Err(CoachTurnedOffFailure());
      final controller = await start();
      expect(state().phase, CoachSessionPhase.unavailable);

      model.availability = const Ok(unit);
      await controller.retryCoachStart();
      expect(state().phase, CoachSessionPhase.ready);
      expect(state().failure, isNull);
      expect(model.availabilityChecks, 2);
      expect(model.requests, isEmpty);
    });

    test('still unavailable says so again', () async {
      model.availability = const Err(CoachDeviceNotVerifiedFailure());
      final controller = await start();
      await controller.retryCoachStart();
      expect(state().phase, CoachSessionPhase.unavailable);
      expect(state().failure, isA<CoachDeviceNotVerifiedFailure>());
      expect(model.availabilityChecks, 2);
    });

    test('mid-conversation and still unavailable: says so, keeps what was '
        'said, and sends nothing', () async {
      final controller = await start();
      await controller.sendCoachMessage('Hello');
      model.failNext = const CoachTurnedOffFailure();
      await controller.sendCoachMessage('Again');
      final sent = model.requests.length;

      model.availability = const Err(CoachTurnedOffFailure());
      await controller.retryCoachStart();
      expect(state().phase, CoachSessionPhase.unavailable);
      expect(state().session.messages, hasLength(3));
      expect(model.requests, hasLength(sent));
    });

    test('is ignored when the session is ready', () async {
      final controller = await start();
      await controller.retryCoachStart();
      expect(state().phase, CoachSessionPhase.ready);
      expect(model.availabilityChecks, 1);
    });
  });

  test('disposing mid-reply cancels the stream', () async {
    model.manualReplies = true;
    container = ProviderContainer.test(
      overrides: coachTestOverrides(model: model, repository: repository),
    );
    final sub = container.listen(provider, (_, _) {});
    await pumpEventQueue();
    unawaited(container.read(provider.notifier).sendCoachMessage('Hi'));
    await pumpEventQueue();
    sub.close();
    await pumpEventQueue();
    expect(model.cancelled, isTrue);
  });

  test('saving refreshes the list of past sessions', () async {
    final controller = await start();
    container.listen(coachSessionListProvider, (_, _) {});
    expect(await container.read(coachSessionListProvider.future), isEmpty);
    await controller.sendCoachMessage('Hi');
    await pumpEventQueue();
    expect(await container.read(coachSessionListProvider.future), hasLength(1));
  });
}
