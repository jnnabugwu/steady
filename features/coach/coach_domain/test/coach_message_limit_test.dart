import 'package:coach_domain/coach_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the message cap matches the proxy: 1,000 code points', () {
    expect(coachMaxMessageChars, 1000);
  });

  test('clamps a message to the longest allowed, trimmed', () {
    expect(clampCoachMessage('  hi  '), 'hi');
    expect(clampCoachMessage('x' * 5000).length, coachMaxMessageChars);
  });

  test('counts code points, so an emoji is never split', () {
    final emoji = '🙂' * (coachMaxMessageChars + 10);
    final clamped = clampCoachMessage(emoji);
    expect(clamped.runes.length, coachMaxMessageChars);
    expect(clamped.runes.every((r) => r == '🙂'.runes.single), isTrue);
  });
}
