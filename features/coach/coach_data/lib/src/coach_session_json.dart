import 'package:coach_domain/coach_domain.dart';

/// The file format version [encodeCoachFile] writes.
const coachFileVersion = 1;

/// Encodes [sessions] as the coach file's JSON object:
///
/// ```json
/// {"version": 1, "sessions": [{"id": "...", "kind": "weekly",
///   "startedAt": "...Z", "messages": [{"role": "coach", "text": "...",
///   "at": "...Z"}]}]}
/// ```
///
/// Times are written in UTC (ISO 8601) and read back as local time, so a
/// time-zone change doesn't move a session's moment. Enums are written by
/// name. `endedAt` and `summary` are left out when `null`.
Map<String, Object?> encodeCoachFile(List<CoachSession> sessions) => {
  'version': coachFileVersion,
  'sessions': [for (final s in sessions) _encodeSession(s)],
};

Map<String, Object?> _encodeSession(CoachSession s) => {
  'id': s.id,
  'kind': s.kind.name,
  'startedAt': s.startedAt.toUtc().toIso8601String(),
  if (s.endedAt case final endedAt?)
    'endedAt': endedAt.toUtc().toIso8601String(),
  'summary': ?s.summary,
  'messages': [
    for (final m in s.messages)
      {
        'role': m.role.name,
        'text': m.text,
        'at': m.at.toUtc().toIso8601String(),
      },
  ],
};

/// Decodes what [encodeCoachFile] wrote. Throws a [FormatException] for
/// anything else: a different shape, an unknown version or enum name, a
/// missing or mistyped field, or an unparseable time.
List<CoachSession> decodeCoachFile(Object? json) {
  if (json is! Map<String, Object?>) {
    throw const FormatException('Coach file is not a JSON object');
  }
  final version = json['version'];
  if (version != coachFileVersion) {
    throw FormatException('Unsupported coach file version', version);
  }
  final sessions = json['sessions'];
  if (sessions is! List<Object?>) {
    throw const FormatException('Coach file has no "sessions" list');
  }
  return [for (final s in sessions) _decodeSession(s)];
}

CoachSession _decodeSession(Object? json) {
  final field = _fieldsOf(json, 'Coach session');
  final endedAt = field<String?>('endedAt');
  final session = CoachSession(
    id: field<String>('id'),
    kind: _byName(CoachSessionKind.values, field<String>('kind')),
    startedAt: _time(field<String>('startedAt')),
    endedAt: endedAt == null ? null : _time(endedAt),
    summary: field<String?>('summary'),
    messages: [
      for (final m in field<List<Object?>>('messages')) _decodeMessage(m),
    ],
  );
  // The same rule `saveSession` writes by, so a file holding a session this
  // app could never have written reads as corrupt rather than as history.
  if (validateCoachSession(session) case final invalid?) {
    throw FormatException('Invalid coach session: ${invalid.message}');
  }
  return session;
}

CoachMessage _decodeMessage(Object? json) {
  final field = _fieldsOf(json, 'Coach message');
  return CoachMessage(
    role: _byName(CoachMessageRole.values, field<String>('role')),
    text: field<String>('text'),
    at: _time(field<String>('at')),
  );
}

/// A typed reader for [json]'s fields; throws if [json] isn't an object.
T Function<T>(String key) _fieldsOf(Object? json, String what) {
  if (json is! Map<String, Object?>) {
    throw FormatException('$what is not a JSON object', json);
  }
  return <T>(String key) {
    final value = json[key];
    if (value is! T) throw FormatException('Bad $what field "$key"', value);
    return value;
  };
}

DateTime _time(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('Bad coach time', value);
  return parsed.toLocal();
}

E _byName<E extends Enum>(List<E> values, String name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  throw FormatException('Unknown coach value', name);
}
