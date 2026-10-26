import 'package:coach_domain/coach_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// "Keep going" (#80, Jordan's decision of 2026-10-25): a reply cut off at
/// the reply cap is trimmed to its last complete sentence, and the screen
/// offers to continue it.
void main() {
  /// A reply long enough for the iOS 26 heuristic: its estimate is more
  /// than half the cap.
  final long = 'You logged most days this week. ' * 30;

  group('wasCutOff', () {
    test("the model's own token count reaching the cap is enough", () {
      expect(
        CoachKeepGoing.wasCutOff(
          'Short and complete.',
          outputTokens: coachMaxReplyTokens,
        ),
        isTrue,
      );
    });

    test('a short reply with no ending punctuation is not cut off', () {
      expect(CoachKeepGoing.wasCutOff('Nice work on Tuesday'), isFalse);
      expect(
        CoachKeepGoing.wasCutOff('Nice work on Tuesday', outputTokens: 7),
        isFalse,
      );
    });

    test('without a count, a long reply that stops mid-sentence is', () {
      expect(CoachKeepGoing.wasCutOff('${long}On Thursday you'), isTrue);
    });

    test('a long reply that ends a sentence is not', () {
      expect(CoachKeepGoing.wasCutOff(long), isFalse);
      expect(CoachKeepGoing.wasCutOff('$long What felt hardest?'), isFalse);
      expect(CoachKeepGoing.wasCutOff('$long ("Logged.")'), isFalse);
    });

    test('a count below the cap still falls back to the heuristic', () {
      // A count that came out low can't hide an obvious cut.
      expect(
        CoachKeepGoing.wasCutOff('${long}On Thursday you', outputTokens: 3),
        isTrue,
      );
    });

    test('an empty reply is never cut off', () {
      expect(CoachKeepGoing.wasCutOff('   '), isFalse);
    });
  });

  group('trim', () {
    test('drops the unfinished sentence', () {
      expect(
        CoachKeepGoing.trim('You logged Monday. Then on Tuesday you'),
        'You logged Monday.',
      );
    });

    test('keeps closing quotes and brackets with their sentence', () {
      expect(
        CoachKeepGoing.trim('You called it "a good start." And then'),
        'You called it "a good start."',
      );
      expect(
        CoachKeepGoing.trim('(That was Monday!) Tuesday was'),
        '(That was Monday!)',
      );
    });

    test('a complete list item ends at its line break', () {
      expect(
        CoachKeepGoing.trim(
          'Two ideas:\n- Log breakfast first\n- Walk after lun',
        ),
        'Two ideas:\n- Log breakfast first',
      );
    });

    test('a list number is not a sentence end', () {
      expect(
        CoachKeepGoing.trim('Ideas:\n1. Log breakfast\n2. Wal'),
        'Ideas:\n1. Log breakfast',
      );
    });

    test('a decimal is not a sentence end', () {
      expect(
        CoachKeepGoing.trim('You walked 2.5 miles. On Sunday 1.5 mi'),
        'You walked 2.5 miles.',
      );
    });

    test('CJK sentences end without a following space', () {
      expect(CoachKeepGoing.trim('月曜日は記録しました。火曜日は'), '月曜日は記録しました。');
    });

    test('a reply with no complete sentence is kept whole', () {
      expect(
        CoachKeepGoing.trim('  You logged every single day this '),
        'You logged every single day this',
      );
    });

    test('a complete reply is unchanged', () {
      expect(
        CoachKeepGoing.trim('All good. Well done? '),
        'All good. Well done?',
      );
    });
  });

  test('the prompt asks to go on, and the transcript stores "Keep going"', () {
    expect(
      CoachKeepGoing.prompt,
      startsWith(
        'Please go on from where you '
        'stopped.',
      ),
    );
    expect(CoachKeepGoing.message, 'Keep going');
  });
}
