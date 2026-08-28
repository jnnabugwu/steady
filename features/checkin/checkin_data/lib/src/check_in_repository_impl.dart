import 'package:checkin_domain/checkin_domain.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';

/// Implements `CheckInRepository` by composing over an injected
/// `DailyMetricRepository` — checkin never talks to its own datasource or
/// gets its own SwiftData model, so the "one shared entity" invariant holds.
/// Owning the `CheckInStatus` <-> `LoggingStatus` mapping is the whole
/// reason this class exists beyond pure delegation.
class CheckInRepositoryImpl implements CheckInRepository {
  CheckInRepositoryImpl(this._dailyMetrics);

  final DailyMetricRepository _dailyMetrics;

  @override
  ResultFuture<CheckInStatus?> getStatus(DateTime date) async {
    final result = await _dailyMetrics.getByDate(date);
    return result.fold(Err.new, (m) => Ok(_toCheckInStatus(m?.loggingStatus)));
  }

  @override
  ResultFuture<Unit> logCheckIn(DateTime date, CheckInStatus status) async {
    final result = await _dailyMetrics.upsert(
      date,
      loggingStatus: _toLoggingStatus(status),
    );
    return result.fold(Err.new, (_) => const Ok(unit));
  }

  CheckInStatus? _toCheckInStatus(LoggingStatus? status) => switch (status) {
    LoggingStatus.logged => CheckInStatus.logged,
    LoggingStatus.partial => CheckInStatus.partial,
    LoggingStatus.skipped => CheckInStatus.skipped,
    null => null,
  };

  LoggingStatus _toLoggingStatus(CheckInStatus status) => switch (status) {
    CheckInStatus.logged => LoggingStatus.logged,
    CheckInStatus.partial => LoggingStatus.partial,
    CheckInStatus.skipped => LoggingStatus.skipped,
  };
}
