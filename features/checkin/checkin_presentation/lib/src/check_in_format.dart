import 'package:checkin_domain/checkin_domain.dart';
import 'package:ui_kit/ui_kit.dart';

/// Maps to `ui_kit`'s status ladder for the swatches and stones.
/// Presentation-only: `CheckInStatus` stays its own domain enum.
LoggingStatus loggingStatusFor(CheckInStatus status) => switch (status) {
  CheckInStatus.logged => LoggingStatus.logged,
  CheckInStatus.partial => LoggingStatus.partial,
  CheckInStatus.skipped => LoggingStatus.skipped,
};

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

/// E.g. "Mon, Aug 24".
String dayAndDate(DateTime date) =>
    '${shortWeekday(date)}, ${_months[date.month - 1]} ${date.day}';
