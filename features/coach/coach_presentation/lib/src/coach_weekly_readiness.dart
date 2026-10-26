import 'package:checkin_domain/checkin_domain.dart';
import 'package:coach_domain/coach_domain.dart';
import 'package:failures/failures.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:metrics_domain/metrics_domain.dart';

part 'coach_weekly_readiness.freezed.dart';

/// The week the weekly session looks back on: the last **completed**
/// Friday→Thursday week before [now]'s day (product overview's week,
/// `weekStartFor`). On a Friday that's the week that ended yesterday.
({DateTime first, DateTime last}) coachWeeklyWindow(DateTime now) {
  final local = now.toLocal();
  final thisWeek = weekStartFor(DateTime(local.year, local.month, local.day));
  return (
    first: DateTime(thisWeek.year, thisWeek.month, thisWeek.day - 7),
    last: DateTime(thisWeek.year, thisWeek.month, thisWeek.day - 1),
  );
}

/// Whether the weekly session can start for a week, and why not.
@freezed
abstract class WeeklyReadiness with _$WeeklyReadiness {
  /// Creates the readiness of the week [first]–[last].
  const factory WeeklyReadiness({
    /// The week's Friday, at local midnight.
    required DateTime first,

    /// The week's Thursday, at local midnight.
    required DateTime last,

    /// Days in the week with any check-in status.
    required int daysWithCheckIn,

    /// Whether any of the seven days couldn't be read at all.
    ///
    /// The session's own gate stays permissive about this — an unreadable
    /// day counts as no check-in, and only a week where *every* day fails
    /// is a failure, so a half-broken store doesn't block a session the
    /// person asked for. The Today nudge is the stricter reader: it offers
    /// a session unasked, so it stands down on anything it couldn't read
    /// (`coachNudgeProvider`).
    @Default(false) bool anyDayUnreadable,
  }) = _WeeklyReadiness;

  const WeeklyReadiness._();

  /// Whether the session may start ([weeklySessionAllowed]: at least
  /// [weeklySessionMinCheckInDays] of the seven days).
  bool get allowed => weeklySessionAllowed(daysWithCheckIn);
}

/// The weekly session's gate, a use case with real logic (CLAUDE.md §4):
/// don't start the Friday session if fewer than 4 of the week's 7 days
/// have any check-in status.
///
/// Reads each day's status through `CheckInRepository`. A day that can't
/// be read counts as no check-in, and if every day fails the result is
/// the failure, so a broken store never looks like a quiet week.
class CheckWeeklyReadiness {
  /// Creates the use case.
  const CheckWeeklyReadiness(this.checkIns);

  /// Check-in statuses.
  final CheckInRepository checkIns;

  /// The readiness of the week [coachWeeklyWindow] picks for [now].
  ResultFuture<WeeklyReadiness> call(DateTime now) async {
    final window = coachWeeklyWindow(now);
    final results = await Future.wait([
      for (var i = 0; i < 7; i++)
        _read(
          DateTime(window.first.year, window.first.month, window.first.day + i),
        ),
    ]);
    if (results.every((r) => r is Err)) {
      return Err((results.first as Err<CheckInStatus?>).failure);
    }
    final days = results
        .where((r) => r is Ok<CheckInStatus?> && r.value != null)
        .length;
    return Ok(
      WeeklyReadiness(
        first: window.first,
        last: window.last,
        daysWithCheckIn: days,
        // Kept rather than folded into `days`: four readable check-ins and
        // three failed reads would otherwise be indistinguishable from a
        // clean four-day week, and the nudge would offer a session off a
        // week it couldn't actually see.
        anyDayUnreadable: results.any((r) => r is Err),
      ),
    );
  }

  Future<Result<CheckInStatus?>> _read(DateTime day) async {
    try {
      return await checkIns.getStatus(day);
    } on Object catch (e) {
      return Err(UnknownFailure('Could not read a check-in', cause: e));
    }
  }
}
