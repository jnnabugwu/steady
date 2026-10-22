import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:flutter_test/flutter_test.dart';

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

    test('stays on midnight across a DST change', () {
      // US DST ends Sun 2026-11-01, inside the week of Fri 2026-10-30.
      final dates = weekCardDates(DateTime(2026, 10, 30));
      expect(dates, hasLength(7));
      expect(dates.every((d) => d.hour == 0 && d.minute == 0), isTrue);
      expect(dates.last, DateTime(2026, 11, 5));
    });
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
