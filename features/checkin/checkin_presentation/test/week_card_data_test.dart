import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// The local days in [year] during which the host time zone changes its UTC
/// offset (DST starts or ends), found by comparing consecutive midnights.
///
/// Derived from the host zone instead of hard-coding a US date: Dart's local
/// time always follows the host's zone (it can't be overridden from inside a
/// test), and this repo's CI runs no tests, so there is no fixed zone to rely
/// on. Empty when the host zone has no DST, in which case there is nothing
/// to cross and the DST test is skipped rather than passing vacuously.
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
  group('weekCardStart', () {
    test('is the Friday that starts the Friday-Thursday week', () {
      // Mon 2026-08-24 → Fri 2026-08-21.
      expect(weekCardStart(DateTime(2026, 8, 24)), DateTime(2026, 8, 21));
      // Thu 2026-08-27 is the last day of the same week.
      expect(weekCardStart(DateTime(2026, 8, 27)), DateTime(2026, 8, 21));
      // Fri 2026-08-28 starts the next one.
      expect(weekCardStart(DateTime(2026, 8, 28)), DateTime(2026, 8, 28));
    });

    test('drops the time of day', () {
      expect(
        weekCardStart(DateTime(2026, 8, 24, 21, 45)),
        DateTime(2026, 8, 21),
      );
    });

    test('crosses a month boundary', () {
      // Thu 2026-10-01 → Fri 2026-09-25.
      expect(weekCardStart(DateTime(2026, 10)), DateTime(2026, 9, 25));
    });

    test('crosses a year boundary', () {
      // Thu 2026-01-01 → Fri 2025-12-26.
      expect(weekCardStart(DateTime(2026)), DateTime(2025, 12, 26));
    });
  });

  group('weekCardDates', () {
    test('7 consecutive midnights across a month boundary', () {
      expect(weekCardDates(DateTime(2026, 9, 25)), [
        DateTime(2026, 9, 25),
        DateTime(2026, 9, 26),
        DateTime(2026, 9, 27),
        DateTime(2026, 9, 28),
        DateTime(2026, 9, 29),
        DateTime(2026, 9, 30),
        DateTime(2026, 10),
      ]);
    });

    test('7 consecutive midnights across a year boundary', () {
      expect(weekCardDates(DateTime(2025, 12, 26)), [
        DateTime(2025, 12, 26),
        DateTime(2025, 12, 27),
        DateTime(2025, 12, 28),
        DateTime(2025, 12, 29),
        DateTime(2025, 12, 30),
        DateTime(2025, 12, 31),
        DateTime(2026),
      ]);
    });

    test('the week of Fri 2026-10-30 is 7 midnights ending Thu 11-05', () {
      // A fixed-date check. It only crosses a DST change (US DST ends Sun
      // 2026-11-01) on a host in a US zone; the host-zone test below is the
      // one that always does.
      final dates = weekCardDates(DateTime(2026, 10, 30));
      expect(dates, hasLength(7));
      expect(dates.every((d) => d.hour == 0 && d.minute == 0), isTrue);
      expect(dates.last, DateTime(2026, 11, 5));
    });

    final dstChanges = _dstChangeDays(2026);
    test(
      "stays on midnight across the host zone's DST changes",
      () {
        for (final change in dstChanges) {
          // The share-card week that contains the change day.
          final weekStart = weekCardStart(change);
          final dates = weekCardDates(weekStart);
          final reason = 'week of $weekStart, DST change on $change';
          expect(dates, hasLength(7), reason: reason);
          expect(dates, contains(change), reason: reason);
          if (change.weekday != DateTime.thursday) {
            // Unless the clocks change on the window's last night, the
            // week's midnights straddle the change.
            expect(
              dates.first.timeZoneOffset,
              isNot(dates.last.timeZoneOffset),
              reason: 'precondition: $reason',
            );
          }
          expect(
            dates.every((d) => d.hour == 0 && d.minute == 0),
            isTrue,
            reason: reason,
          );
          // Consecutive calendar days, counted in UTC so DST can't skew it.
          for (var i = 1; i < dates.length; i++) {
            final gap =
                DateTime.utc(
                  dates[i].year,
                  dates[i].month,
                  dates[i].day,
                ).difference(
                  DateTime.utc(
                    dates[i - 1].year,
                    dates[i - 1].month,
                    dates[i - 1].day,
                  ),
                );
            expect(gap, const Duration(days: 1), reason: reason);
          }
        }
      },
      skip: dstChanges.isEmpty
          ? 'The host time zone has no DST change in 2026.'
          : false,
    );
  });

  test('weekCardFileName is dated by the week start', () {
    expect(
      weekCardFileName(DateTime(2026, 8, 21)),
      'steady-week-2026-08-21.png',
    );
    expect(weekCardFileName(DateTime(2027)), 'steady-week-2027-01-01.png');
  });

  group('WeekCardData.fromMetrics', () {
    final weekStart = DateTime(2026, 8, 21);

    test('always has 7 days, empty where nothing was recorded', () {
      final data = WeekCardData.fromMetrics(weekStart, [
        DailyMetric(
          date: DateTime(2026, 8, 22),
          loggingStatus: LoggingStatus.partial,
          caloriesEaten: 1850,
          steps: 8204,
        ),
      ]);

      expect(data.weekStart, weekStart);
      expect(data.days.map((d) => d.date), weekCardDates(weekStart));
      expect(data.days[1].status, LoggingStatus.partial);
      expect(data.days[1].caloriesEaten, 1850);
      expect(data.days[1].steps, 8204);
      for (final i in [0, 2, 3, 4, 5, 6]) {
        expect(data.days[i].status, isNull);
        expect(data.days[i].caloriesEaten, isNull);
        expect(data.days[i].steps, isNull);
      }
    });

    test('ignores rows outside the week', () {
      final data = WeekCardData.fromMetrics(weekStart, [
        DailyMetric(
          date: DateTime(2026, 8, 20),
          loggingStatus: LoggingStatus.logged,
        ),
        DailyMetric(
          date: DateTime(2026, 8, 28),
          loggingStatus: LoggingStatus.logged,
        ),
      ]);

      expect(data.days.every((d) => d.status == null), isTrue);
    });

    test('matches a row whose date carries a time of day', () {
      final data = WeekCardData.fromMetrics(weekStart, [
        DailyMetric(
          date: DateTime(2026, 8, 27, 23, 59),
          loggingStatus: LoggingStatus.skipped,
        ),
      ]);

      expect(data.days.last.status, LoggingStatus.skipped);
    });
  });
}
