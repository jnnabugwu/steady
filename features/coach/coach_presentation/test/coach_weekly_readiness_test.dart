import 'package:checkin_domain/checkin_domain.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_domains.dart';

/// The weekly session's gate (#81): the last completed Friday→Thursday
/// week, and the 4-of-7 check-in rule.
void main() {
  group('coachWeeklyWindow', () {
    test('on a Friday, the week that ended yesterday', () {
      final w = coachWeeklyWindow(DateTime(2026, 10, 23, 20)); // Friday
      expect(w.first, DateTime(2026, 10, 16));
      expect(w.last, DateTime(2026, 10, 22));
      expect(w.first.weekday, DateTime.friday);
      expect(w.last.weekday, DateTime.thursday);
    });

    test('later in the week, still the last completed week', () {
      expect(
        coachWeeklyWindow(DateTime(2026, 10, 25, 9)).first,
        DateTime(2026, 10, 16),
      );
      // Thursday the 29th: the 23rd → 29th week isn't over yet.
      expect(
        coachWeeklyWindow(DateTime(2026, 10, 29, 23)).first,
        DateTime(2026, 10, 16),
      );
    });

    test('across a month boundary', () {
      final w = coachWeeklyWindow(DateTime(2026, 11, 6, 8)); // Friday
      expect(w.first, DateTime(2026, 10, 30));
      expect(w.last, DateTime(2026, 11, 5));
      expect(coachWeekLabel(w.first, w.last), 'Oct 30 – Nov 5');
      expect(
        coachWeekLabel(DateTime(2026, 10, 16), DateTime(2026, 10, 22)),
        'Oct 16 – 22',
      );
    });
  });

  group('CheckWeeklyReadiness', () {
    final friday = DateTime(2026, 10, 23, 20);
    FakeCheckIns days(int count) => FakeCheckIns({
      for (var i = 0; i < count; i++)
        DateTime(2026, 10, 16 + i): CheckInStatus.values[i % 3],
    });

    test('three days with a check-in: the session does not start', () async {
      final result = await CheckWeeklyReadiness(days(3))(friday);
      final week = (result as Ok<WeeklyReadiness>).value;
      expect(week.daysWithCheckIn, 3);
      expect(week.allowed, isFalse);
    });

    test('four days, any status (skipped counts): it starts', () async {
      final result = await CheckWeeklyReadiness(days(4))(friday);
      final week = (result as Ok<WeeklyReadiness>).value;
      expect(week.daysWithCheckIn, 4);
      expect(week.allowed, isTrue);
      expect(week.first, DateTime(2026, 10, 16));
    });

    test("days outside the week don't count", () async {
      final checkIns = FakeCheckIns({
        for (var d = 9; d <= 15; d++)
          DateTime(2026, 10, d): CheckInStatus.logged,
        for (var d = 23; d <= 25; d++)
          DateTime(2026, 10, d): CheckInStatus.logged,
      });
      final result = await CheckWeeklyReadiness(checkIns)(friday);
      expect((result as Ok<WeeklyReadiness>).value.daysWithCheckIn, 0);
    });

    test('a store that fails on every day is the failure, never a quiet '
        'week', () async {
      final checkIns = days(7)..failure = const UnknownFailure('down');
      final result = await CheckWeeklyReadiness(checkIns)(friday);
      expect(result, isA<Err<WeeklyReadiness>>());
    });
  });
}
