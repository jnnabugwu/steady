import 'package:flutter_test/flutter_test.dart';
import 'package:onboarding_domain/onboarding_domain.dart';
import 'package:onboarding_presentation/onboarding_presentation.dart';

/// Every string onboarding shows.
List<String> _everyString() => [
  OnboardingCopy.notNow,
  OnboardingCopy.continueLabel,
  OnboardingCopy.skip,
  OnboardingCopy.saveFailed,
  OnboardingCopy.readFailed,
  OnboardingCopy.tryAgain,
  OnboardingCopy.firstStoneTitle,
  OnboardingCopy.firstStoneReason,
  OnboardingCopy.firstStoneHint,
  OnboardingCopy.firstStonePlaced,
  OnboardingCopy.stoneToPlace,
  OnboardingCopy.stonePlaced,
  OnboardingCopy.trackingTitle,
  OnboardingCopy.trackingReason,
  for (final t in FoodTracking.values) OnboardingCopy.tracking(t),
  OnboardingCopy.sourceTitle,
  OnboardingCopy.sourceReason,
  for (final s in OnboardingSource.values) s.label,
  OnboardingCopy.healthTitle,
  OnboardingCopy.healthReason,
  OnboardingCopy.healthPreviewCaption,
  OnboardingCopy.healthConnect,
  OnboardingCopy.weekTitle,
  OnboardingCopy.weekReason,
  OnboardingCopy.activitiesHeading,
  OnboardingCopy.weekendsHeading,
  for (final a in OnboardingActivity.values) OnboardingCopy.activity(a),
  for (final w in WeekendShape.values) OnboardingCopy.weekends(w),
  OnboardingCopy.hardPartsTitle,
  OnboardingCopy.hardPartsReason,
  for (final h in HardPart.values) OnboardingCopy.hardPart(h),
  OnboardingCopy.voiceTitle,
  OnboardingCopy.voiceReason,
  for (final v in CoachVoice.values) ...[
    OnboardingCopy.voice(v),
    OnboardingCopy.voiceDetail(v),
    OnboardingCopy.sampleReply(v),
  ],
  OnboardingCopy.sampleSituation,
  OnboardingCopy.meetCoachTitle,
  OnboardingCopy.meetCoachReason,
  OnboardingCopy.meetCoachIntro,
  OnboardingCopy.noteLabel,
  OnboardingCopy.notePlaceholder,
  OnboardingCopy.turnOnCoach,
  OnboardingCopy.firstWeekTitle,
  OnboardingCopy.firstWeekReason,
  OnboardingCopy.firstWeekContinue,
  OnboardingCopy.cairnTitle,
  OnboardingCopy.cairnNext,
  OnboardingCopy.cairnSkipped,
  OnboardingCopy.goToToday,
  OnboardingCopy.aboutMeTitle,
  OnboardingCopy.aboutMeRowDetail,
  OnboardingCopy.aboutMeIntro,
  OnboardingCopy.aboutMeSaveFailed,
  OnboardingCopy.aboutMeTrackingHeading,
  OnboardingCopy.aboutMeWeekHeading,
  OnboardingCopy.aboutMeHardPartsHeading,
  OnboardingCopy.aboutMeVoiceHeading,
  OnboardingCopy.aboutMeNoteHeading,
];

void main() {
  test('no streaks, and the coach is never "Plus" or an upgrade', () {
    final banned = RegExp(
      'streak|in a row|plus|upgrade|premium',
      caseSensitive: false,
    );
    for (final text in _everyString()) {
      expect(text, isNot(matches(banned)), reason: text);
    }
  });

  test('no body or goal questions', () {
    final banned = RegExp(
      'how much do you weigh|your weight|goal weight|height|how old|'
      r'your age|birthday|\bsex\b|gender|daily calorie',
      caseSensitive: false,
    );
    for (final text in _everyString()) {
      expect(text, isNot(matches(banned)), reason: text);
    }
  });

  test('every voice answers the skipped Saturday without shame, '
      'Direct included', () {
    final shame = RegExp(
      'should have|shouldn’t|disappoint|lazy|fail|excuse|no excuses|'
      r'again\?|bad|wrong|guilt|you need to|you have to|must',
      caseSensitive: false,
    );
    for (final voice in CoachVoice.values) {
      final reply = OnboardingCopy.sampleReply(voice);
      expect(reply, isNot(matches(shame)), reason: '$voice: $reply');
      // Each offers one small next step, as a question or an invitation.
      expect(reply, matches(RegExp('Saturday')));
    }
    // Three different voices, not one text.
    expect(
      CoachVoice.values.map(OnboardingCopy.sampleReply).toSet(),
      hasLength(CoachVoice.values.length),
    );
  });

  test("screen 3's codes are pinned, in order", () {
    expect(OnboardingSource.values.map((s) => s.code), [
      'friend',
      'instagram',
      'reddit',
      'appStore',
      'tiktok',
      'other',
    ]);
  });

  test("Health copy makes Steady's claim, not one about Apple Health", () {
    for (final text in _everyString()) {
      if (!text.contains('iCloud')) continue;
      // Apple Health can sync through iCloud itself; what Steady can
      // promise is that its own iCloud sync never holds Health values.
      expect(text, contains('Steady’s iCloud'), reason: text);
      expect(text, isNot(contains('never stored in iCloud')), reason: text);
      expect(text, isNot(contains('stay on this iPhone')), reason: text);
    }
    expect(OnboardingCopy.healthReason, contains('reads them live'));
  });
}
