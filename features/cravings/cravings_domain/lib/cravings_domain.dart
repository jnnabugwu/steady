/// Craving support (iPhone only): what one craving check-in records, the
/// repository it's stored through, and the gentle weekly summary.
///
/// Craving events are **device-only** by design: they never go to iCloud
/// (CLAUDE.md §7, App Store 5.1.3(ii)).
library;

export 'src/craving_event.dart';
export 'src/craving_repository.dart';
export 'src/craving_week_summary.dart';
