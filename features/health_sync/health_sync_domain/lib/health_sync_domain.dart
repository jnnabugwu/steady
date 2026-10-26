/// Health sync (iOS only): reading Apple Health's daily totals and weight.
///
/// Read live and kept in memory only: nothing here writes to the shared,
/// iCloud-synced `DailyMetric` store (App Store guideline 5.1.3(ii)).
library;

export 'src/health_authorization_status.dart';
export 'src/health_day_totals.dart';
export 'src/health_kit_repository.dart';
export 'src/weight_trend.dart';
export 'src/weight_unit.dart';
