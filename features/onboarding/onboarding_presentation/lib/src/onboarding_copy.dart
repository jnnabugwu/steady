import 'package:onboarding_domain/onboarding_domain.dart';

/// Onboarding's words, in one place (docs/design/onboarding.md, "The
/// flow"). The coach's voice is variant B's from the prototype.
///
/// No body or goal questions, no calorie targets and no streaks anywhere:
/// `test/onboarding_copy_test.dart` checks every string.
abstract final class OnboardingCopy {
  // Shared

  /// The quiet way out, in the corner of every question screen.
  static const notNow = 'Not now';

  /// Moves on once a screen is answered.
  static const continueLabel = 'Continue';

  /// Moves on without answering; the step still places a dimmer stone.
  static const skip = 'Skip';

  /// The back arrow's screen-reader label.
  static const back = 'Back';

  /// Shown when a save failed. The flow goes on regardless.
  static const saveFailed =
      'Couldn’t save that on this iPhone. You can change it later in '
      'Settings.';

  /// Shown when the stored answers couldn't be read.
  static const readFailed = 'Steady couldn’t open your answers on this iPhone.';

  /// Reads the stored answers again after [readFailed].
  static const tryAgain = 'Try again';

  // 1. Place your first stone

  /// Screen 1's title.
  static const firstStoneTitle = 'Place your first stone';

  /// Screen 1's line.
  static const firstStoneReason = 'Log more days, without the guilt.';

  /// Screen 1's hint, before the stone is placed.
  static const firstStoneHint = 'Tap the stone, or drag it to the ground.';

  /// Screen 1, once the stone is down.
  static const firstStonePlaced =
      'That’s your first stone. Each step here adds another.';

  /// The stone's screen-reader label before it's placed.
  static const stoneToPlace = 'A stone. Double-tap to place it on the ground.';

  /// The stone's screen-reader label once it's placed.
  static const stonePlaced = 'Your first stone, on the ground.';

  // 2. How you track food

  /// Screen 2's title.
  static const trackingTitle = 'How do you track what you eat?';

  /// Screen 2's reason line.
  static const trackingReason = 'So Today shows the right thing.';

  /// Screen 2's rows.
  static String tracking(FoodTracking tracking) => switch (tracking) {
    FoodTracking.calAi => 'Cal AI',
    FoodTracking.otherHealthApp => 'Another app that writes to Apple Health',
    FoodTracking.justStarting => 'I’m just starting',
  };

  // 3. Where did you hear about Steady?

  /// Screen 3's title.
  static const sourceTitle = 'Where did you hear about Steady?';

  /// Screen 3's reason line.
  static const sourceReason = 'It helps a small app know what’s working.';

  // 4. Apple Health

  /// Screen 4's title.
  static const healthTitle = 'Bring in Apple Health';

  /// Screen 4's reason line. The claim is Steady's own, not Apple Health's
  /// (which can sync through iCloud itself): Steady reads Health live and
  /// never saves its values, so they never reach Steady's iCloud sync
  /// (CLAUDE.md §7).
  static const healthReason =
      'Steps, energy and calories eaten show up on Today. Steady reads them '
      'live and never saves them, so they never go into Steady’s iCloud '
      'sync.';

  /// The caption over the sample tiles.
  static const healthPreviewCaption = 'A sample of Today';

  /// Screen 4's button: the app asks for Apple Health next.
  static const healthConnect = 'Connect Apple Health';

  // 5. Your week

  /// Screen 5's title.
  static const weekTitle = 'What does your week look like?';

  /// Screen 5's reason line.
  static const weekReason = 'So the coach’s ideas fit your days.';

  /// Screen 5's first group.
  static const activitiesHeading = 'What keeps you moving';

  /// Screen 5's second group.
  static const weekendsHeading = 'My weekends are';

  /// Screen 5's activity chips.
  static String activity(OnboardingActivity activity) => switch (activity) {
    OnboardingActivity.tennis => 'Tennis',
    OnboardingActivity.gym => 'Gym',
    OnboardingActivity.walks => 'Walks',
    OnboardingActivity.runs => 'Runs',
    OnboardingActivity.yoga => 'Yoga',
    OnboardingActivity.other => 'Other',
  };

  /// Screen 5's weekend rows.
  static String weekends(WeekendShape weekends) => switch (weekends) {
    WeekendShape.busier => 'Busier',
    WeekendShape.quieter => 'Quieter',
    WeekendShape.mixed => 'All over the place',
  };

  // 6. What gets in the way

  /// Screen 6's title.
  static const hardPartsTitle = 'What gets in the way of logging?';

  /// Screen 6's reason line.
  static const hardPartsReason =
      'Pick any. The coach plans around them, without judging.';

  /// Screen 6's rows.
  static String hardPart(HardPart part) => switch (part) {
    HardPart.eatingOut => 'Eating out',
    HardPart.lateNights => 'Late nights',
    HardPart.weekends => 'Weekends',
    HardPart.forgetting => 'Forgetting',
    HardPart.travel => 'Travel',
    HardPart.feelingJudged => 'Feeling judged',
  };

  // 7. Your coach's voice

  /// Screen 7's title.
  static const voiceTitle = 'How should your coach talk to you?';

  /// Screen 7's reason line.
  static const voiceReason =
      'Pick one to hear it. You can change it later in Settings.';

  /// Screen 7's rows.
  static String voice(CoachVoice voice) => switch (voice) {
    CoachVoice.gentle => 'Gentle',
    CoachVoice.direct => 'Direct',
    CoachVoice.playful => 'Playful',
  };

  /// The line under each voice's row.
  static String voiceDetail(CoachVoice voice) => switch (voice) {
    CoachVoice.gentle => 'Warm and patient',
    CoachVoice.direct => 'Straight to the point, never harsh',
    CoachVoice.playful => 'Light, with a little fun',
  };

  /// What the person says in the sample exchange.
  static const sampleSituation = 'I skipped logging Saturday.';

  /// The coach's answer to [sampleSituation] in [voice], written in advance
  /// (no network). **A Direct coach still never shames:** every voice names
  /// the gap without blame and offers one small next step.
  static String sampleReply(CoachVoice voice) => switch (voice) {
    CoachVoice.gentle =>
      'Saturdays are often the hardest day to log, and one quiet day '
          'doesn’t undo the rest of your week. Want to pick one small thing '
          'that would make next Saturday easier?',
    CoachVoice.direct =>
      'One skipped Saturday is a gap, not a problem. What got in the way: '
          'plans, or just forgetting? Let’s pick one fix for next Saturday.',
    CoachVoice.playful =>
      'Saturday went off the map! Happens to the best of us, and weekends '
          'are sneaky. Want to try a ten-second log right after you get '
          'home?',
  };

  /// The sample exchange's labels, for screen readers.
  static const sampleYou = 'You';

  /// The coach's side of the sample exchange.
  static const sampleCoach = 'Coach';

  // 8. Meet the coach

  /// Screen 8's title.
  static const meetCoachTitle = 'Meet your coach';

  /// Screen 8's reason line.
  static const meetCoachReason =
      'A 5-minute check-in each week, and a chat whenever you want one.';

  /// Screen 8's intro.
  static const meetCoachIntro =
      'It talks about logging, steps and what gets in the way. It never sets '
      'calorie targets or weight goals, and it asks before it sends '
      'anything.';

  /// The optional note's label.
  static const noteLabel = 'Anything else the coach should know?';

  /// The optional note's placeholder.
  static const notePlaceholder = 'Optional, e.g. I work nights twice a month';

  /// Screen 8's button: the app shows the coach's consent screen next.
  static const turnOnCoach = 'Turn on the coach';

  // 9. Your first week

  /// Screen 9's title.
  static const firstWeekTitle = 'Your first week';

  /// Screen 9's reason line.
  static const firstWeekReason =
      'A few small things to try, from your answers. None of them are rules.';

  /// Screen 9's button.
  static const firstWeekContinue = 'Sounds good';

  // 10. Your cairn

  /// Screen 10's title.
  static const cairnTitle = 'Your cairn';

  /// Screen 10's line.
  static const cairnNext = 'Tonight’s check-in adds the next.';

  /// Screen 10's second line: skipped steps left stones too.
  static const cairnSkipped = 'A skipped step still placed a stone.';

  /// Screen 10's button.
  static const goToToday = 'Go to Today';
}
