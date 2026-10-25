/// The coach's data layer (iPhone only, CLAUDE.md §11).
///
/// `FileCoachRepository`: coach sessions and transcripts in a JSON file on
/// this device only. Never SwiftData or CloudKit, never synced.
/// `MethodChannelCoachModel`: the `steady/coach` Foundation Models channel.
library;

export 'src/coach_model_wire.dart' show CoachModelChannel;
export 'src/coach_session_json.dart' show decodeCoachFile, encodeCoachFile;
export 'src/file_coach_repository.dart';
export 'src/method_channel_coach_model.dart';
