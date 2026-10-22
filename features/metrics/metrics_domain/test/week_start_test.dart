import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_domain/metrics_domain.dart';

/// The local days in [year] during which the host time zone changes its UTC
/// offset (DST starts or ends), found by comparing consecutive midnights.
///
/// Derived from the host zone instead of hard-coding a US date: Dart's local
/// time always follows the host's zone (it can't be overridden from inside a
/// test). CI's runners are UTC, so the test workflow sets
/// `TZ=America/Chicago` to make this case run there. Empty when the host
/// zone has no DST, in which case there is nothing to cross and the DST test
/// is skipped rather than passing vacuously.
List<DateTime> _dstChangeDays(int year) => [
  for (
    var day = DateTime(year);
    day.year == year;
    day = DateTime(day.year, day.month, day.day + 1)
  )
    if (DateTime(day.year, day.month, day.day + 1).timeZoneOffset !=
        day.timeZoneOffset)
      day,
];

void main() {
  group('weekStartFor', () {
    test('defaults to the Friday anchor (Friday-Thursday window)', () {
      // 2026-10-22 is a Thursday, the last day of the week starting Fri 16th.
      expect(weekStartFor(DateTime(2026, 10, 22)), DateTime(2026, 10, 16));
    });

    test('an anchor day is its own week start', () {
      expect(weekStartFor(DateTime(2026, 10, 16)), DateTime(2026, 10, 16));
    });

    test('drops the time of day', () {
      expect(
        weekStartFor(DateTime(2026, 10, 22, 18, 30)),
        DateTime(2026, 10, 16),
      );
    });

    test('crosses a month boundary', () {
      // Thu 2026-10-01 belongs to the week starting Fri 2026-09-25.
      expect(weekStartFor(DateTime(2026, 10)), DateTime(2026, 9, 25));
    });

    test('crosses a year boundary', () {
      // Thu 2026-01-01 belongs to the week starting Fri 2025-12-26.
      expect(weekStartFor(DateTime(2026)), DateTime(2025, 12, 26));
      // Sun 2027-01-03 belongs to the week starting Fri 2027-01-01.
      expect(weekStartFor(DateTime(2027, 1, 3)), DateTime(2027));
    });

    test('the week of US DST end (Sun 2026-11-01) starts Fri 2026-10-30', () {
      // A fixed-date check. It only crosses a DST change on a host in a US
      // zone; the host-zone test below is the one that always does.
      final start = weekStartFor(DateTime(2026, 11, 1, 12));
      expect(start, DateTime(2026, 10, 30));
      expect(start.hour, 0);
    });

    final dstChanges = _dstChangeDays(2026);
    test(
      "lands on midnight across the host zone's DST changes",
      () {
        for (final change in dstChanges) {
          // The day after the clocks changed, at noon. With every anchor
          // weekday, the week start falls on 0-6 days earlier, so at least
          // one (anchored on the change day itself) is on the far side of
          // the change.
          final after = DateTime(change.year, change.month, change.day + 1, 12);
          expect(
            after.timeZoneOffset,
            isNot(change.timeZoneOffset),
            reason: 'precondition: $change and $after straddle a DST change',
          );
          for (
            var anchor = DateTime.monday;
            anchor <= DateTime.sunday;
            anchor++
          ) {
            final start = weekStartFor(after, anchorWeekday: anchor);
            final reason = 'week of $after anchored on weekday $anchor';
            expect(start.hour, 0, reason: reason);
            expect(start.minute, 0, reason: reason);
            expect(start.weekday, anchor, reason: reason);
            // Whole calendar days back, counted in UTC so DST can't skew it.
            final daysBack = DateTime.utc(after.year, after.month, after.day)
                .difference(DateTime.utc(start.year, start.month, start.day))
                .inDays;
            expect(daysBack, inInclusiveRange(0, 6), reason: reason);
          }
          expect(
            weekStartFor(after, anchorWeekday: change.weekday),
            change,
            reason: 'the week anchored on the change day starts before it',
          );
        }
      },
      skip: dstChanges.isEmpty
          ? 'The host time zone has no DST change in 2026.'
          : false,
    );

    test('honors a custom anchor', () {
      expect(
        weekStartFor(DateTime(2026, 10, 22), anchorWeekday: DateTime.monday),
        DateTime(2026, 10, 19),
      );
    });
  });
}
