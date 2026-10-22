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
