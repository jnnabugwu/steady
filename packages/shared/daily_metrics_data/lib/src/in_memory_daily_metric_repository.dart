import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';

/// An in-memory `DailyMetricRepository`, backed by a `Map` keyed on
/// date-normalized-to-midnight. Stands in for the eventual SwiftData/
/// CloudKit-backed implementation.
class InMemoryDailyMetricRepository implements DailyMetricRepository {
  final Map<DateTime, DailyMetric> _store = {};

  DateTime _key(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  ResultFuture<DailyMetric?> getByDate(DateTime date) async {
    return Ok(_store[_key(date)]);
  }

  @override
  ResultFuture<List<DailyMetric>> getRange(
    DateTime start,
    DateTime end,
  ) async {
    final normalizedStart = _key(start);
    final normalizedEnd = _key(end);
    if (normalizedStart.isAfter(normalizedEnd)) {
      return const Err(ValidationFailure('start must not be after end'));
    }
    final results =
        _store.entries
            .where(
              (e) =>
                  !e.key.isBefore(normalizedStart) &&
                  !e.key.isAfter(normalizedEnd),
            )
            .map((e) => e.value)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return Ok(results);
  }

  @override
  ResultFuture<DailyMetric> upsert(
    DateTime date, {
    int? caloriesEaten,
    int? caloriesBurnedActive,
    int? caloriesBurnedBasal,
    int? steps,
    LoggingStatus? loggingStatus,
  }) async {
    final key = _key(date);
    final existing = _store[key];
    final merged = DailyMetric(
      date: key,
      caloriesEaten: caloriesEaten ?? existing?.caloriesEaten,
      caloriesBurnedActive:
          caloriesBurnedActive ?? existing?.caloriesBurnedActive,
      caloriesBurnedBasal:
          caloriesBurnedBasal ?? existing?.caloriesBurnedBasal,
      steps: steps ?? existing?.steps,
      loggingStatus: loggingStatus ?? existing?.loggingStatus,
    );
    _store[key] = merged;
    return Ok(merged);
  }

  @override
  ResultFuture<Unit> delete(DateTime date) async {
    _store.remove(_key(date));
    return const Ok(unit);
  }
}
