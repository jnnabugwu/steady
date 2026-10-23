import 'package:failures/failures.dart';
import 'package:health_sync_domain/health_sync_domain.dart';

/// In-memory [HealthKitRepository] for tests and previews.
///
/// Answers [dailyTotals] from [days] (keyed by local midnight), filling the
/// rest of the range with empty days the way the native side does.
/// [requestAuthorization] moves [status] from `notDetermined` to
/// `requested`, like the real permission sheet. Counts calls, so tests can
/// assert the sheet was asked for once.
class InMemoryHealthKitRepository implements HealthKitRepository {
  /// Creates the repository, starting at [status] with [days] of data.
  InMemoryHealthKitRepository({
    this.status = HealthAuthorizationStatus.notDetermined,
    Iterable<HealthDayTotals> days = const [],
  }) : days = {
         for (final d in days)
           DateTime(d.date.year, d.date.month, d.date.day): d,
       };

  /// What [authorizationStatus] returns.
  HealthAuthorizationStatus status;

  /// Health's data, by local midnight.
  final Map<DateTime, HealthDayTotals> days;

  /// When set, every method returns `Err(failure)`.
  Failure? failure;

  /// How many times [requestAuthorization] has been called.
  int requestAuthorizationCalls = 0;

  /// How many times [dailyTotals] has been called.
  int dailyTotalsCalls = 0;

  @override
  ResultFuture<bool> isAvailable() async =>
      _or(() => status != HealthAuthorizationStatus.unavailable);

  @override
  ResultFuture<HealthAuthorizationStatus> authorizationStatus() async =>
      _or(() => status);

  @override
  ResultFuture<Unit> requestAuthorization() async {
    requestAuthorizationCalls++;
    return _or(() {
      if (status == HealthAuthorizationStatus.notDetermined) {
        status = HealthAuthorizationStatus.requested;
      }
      return unit;
    });
  }

  @override
  ResultFuture<List<HealthDayTotals>> dailyTotals(
    DateTime start,
    DateTime end,
  ) async {
    dailyTotalsCalls++;
    return _or(() {
      final last = DateTime(end.year, end.month, end.day);
      return [
        for (
          var d = DateTime(start.year, start.month, start.day);
          !d.isAfter(last);
          d = DateTime(d.year, d.month, d.day + 1)
        )
          days[d] ?? HealthDayTotals(date: d),
      ];
    });
  }

  Result<T> _or<T>(T Function() value) {
    final failure = this.failure;
    return failure == null ? Ok(value()) : Err(failure);
  }
}
