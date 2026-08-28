import 'package:failures/failures.dart';
import 'package:notifications_domain/notifications_domain.dart';

/// An in-memory `NotificationScheduler`, recording scheduled/cancelled
/// dates in a `Set`. There's nothing meaningful to fake about an OS
/// notification actually firing -- the fake's job is just recording what
/// was asked for.
class InMemoryNotificationScheduler implements NotificationScheduler {
  final Set<DateTime> _scheduled = {};

  DateTime _key(DateTime date) => DateTime(date.year, date.month, date.day);

  /// The dates currently scheduled, for test assertions.
  Set<DateTime> get scheduledDates => Set.unmodifiable(_scheduled);

  @override
  ResultFuture<Unit> scheduleEndOfDayReminder(DateTime date) async {
    _scheduled.add(_key(date));
    return const Ok(unit);
  }

  @override
  ResultFuture<Unit> cancelReminder(DateTime date) async {
    _scheduled.remove(_key(date));
    return const Ok(unit);
  }
}
