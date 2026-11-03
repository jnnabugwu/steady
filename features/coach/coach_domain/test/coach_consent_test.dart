import 'package:coach_domain/coach_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// The consent copy (#153, App Store 5.1.2): it has to name who gets the
/// data, list what's sent, and say what it's for.
void main() {
  final all = [
    CoachConsent.title,
    CoachConsent.intro,
    ...CoachConsent.items,
    CoachConsent.use,
    CoachConsent.closing,
  ].join('\n');

  test('the version starts at 1', () {
    expect(CoachConsent.currentVersion, greaterThanOrEqualTo(1));
  });

  test('names Claude and Anthropic', () {
    expect(CoachConsent.intro, contains('Claude'));
    expect(CoachConsent.intro, contains('Anthropic'));
  });

  test("lists everything a conversation sends, and not weight (which isn't "
      'sent)', () {
    const health =
        'steps, energy burned and calories eaten (from Apple Health or your '
        'Cal AI import)';
    expect(CoachConsent.items, [
      "this week's check-ins",
      health,
      'your craving check-ins',
      'what you type to the coach',
    ]);
    expect(all.toLowerCase(), isNot(contains('weight')));
  });

  test("says it's only for the replies, Anthropic's retention, and where "
      'conversations are saved', () {
    expect(CoachConsent.use, contains("only to write the coach's replies"));
    expect(CoachConsent.use, contains('deletes it within 30 days'));
    expect(CoachConsent.use, contains("doesn't use it to train its models"));
    expect(CoachConsent.use, contains('saved only on this iPhone'));
  });

  test('not medical advice, and how to turn it off', () {
    expect(CoachConsent.closing, contains("isn't medical advice"));
    expect(CoachConsent.closing, contains('Settings → Coach'));
  });

  test('the buttons', () {
    expect(CoachConsent.allow, 'Allow and continue');
    expect(CoachConsent.notNow, 'Not now');
  });

  test("the Settings line says what's sent, and to whom", () {
    expect(CoachConsent.settingsLine, contains('Anthropic'));
    expect(CoachConsent.settingsLine, contains('only to write the replies'));
  });
}
