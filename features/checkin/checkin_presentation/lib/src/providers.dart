import 'package:checkin_domain/checkin_domain.dart';
import 'package:checkin_presentation/src/week_card_sharer.dart';
import 'package:metrics_domain/metrics_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The `CheckInRepository` this feature reads and writes through.
///
/// Typed against the domain interface only: this package never depends on
/// `checkin_data` (CLAUDE.md §3). `app/lib/providers.dart` overrides it with
/// the real implementation in `appProviderOverrides` (CLAUDE.md §9); tests
/// override it with a fake. Reading it without an override throws.
///
/// `keepAlive`: repositories are cheap and stateless, so recreating one
/// gains nothing (D6).
@Riverpod(keepAlive: true)
CheckInRepository checkInRepository(Ref ref) =>
    throw UnimplementedError('Override checkInRepositoryProvider in app/');

/// The read-only `MetricsRepository` the week share card reads through.
///
/// One range read covers the whole week: each `DailyMetric` row carries the
/// day's logging status plus the opt-in calories and steps. Typed against
/// `metrics_domain` only, never `metrics_data` or `metrics_presentation`
/// (CLAUDE.md §2–§3). `app/lib/providers.dart` overrides it so it reads the
/// shared `DailyMetricRepository`; tests override it with a fake. Reading it
/// without an override throws.
///
/// `keepAlive`: repositories are cheap and stateless (D6).
@Riverpod(keepAlive: true)
MetricsRepository weekMetricsRepository(Ref ref) =>
    throw UnimplementedError('Override weekMetricsRepositoryProvider in app/');

/// How a rendered week card leaves the app. Defaults to the system share
/// sheet ([shareViaSystemSheet]); tests override it so they never reach the
/// share_plus plugin.
///
/// `keepAlive`: a stateless function, so recreating it gains nothing. It
/// never holds the PNG; bytes are passed per call and dropped after.
@Riverpod(keepAlive: true)
WeekCardSharer weekCardSharer(Ref ref) => shareViaSystemSheet;

/// The current time, as the check-in screen reads it.
typedef CheckInClock = DateTime Function();

/// The clock the check-in screen reads "now" from, to tell which day of the
/// week's cairn is today (and so which days are still to come). Defaults to
/// [DateTime.now]; tests pin it.
///
/// `keepAlive`: cheap and stateless (D6).
@Riverpod(keepAlive: true)
CheckInClock checkInClock(Ref ref) => DateTime.now;

/// Today's date (local midnight), as the check-in and cairn cards and the
/// app's Today screen read it. Built from [checkInClockProvider], so tests
/// pin it through the clock. The clock's value is read in local time, so a
/// UTC clock still gives the local calendar date.
///
/// **Rolls over at midnight** through [refreshToday]: the app root calls it
/// from a timer set for the next local midnight ([untilNextMidnight]) and on
/// every return to the foreground (a timer can fire late while the device
/// sleeps). A screen left open overnight then moves to the new day, and the
/// date-keyed families its watchers key on (`checkInControllerProvider`,
/// `weekCardControllerProvider`, ...) move with it. The timer lives in the
/// widget tree, not here, so it ends with the app's root widget.
///
/// `keepAlive`: one value for the whole app.
@Riverpod(keepAlive: true)
class CheckInToday extends _$CheckInToday {
  @override
  DateTime build() {
    final now = ref.watch(checkInClockProvider)().toLocal();
    return DateTime(now.year, now.month, now.day);
  }

  /// How long from the clock's now until the next local midnight: when to
  /// call [refreshToday] next.
  Duration untilNextMidnight() {
    final now = ref.read(checkInClockProvider)().toLocal();
    return DateTime(now.year, now.month, now.day + 1).difference(now);
  }

  /// Domain event: DayChanged.
  ///
  /// Re-reads the clock and moves to the new day if the date has changed
  /// (e.g. the app sat in the background over midnight). Does nothing on
  /// the same day, so watchers don't rebuild.
  void refreshToday() {
    final now = ref.read(checkInClockProvider)().toLocal();
    if (DateTime(now.year, now.month, now.day) != state) ref.invalidateSelf();
  }
}
