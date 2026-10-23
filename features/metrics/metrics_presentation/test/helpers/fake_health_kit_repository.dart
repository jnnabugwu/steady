import 'package:failures/failures.dart';
import 'package:health_sync_domain/health_sync_domain.dart';

/// Hand-written fake for `HealthKitRepository` (this package can't use
/// `health_sync_data`'s in-memory one: CLAUDE.md §3).
///
/// [dailyTotals] answers from [days], one row per day of the range like the
/// native side, or `Err(failure)` when [failure] is set. Records each call.
class FakeHealthKitRepository implements HealthKitRepository {
  FakeHealthKitRepository({List<HealthDayTotals> days = const []})
    : days = {
        for (final d in days)
          DateTime(d.date.year, d.date.month, d.date.day): d,
      };

  final Map<DateTime, HealthDayTotals> days;

  Failure? failure;

  final List<(DateTime, DateTime)> dailyTotalsCalls = [];

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
    dailyTotalsCalls.add((start, end));
    final failure = this.failure;
    if (failure != null) return Err(failure);
    return Ok([
      for (
        var d = start;
        !d.isAfter(end);
        d = DateTime(d.year, d.month, d.day + 1)
      )
        days[d] ?? HealthDayTotals(date: d),
    ]);
  }
}
