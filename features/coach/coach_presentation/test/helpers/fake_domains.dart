import 'package:checkin_domain/checkin_domain.dart';
import 'package:cravings_domain/cravings_domain.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_domain/metrics_domain.dart';

/// Check-in statuses by local midnight.
class FakeCheckIns implements CheckInRepository {
  FakeCheckIns([Map<DateTime, CheckInStatus>? statuses])
    : statuses = statuses ?? {};

  final Map<DateTime, CheckInStatus> statuses;

  /// When set, every read fails.
  Failure? failure;

  @override
  ResultFuture<CheckInStatus?> getStatus(DateTime date) async {
    if (failure case final f?) return Err(f);
    return Ok(statuses[DateTime(date.year, date.month, date.day)]);
  }

  @override
  ResultFuture<Unit> logCheckIn(DateTime date, CheckInStatus status) async {
    statuses[DateTime(date.year, date.month, date.day)] = status;
    return const Ok(unit);
  }
}

/// Calories eaten by local midnight.
class FakeMetrics implements MetricsRepository {
  FakeMetrics([Map<DateTime, int>? eaten]) : eaten = eaten ?? {};

  final Map<DateTime, int> eaten;

  /// When set, every read fails.
  Failure? failure;

  @override
  ResultFuture<List<DailyMetric>> getRange(DateTime start, DateTime end) async {
    if (failure case final f?) return Err(f);
    return Ok([
      for (final MapEntry(:key, :value) in eaten.entries)
        if (!key.isBefore(start) && !key.isAfter(end))
          DailyMetric(date: key, caloriesEaten: value),
    ]);
  }

  @override
  ResultFuture<List<WeeklyBucket>> getWeeks(
    DateTime start,
    DateTime end, {
    int anchorWeekday = DateTime.friday,
  }) async => const Ok([]);
}

/// Apple Health's totals by local midnight.
class FakeHealth implements HealthKitRepository {
  FakeHealth([Map<DateTime, HealthDayTotals>? totals]) : totals = totals ?? {};

  final Map<DateTime, HealthDayTotals> totals;

  /// When set, every read fails.
  Failure? failure;

  @override
  ResultFuture<List<HealthDayTotals>> dailyTotals(
    DateTime start,
    DateTime end,
  ) async {
    if (failure case final f?) return Err(f);
    return Ok([
      for (
        var d = DateTime(start.year, start.month, start.day);
        !d.isAfter(end);
        d = DateTime(d.year, d.month, d.day + 1)
      )
        totals[d] ?? HealthDayTotals(date: d),
    ]);
  }

  @override
  ResultFuture<HealthAuthorizationStatus> authorizationStatus() async =>
      const Ok(HealthAuthorizationStatus.requested);

  @override
  ResultFuture<bool> isAvailable() async => const Ok(true);

  @override
  ResultFuture<Unit> requestAuthorization() async => const Ok(unit);
}

/// Craving check-ins.
class FakeCravings implements CravingRepository {
  FakeCravings([List<CravingEvent>? events]) : events = events ?? [];

  final List<CravingEvent> events;

  /// When set, every read fails.
  Failure? failure;

  @override
  ResultFuture<List<CravingEvent>> getBetween(
    DateTime start,
    DateTime end,
  ) async {
    if (failure case final f?) return Err(f);
    return Ok([
      for (final e in events)
        if (!e.startedAt.isBefore(start) && e.startedAt.isBefore(end)) e,
    ]);
  }

  @override
  ResultFuture<Unit> save(CravingEvent event) async {
    events.add(event);
    return const Ok(unit);
  }

  @override
  ResultFuture<Unit> deleteAll() async {
    events.clear();
    return const Ok(unit);
  }
}

/// A craving check-in that started at [at].
CravingEvent craving(
  String id,
  DateTime at, {
  Set<CravingReason> reasons = const {},
}) => CravingEvent(
  id: id,
  startedAt: at,
  intensityBefore: 3,
  reasons: reasons,
  tookMinute: false,
  outcome: CravingOutcome.notSure,
);
