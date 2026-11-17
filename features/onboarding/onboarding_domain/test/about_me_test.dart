import 'package:flutter_test/flutter_test.dart';
import 'package:onboarding_domain/onboarding_domain.dart';

void main() {
  group('aboutMeNoteMaxChars', () {
    test('is 200 (docs/design/onboarding.md, screen 8)', () {
      expect(aboutMeNoteMaxChars, 200);
    });
  });

  group('isValidAboutMeNote', () {
    test('null (skipped) is valid', () {
      expect(isValidAboutMeNote(null), isTrue);
    });

    test('exactly the limit is valid; one more is not', () {
      expect(isValidAboutMeNote('a' * aboutMeNoteMaxChars), isTrue);
      expect(isValidAboutMeNote('a' * (aboutMeNoteMaxChars + 1)), isFalse);
    });

    test('counts code points, not UTF-16 units, like the coach', () {
      // '😀' is one code point but two UTF-16 units: 200 of them is 400
      // `length` and still fits. Matches `coachMaxMessageChars`, and the
      // proxy's code-point cap on messages; whether the proxy counts the
      // note the same way is an assumption until its `aboutMe` field lands.
      final emoji = '😀' * aboutMeNoteMaxChars;
      expect(emoji.length, 2 * aboutMeNoteMaxChars);
      expect(isValidAboutMeNote(emoji), isTrue);
      expect(isValidAboutMeNote('$emoji!'), isFalse);
    });
  });

  group('trimAboutMeNote', () {
    test('a blank or null note is no note', () {
      expect(trimAboutMeNote(null), isNull);
      expect(trimAboutMeNote(''), isNull);
      expect(trimAboutMeNote(' \n\t '), isNull);
    });

    test('trims the ends only', () {
      expect(trimAboutMeNote('  I work\n nights \n'), 'I work\n nights');
    });

    test('never cuts: an over-long note stays over-long', () {
      final long = 'a' * (aboutMeNoteMaxChars + 1);
      expect(trimAboutMeNote(' $long '), long);
      expect(isValidAboutMeNote(trimAboutMeNote(long)), isFalse);
    });
  });

  group('clampAboutMeNote', () {
    test('trims, and leaves a short note as it is', () {
      expect(clampAboutMeNote('  I work nights  '), 'I work nights');
    });

    test('a blank or null note is skipped', () {
      expect(clampAboutMeNote(null), isNull);
      expect(clampAboutMeNote(''), isNull);
      expect(clampAboutMeNote(' \n\t '), isNull);
    });

    test('cuts to the limit in code points, never splitting one', () {
      final clamped = clampAboutMeNote('😀' * (aboutMeNoteMaxChars + 5))!;
      expect(clamped.runes.length, aboutMeNoteMaxChars);
      expect(clamped, '😀' * aboutMeNoteMaxChars);
      expect(isValidAboutMeNote(clamped), isTrue);
    });

    test('trims before counting', () {
      final note = '${' ' * 10}${'a' * aboutMeNoteMaxChars}${' ' * 10}';
      expect(clampAboutMeNote(note), 'a' * aboutMeNoteMaxChars);
    });
  });

  group('AboutMe', () {
    test('defaults to every answer skipped', () {
      // The default constructor itself, not the constant it should equal.
      // ignore: use_named_constants
      const aboutMe = AboutMe();
      expect(aboutMe.voice, isNull);
      expect(aboutMe.tracking, isNull);
      expect(aboutMe.activities, isEmpty);
      expect(aboutMe.weekends, isNull);
      expect(aboutMe.hardParts, isEmpty);
      expect(aboutMe.note, isNull);
      expect(aboutMe, AboutMe.empty);
      expect(aboutMe.isEmpty, isTrue);
    });

    test('any answer makes it non-empty', () {
      expect(const AboutMe(voice: CoachVoice.direct).isEmpty, isFalse);
      expect(const AboutMe(hardParts: {HardPart.travel}).isEmpty, isFalse);
      expect(const AboutMe(note: 'hi').isEmpty, isFalse);
    });

    test('compares sets by contents, not order or identity', () {
      expect(
        const AboutMe(
          activities: {OnboardingActivity.walks, OnboardingActivity.tennis},
        ),
        const AboutMe(
          activities: {OnboardingActivity.tennis, OnboardingActivity.walks},
        ),
      );
    });

    test('its sets are unmodifiable', () {
      // A growable set in: freezed wraps it, so the entity can't be
      // changed through its getter.
      final activities = {OnboardingActivity.gym};
      final aboutMe = AboutMe(activities: activities);
      expect(
        () => aboutMe.activities.add(OnboardingActivity.yoga),
        throwsUnsupportedError,
      );
    });
  });

  group('OnboardingRecord', () {
    test('initial is not completed, not started, nothing answered', () {
      expect(OnboardingRecord.initial.completed, isFalse);
      expect(OnboardingRecord.initial.step, isNull);
      expect(OnboardingRecord.initial.aboutMe, AboutMe.empty);
      // The default constructor itself, not the constant.
      // ignore: use_named_constants
      expect(const OnboardingRecord(), OnboardingRecord.initial);
    });

    test('whenUnreadable is done, with nothing answered and no step', () {
      expect(OnboardingRecord.whenUnreadable.completed, isTrue);
      expect(OnboardingRecord.whenUnreadable.step, isNull);
      expect(OnboardingRecord.whenUnreadable.aboutMe, AboutMe.empty);
    });
  });
}
