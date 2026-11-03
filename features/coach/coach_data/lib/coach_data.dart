/// The coach's data layer (iPhone only, CLAUDE.md §11).
///
/// `FileCoachRepository`: coach sessions and transcripts in a JSON file on
/// this device only. Never SwiftData or CloudKit, never synced.
/// `HostedCoachModel`: the coach's replies, from Steady's proxy
/// (`jnnabugwu/steady-backend`) over HTTPS and server-sent events, with App
/// Attest on every request (`AppAttest`, `AppAttestKeyStore`).
library;

export 'src/app_attest/app_attest.dart';
export 'src/coach_session_json.dart' show decodeCoachFile, encodeCoachFile;
export 'src/file_coach_repository.dart';
export 'src/hosted/coach_proxy_config.dart';
export 'src/hosted/coach_proxy_wire.dart'
    show CoachProxyWire, coachFailureForCode, encodeCoachRequest;
export 'src/hosted/coach_sse.dart';
export 'src/hosted/hosted_coach_model.dart';
