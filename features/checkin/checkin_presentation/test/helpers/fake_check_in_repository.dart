import 'dart:async';

import 'package:checkin_domain/checkin_domain.dart';
import 'package:failures/failures.dart';

/// Hand-written fake for `CheckInRepository`.
///
/// Each method returns whatever its handler returns. Every call is
/// recorded so tests can assert on the arguments and call counts.
class FakeCheckInRepository implements CheckInRepository {
  FakeCheckInRepository({
    FutureOr<Result<CheckInStatus?>> Function(DateTime date)? onGetStatus,
    FutureOr<Result<Unit>> Function(DateTime date, CheckInStatus status)?
    onLogCheckIn,
  }) : onGetStatus = onGetStatus ?? ((_) => const Ok(null)),
       onLogCheckIn = onLogCheckIn ?? ((_, _) => const Ok(unit));

  FutureOr<Result<CheckInStatus?>> Function(DateTime date) onGetStatus;
  FutureOr<Result<Unit>> Function(DateTime date, CheckInStatus status)
  onLogCheckIn;

  final List<DateTime> getStatusCalls = [];
  final List<(DateTime, CheckInStatus)> logCheckInCalls = [];

  @override
  ResultFuture<CheckInStatus?> getStatus(DateTime date) async {
    getStatusCalls.add(date);
    return await onGetStatus(date);
  }

  @override
  ResultFuture<Unit> logCheckIn(DateTime date, CheckInStatus status) async {
    logCheckInCalls.add((date, status));
    return await onLogCheckIn(date, status);
  }
}
