/// Craving support's data layer: `FileCravingRepository`, a JSON file on
/// this device only. Never SwiftData or CloudKit, never synced
/// (CLAUDE.md §7).
library;

export 'src/craving_event_json.dart' show decodeCravingFile, encodeCravingFile;
export 'src/file_craving_repository.dart';
