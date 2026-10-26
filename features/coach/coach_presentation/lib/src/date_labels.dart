/// The calendar labels coach_presentation prints, on screen and in the
/// coach's context text: the one source for weekday and month names in this
/// package, so a session's date and the context's day lines can't disagree.
/// Dependency-free (no `intl`), English only, like the rest of the app.
library;

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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

/// E.g. "Aug".
String shortMonth(DateTime date) => _months[date.month - 1];
