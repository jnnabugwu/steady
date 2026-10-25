/// The weekly session's rule and structure (#81, product overview §6).
library;

/// The fewest days, of the week's seven, that need a check-in status
/// (logged, partial or skipped) before the weekly session starts
/// (CLAUDE.md §4's example rule). With fewer, there isn't enough of the
/// week to talk about; a chat is still there any time.
const int weeklySessionMinCheckInDays = 4;

/// Whether a week with [daysWithCheckIn] days that have any check-in
/// status may have its weekly session.
bool weeklySessionAllowed(int daysWithCheckIn) =>
    daysWithCheckIn >= weeklySessionMinCheckInDays;

/// One thread of the weekly session. Each is its own topic, in this order,
/// never blended into one recap (product overview §6).
enum WeeklyTopic {
  /// How the week felt, then logging consistency.
  logging,

  /// Step consistency.
  steps,

  /// A gentle reflection on the week's craving check-ins: observations
  /// with a question, never a grade. Only when there were any.
  cravings,

  /// One small thing to try next week, chosen by the person.
  nextWeek,
}

/// The topics of a week's session, in order: logging, steps, cravings only
/// if there were [cravingCount] > 0, then next week.
List<WeeklyTopic> weeklyTopicsFor({required int cravingCount}) => [
  WeeklyTopic.logging,
  WeeklyTopic.steps,
  if (cravingCount > 0) WeeklyTopic.cravings,
  WeeklyTopic.nextWeek,
];

/// What the app tells the coach to start [topic] with. App prompts, not
/// the person's words: they never appear in the transcript, only the
/// coach's reply does. Short, since each one counts against the context.
///
/// The craving prompt follows `docs/research/craving_support.md` ("What
/// the weekly review could reflect on"): when and what was behind them, as
/// an observation with a question; no grade, no comparison with other
/// weeks, nothing about calories or food.
String weeklyTopicPrompt(WeeklyTopic topic) => switch (topic) {
  WeeklyTopic.logging =>
    'Begin the weekly check-in. Ask how the week felt. Then talk only about '
        'logging consistency: which days were logged fully, partly or '
        'skipped. One observation from the data, one question.',
  WeeklyTopic.steps =>
    'Move to a new topic: step consistency this week. Leave logging behind. '
        'One observation from the step data, one question. If there is no '
        'step data, say so briefly and ask how moving felt this week.',
  WeeklyTopic.cravings =>
    'Move to a new topic: the craving check-ins this week. Describe when '
        'they came and what was behind them, as an observation, then ask '
        'one question. No grades, no comparison with other weeks, and '
        'nothing about calories or food choices.',
  WeeklyTopic.nextWeek =>
    "Last topic: ask if there's one small thing they'd like to try next "
        'week. If they pick one, help phrase it as something to do, like '
        '"If it\'s 4pm and I\'m tired, then I\'ll have the snack I brought." '
        'Let them choose; never suggest calorie targets or diets.',
};
