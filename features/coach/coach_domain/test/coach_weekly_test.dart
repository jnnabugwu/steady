import 'package:coach_domain/coach_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// The weekly session's rule and structure (#81).
void main() {
  group('the 4-of-7 rule', () {
    test('needs at least four days with a check-in', () {
      expect(weeklySessionMinCheckInDays, 4);
      for (var days = 0; days <= 7; days++) {
        expect(weeklySessionAllowed(days), days >= 4, reason: '$days days');
      }
    });
  });

  group('topics', () {
    test('logging, then steps, then next week, as separate threads', () {
      expect(weeklyTopicsFor(cravingCount: 0), [
        WeeklyTopic.logging,
        WeeklyTopic.steps,
        WeeklyTopic.nextWeek,
      ]);
    });

    test('a craving reflection only when there were cravings', () {
      expect(weeklyTopicsFor(cravingCount: 2), [
        WeeklyTopic.logging,
        WeeklyTopic.steps,
        WeeklyTopic.cravings,
        WeeklyTopic.nextWeek,
      ]);
    });
  });

  test("each topic's name is its wire value on the proxy", () {
    expect(WeeklyTopic.values.map((t) => t.name), [
      'logging',
      'steps',
      'cravings',
      'nextWeek',
    ]);
  });
}
