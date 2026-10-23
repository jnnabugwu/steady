/// Apple Health values (steps, burned calories) in the history: read live,
/// held in memory, **never written** to the shared `DailyMetric` store.
///
/// That store is SwiftData mirrored to the user's iCloud (CloudKit), and
/// App Store guideline 5.1.3(ii) forbids storing personal health
/// information in iCloud. So Health is read on the iPhone each time the
/// history shows, merged with the stored rows in memory
/// ([mergeLiveHealth]), and dropped with the screen. The Mac has no Health
/// data at all (HealthKit is iOS only here), and neither does the coach.
///
/// `DailyMetric` keeps its `steps` and `caloriesBurned*` fields (CloudKit's
/// production schema is additive-only), but nothing writes them any more,
/// and the history ignores whatever an older build stored there.
library;

import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'live_health.g.dart';

/// How many days of Health the history reads, today included.
const int healthHistoryDays = 30;

/// The [healthHistoryDays]-day window ending on [now]'s calendar day, both
/// ends at local midnight: the key to pass to [healthDayTotalsProvider], so
/// every caller on the same day shares one provider.
({DateTime start, DateTime end}) healthHistoryWindow(DateTime now) {
  final end = DateTime(now.year, now.month, now.day);
  return (
    start: DateTime(end.year, end.month, end.day - (healthHistoryDays - 1)),
    end: end,
  );
}

/// Where the history reads Apple Health from, or `null` where there is no
/// Health to read (macOS, and tests that don't override it).
///
/// Typed against `health_sync_domain` only: this package never depends on
/// `health_sync_data` (CLAUDE.md §3). `app/lib/providers.dart` binds it to
/// the app's one `healthKitRepositoryProvider`, which is non-null on iOS
/// only.
///
/// `keepAlive`: cheap and stateless (D6).
@Riverpod(keepAlive: true)
HealthKitRepository? metricsHealthKitRepository(Ref ref) => null;

/// A [Failure] was already mapped at the `_data` boundary: surface it at
/// once (the history then shows no Health values) instead of retrying.
Duration? _retryUnlessFailure(int retryCount, Object error) =>
    error is Failure ? null : ProviderContainer.defaultRetry(retryCount, error);

/// Apple Health's totals for each day from [start] to [end] (inclusive,
/// local midnights; build the key with [healthHistoryWindow]), keyed by
/// local midnight. Days with no Health samples at all are left out.
///
/// Empty where [metricsHealthKitRepositoryProvider] is `null` (macOS). A
/// Health error throws its [Failure] into `AsyncError`.
///
/// Auto-dispose, so the values live only while a screen shows them (never
/// `keepAlive`: CLAUDE.md §4 on families). The app re-reads it on every
/// return to the foreground by invalidating it, so today's steps stay
/// current.
@Riverpod(retry: _retryUnlessFailure)
Future<Map<DateTime, HealthDayTotals>> healthDayTotals(
  Ref ref,
  DateTime start,
  DateTime end,
) async {
  final health = ref.watch(metricsHealthKitRepositoryProvider);
  if (health == null) return const {};
  return switch (await health.dailyTotals(start, end)) {
    Ok(:final value) => Map.unmodifiable({
      for (final day in value)
        if (!day.isEmpty) _midnight(day.date): day,
    }),
    Err(:final failure) => throw failure,
  };
}

/// The history's days: each stored row's own fields (calories eaten,
/// logging status) with that day's live Health values, plus a day for every
/// [health] date that has no stored row (steps on a day with no PDF import).
/// Newest first.
///
/// In memory only: the result is for display and must never be passed to
/// `DailyMetricRepository` (see the library comment). A stored row's own
/// Health fields are ignored, replaced by [health] or left `null`.
List<DailyMetric> mergeLiveHealth(
  List<DailyMetric> rows,
  Map<DateTime, HealthDayTotals> health,
) {
  final byDate = <DateTime, DailyMetric>{
    for (final row in rows) _midnight(row.date): row,
  };
  final merged = [
    for (final MapEntry(key: date, value: row) in byDate.entries)
      row.copyWith(
        steps: health[date]?.steps,
        caloriesBurnedActive: health[date]?.caloriesBurnedActive,
        caloriesBurnedBasal: health[date]?.caloriesBurnedBasal,
      ),
    for (final MapEntry(key: date, value: day) in health.entries)
      if (!byDate.containsKey(date))
        DailyMetric(
          date: date,
          steps: day.steps,
          caloriesBurnedActive: day.caloriesBurnedActive,
          caloriesBurnedBasal: day.caloriesBurnedBasal,
        ),
  ]..sort((a, b) => b.date.compareTo(a.date));
  return List.unmodifiable(merged);
}

DateTime _midnight(DateTime date) => DateTime(date.year, date.month, date.day);
