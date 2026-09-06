/// Decides whether tonight's end-of-day reminder should fire.
///
/// Takes a plain `bool` rather than a `DailyMetric?`/`LoggingStatus?` --
/// this keeps `notifications_domain` free of any dependency on
/// `daily_metrics_domain`. The caller (app-layer orchestration, not built
/// yet) is responsible for reducing today's row down to this one bool
/// before calling in.
class EndOfDayReminderPolicy {
  /// Returns `true` if the 10pm reminder should be scheduled, i.e. nothing
  /// has been logged for today yet.
  bool shouldSchedule({required bool hasAnyLogForToday}) =>
      !hasAnyLogForToday;
}
