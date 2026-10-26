import 'package:coach_domain/coach_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the coach's tone and safety constraints (#82). Each test names
/// one constraint; if an edit to `CoachInstructions` drops it, that test
/// fails. Checked against every session kind, since each one is a complete
/// set of instructions on its own.
void main() {
  const kinds = {
    'weekly session': CoachInstructions.weeklySession,
    'chat': CoachInstructions.chat,
  };

  for (final MapEntry(key: kind, value: text) in kinds.entries) {
    group(kind, () {
      final lower = text.toLowerCase();

      void expectAll(List<String> phrases) {
        for (final phrase in phrases) {
          expect(lower, contains(phrase.toLowerCase()), reason: phrase);
        }
      }

      test('starts from the shared rules', () {
        expect(text, startsWith(CoachInstructions.rules));
      });

      test('is a coach, not a therapist, and gives no medical advice', () {
        expectAll([
          'You are a coach, not a therapist',
          "don't give medical advice",
        ]);
      });

      test("reflects on the person's own logged data and asks questions", () {
        expectAll(["Reflect on the person's own logged data", 'ask questions']);
      });

      test('keeps replies short, with at most one question', () {
        expectAll(['two to four sentences', 'at most one question']);
      });

      test('never originates calorie targets, weight goals, deficits or '
          'diets, including from craving data', () {
        expectAll([
          'Never give a calorie target',
          'a weight goal',
          'a calorie deficit',
          'a diet',
          'a meal plan',
          'even if asked',
          'not from craving data either',
        ]);
      });

      test('only uses numbers from the data', () {
        expectAll(["Don't make up numbers"]);
      });

      test('no streaks, grades or shame for missed or partial days', () {
        expectAll([
          'No streaks, grades, scores or shame',
          'A missed or partial day is information, not a failure',
          "Don't call days or foods good or bad",
        ]);
      });

      test('points to help, and does not coach through, disordered eating, '
          'feeling out of control with food, or a crisis', () {
        expectAll([
          'disordered eating',
          'out of control with food',
          'a crisis',
          "don't coach through it",
          'Thank them for saying it',
          'ANAD',
          '1-888-375-7767',
          'call or text 988',
        ]);
      });

      test('the numbers rule exempts the help lines, so it cannot suppress '
          'them', () {
        // "Only mention numbers that are in the person's data" would
        // otherwise forbid the two numbers the Safety section requires.
        expectAll(['apart from the help-line numbers under Safety']);
        final rule = text.indexOf('Only mention numbers');
        expect(rule, isNonNegative);
        expect(text.indexOf('1-888-375-7767'), greaterThan(rule));
      });

      test('stays short enough for the on-device context', () {
        // About 3 to 4 characters per token in English: 2,600 characters
        // is roughly 650 to 870 tokens of the 4,096-token window, leaving
        // the rest for the week's data, prompts and replies.
        expect(text.length, lessThan(2600));
      });
    });
  }

  test('the weekly session keeps logging and steps as separate threads', () {
    const text = CoachInstructions.weeklySession;
    expect(text, contains('two things, one at a time, as separate topics'));
    final logging = text.indexOf('first logging consistency');
    final steps = text.indexOf('then step consistency');
    expect(logging, isNonNegative);
    expect(steps, greaterThan(logging));
  });

  test('the weekly session is about 5 minutes, and says to keep it brief', () {
    const text = CoachInstructions.weeklySession;
    expect(
      text,
      contains(
        'about 5 minutes, so keep it brief: one or two questions per topic '
        'and short replies',
      ),
    );
    expect(text, isNot(contains('15 minutes')));
  });

  test('the weekly session reflects on cravings without comparing weeks', () {
    expect(
      CoachInstructions.weeklySession,
      contains("Don't compare craving counts with other weeks"),
    );
  });

  group('session instructions and the summary request', () {
    test("a session's instructions are its kind's, then the data", () {
      final text = CoachInstructions.forSession(
        CoachInstructions.chat,
        'Mon Oct 19: logged fully',
      );
      expect(text, startsWith(CoachInstructions.chat));
      expect(text, endsWith("The person's data:\nMon Oct 19: logged fully"));
    });

    test('the summary request is short and defers to the summary '
        'instructions', () {
      const request = CoachInstructions.summaryRequest;
      expect(request, contains('neutral'));
      expect(request, contains('following your instructions'));
      expect(request.length, lessThan(400));
    });
  });

  group('summary instructions', () {
    const text = CoachInstructions.summary;
    final lower = text.toLowerCase();

    void expectAll(List<String> phrases) {
      for (final phrase in phrases) {
        expect(lower, contains(phrase.toLowerCase()), reason: phrase);
      }
    }

    test("don't carry the coaching rules, which ask for questions", () {
      // The coaching rules say "ask questions"; a summary must not.
      expect(text, isNot(contains(CoachInstructions.rules)));
      expect(lower, isNot(contains('ask questions')));
      expectAll(['you are not the coach', "don't coach", "don't ask anything"]);
    });

    test('covers tracking habits and next week, briefly', () {
      expectAll([
        'two or three short, neutral sentences',
        'tracking habits',
        'anything they chose to try next week',
      ]);
    });

    test('gives no advice, questions, judgement, streaks or praise', () {
      expectAll([
        'No advice, no questions and no judgement',
        'No streaks, grades, scores or praise',
        "Don't call days or foods good or bad",
      ]);
    });

    test('leaves out cravings and exact numbers (CLAUDE.md §7)', () {
      expectAll([
        'Leave out cravings',
        'Leave out exact numbers',
        'no calories, steps, weights or counts',
      ]);
    });

    test('never adds calorie targets, weight goals, deficits or diets', () {
      expectAll([
        'Never add a calorie target',
        'a weight goal',
        'a calorie deficit',
        'a diet',
        'a meal plan',
      ]);
    });

    test('handles disordered eating or a crisis without detail', () {
      expectAll([
        'disordered eating',
        'out of control with food',
        'a crisis',
        'say only that they talked about something hard',
        'were pointed to help',
      ]);
    });

    test('stays short enough for the on-device context', () {
      expect(text.length, lessThan(2600));
    });
  });

  group('context summary instructions (carried forward, never stored)', () {
    const text = CoachInstructions.contextSummary;
    final lower = text.toLowerCase();

    void expectAll(List<String> phrases) {
      for (final phrase in phrases) {
        expect(lower, contains(phrase.toLowerCase()), reason: phrase);
      }
    }

    test("don't carry the coaching rules, and don't coach or ask", () {
      expect(text, isNot(contains(CoachInstructions.rules)));
      expectAll(['you are not the coach', "don't coach", "don't ask anything"]);
    });

    test('keeps what the coach needs to carry on, cravings and numbers '
        'included', () {
      expectAll([
        'so the coach can carry on',
        'including cravings and any numbers they mentioned',
      ]);
      expect(lower, isNot(contains('leave out cravings')));
    });

    test('gives no advice, questions, judgement, streaks or praise', () {
      expectAll([
        'No advice, no questions and no judgement',
        'No streaks, grades, scores or praise',
      ]);
    });

    test('never adds calorie targets, weight goals, deficits or diets', () {
      expectAll([
        'Never add a calorie target',
        'a weight goal',
        'a calorie deficit',
        'a diet',
        'a meal plan',
      ]);
    });

    test('keeps a crisis or disordered eating in view, with the help', () {
      expectAll([
        'disordered eating',
        'out of control with food',
        'a crisis',
        'were pointed to help',
      ]);
    });

    test('stays short enough for the on-device context', () {
      expect(text.length, lessThan(2600));
    });
  });

  group('copy', () {
    test('the not-medical-advice note says so', () {
      expect(CoachCopy.notMedicalAdvice, contains("isn't medical advice"));
      expect(CoachCopy.notMedicalAdvice, contains('talk to a doctor'));
    });

    test('the help line matches the numbers in the instructions', () {
      for (final number in ['1-888-375-7767', '988']) {
        expect(CoachCopy.helpLine, contains(number));
        expect(CoachInstructions.rules, contains(number));
      }
    });
  });
}
