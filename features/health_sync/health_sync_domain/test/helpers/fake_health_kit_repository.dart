import 'package:failures/failures.dart';
import 'package:health_sync_domain/health_sync_domain.dart';

/// A [HealthKitRepository] that answers from [days] (keyed by local
/// midnight), filling every other day in the asked-for range with an empty
/// row, the way the native side does. Records the ranges asked for.
class FakeHealthKitRepository implements HealthKitRepository {
  FakeHealthKitRepository([Iterable<HealthDayTotals> days = const []])
    : days = {for (final d in days) d.date: d};

  final Map<DateTime, HealthDayTotals> days;

  /// When set, [dailyTotals] returns it.
  Failure? totalsFailure;

  final List<(DateTime, DateTime)> ranges = [];

  @override
  ResultFuture<bool> isAvailable() async => const Ok(true);

  @override
  ResultFuture<HealthAuthorizationStatus> authorizationStatus() async =>
      const Ok(HealthAuthorizationStatus.requested);

  @override
  ResultFuture<Unit> requestAuthorization() async => const Ok(unit);

  @override
  ResultFuture<List<HealthDayTotals>> dailyTotals(
    DateTime start,
    DateTime end,
  ) async {
    ranges.add((start, end));
    final failure = totalsFailure;
    if (failure != null) return Err(failure);
    return Ok([
      for (
        var d = DateTime(start.year, start.month, start.day);
        !d.isAfter(end);
        d = DateTime(d.year, d.month, d.day + 1)
      )
        days[d] ?? HealthDayTotals(date: d),
    ]);
  }
}
