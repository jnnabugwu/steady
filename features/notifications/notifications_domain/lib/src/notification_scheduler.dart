import 'package:failures/failures.dart';

/// Schedules and cancels the local end-of-day reminder notification.
abstract class NotificationScheduler {
  /// Schedules the 10pm reminder for [date], if nothing has been logged yet.
  ResultFuture<Unit> scheduleEndOfDayReminder(DateTime date);

  /// Cancels the reminder for [date], if one is scheduled.
  ResultFuture<Unit> cancelReminder(DateTime date);
}
