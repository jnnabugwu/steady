import 'package:checkin_domain/checkin_domain.dart';
import 'package:coach_presentation/src/date_labels.dart';
import 'package:cravings_domain/cravings_domain.dart';
import 'package:failures/failures.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_domain/metrics_domain.dart';

part 'coach_week_context.freezed.dart';

/// One day of what the coach sees.
@freezed
abstract class CoachDayData with _$CoachDayData {
  /// Creates one day's data.
  const factory CoachDayData({
    /// The day, at local midnight.
    required DateTime date,

    /// The end-of-day check-in, or `null` if there was none (or it
    /// couldn't be read: see [checkInUnreadable]).
    CheckInStatus? status,

    /// Whether this day's check-in couldn't be read, so `null` [status]
    /// isn't a day without one.
    @Default(false) bool checkInUnreadable,

    /// Calories eaten (from a Cal AI import), or `null` if none.
    int? caloriesEaten,

    /// Steps from Apple Health, or `null` if unknown.
    int? steps,

    /// Active energy from Apple Health, kcal, or `null` if unknown.
    int? activeEnergy,

    /// Basal (resting) energy from Apple Health, kcal, or `null`.
    int? basalEnergy,
  }) = _CoachDayData;
}

/// What the coach is told about a run of days: built only from other
/// features' domain interfaces (CLAUDE.md §3), by [BuildCoachWeekContext],
/// and turned into the model's compact text by [formatCoachWeek].
@freezed
abstract class CoachWeekData with _$CoachWeekData {
  /// Creates the week's data.
  const factory CoachWeekData({
    /// Every day in the window, oldest first.
    required List<CoachDayData> days,

    /// Today, at local midnight. Today's line may be incomplete.
    required DateTime today,

    /// Whether check-in statuses could be read.
    @Default(true) bool checkInsRead,

    /// Whether calories eaten could be read.
    @Default(true) bool caloriesRead,

    /// Whether Apple Health could be read (`false` where there's none).
    @Default(true) bool healthRead,

    /// Whether craving check-ins could be read.
    @Default(true) bool cravingsRead,

    /// How many craving check-ins started in the window.
    @Default(0) int cravingCount,

    /// When they started, by part of the day.
    @Default(<CravingTimeOfDay, int>{}) Map<CravingTimeOfDay, int> cravingTimes,

    /// What was behind them, if the person said (one event can have
    /// several). Only the weekly session shows these.
    @Default(<CravingReason, int>{}) Map<CravingReason, int> cravingReasons,
  }) = _CoachWeekData;
}

/// The coach's 7-day window ending on [now]'s local day: six days before
/// it through today.
({DateTime first, DateTime last}) coachChatWindow(DateTime now) {
  final local = now.toLocal();
  return (
    first: DateTime(local.year, local.month, local.day - 6),
    last: DateTime(local.year, local.month, local.day),
  );
}

/// Builds the coach's context for a run of days (a use case: it combines
/// four repositories, CLAUDE.md §4).
///
/// Reads, for each day from `first` to `last`: the check-in status
/// (`checkin_domain`), calories eaten (`metrics_domain`), steps and
/// active/basal energy live from Apple Health (`health_sync_domain`, iPhone
/// only, never stored), and the craving check-ins' count, time of day and
/// reasons (`cravings_domain`).
///
/// **Never fails.** A source that can't be read is marked as such (the
/// text then says it's unavailable) and the rest still goes to the coach:
/// a missing piece shouldn't keep someone from talking.
class BuildCoachWeekContext {
  /// Creates the use case. [health] is `null` where there's no Apple
  /// Health; [cravings] is `null` where craving support isn't offered.
  const BuildCoachWeekContext({
    required this.checkIns,
    required this.metrics,
    required this.health,
    required this.cravings,
  });

  /// Check-in statuses.
  final CheckInRepository checkIns;

  /// Calories eaten.
  final MetricsRepository metrics;

  /// Apple Health's daily totals, or `null`.
  final HealthKitRepository? health;

  /// Craving check-ins, or `null`.
  final CravingRepository? cravings;

  /// The data for [first] through [last] (local days, inclusive), as of
  /// [now].
  Future<CoachWeekData> call({
    required DateTime first,
    required DateTime last,
    required DateTime now,
  }) async {
    final days = <DateTime>[
      for (
        var d = DateTime(first.year, first.month, first.day);
        !d.isAfter(last);
        d = DateTime(d.year, d.month, d.day + 1)
      )
        d,
    ];
    final end = DateTime(last.year, last.month, last.day);

    final statuses = await Future.wait([
      for (final day in days) _guard(() => checkIns.getStatus(day)),
    ]);
    final checkInsRead = statuses.every((r) => r is Ok);

    final metricRows = await _guard(() => metrics.getRange(days.first, end));
    final eaten = <DateTime, int>{
      if (metricRows case Ok(:final value))
        for (final row in value) _day(row.date): ?row.caloriesEaten,
    };

    final healthRepo = health;
    final healthRows = healthRepo == null
        ? null
        : await _guard(() => healthRepo.dailyTotals(days.first, end));
    final totals = <DateTime, HealthDayTotals>{
      if (healthRows case Ok(:final value))
        for (final row in value) _day(row.date): row,
    };

    final cravingRepo = cravings;
    final cravingRows = cravingRepo == null
        ? null
        : await _guard(
            () => cravingRepo.getBetween(
              days.first,
              DateTime(end.year, end.month, end.day + 1),
            ),
          );
    final times = <CravingTimeOfDay, int>{};
    final reasons = <CravingReason, int>{};
    var count = 0;
    if (cravingRows case Ok(:final value)) {
      for (final event in value) {
        count++;
        times.update(
          cravingTimeOfDay(event.startedAt.toLocal()),
          (n) => n + 1,
          ifAbsent: () => 1,
        );
        for (final reason in event.reasons) {
          reasons.update(reason, (n) => n + 1, ifAbsent: () => 1);
        }
      }
    }

    final local = now.toLocal();
    return CoachWeekData(
      today: DateTime(local.year, local.month, local.day),
      days: [
        for (final (i, day) in days.indexed)
          CoachDayData(
            date: day,
            status: switch (statuses[i]) {
              Ok(:final value) => value,
              Err() => null,
            },
            checkInUnreadable: statuses[i] is Err,
            caloriesEaten: eaten[day],
            steps: totals[day]?.steps,
            activeEnergy: totals[day]?.caloriesBurnedActive,
            basalEnergy: totals[day]?.caloriesBurnedBasal,
          ),
      ],
      checkInsRead: checkInsRead,
      caloriesRead: metricRows is Ok,
      healthRead: healthRows is Ok,
      cravingsRead: cravingRows is Ok,
      cravingCount: count,
      cravingTimes: times,
      cravingReasons: reasons,
    );
  }

  static DateTime _day(DateTime d) {
    final local = d.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// [read], with anything it throws turned into an `Err`, so one broken
  /// source can't fail the whole context.
  static Future<Result<T>> _guard<T>(ResultFuture<T> Function() read) async {
    try {
      return await read();
    } on Object catch (e) {
      return Err(UnknownFailure('Could not read the coach context', cause: e));
    }
  }
}

/// The most characters [formatCoachWeek] writes: about 400 tokens at the
/// budget's three characters per token, a tenth of the 4,096-token window.
const int coachWeekContextMaxChars = 1200;

/// The week's data as the compact text the coach's instructions carry.
///
/// One line per day (`Mon Oct 19: logged; ate 2140 kcal; 8412 steps;
/// burned 520 active + 1650 resting kcal`); a note when Health was read but
/// gave nothing for any day, since that may mean it isn't shared; then
/// cravings: how many and
/// when, and with [includeCravingReasons] what was behind them. No
/// craving line ever mentions food or calories. Capped at
/// [coachWeekContextMaxChars].
String formatCoachWeek(
  CoachWeekData data, {
  bool includeCravingReasons = false,
}) {
  // A past week (the weekly session's) doesn't include today.
  final header = data.days.any((d) => d.date == data.today)
      ? 'Days, oldest first (${_date(data.today)} is today and may not be '
            'finished):'
      : 'Days, oldest first (a finished week; today is '
            '${_date(data.today)}):';
  final lines = <String>[
    header,
    for (final day in data.days) _dayLine(day),
    if (!data.checkInsRead) 'Some check-ins could not be read.',
    if (!data.caloriesRead) 'Calories eaten could not be read.',
    if (!data.healthRead) 'Steps and burned energy are not available.',
    if (data.healthRead && !data.days.any(_hasHealth)) _healthMaybeNotShared,
    _cravingLine(data, includeReasons: includeCravingReasons),
  ];
  final text = lines.join('\n');
  return text.length <= coachWeekContextMaxChars
      ? text
      : text.substring(0, coachWeekContextMaxChars);
}

const _healthMaybeNotShared =
    'No steps or burned energy came from Apple Health for these days. '
    "Health may not be shared with Steady, so don't read that as no "
    'movement.';

/// Whether [day] has any Apple Health value. HealthKit never says whether
/// read access was granted, so a run of days with none at all can mean
/// Health isn't shared rather than no movement (`HealthKitRepository`).
bool _hasHealth(CoachDayData day) =>
    day.steps != null || day.activeEnergy != null || day.basalEnergy != null;

String _dayLine(CoachDayData day) {
  final parts = [
    switch (day.status) {
      CheckInStatus.logged => 'logged fully',
      CheckInStatus.partial => 'logged partly',
      CheckInStatus.skipped => 'skipped logging',
      null when day.checkInUnreadable => "check-in couldn't be read",
      null => 'no check-in',
    },
    if (day.caloriesEaten case final kcal?) 'ate $kcal kcal',
    if (day.steps case final steps?) '$steps steps',
    ?_burned(day),
  ];
  return '${_date(day.date)}: ${parts.join('; ')}';
}

String? _burned(CoachDayData day) =>
    switch ((day.activeEnergy, day.basalEnergy)) {
      (final a?, final b?) => 'burned $a active + $b resting kcal',
      (final a?, null) => 'burned $a active kcal',
      (null, final b?) => 'burned $b resting kcal',
      (null, null) => null,
    };

String _cravingLine(CoachWeekData data, {required bool includeReasons}) {
  if (!data.cravingsRead) return 'Craving check-ins are not available.';
  if (data.cravingCount == 0) return 'Craving check-ins: none.';
  final times = [
    for (final time in CravingTimeOfDay.values)
      if (data.cravingTimes[time] case final n?) '$n in the ${time.name}',
  ].join(', ');
  final reasons = [
    for (final reason in CravingReason.values)
      if (data.cravingReasons[reason] case final n?)
        '${_reasonLabel(reason)} $n',
  ].join(', ');
  return [
    'Craving check-ins: ${data.cravingCount} ($times).',
    if (includeReasons && reasons.isNotEmpty) 'What was behind them: $reasons.',
  ].join(' ');
}

String _reasonLabel(CravingReason reason) => switch (reason) {
  CravingReason.hungry => 'hungry',
  CravingReason.bored => 'bored',
  CravingReason.stressed => 'stressed',
  CravingReason.tired => 'tired',
  CravingReason.habit => 'habit or saw it',
  CravingReason.notSure => 'not sure',
};

String _date(DateTime d) => '${shortWeekday(d)} ${shortMonth(d)} ${d.day}';
