/// User-triggered data export, the account-loss mitigation (CLAUDE.md §7).
///
/// Pure Dart: reads `DailyMetric` rows through the shared
/// `DailyMetricRepository` interface (and, on the iPhone, coach sessions
/// through `CoachRepository`) and turns them into a dated CSV or JSON
/// `ExportFile`. Delivering the file (the share sheet) is
/// `data_export_presentation`'s job.
library;

export 'src/export_bundle.dart';
export 'src/export_failures.dart';
export 'src/export_file.dart';
export 'src/export_format.dart';
export 'src/export_receipt.dart';
export 'src/read_export_bundle.dart';
