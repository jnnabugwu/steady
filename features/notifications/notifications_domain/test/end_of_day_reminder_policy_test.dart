import 'package:flutter_test/flutter_test.dart';
import 'package:notifications_domain/notifications_domain.dart';

void main() {
  group('EndOfDayReminderPolicy', () {
    final policy = EndOfDayReminderPolicy();

    test('schedules when nothing has been logged today', () {
      expect(policy.shouldSchedule(hasAnyLogForToday: false), isTrue);
    });

    test('does not schedule when something has been logged today', () {
      expect(policy.shouldSchedule(hasAnyLogForToday: true), isFalse);
    });
  });
}
