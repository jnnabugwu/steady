import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:metrics_domain/metrics_domain.dart';

/// The start of the share-card week containing [date].
///
/// Delegates to `metrics_domain`'s [weekStartFor] with its default anchor
/// (Friday, the product doc's Friday→Thursday window), so the card and a
/// future week view always agree on which 7 days "this week" means. The
/// result is local midnight, so it is safe as a family key (CLAUDE.md §4).
DateTime weekCardStart(DateTime date) => weekStartFor(date);

/// The 7 calendar days starting at [weekStart], each at local midnight.
///
/// Calendar-date arithmetic, not `Duration(days: i)`, so a DST change in
/// the middle of the week doesn't shift a day to 23:00 or 01:00.
List<DateTime> weekCardDates(DateTime weekStart) => List.generate(
  DateTime.daysPerWeek,
  (i) => DateTime(weekStart.year, weekStart.month, weekStart.day + i),
);

/// The shared PNG's file name, e.g. `steady-week-2026-10-16.png` for the
/// week starting Friday 16 October 2026.
String weekCardFileName(DateTime weekStart) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'steady-week-${weekStart.year}-${two(weekStart.month)}-'
      '${two(weekStart.day)}.png';
}

/// One day on the week share card.
@immutable
class WeekCardDay {
  /// Creates one day's card data. Every field but [date] may be absent.
  const WeekCardDay({
    required this.date,
    this.status,
    this.caloriesEaten,
    this.steps,
  });

  /// The calendar day, at local midnight.
  final DateTime date;

  /// The day's check-in status, or `null` when nothing was checked in.
  final LoggingStatus? status;

  /// Calories eaten, if recorded. Shown only when the user opts in.
  final int? caloriesEaten;

  /// Step count, if recorded. Shown only when the user opts in.
  final int? steps;
}

/// Everything the week share card shows: always exactly 7 [days], one per
/// calendar day from [weekStart], including days with nothing recorded.
///
/// Holds only the card's data, never rendered PNG bytes.
@immutable
class WeekCardData {
  /// Creates card data for the week starting [weekStart].
  WeekCardData({required this.weekStart, required List<WeekCardDay> days})
    : assert(days.length == DateTime.daysPerWeek, 'A week has 7 days.'),
      days = List.unmodifiable(days);

  /// Builds the 7 days from whatever `DailyMetric` [rows] exist in the
  /// week. A day with no row becomes an empty [WeekCardDay]; rows outside
  /// the week are ignored.
  factory WeekCardData.fromMetrics(DateTime weekStart, List<DailyMetric> rows) {
    final byDay = {
      for (final row in rows)
        DateTime(row.date.year, row.date.month, row.date.day): row,
    };
    return WeekCardData(
      weekStart: weekStart,
      days: [
        for (final date in weekCardDates(weekStart))
          WeekCardDay(
            date: date,
            status: byDay[date]?.loggingStatus,
            caloriesEaten: byDay[date]?.caloriesEaten,
            steps: byDay[date]?.steps,
          ),
      ],
    );
  }

  /// The first day of the week, at local midnight.
  final DateTime weekStart;

  /// The week's 7 days, in order. Unmodifiable.
  final List<WeekCardDay> days;
}
