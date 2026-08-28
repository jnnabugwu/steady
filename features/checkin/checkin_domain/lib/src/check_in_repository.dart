import 'package:checkin_domain/src/check_in_status.dart';
import 'package:failures/failures.dart';

/// Reads and writes a day's check-in status.
abstract class CheckInRepository {
  /// Returns the status for [date], or `Ok(null)` if nothing has been
  /// logged for that day yet.
  ResultFuture<CheckInStatus?> getStatus(DateTime date);

  /// Records [status] for [date].
  ResultFuture<Unit> logCheckIn(DateTime date, CheckInStatus status);
}
