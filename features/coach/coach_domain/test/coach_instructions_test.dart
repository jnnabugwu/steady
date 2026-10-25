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
          'ANAD',
          '1-888-375-7767',
          'call or text 988',
        ]);
      });

      test('the numbers rule exempts the help lines, so it cannot suppress '
          'them', () {
        // "Only mention numbers that are in the person's data" would
        // otherwise forbid the two numbers the Safety section requires.
        expectAll(["apart from the help-line numbers under Safety"]);
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

  test('the weekly session reflects on cravings without comparing weeks', () {
    expect(
      CoachInstructions.weeklySession,
      contains("Don't compare craving counts with other weeks"),
    );
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
