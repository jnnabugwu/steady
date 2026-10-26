import 'package:coach_domain/coach_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// The weekly session's rule and structure (#81).
void main() {
  group('the 4-of-7 rule', () {
    test('needs at least four days with a check-in', () {
      expect(weeklySessionMinCheckInDays, 4);
      for (var days = 0; days <= 7; days++) {
        expect(weeklySessionAllowed(days), days >= 4, reason: '$days days');
      }
    });
  });

  group('topics', () {
    test('logging, then steps, then next week, as separate threads', () {
      expect(weeklyTopicsFor(cravingCount: 0), [
        WeeklyTopic.logging,
        WeeklyTopic.steps,
        WeeklyTopic.nextWeek,
      ]);
    });

    test('a craving reflection only when there were cravings', () {
      expect(weeklyTopicsFor(cravingCount: 2), [
        WeeklyTopic.logging,
        WeeklyTopic.steps,
        WeeklyTopic.cravings,
        WeeklyTopic.nextWeek,
      ]);
    });

    test('logging opens the session by asking how the week felt, and asks '
        'nothing else', () {
      final prompt = weeklyTopicPrompt(WeeklyTopic.logging);
      expect(prompt, contains('asking how the week felt'));
      expect(prompt, contains('logging consistency'));
      // One question per reply (`CoachInstructions.rules`). The prompt used
      // to ask for the feeling question *and* a second one from the data.
      expect(prompt, contains('as your only question'));
      expect(prompt, isNot(contains('one question')));
    });

    test('each later topic is a new thread that leaves the last behind', () {
      expect(weeklyTopicPrompt(WeeklyTopic.steps), contains('new topic'));
      expect(
        weeklyTopicPrompt(WeeklyTopic.steps),
        contains('Leave logging behind'),
      );
      expect(weeklyTopicPrompt(WeeklyTopic.cravings), contains('new topic'));
    });

    test('the craving reflection is an observation with a question, never '
        'a grade, a comparison or food advice', () {
      final prompt = weeklyTopicPrompt(WeeklyTopic.cravings);
      for (final phrase in [
        'when they came and what was behind them',
        'as an observation',
        'ask one question',
        'No grades',
        'no comparison with other weeks',
        'nothing about calories or food choices',
      ]) {
        expect(prompt, contains(phrase), reason: phrase);
      }
    });

    test('next week is one small thing, phrased as something to do, chosen '
        'by the person', () {
      final prompt = weeklyTopicPrompt(WeeklyTopic.nextWeek);
      expect(prompt, contains('one small thing'));
      expect(prompt, contains('something to do'));
      expect(prompt, contains('Let them choose'));
      expect(prompt, contains('never suggest calorie targets or diets'));
    });
  });

  test('a whole weekly session of app prompts fits the window with room '
      'to talk', () {
    const budget = CoachContextBudget(contextSize: 4096);
    final instructions = CoachInstructions.forSession(
      CoachInstructions.weeklySession,
      'd' * 1200,
    );
    var c = CoachConversation.start(instructions: instructions);
    final at = DateTime(2026, 10, 23, 20);
    for (final topic in weeklyTopicsFor(cravingCount: 1)) {
      final prompt = weeklyTopicPrompt(topic);
      if (c.needsFreshSession(prompt, budget, fromApp: true)) {
        c = c.afterFreshSession('summary');
      }
      final sent = c.promptFor(prompt, fromApp: true);
      expect(c.sessionTokens + budget.turnCost(sent), lessThanOrEqualTo(4096));
      c = c.afterAppPrompt(
        prompt: sent,
        reply: CoachMessage(
          role: CoachMessageRole.coach,
          text: 'r' * 600,
          at: at,
        ),
      );
    }
  });

  test('an app prompt in a fresh session follows the carried context, '
      'unclamped and without "The person now says"', () {
    final c = CoachConversation.start(instructions: 'i')
        .afterTurn(
          prompt: 'hi',
          message: CoachMessage(
            role: CoachMessageRole.user,
            text: 'hi',
            at: DateTime(2026),
          ),
          reply: null,
        )
        .afterFreshSession('Earlier: hello.');
    final long = 'x' * (coachMaxMessageChars + 50);
    final prompt = c.promptFor(long, fromApp: true);
    expect(prompt, startsWith('Earlier in this conversation'));
    expect(prompt, endsWith(long));
    expect(prompt, isNot(contains('The person now says')));
  });
}
