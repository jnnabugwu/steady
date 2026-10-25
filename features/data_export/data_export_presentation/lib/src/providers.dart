import 'package:coach_domain/coach_domain.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:data_export_presentation/src/share_export_file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The `DailyMetricRepository` the export reads every row from.
///
/// Typed against the shared domain interface only: this package never
/// depends on a `*_data` package (CLAUDE.md §3). `app/lib/providers.dart`
/// overrides it with `ref.watch(dailyMetricRepositoryProvider)`, the single
/// shared store (CLAUDE.md §9), so the export sees exactly what checkin and
/// pdf_import wrote. Reading it without an override throws.
///
/// `keepAlive`: the shared store must not be disposed (D6).
@Riverpod(keepAlive: true)
DailyMetricRepository exportDailyMetricRepository(Ref ref) =>
    throw UnimplementedError(
      'Override exportDailyMetricRepositoryProvider in app/',
    );

/// The `CoachRepository` the export reads coach sessions from, or `null`
/// where this device has no coach (the Mac).
///
/// Typed against `coach_domain` only, never `coach_data` (CLAUDE.md §3).
/// `null` by default; `app/lib/providers.dart` binds it on iOS only, to the
/// coach's own `coachRepositoryProvider`. While it's `null` the export has
/// no `coachSessions` and the screen doesn't mention them. Only each
/// session's date, kind and summary are exported, never the transcript.
///
/// `keepAlive`: cheap and stateless (D6).
@Riverpod(keepAlive: true)
CoachRepository? exportCoachRepository(Ref ref) => null;

/// Hands the finished export file to the system share sheet.
///
/// Defaults to the real `share_plus` implementation, which needs no
/// app-level binding. Tests override it so they never reach the plugin.
///
/// `keepAlive`: cheap and stateless (D6).
@Riverpod(keepAlive: true)
ExportFileSharer exportFileSharer(Ref ref) => shareExportFileViaSharePlus;

/// The current time, which stamps the export and dates its file name.
/// A provider so tests can pin the date.
typedef ExportClock = DateTime Function();

/// The clock the export reads "now" from. Defaults to [DateTime.now].
///
/// `keepAlive`: cheap and stateless (D6).
@Riverpod(keepAlive: true)
ExportClock exportClock(Ref ref) => DateTime.now;
