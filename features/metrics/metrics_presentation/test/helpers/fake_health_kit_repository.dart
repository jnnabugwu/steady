import 'package:failures/failures.dart';
import 'package:health_sync_domain/health_sync_domain.dart';

/// Hand-written fake for `HealthKitRepository` (this package can't use
/// `health_sync_data`'s in-memory one: CLAUDE.md §3).
///
/// [dailyTotals] answers from [days], one row per day of the range like the
/// native side, or `Err(failure)` when [failure] is set. Records each call.
/// Like the real repository, days are local calendar days: bounds and seeded
/// dates are normalized to local midnight (a UTC `DateTime` converted
/// first), mirroring `health_sync_data`'s `healthLocalDay`.
class FakeHealthKitRepository implements HealthKitRepository {
  FakeHealthKitRepository({List<HealthDayTotals> days = const []})
    : days = {
        for (final d in days)
          _localDay(d.date): d.copyWith(date: _localDay(d.date)),
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
    final last = _localDay(end);
    return Ok([
      for (
        var d = _localDay(start);
        !d.isAfter(last);
        d = DateTime(d.year, d.month, d.day + 1)
      )
        days[d] ?? HealthDayTotals(date: d),
    ]);
  }
}

DateTime _localDay(DateTime date) {
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day);
}
