/// The coach's data layer (iPhone only, CLAUDE.md §11).
///
/// `FileCoachRepository`: coach sessions and transcripts in a JSON file on
/// this device only. Never SwiftData or CloudKit, never synced.
/// `MethodChannelCoachModel`: the `steady/coach` Foundation Models channel.
/// `MethodChannelAppAttest`: the `steady/app_attest` App Attest channel the
/// hosted coach signs its requests with, and `FileAppAttestKeyStore`, where
/// the attested key id is kept (#150).
library;

export 'src/app_attest/app_attest.dart';
export 'src/app_attest/app_attest_wire.dart' show AppAttestChannel;
export 'src/app_attest/file_app_attest_key_store.dart';
export 'src/app_attest/method_channel_app_attest.dart';
export 'src/coach_model_wire.dart' show CoachModelChannel;
export 'src/coach_session_json.dart' show decodeCoachFile, encodeCoachFile;
export 'src/file_coach_repository.dart';
export 'src/method_channel_coach_model.dart';
