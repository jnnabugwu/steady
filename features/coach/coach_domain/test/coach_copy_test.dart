import 'package:coach_domain/coach_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// The copy the coach screens show (#82). The instructions and their
/// guardrail tests live on the proxy now (`jnnabugwu/steady-backend`).
void main() {
  test('the not-medical-advice note says so', () {
    expect(CoachCopy.notMedicalAdvice, contains("isn't medical advice"));
    expect(CoachCopy.notMedicalAdvice, contains('talk to a doctor'));
  });

  test('the help line gives the eating disorders helpline and 988', () {
    // The same numbers the proxy's instructions point to, word for word in
    // its tests, and the cravings Settings card.
    expect(CoachCopy.helpLine, contains('1-888-375-7767'));
    expect(CoachCopy.helpLine, contains('call or text 988'));
  });

  test('"Keep going" stores a short label and asks the coach to carry on', () {
    expect(CoachKeepGoing.message, 'Keep going');
    expect(CoachKeepGoing.prompt, contains('go on from where you stopped'));
    expect(CoachKeepGoing.prompt.runes.length, lessThan(coachMaxMessageChars));
  });
}
