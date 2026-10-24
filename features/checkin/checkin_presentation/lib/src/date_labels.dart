/// The calendar labels checkin_presentation's screens and cards print:
/// the one source for weekday and month names in this package (the check-in
/// card, the cairn week card and the week share card all use it).
/// Dependency-free (no `intl`), English only, like the rest of the app.
library;

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _fullWeekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// E.g. "Mon".
String shortWeekday(DateTime date) => _weekdays[date.weekday - 1];

/// E.g. "Monday".
String fullWeekday(DateTime date) => _fullWeekdays[date.weekday - 1];

/// E.g. "M", the cairn's row label.
String weekdayLetter(DateTime date) => _weekdays[date.weekday - 1][0];

/// E.g. "Aug".
String shortMonth(DateTime date) => _months[date.month - 1];

/// E.g. "Mon, Aug 24".
String dayAndDate(DateTime date) =>
    '${shortWeekday(date)}, ${shortMonth(date)} ${date.day}';
