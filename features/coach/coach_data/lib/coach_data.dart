/// The coach's data layer (iPhone only, CLAUDE.md §11).
///
/// `FileCoachRepository`: coach sessions and transcripts in a JSON file on
/// this device only. Never SwiftData or CloudKit, never synced.
/// `FileCoachConsentRepository`: whether the person agreed to what the coach
/// sends (the consent text's version), in a small JSON file on this device
/// only, like the sessions.
/// `HostedCoachModel`: the coach's replies, from Steady's proxy
/// (`jnnabugwu/steady-backend`) over HTTPS and server-sent events, with App
/// Attest on every request.
/// `MethodChannelAppAttest`: the `steady/app_attest` App Attest channel the
/// hosted coach signs its requests with, and `FileAppAttestKeyStore`, where
/// the attested key id is kept (#150).
library;

export 'src/app_attest/app_attest.dart';
export 'src/app_attest/app_attest_wire.dart' show AppAttestChannel;
export 'src/app_attest/file_app_attest_key_store.dart';
export 'src/app_attest/method_channel_app_attest.dart';
export 'src/coach_session_json.dart' show decodeCoachFile, encodeCoachFile;
export 'src/file_coach_consent_repository.dart';
export 'src/file_coach_repository.dart';
export 'src/hosted/coach_proxy_config.dart';
export 'src/hosted/coach_proxy_wire.dart'
    show CoachProxyWire, coachFailureForCode, encodeCoachRequest;
export 'src/hosted/coach_sse.dart';
export 'src/hosted/hosted_coach_model.dart';
