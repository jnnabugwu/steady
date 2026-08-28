import 'package:checkin_data/checkin_data.dart';
import 'package:checkin_domain/checkin_domain.dart';
import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:get_it/get_it.dart';
import 'package:metrics_data/metrics_data.dart';
import 'package:metrics_domain/metrics_domain.dart';
import 'package:notifications_data/notifications_data.dart';
import 'package:notifications_domain/notifications_domain.dart';
import 'package:pdf_import_data/pdf_import_data.dart';
import 'package:pdf_import_domain/pdf_import_domain.dart';

/// The app-wide `get_it` instance.
final GetIt getIt = GetIt.instance;

/// Dependency injection entrypoint (CLAUDE.md §9): one `get_it` call across
/// both platform targets, with platform-specific datasource registration
/// done via conditional imports inside this same function -- not
/// duplicated per target. No such registration is needed yet: every
/// repository below is backed by an in-memory fake, which is the same on
/// both platforms.
///
/// `DailyMetricRepository` is registered as a lazy singleton exactly once,
/// and every consumer below resolves it via `getIt<DailyMetricRepository>()`
/// rather than constructing its own instance -- if that invariant is ever
/// broken, checkin/metrics/pdf_import each end up with their own private
/// copy of the shared store, and their writes silently stop being visible
/// to each other even though every isolated unit test still passes. See
/// `app/test/bootstrap_test.dart` for the integration test that guards this.
///
/// `CoachRepository` is intentionally not registered yet -- deferred until
/// the iOS/macOS native work starts (see docs/technical_decisions.md).
///
/// Swap-in-later: once the real SwiftData-backed datasource lands, only the
/// `DailyMetricRepository` factory closure below changes (and platform
/// branching would be added here, only where the coach's inference service
/// or a real notification scheduler actually differ by platform) -- every
/// downstream signature is unchanged.
void configureDependencies() {
  getIt
    ..registerLazySingleton<DailyMetricRepository>(
      InMemoryDailyMetricRepository.new,
    )
    ..registerLazySingleton<CheckInRepository>(
      () => CheckInRepositoryImpl(getIt<DailyMetricRepository>()),
    )
    ..registerLazySingleton<MetricsRepository>(
      () => MetricsRepositoryImpl(getIt<DailyMetricRepository>()),
    )
    ..registerLazySingleton<PdfImportRepository>(
      () => PdfImportRepositoryImpl(
        parser: CalAIParser(),
        dailyMetrics: getIt<DailyMetricRepository>(),
      ),
    )
    ..registerLazySingleton<NotificationScheduler>(
      InMemoryNotificationScheduler.new,
    );
}
