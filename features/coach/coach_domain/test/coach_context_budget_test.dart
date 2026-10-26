import 'package:coach_domain/coach_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// The context budget (#80): a coach session never overflows the
/// on-device model's window (4,096 tokens on iOS 26), however long the
/// chat runs.
void main() {
  final at = DateTime(2026, 10, 24, 20);
  CoachMessage user(String text) =>
      CoachMessage(role: CoachMessageRole.user, text: text, at: at);
  CoachMessage coach(String text) =>
      CoachMessage(role: CoachMessageRole.coach, text: text, at: at);

  /// The largest week summary the app writes (`coachWeekContextMaxChars`
  /// in coach_presentation is 1,200).
  final data = 'd' * 1200;

  group('estimateCoachTokens', () {
    test('counts three characters per token, rounding up', () {
      expect(estimateCoachTokens(''), 0);
      expect(estimateCoachTokens('abc'), 1);
      expect(estimateCoachTokens('abcd'), 2);
      expect(estimateCoachTokens('a' * 3000), 1000);
    });

    test('counts code points, not UTF-16 units', () {
      // Three emoji are six UTF-16 units but three code points, so they
      // cost three tokens here, not six.
      expect(estimateCoachTokens('🙂🙂🙂'), 3);
    });

    test('counts non-Latin text a token per character, the safe side', () {
      // "Three to four characters per token" is an English figure. CJK,
      // Hangul and emoji are split far more finely — often a token each or
      // more — so dividing every code point by three would under-count
      // them threefold and let a turn through that overflows the window.
      expect(estimateCoachTokens('今天过得怎么样'), 7);
      expect(estimateCoachTokens('안녕하세요'), 5);
      // Latin is still three per token, and mixed text adds the two.
      expect(estimateCoachTokens('abcdef'), 2);
      expect(estimateCoachTokens('abc今天'), 3);
    });
  });

  group('CoachContextBudget', () {
    const budget = CoachContextBudget(contextSize: 4096);

    test('reserves a full reply and the margin for every turn', () {
      expect(budget.replyTokens, coachMaxReplyTokens);
      expect(budget.turnCost(''), 512 + 256 + 2 * coachTurnOverheadTokens);
    });

    test('fits a turn exactly up to the window', () {
      final cost = budget.turnCost('abc');
      expect(budget.fitsTurn(sessionTokens: 4096 - cost, prompt: 'abc'), true);
      expect(
        budget.fitsTurn(sessionTokens: 4096 - cost + 1, prompt: 'abc'),
        false,
      );
    });

    test('a fresh session has room for the longest message', () {
      final instructions = CoachInstructions.forSession(
        CoachInstructions.weeklySession,
        data,
      );
      expect(
        budget.promptRoomTokens(estimateCoachTokens(instructions)),
        greaterThan(2 * estimateCoachTokens('m' * coachMaxMessageChars)),
      );
    });

    test('prompt room is never negative', () {
      const tiny = CoachContextBudget(contextSize: 100);
      expect(tiny.promptRoomTokens(50), 0);
    });
  });

  group('CoachConversation', () {
    final instructions = CoachInstructions.forSession(
      CoachInstructions.chat,
      data,
    );

    test('starts holding just the instructions', () {
      final c = CoachConversation.start(instructions: instructions);
      expect(c.sessionTokens, estimateCoachTokens(instructions));
      expect(c.window, isEmpty);
      expect(c.promptFor('Hi'), 'Hi');
    });

    test('clamps a message to the longest allowed, trimmed', () {
      expect(CoachConversation.clampMessage('  hi  '), 'hi');
      expect(
        CoachConversation.clampMessage('x' * 5000).length,
        coachMaxMessageChars,
      );
    });

    test('counts every prompt and reply it sent', () {
      final c = CoachConversation.start(
        instructions: instructions,
      ).afterTurn(prompt: 'abc', message: user('abc'), reply: coach('abcdef'));
      expect(
        c.sessionTokens,
        estimateCoachTokens(instructions) + 1 + 2 + 2 * coachTurnOverheadTokens,
      );
      expect(c.window.map((m) => m.text), ['abc', 'abcdef']);
    });

    test('counts what the model generated when the stored reply is trimmed '
        '(a cut-off reply, "Keep going")', () {
      final c = CoachConversation.start(instructions: instructions).afterTurn(
        prompt: 'abc',
        message: user('abc'),
        reply: coach('abc'),
        generated: 'abcdefghi',
      );
      expect(
        c.sessionTokens,
        estimateCoachTokens(instructions) + 1 + 3 + 2 * coachTurnOverheadTokens,
      );
      expect(c.window.last.text, 'abc');
    });

    test('a fresh session carries the summary and the last messages into '
        'its first prompt only', () {
      var c = CoachConversation.start(instructions: instructions);
      for (var i = 0; i < 4; i++) {
        c = c.afterTurn(
          prompt: 'q$i',
          message: user('question $i'),
          reply: coach('answer $i'),
        );
      }
      expect(c.toSummarise.map((m) => m.text), [
        'question 0',
        'answer 0',
        'question 1',
        'answer 1',
      ]);

      final fresh = c.afterFreshSession('They talked about weekends.');
      expect(fresh.sessionTokens, estimateCoachTokens(instructions));
      expect(fresh.earlierSummary, 'They talked about weekends.');
      final prompt = fresh.promptFor('And Sunday?');
      expect(prompt, contains('They talked about weekends.'));
      expect(prompt, contains('Person: question 3'));
      expect(prompt, contains('Coach: answer 3'));
      expect(prompt, isNot(contains('question 1')));
      expect(prompt, endsWith('The person now says:\nAnd Sunday?'));

      final next = fresh.afterTurn(
        prompt: prompt,
        message: user('And Sunday?'),
        reply: coach('Sunday was logged.'),
      );
      expect(next.promptFor('Thanks'), 'Thanks');
      // The summary survives the next move unless a new one replaces it.
      expect(next.afterFreshSession(null).earlierSummary, isNotNull);
    });

    test('a summary is cut to its cap', () {
      final c = CoachConversation.start(instructions: instructions)
          .afterFreshSession('s' * 5000);
      expect(c.earlierSummary!.runes.length, coachMaxCarriedSummaryChars);
    });

    test('without carry, a fresh session starts clean', () {
      final c = CoachConversation.start(instructions: instructions)
          .afterTurn(prompt: 'a', message: user('a'), reply: coach('b'))
          .afterFreshSession('summary')
          .withoutCarry();
      expect(c.promptFor('hi'), 'hi');
      expect(c.window, isEmpty);
    });

    for (final (kind, base) in [
      ('chat', CoachInstructions.chat),
      ('weekly session', CoachInstructions.weeklySession),
    ]) {
      test('a long $kind never overflows the window', () {
        const budget = CoachContextBudget(contextSize: 4096);
        final instructions = CoachInstructions.forSession(base, data);
        var c = CoachConversation.start(instructions: instructions);
        var freshSessions = 0;
        // 120 turns of the longest message and the longest reply the
        // channel allows (512 tokens, about 1,536 characters).
        for (var turn = 0; turn < 120; turn++) {
          final message = '$turn ${'m' * 2000}';
          if (c.needsFreshSession(message, budget)) {
            freshSessions++;
            c = c.afterFreshSession('s' * 2000);
            if (c.needsFreshSession(message, budget)) c = c.withoutCarry();
          }
          final prompt = c.promptFor(message);
          expect(
            c.sessionTokens + budget.turnCost(prompt),
            lessThanOrEqualTo(budget.contextSize),
            reason: 'turn $turn',
          );
          c = c.afterTurn(
            prompt: prompt,
            message: user(CoachConversation.clampMessage(message)),
            reply: coach('r' * (coachMaxReplyTokens * 3)),
          );
          expect(
            c.sessionTokens,
            lessThanOrEqualTo(budget.contextSize - budget.marginTokens),
          );
        }
        expect(freshSessions, greaterThan(10));
      });
    }

    test('an app prompt counts toward the session, its reply joins the '
        'window', () {
      final c = CoachConversation.start(instructions: instructions)
          .afterAppPrompt(prompt: 'Open the session.', reply: coach('Hello'));
      expect(c.window.single.text, 'Hello');
      expect(c.sessionTokens, greaterThan(estimateCoachTokens(instructions)));
    });
  });

  group('summary prompts', () {
    const budget = CoachContextBudget(contextSize: 4096);
    final instructions = CoachInstructions.forSession(
      CoachInstructions.chat,
      data,
    );
    final instructionTokens = estimateCoachTokens(instructions);

    test('nothing to summarise is null', () {
      expect(
        coachSummaryPrompt(
          request: CoachInstructions.summaryRequest,
          messages: const [],
          budget: budget,
          instructionTokens: instructionTokens,
        ),
        isNull,
      );
    });

    test('starts with the request and lists the conversation', () {
      final prompt = coachSummaryPrompt(
        request: CoachInstructions.summaryRequest,
        messages: [user('How was Sunday?'), coach('You logged it.')],
        earlierSummary: 'Earlier, weekends.',
        budget: budget,
        instructionTokens: instructionTokens,
      )!;
      expect(prompt, startsWith(CoachInstructions.summaryRequest));
      expect(prompt, contains('Earlier, weekends.'));
      expect(
        prompt,
        contains('Person: How was Sunday?\nCoach: You logged it.'),
      );
    });

    test('drops the oldest messages until it fits a fresh session', () {
      final messages = [for (var i = 0; i < 40; i++) user('$i ${'x' * 400}')];
      final prompt = coachSummaryPrompt(
        request: CoachInstructions.summaryRequest,
        messages: messages,
        budget: budget,
        instructionTokens: instructionTokens,
      )!;
      expect(
        estimateCoachTokens(prompt),
        lessThanOrEqualTo(budget.promptRoomTokens(instructionTokens)),
      );
      expect(prompt, contains('39 '));
      expect(prompt, isNot(contains('Person: 0 ')));
    });

    // Sized by estimateCoachTokens, not by characters at the Latin rate:
    // 400 CJK or emoji characters are about 400 tokens, not 133.
    for (final (script, text) in [
      ('CJK', '今天过得怎么样' * 57),
      ('Hangul', '안녕하세요' * 80),
      ('emoji', '🙂' * 400),
    ]) {
      test('a $script transcript fits a fresh session by token estimate', () {
        final messages = [for (var i = 0; i < 40; i++) user('$i $text')];
        final prompt = coachSummaryPrompt(
          request: CoachInstructions.summaryRequest,
          messages: messages,
          budget: budget,
          instructionTokens: instructionTokens,
        )!;
        expect(
          estimateCoachTokens(prompt),
          lessThanOrEqualTo(budget.promptRoomTokens(instructionTokens)),
        );
        expect(prompt, contains('Person: 39 '));
        expect(prompt, isNot(contains('Person: 0 ')));
      });
    }

    test('keeps exactly the newest messages that fit, however long the '
        'transcript', () {
      // 3,000 messages: the fit is one pass over them, newest first.
      final messages = [for (var i = 0; i < 3000; i++) user('$i ${'z' * 90}')];
      final prompt = coachSummaryPrompt(
        request: CoachInstructions.summaryRequest,
        messages: messages,
        budget: budget,
        instructionTokens: instructionTokens,
      )!;
      final room = budget.promptRoomTokens(instructionTokens);
      expect(estimateCoachTokens(prompt), lessThanOrEqualTo(room));
      expect(prompt, endsWith('Person: 2999 ${'z' * 90}'));
      // The oldest message kept is preceded by one that wouldn't fit.
      final firstKept = RegExp(r'Person: (\d+) ').firstMatch(prompt)!;
      final first = int.parse(firstKept.group(1)!);
      expect(first, greaterThan(0));
      final withOneMore = coachTranscriptLines(messages.sublist(first - 1));
      expect(
        estimateCoachTokens(
          '${CoachInstructions.summaryRequest}\n\nThe conversation:\n'
          '$withOneMore',
        ),
        greaterThan(room),
      );
    });

    test('an earlier summary too long for the room is cut to fit, by '
        'tokens', () {
      final prompt = coachSummaryPrompt(
        request: CoachInstructions.summaryRequest,
        messages: [user('Hi')],
        earlierSummary: '周末' * 4000,
        budget: budget,
        instructionTokens: instructionTokens,
      )!;
      expect(
        estimateCoachTokens(prompt),
        budget.promptRoomTokens(instructionTokens),
      );
    });

    test('a summary session is sized for the summary instructions by '
        'default', () {
      final messages = [for (var i = 0; i < 40; i++) user('$i ${'x' * 400}')];
      final prompt = coachSummaryPrompt(
        request: CoachInstructions.summaryRequest,
        messages: messages,
        budget: budget,
      )!;
      expect(
        estimateCoachTokens(prompt),
        lessThanOrEqualTo(
          budget.promptRoomTokens(
            estimateCoachTokens(CoachInstructions.summary),
          ),
        ),
      );
      // More room than under the coaching instructions with the data.
      expect(
        prompt.length,
        greaterThan(
          coachSummaryPrompt(
            request: CoachInstructions.summaryRequest,
            messages: messages,
            budget: budget,
            instructionTokens: instructionTokens,
          )!.length,
        ),
      );
    });

    test('the end summary uses the whole transcript when it fits, else the '
        'earlier summary and the window', () {
      var c = CoachConversation.start(instructions: instructions);
      final all = <CoachMessage>[];
      for (var i = 0; i < 3; i++) {
        final q = user('q$i');
        final a = coach('a$i');
        all.addAll([q, a]);
        c = c.afterTurn(prompt: 'q$i', message: q, reply: a);
      }
      final short = c.summaryPromptFor(
        all,
        request: CoachInstructions.summaryRequest,
        budget: budget,
      )!;
      expect(short, contains(coachTranscriptLines(all)));

      final long = [
        for (var i = 0; i < 30; i++) user('$i ${'y' * 400}'),
        ...c.window,
      ];
      final moved = c.afterFreshSession('The start, in short.');
      final prompt = moved.summaryPromptFor(
        long,
        request: CoachInstructions.summaryRequest,
        budget: budget,
      )!;
      expect(prompt, contains('The start, in short.'));
      expect(prompt, isNot(contains('Person: 0 ')));
    });
  });
}
