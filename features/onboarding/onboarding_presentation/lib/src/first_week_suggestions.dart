import 'package:onboarding_domain/onboarding_domain.dart';

/// Screen 9's "Your first week": two or three small things to try, built
/// from [aboutMe] by fixed templates, in the app, with no network
/// (docs/design/onboarding.md, "The flow").
///
/// - **Never a calorie target, weight goal or diet rule,** and no streaks:
///   only when and how to log, and that a partial or skipped day still
///   counts. The coach's guardrails hold here too.
/// - What gets in the way comes first (it's what the week will meet), then
///   an activity, then the weekends and how the person tracks food, then
///   the rest of each, in the answers' own order. Two general suggestions
///   fill in where the answers run out.
/// - **Three when any answer has a template behind it** (what gets in
///   the way, an activity, the weekends, how food is tracked): the
///   tailored ones, then the general ones to make up three. **Two, the
///   general ones, when none has:** everything skipped, or only the voice
///   or the note answered, since those shape how the coach talks, not
///   what to try.
///
/// Pure and deterministic: the same answers always give the same list.
List<String> firstWeekSuggestions(AboutMe aboutMe) {
  final hardParts = [
    for (final part in HardPart.values)
      if (aboutMe.hardParts.contains(part)) _forHardPart(part),
  ];
  final activities = [
    for (final activity in OnboardingActivity.values)
      if (aboutMe.activities.contains(activity)) _forActivity(activity),
  ];
  final tailored = [
    ...hardParts.take(1),
    ...activities.take(1),
    if (aboutMe.weekends case final weekends?) _forWeekends(weekends),
    if (aboutMe.tracking case final tracking?) _forTracking(tracking),
    ...hardParts.skip(1),
    ...activities.skip(1),
  ];
  return {
    ...tailored,
    ...generalSuggestions,
  }.take(tailored.isEmpty ? 2 : 3).toList();
}

/// The suggestions for anyone, whatever they answered.
const generalSuggestions = [
  'Check in each night. Logged, partial or skipped, every day counts.',
  'Log one meal a day this week. Anything more is a bonus.',
];

String _forHardPart(HardPart part) => switch (part) {
  HardPart.eatingOut =>
    'When you eat out, log a rough guess. Close enough counts.',
  HardPart.lateNights => 'On a late night, a quick partial check-in is plenty.',
  HardPart.weekends => 'On Saturday, log just one meal. That’s enough.',
  HardPart.forgetting => 'Pick one meal a day and log it right after you eat.',
  HardPart.travel => 'Travelling? Log what you can, and check in as partial.',
  HardPart.feelingJudged =>
    'Nothing here grades your day. Even a skipped day places a stone.',
};

String _forActivity(OnboardingActivity activity) => switch (activity) {
  OnboardingActivity.tennis => 'On tennis days, log lunch before you head out.',
  OnboardingActivity.gym =>
    'On gym days, log your next meal before you leave the gym.',
  OnboardingActivity.walks =>
    'After a walk, take a minute to log your last meal.',
  OnboardingActivity.runs => 'After a run, log breakfast before you shower.',
  OnboardingActivity.yoga => 'After yoga, take a minute to log your next meal.',
  OnboardingActivity.other =>
    'On your active days, log one meal before you head out.',
};

String _forWeekends(WeekendShape weekends) => switch (weekends) {
  WeekendShape.busier => 'On a busy weekend day, logging one meal is plenty.',
  WeekendShape.quieter =>
    'Use a quiet weekend morning to look back at your week.',
  WeekendShape.mixed =>
    'Weekends vary. Check in each night, whatever the day was like.',
};

String _forTracking(FoodTracking tracking) => switch (tracking) {
  FoodTracking.calAi =>
    'Keep logging in Cal AI. Steady can read it from Apple Health.',
  FoodTracking.otherHealthApp =>
    'Keep logging in your usual app. Steady can read it from Apple Health.',
  FoodTracking.justStarting =>
    'Start with one meal a day. More can come later.',
};
