/// Health sync (iOS only): Apple Health daily totals, read live through
/// `HealthKitRepository`. Nothing here is merged into the shared
/// `DailyMetric` store.
library;

export 'src/health_authorization_status.dart';
export 'src/health_day_totals.dart';
export 'src/health_kit_repository.dart';
export 'src/health_sync_report.dart';
export 'src/sync_health_days.dart';
