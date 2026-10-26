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
  const summaryRequest = CoachInstructions.summaryRequest;
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
  Future<CoachSessionController> start() async {
    container = ProviderContainer.test(
      overrides: coachTestOverrides(model: model, repository: repository),
    )..listen(provider, (_, _) {});
    await pumpEventQueue();
    // The lint takes the notifier for a Future; it isn't one.
    // ignore: async_return_with_no_await
    return container.read(provider.notifier);
  }

  CoachSessionState state() => container.read(provider);

  group('starting', () {
    final reasons = <CoachModelUnavailableFailure>[
      const CoachDeviceNotEligibleFailure(),
      const CoachAppleIntelligenceNotEnabledFailure(),
      const CoachModelNotReadyFailure(),
      const CoachOsTooOldFailure(),
      const CoachModelUnavailableUnknownFailure(),
    ];
    for (final reason in reasons) {
      test(
        'unavailable (${reason.runtimeType}): says why, starts nothing',
        () async {
          model.availability = Err(reason);
          await start();
          expect(state().phase, CoachSessionPhase.unavailable);
          expect(state().failure, reason);
          expect(model.instructions, isEmpty);
        },
      );
    }

    test('a session that fails to start says so', () async {
      model.startResult = const Err(PlatformChannelFailure('boom'));
      await start();
      expect(state().phase, CoachSessionPhase.failedToStart);
    });

    test(
      "primes the model with the chat instructions and the week's data",
      () async {
        await start();
        expect(state().phase, CoachSessionPhase.ready);
        final instructions = model.instructions.single;
        expect(instructions, startsWith(CoachInstructions.chat));
        expect(instructions, contains("The person's data:"));
        expect(
          instructions,
          contains('Sat Oct 24: logged fully; ate 1800 kcal'),
        );
        expect(state().session.startedAt, coachTestNow);
      },
    );

    test('nothing is stored before the person says something', () async {
      await start();
      expect(repository.sessions, isEmpty);
    });
  });

  group('sendCoachMessage', () {
    test('streams the reply snapshot by snapshot, then saves it', () async {
      model.manualReplies = true;
      final controller = await start();
      unawaited(controller.sendCoachMessage('  How was my week?  '));
      await pumpEventQueue();

      expect(state().phase, CoachSessionPhase.replying);
      expect(state().session.messages.single.text, 'How was my week?');
      // Saved as soon as the person said it.
      expect(repository.sessions.single.messages, hasLength(1));
      expect(model.prompts.single.prompt, 'How was my week?');

      model.reply('You logged');
      await pumpEventQueue();
      expect(state().reply, 'You logged');
      model.reply('You logged Saturday.');
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

    test(
      'is ignored while the coach replies, and for an empty message',
      () async {
        model.manualReplies = true;
        final controller = await start();
        await controller.sendCoachMessage('   ');
        expect(model.prompts, isEmpty);

        unawaited(controller.sendCoachMessage('One'));
        await pumpEventQueue();
        await controller.sendCoachMessage('Two');
        expect(model.prompts, hasLength(1));
        expect(state().session.messages, hasLength(1));
      },
    );

    test('a failed reply keeps the conversation, with the failure', () async {
      final controller = await start();
      model.failNext = const CoachInferenceFailure(
        'guardrail',
        reason: CoachInferenceFailureReason.guardrailViolation,
      );
      await controller.sendCoachMessage('Hard day.');
      expect(state().phase, CoachSessionPhase.ready);
      expect(state().guardrailTripped, isTrue);
      expect(state().session.messages.single.text, 'Hard day.');

      // The next message clears it.
      await controller.sendCoachMessage('Thanks.');
      expect(state().failure, isNull);
      expect(state().guardrailTripped, isFalse);
    });

    test(
      'a context overflow moves to a fresh session and retries once',
      () async {
        final controller = await start();
        model.failNext = const CoachInferenceFailure(
          'full',
          reason: CoachInferenceFailureReason.contextExceeded,
        );
        await controller.sendCoachMessage('Hello');
        expect(model.prompts.map((p) => p.session), ['s0', 's1']);
        expect(model.ended, contains('s0'));
        expect(state().failure, isNull);
        expect(state().session.messages.last.text, 'Coach reply.');
      },
    );

    test('a fresh session that fails to start ends the session, and the '
        'next message is a no-op rather than a crash', () async {
      final controller = await start();
      model
        // Overflow sends the conversation to a fresh model session...
        ..failNext = const CoachInferenceFailure(
          'full',
          reason: CoachInferenceFailureReason.contextExceeded,
        )
        // ...and starting that one fails: no model session is left.
        ..startResult = const Err(PlatformChannelFailure('boom'));
      await controller.sendCoachMessage('Hello');

      // Going back to `ready` would offer a composer with nothing behind
      // it, and the next send would dereference a null model session.
      expect(state().phase, CoachSessionPhase.failedToStart);
      expect(state().failure, isA<PlatformChannelFailure>());

      final before = model.prompts.length;
      await controller.sendCoachMessage('Are you there?');
      expect(model.prompts.length, before);
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

  group('the context budget in a long chat', () {
    test('every prompt fits the window, older turns are summarised into a '
        'fresh session', () async {
      model.replyFor = (prompt) =>
          prompt.startsWith(CoachInstructions.summaryRequest)
          ? 'They went over weekend logging.'
          // The longest reply the channel allows, about 512 tokens.
          : 'r' * (coachMaxReplyTokens * 3);
      final controller = await start();
      const budget = CoachContextBudget(contextSize: 4096);

      for (var i = 0; i < 30; i++) {
        await controller.sendCoachMessage('$i ${'m' * 990}');
      }

      // Replay what each model session was sent and check none of them
      // could overflow: its own instructions + prompts + full-length
      // replies. Session `sN` is the Nth started, so its instructions are
      // `model.instructions[N]`.
      final bySession = <String, List<String>>{};
      for (final p in model.prompts) {
        bySession.putIfAbsent(p.session, () => []).add(p.prompt);
      }
      expect(bySession.length, greaterThan(5));
      for (final MapEntry(key: id, value: prompts) in bySession.entries) {
        final instructions = model.instructions[int.parse(id.substring(1))];
        // Summaries run under the summary instructions, never the coaching
        // ones (which ask for questions); every other session coaches.
        expect(
          instructions,
          prompts.first.startsWith(CoachInstructions.summaryRequest)
              ? CoachInstructions.summary
              : startsWith(CoachInstructions.chat),
          reason: 'session $id',
        );
        var used = estimateCoachTokens(instructions);
        for (final prompt in prompts) {
          expect(
            used + budget.turnCost(prompt),
            lessThanOrEqualTo(4096),
            reason: 'session $id',
          );
          used +=
              estimateCoachTokens(prompt) +
              coachMaxReplyTokens +
              2 * coachTurnOverheadTokens;
        }
      }
      // A fresh session's first prompt carries the summary.
      final carried = model.prompts.where(
        (p) => p.prompt.contains('They went over weekend logging.'),
      );
      expect(carried, isNotEmpty);
      // The full transcript is still stored.
      expect(state().session.messages, hasLength(60));
    });
  });

  group('stopCoachReply', () {
    test('stops the stream and keeps what was said so far', () async {
      model.manualReplies = true;
      final controller = await start();
      unawaited(controller.sendCoachMessage('Tell me about Tuesday.'));
      await pumpEventQueue();
      model.reply('Tuesday was');
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

  group('endCoachSession', () {
    test('asks for a neutral summary under the summary instructions, then '
        'stores it with the end time', () async {
      final controller = await start();
      await controller.sendCoachMessage('I skipped Wednesday.');
      await controller.endCoachSession();

      expect(state().phase, CoachSessionPhase.ended);
      final summaryPrompt = model.prompts.last;
      expect(
        summaryPrompt.prompt,
        startsWith(CoachInstructions.summaryRequest),
      );
      expect(summaryPrompt.prompt, contains('Person: I skipped Wednesday.'));
      // A separate model session, primed to summarise, not to coach.
      expect(summaryPrompt.session, isNot('s0'));
      expect(model.instructions.first, startsWith(CoachInstructions.chat));
      expect(model.instructions.last, CoachInstructions.summary);

      final stored = repository.sessions.single;
      expect(stored.summary, 'A short summary.');
      expect(stored.endedAt, coachTestNow);
      expect(model.ended, containsAll(['s0', summaryPrompt.session]));
    });

    test('a session where nothing was said stores nothing', () async {
      final controller = await start();
      await controller.endCoachSession();
      expect(state().phase, CoachSessionPhase.ended);
      expect(repository.sessions, isEmpty);
      expect(model.ended, ['s0']);
    });

    test('a failed summary still ends and stores the session', () async {
      final controller = await start();
      await controller.sendCoachMessage('Hi');
      model.failNext = const CoachInferenceFailure(
        'x',
        reason: CoachInferenceFailureReason.other,
      );
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
      model.reply('Hello th');
      await pumpEventQueue();
      await controller.endCoachSession();
      expect(state().phase, CoachSessionPhase.ended);
      expect(repository.sessions.single.messages.map((m) => m.text), [
        'Hi',
        'Hello th',
      ]);
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
      expect(model.prompts, isEmpty);
      saving.complete();
      await ending;
      await pumpEventQueue();

      // The turn stopped after its save: the only prompt is the summary.
      expect(model.prompts.single.prompt, startsWith(summaryRequest));
      expect(state().phase, CoachSessionPhase.ended);
      expect(repository.sessions.single.messages.single.text, 'Hi');
      expect(repository.sessions.single.summary, 'A short summary.');
    });

    test('ending during a move to a fresh model session waits for it, and '
        'the turn sends nothing more', () async {
      final controller = await start();
      final starting = Completer<void>();
      model
        ..failNext = const CoachInferenceFailure(
          'full',
          reason: CoachInferenceFailureReason.contextExceeded,
        )
        // Hold the fresh session's start, mid-move.
        ..beforeStart = () {
          model.beforeStart = null;
          return starting.future;
        };
      unawaited(controller.sendCoachMessage('Hello'));
      await pumpEventQueue();

      final ending = controller.endCoachSession();
      await pumpEventQueue();
      starting.complete();
      await ending;
      await pumpEventQueue();

      // The overflowed reply isn't retried after the session ended.
      expect(model.prompts.where((p) => p.prompt == 'Hello'), hasLength(1));
      expect(model.prompts.last.prompt, startsWith(summaryRequest));
      // Every model session started is ended, the fresh one included.
      expect(model.ended.toSet(), {'s0', 's1', 's2'});
      expect(state().phase, CoachSessionPhase.ended);
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
      model.reply('Hello th');
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

      // Hold the summary's model session while the history is deleted.
      final starting = Completer<void>();
      model.beforeStart = () {
        model.beforeStart = null;
        return starting.future;
      };
      final ending = controller.endCoachSession();
      await pumpEventQueue();
      container.listen(coachHistoryControllerProvider, (_, _) {});
      await container.read(coachHistoryControllerProvider.future);
      await container
          .read(coachHistoryControllerProvider.notifier)
          .deleteCoachHistory();
      expect(repository.sessions, isEmpty);

      starting.complete();
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
      final prompts = model.prompts.length;
      await controller.endCoachSession();
      expect(model.prompts, hasLength(prompts));
    });
  });

  group('retryCoachStart', () {
    test('after an unavailable start, checks again and starts', () async {
      model.availability = const Err(CoachAppleIntelligenceNotEnabledFailure());
      final controller = await start();
      expect(state().phase, CoachSessionPhase.unavailable);

      model.availability = const Ok(CoachModelInfo(contextSize: 4096));
      await controller.retryCoachStart();
      expect(state().phase, CoachSessionPhase.ready);
      expect(state().failure, isNull);
      expect(model.availabilityChecks, 2);
      expect(model.instructions, hasLength(1));
    });

    test('still unavailable says so again', () async {
      model.availability = const Err(CoachModelNotReadyFailure());
      final controller = await start();
      await controller.retryCoachStart();
      expect(state().phase, CoachSessionPhase.unavailable);
      expect(state().failure, isA<CoachModelNotReadyFailure>());
      expect(model.availabilityChecks, 2);
    });

    test('mid-conversation, moves to a fresh model session and the chat '
        'goes on', () async {
      final controller = await start();
      model
        ..failNext = const CoachInferenceFailure(
          'full',
          reason: CoachInferenceFailureReason.contextExceeded,
        )
        ..startResult = const Err(PlatformChannelFailure('boom'));
      await controller.sendCoachMessage('Hello');
      expect(state().phase, CoachSessionPhase.failedToStart);

      model.startResult = null;
      await controller.retryCoachStart();
      expect(state().phase, CoachSessionPhase.ready);
      expect(state().session.messages.first.text, 'Hello');

      await controller.sendCoachMessage('Are you there?');
      expect(model.prompts.last.prompt, contains('Are you there?'));
      expect(state().session.messages.last.text, 'Coach reply.');
    });

    test('is ignored when the session is ready', () async {
      final controller = await start();
      await controller.retryCoachStart();
      expect(state().phase, CoachSessionPhase.ready);
      expect(model.availabilityChecks, 1);
    });
  });

  test(
    'disposing mid-reply cancels the stream and ends the model session',
    () async {
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
      expect(model.ended, ['s0']);
    },
  );

  test('saving refreshes the list of past sessions', () async {
    final controller = await start();
    container.listen(coachSessionListProvider, (_, _) {});
    expect(await container.read(coachSessionListProvider.future), isEmpty);
    await controller.sendCoachMessage('Hi');
    await pumpEventQueue();
    expect(await container.read(coachSessionListProvider.future), hasLength(1));
  });
}
