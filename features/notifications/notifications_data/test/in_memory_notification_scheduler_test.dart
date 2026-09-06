import 'package:flutter_test/flutter_test.dart';
import 'package:notifications_data/notifications_data.dart';

void main() {
  group('InMemoryNotificationScheduler', () {
    test('scheduleEndOfDayReminder records the date', () async {
      final scheduler = InMemoryNotificationScheduler();
      final date = DateTime(2026, 8, 24);

      await scheduler.scheduleEndOfDayReminder(date);

      expect(scheduler.scheduledDates, contains(DateTime(2026, 8, 24)));
    });

    test('cancelReminder removes a scheduled date', () async {
      final scheduler = InMemoryNotificationScheduler();
      final date = DateTime(2026, 8, 24);
      await scheduler.scheduleEndOfDayReminder(date);

      await scheduler.cancelReminder(date);

      expect(scheduler.scheduledDates, isEmpty);
    });
  });
}
