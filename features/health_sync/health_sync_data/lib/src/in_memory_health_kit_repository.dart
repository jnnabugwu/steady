import 'package:failures/failures.dart';
import 'package:health_sync_data/src/health_kit_wire.dart';
import 'package:health_sync_domain/health_sync_domain.dart';

/// In-memory [HealthKitRepository] for tests and previews.
///
/// Answers [dailyTotals] from [days] (keyed by local midnight), filling the
/// rest of the range with empty days the way the native side does. Same
/// date contract as `MethodChannelHealthKitRepository`: local calendar days
/// (a UTC `DateTime` is converted first), years 0000 to 9999, and `start`
/// not after `end`, else `Err(ValidationFailure)`.
/// [requestAuthorization] moves [status] from `notDetermined` to
/// `requested`, like the real permission sheet. Counts calls, so tests can
/// assert the sheet was asked for once.
class InMemoryHealthKitRepository implements HealthKitRepository {
  /// Creates the repository, starting at [status] with [days] of data.
  InMemoryHealthKitRepository({
    this.status = HealthAuthorizationStatus.notDetermined,
    this.weightUnit = WeightUnit.kilograms,
    Iterable<HealthDayTotals> days = const [],
  }) : days = {
         for (final d in days)
           healthLocalDay(d.date): d.copyWith(date: healthLocalDay(d.date)),
       };

  /// What [authorizationStatus] returns.
  HealthAuthorizationStatus status;

  /// What [preferredWeightUnit] returns.
  WeightUnit weightUnit;

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
    final failure = this.failure;
    if (failure != null) return Err(failure);
    final first = healthLocalDay(start);
    final last = healthLocalDay(end);
    if (!isSupportedHealthDate(first) || !isSupportedHealthDate(last)) {
      return const Err(
        ValidationFailure('start and end must be in the years 0000 to 9999'),
      );
    }
    if (first.isAfter(last)) {
      return const Err(ValidationFailure('start must not be after end'));
    }
    return Ok([
      for (
        var d = first;
        !d.isAfter(last);
        d = DateTime(d.year, d.month, d.day + 1)
      )
        days[d] ?? HealthDayTotals(date: d),
    ]);
  }

  @override
  ResultFuture<WeightUnit> preferredWeightUnit() async => _or(() => weightUnit);

  Result<T> _or<T>(T Function() value) {
    final failure = this.failure;
    return failure == null ? Ok(value()) : Err(failure);
  }
}
