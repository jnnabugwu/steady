/// The coach's data layer (iPhone only, CLAUDE.md §11).
///
/// `FileCoachRepository`: coach sessions and transcripts in a JSON file on
/// this device only. Never SwiftData or CloudKit, never synced.
library;

export 'src/coach_session_json.dart' show decodeCoachFile, encodeCoachFile;
export 'src/file_coach_repository.dart';
