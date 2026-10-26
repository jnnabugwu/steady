import 'package:checkin_domain/checkin_domain.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:cravings_domain/cravings_domain.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_domain/metrics_domain.dart';

import 'helpers/fake_domains.dart';

/// The coach's 7-day context (#80): built from the four domains only,
/// compact, and never failing outright.
void main() {
  // Sunday, Oct 25 2026, 8pm. The window is Mon 19 → Sun 25.
  final now = DateTime(2026, 10, 25, 20);
  final window = coachChatWindow(now);

  late FakeCheckIns checkIns;
  late FakeMetrics metrics;
  late FakeHealth health;
  late FakeCravings cravings;

  setUp(() {
    checkIns = FakeCheckIns({
      DateTime(2026, 10, 19): CheckInStatus.logged,
      DateTime(2026, 10, 20): CheckInStatus.partial,
      DateTime(2026, 10, 21): CheckInStatus.skipped,
      // Before the window: ignored.
      DateTime(2026, 10, 18): CheckInStatus.logged,
    });
    metrics = FakeMetrics({
      DateTime(2026, 10, 19): 2140,
      DateTime(2026, 10, 20): 1320,
    });
    health = FakeHealth({
      DateTime(2026, 10, 19): HealthDayTotals(
        date: DateTime(2026, 10, 19),
        steps: 8412,
        caloriesBurnedActive: 520,
        caloriesBurnedBasal: 1650,
      ),
      DateTime(2026, 10, 22): HealthDayTotals(
        date: DateTime(2026, 10, 22),
        steps: 3000,
      ),
    });
    cravings = FakeCravings([
      craving('a', DateTime(2026, 10, 20, 19), reasons: {CravingReason.tired}),
      craving('b', DateTime(2026, 10, 23, 21), reasons: {CravingReason.tired}),
      craving('c', DateTime(2026, 10, 24, 14)),
      // Outside the window.
      craving('d', DateTime(2026, 10, 18, 19)),
    ]);
  });

  BuildCoachWeekContext build({bool withHealth = true}) =>
      BuildCoachWeekContext(
        checkIns: checkIns,
        metrics: metrics,
        health: withHealth ? health : null,
        cravings: cravings,
      );

  test('the chat window is the last seven calendar days, today included', () {
    expect(window.first, DateTime(2026, 10, 19));
    expect(window.last, DateTime(2026, 10, 25));
  });

  test('reads each day from the four domains', () async {
    final data = await build()(
      first: window.first,
      last: window.last,
      now: now,
    );
    expect(data.days, hasLength(7));
    expect(data.today, DateTime(2026, 10, 25));
    final monday = data.days.first;
    expect(monday.status, CheckInStatus.logged);
    expect(monday.caloriesEaten, 2140);
    expect(monday.steps, 8412);
    expect(monday.activeEnergy, 520);
    expect(monday.basalEnergy, 1650);
    expect(data.days[3].steps, 3000);
    expect(data.days.last.status, isNull);
    expect(data.cravingCount, 3);
    expect(data.cravingTimes, {
      CravingTimeOfDay.evening: 2,
      CravingTimeOfDay.afternoon: 1,
    });
    expect(data.cravingReasons, {CravingReason.tired: 2});
  });

  test('formats one compact line per day, then cravings', () async {
    final text = formatCoachWeek(
      await build()(first: window.first, last: window.last, now: now),
    );
    final lines = text.split('\n');
    expect(lines.first, contains('Sun Oct 25 is today'));
    expect(
      lines[1],
      'Mon Oct 19: logged fully; ate 2140 kcal; 8412 steps; burned 520 '
      'active + 1650 resting kcal',
    );
    expect(lines[2], 'Tue Oct 20: logged partly; ate 1320 kcal');
    expect(lines[3], 'Wed Oct 21: skipped logging');
    expect(lines[4], 'Thu Oct 22: no check-in; 3000 steps');
    expect(
      lines.last,
      'Craving check-ins: 3 (1 in the afternoon, 2 in the evening).',
    );
    // Reasons only for the weekly session.
    expect(text, isNot(contains('tired')));
  });

  test('the craving line never mentions food or calories, and reasons '
      'show only when asked for', () async {
    final data = await build()(
      first: window.first,
      last: window.last,
      now: now,
    );
    final line = formatCoachWeek(
      data,
      includeCravingReasons: true,
    ).split('\n').last;
    expect(line, contains('What was behind them: tired 2.'));
    expect(line.toLowerCase(), isNot(contains('kcal')));
    expect(line.toLowerCase(), isNot(contains('calorie')));
  });

  test('without Health it says so, and still has the rest', () async {
    final text = formatCoachWeek(
      await build(withHealth: false)(
        first: window.first,
        last: window.last,
        now: now,
      ),
    );
    expect(text, contains('Steps and burned energy are not available.'));
    expect(text, isNot(contains('steps;')));
    expect(text, contains('ate 2140 kcal'));
  });

  test('a source that fails is noted, never fatal', () async {
    const failure = UnknownFailure('nope');
    checkIns.failure = failure;
    metrics.failure = failure;
    health.failure = failure;
    cravings.failure = failure;
    final data = await build()(
      first: window.first,
      last: window.last,
      now: now,
    );
    expect(data.checkInsRead, isFalse);
    expect(data.caloriesRead, isFalse);
    expect(data.healthRead, isFalse);
    expect(data.cravingsRead, isFalse);
    final text = formatCoachWeek(data);
    expect(text, contains('Some check-ins could not be read.'));
    expect(text, contains('Calories eaten could not be read.'));
    expect(text, contains('Craving check-ins are not available.'));
  });

  test('Health read but empty for every day says it may not be shared, '
      'not that there was no movement', () async {
    health.totals.clear();
    final data = await build()(
      first: window.first,
      last: window.last,
      now: now,
    );
    expect(data.healthRead, isTrue);
    final text = formatCoachWeek(data);
    expect(text, contains('Health may not be shared with Steady'));
    expect(text, isNot(contains('Steps and burned energy are not available.')));
  });

  test('Health with values on some days adds no such note', () async {
    final text = formatCoachWeek(
      await build()(first: window.first, last: window.last, now: now),
    );
    expect(text, isNot(contains('may not be shared')));
  });

  test(
    "a day whose check-in couldn't be read says so, not 'no check-in'",
    () async {
      checkIns.failingDays.add(DateTime(2026, 10, 20));
      final data = await build()(
        first: window.first,
        last: window.last,
        now: now,
      );
      final text = formatCoachWeek(data);
      expect(text, contains("Tue Oct 20: check-in couldn't be read"));
      expect(text, contains('Mon Oct 19: logged fully'));
      // A day with nothing logged is still just that.
      expect(text, contains('Thu Oct 22: no check-in'));
    },
  );

  test('a source that throws is caught and noted, never fatal', () async {
    final data = await BuildCoachWeekContext(
      checkIns: _ThrowingCheckIns(),
      metrics: _ThrowingMetrics(),
      health: _ThrowingHealth(),
      cravings: _ThrowingCravings(),
    )(first: window.first, last: window.last, now: now);
    expect(data.checkInsRead, isFalse);
    expect(data.caloriesRead, isFalse);
    expect(data.healthRead, isFalse);
    expect(data.cravingsRead, isFalse);
    expect(data.days, hasLength(7));
    final text = formatCoachWeek(data);
    expect(text, contains('Some check-ins could not be read.'));
    expect(text, contains('Calories eaten could not be read.'));
    expect(text, contains('Steps and burned energy are not available.'));
    expect(text, contains('Craving check-ins are not available.'));
  });

  test('a full week with every value stays under the cap', () async {
    for (var i = 0; i < 7; i++) {
      final day = DateTime(2026, 10, 19 + i);
      checkIns.statuses[day] = CheckInStatus.partial;
      metrics.eaten[day] = 12345;
      health.totals[day] = HealthDayTotals(
        date: day,
        steps: 123456,
        caloriesBurnedActive: 12345,
        caloriesBurnedBasal: 12345,
      );
      cravings.events.addAll([
        for (final hour in [7, 13, 19, 23])
          craving(
            '$i$hour',
            DateTime(2026, 10, 19 + i, hour),
            reasons: CravingReason.values.toSet(),
          ),
      ]);
    }
    final text = formatCoachWeek(
      await build()(first: window.first, last: window.last, now: now),
      includeCravingReasons: true,
    );
    expect(text.length, lessThanOrEqualTo(coachWeekContextMaxChars));
    // Nothing was cut: the last line is complete.
    expect(text, endsWith('not sure 28.'));
  });
}

/// Repositories that throw instead of returning `Err`, for `_guard`.
class _ThrowingCheckIns implements CheckInRepository {
  @override
  ResultFuture<CheckInStatus?> getStatus(DateTime date) =>
      throw StateError('check-ins broke');

  @override
  ResultFuture<Unit> logCheckIn(DateTime date, CheckInStatus status) =>
      throw UnimplementedError();
}

class _ThrowingMetrics implements MetricsRepository {
  @override
  ResultFuture<List<DailyMetric>> getRange(DateTime start, DateTime end) =>
      throw StateError('metrics broke');

  @override
  ResultFuture<List<WeeklyBucket>> getWeeks(
    DateTime start,
    DateTime end, {
    int anchorWeekday = DateTime.friday,
  }) => throw UnimplementedError();
}

class _ThrowingHealth implements HealthKitRepository {
  @override
  ResultFuture<List<HealthDayTotals>> dailyTotals(
    DateTime start,
    DateTime end,
  ) => throw StateError('health broke');

  @override
  ResultFuture<HealthAuthorizationStatus> authorizationStatus() =>
      throw UnimplementedError();

  @override
  ResultFuture<bool> isAvailable() => throw UnimplementedError();

  @override
  ResultFuture<Unit> requestAuthorization() => throw UnimplementedError();

  @override
  ResultFuture<WeightUnit> preferredWeightUnit() => throw UnimplementedError();
}

class _ThrowingCravings implements CravingRepository {
  @override
  ResultFuture<List<CravingEvent>> getBetween(DateTime start, DateTime end) =>
      throw StateError('cravings broke');

  @override
  ResultFuture<Unit> save(CravingEvent event) => throw UnimplementedError();

  @override
  ResultFuture<Unit> deleteAll() => throw UnimplementedError();
}
