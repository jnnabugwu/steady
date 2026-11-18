import 'package:flutter_test/flutter_test.dart';
import 'package:onboarding_domain/onboarding_domain.dart';
import 'package:onboarding_presentation/onboarding_presentation.dart';

/// Every About me worth checking: nothing, each single answer, and
/// everything at once.
Iterable<AboutMe> _everyShape() sync* {
  yield AboutMe.empty;
  for (final tracking in FoodTracking.values) {
    yield AboutMe(tracking: tracking);
  }
  for (final activity in OnboardingActivity.values) {
    yield AboutMe(activities: {activity});
  }
  for (final weekends in WeekendShape.values) {
    yield AboutMe(weekends: weekends);
  }
  for (final part in HardPart.values) {
    yield AboutMe(hardParts: {part});
  }
  for (final voice in CoachVoice.values) {
    yield AboutMe(voice: voice);
  }
  yield AboutMe(
    tracking: FoodTracking.calAi,
    activities: OnboardingActivity.values.toSet(),
    weekends: WeekendShape.busier,
    hardParts: HardPart.values.toSet(),
    voice: CoachVoice.direct,
    note: 'I work nights twice a month',
  );
}

void main() {
  group('firstWeekSuggestions', () {
    test('built from the answers: what gets in the way, then an activity, '
        'then the weekends', () {
      expect(
        firstWeekSuggestions(
          const AboutMe(
            activities: {OnboardingActivity.tennis, OnboardingActivity.walks},
            weekends: WeekendShape.busier,
            hardParts: {HardPart.eatingOut, HardPart.lateNights},
          ),
        ),
        [
          'When you eat out, log a rough guess. Close enough counts.',
          'On tennis days, log lunch before you head out.',
          'On a busy weekend day, logging one meal is plenty.',
        ],
      );
    });

    test('nothing answered gets the two general suggestions', () {
      expect(firstWeekSuggestions(AboutMe.empty), generalSuggestions);
      expect(generalSuggestions, hasLength(2));
    });

    test('one templated answer gets three; the general ones fill in', () {
      final one = firstWeekSuggestions(
        const AboutMe(tracking: FoodTracking.justStarting),
      );
      expect(one, [
        'Start with one meal a day. More can come later.',
        ...generalSuggestions,
      ]);
    });

    test('only the voice or the note gets the two general ones: '
        'they shape how the coach talks, not what to try', () {
      for (final aboutMe in [
        const AboutMe(voice: CoachVoice.gentle),
        const AboutMe(note: 'I work nights'),
        const AboutMe(voice: CoachVoice.playful, note: 'I work nights'),
      ]) {
        expect(firstWeekSuggestions(aboutMe), generalSuggestions);
      }
    });

    test('three exactly when an answer has a template behind it', () {
      for (final aboutMe in _everyShape()) {
        final templated =
            aboutMe.tracking != null ||
            aboutMe.weekends != null ||
            aboutMe.activities.isNotEmpty ||
            aboutMe.hardParts.isNotEmpty;
        expect(
          firstWeekSuggestions(aboutMe),
          hasLength(templated ? 3 : 2),
          reason: '$aboutMe',
        );
      }
    });

    test('two or three, never repeated, whatever the answers', () {
      for (final aboutMe in _everyShape()) {
        final suggestions = firstWeekSuggestions(aboutMe);
        expect(suggestions.length, inInclusiveRange(2, 3), reason: '$aboutMe');
        expect(suggestions.toSet(), hasLength(suggestions.length));
      }
    });

    test('never a calorie target, weight goal, diet rule or streak', () {
      final banned = RegExp(
        r'\d|calorie|kcal|weight|goal|target|diet|streak|in a row|\blose\b|'
        'should|must|never miss|fail',
        caseSensitive: false,
      );
      for (final aboutMe in _everyShape()) {
        for (final suggestion in firstWeekSuggestions(aboutMe)) {
          expect(suggestion, isNot(matches(banned)), reason: suggestion);
        }
      }
    });

    test('the same answers always give the same list', () {
      const aboutMe = AboutMe(
        hardParts: {HardPart.travel, HardPart.weekends},
        activities: {OnboardingActivity.runs},
      );
      expect(firstWeekSuggestions(aboutMe), firstWeekSuggestions(aboutMe));
    });
  });
}
