import 'package:cravings_domain/src/craving_event.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'craving_week_summary.freezed.dart';

/// A part of the day a craving started in, for the weekly summary.
enum CravingTimeOfDay {
  /// 5:00 to 11:59.
  morning,

  /// 12:00 to 16:59.
  afternoon,

  /// 17:00 to 21:59.
  evening,

  /// 22:00 to 4:59.
  night,
}

/// The part of the day [time] falls in, by its local hour.
CravingTimeOfDay cravingTimeOfDay(DateTime time) => switch (time.hour) {
  >= 5 && < 12 => CravingTimeOfDay.morning,
  >= 12 && < 17 => CravingTimeOfDay.afternoon,
  >= 17 && < 22 => CravingTimeOfDay.evening,
  _ => CravingTimeOfDay.night,
};

/// The summary's window: the seven calendar days ending with [now]'s day,
/// from midnight six days before it to the next midnight. Built from
/// calendar fields, not by subtracting hours, so a DST change can't shift
/// it.
({DateTime start, DateTime end}) cravingWeekWindow(DateTime now) => (
  start: DateTime(now.year, now.month, now.day - 6),
  end: DateTime(now.year, now.month, now.day + 1),
);

/// What the home screen says about the last seven days of cravings.
///
/// **Descriptive only, never a grade.** It carries how many check-ins there
/// were and when most of them happened, and deliberately nothing about
/// outcomes: no "passed" counts, no share resisted, no streaks
/// (docs/research/craving_support.md §4, §6).
@freezed
abstract class CravingWeekSummary with _$CravingWeekSummary {
  /// Creates a [CravingWeekSummary].
  const factory CravingWeekSummary({
    /// Craving check-ins started in the window.
    required int count,

    /// The part of the day more than half of them started in, or `null`
    /// when no part of the day has a majority (or there were none).
    CravingTimeOfDay? mostly,
  }) = _CravingWeekSummary;
}

/// Summarizes the [events] that started in [cravingWeekWindow] of [now].
/// Events outside the window are ignored, so callers may pass extra.
CravingWeekSummary summarizeCravingWeek(
  Iterable<CravingEvent> events, {
  required DateTime now,
}) {
  final window = cravingWeekWindow(now);
  final counts = <CravingTimeOfDay, int>{};
  var total = 0;
  for (final event in events) {
    final at = event.startedAt;
    if (at.isBefore(window.start) || !at.isBefore(window.end)) continue;
    total++;
    counts.update(cravingTimeOfDay(at), (n) => n + 1, ifAbsent: () => 1);
  }
  CravingTimeOfDay? mostly;
  for (final MapEntry(:key, :value) in counts.entries) {
    if (value * 2 > total) mostly = key;
  }
  return CravingWeekSummary(count: total, mostly: mostly);
}
