/// The local-midnight start of the week containing [date], for weeks that
/// begin on [anchorWeekday] (`DateTime.friday` by default — the product
/// doc's Friday→Thursday window).
///
/// The single definition of "which week is this day in": `bucketIntoWeeks`
/// buckets with it, and anything else that shows "a week" (e.g. the
/// check-in share card) should key on it too, so the two never disagree.
///
/// Calendar-date arithmetic, not `Duration(days: n)`: subtracting a fixed
/// 24h duration across a DST transition lands on 23:00/01:00 of an adjacent
/// day, which would give a non-midnight week start. The `DateTime`
/// constructor normalizes a negative or zero day-of-month into the previous
/// month (and year), and always yields local midnight.
DateTime weekStartFor(DateTime date, {int anchorWeekday = DateTime.friday}) {
  final daysSinceAnchor = (date.weekday - anchorWeekday) % 7;
  return DateTime(date.year, date.month, date.day - daysSinceAnchor);
}
