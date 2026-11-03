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
///
/// The app opens a topic with an app turn (`CoachTurn.app`), which the proxy
/// expands into that topic's prompt (`src/coach/weekly.ts` in
/// `jnnabugwu/steady-backend`). Each value's [name] is the wire value.
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
