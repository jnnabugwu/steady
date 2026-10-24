import 'package:cravings_domain/cravings_domain.dart';

/// The file format version [encodeCravingFile] writes.
const cravingFileVersion = 1;

/// Encodes [events] as the craving file's JSON object:
///
/// ```json
/// {"version": 1, "cravings": [{"id": "...", "startedAt": "...Z", ...}]}
/// ```
///
/// Times are written in UTC (ISO 8601) and read back as local time, so a
/// time-zone change doesn't move a craving's moment. Enums are written by
/// name. Optional fields are left out when `null`.
Map<String, Object?> encodeCravingFile(List<CravingEvent> events) => {
  'version': cravingFileVersion,
  'cravings': [for (final e in events) _encode(e)],
};

Map<String, Object?> _encode(CravingEvent e) => {
  'id': e.id,
  'startedAt': e.startedAt.toUtc().toIso8601String(),
  if (e.endedAt case final endedAt?)
    'endedAt': endedAt.toUtc().toIso8601String(),
  'intensityBefore': e.intensityBefore,
  'intensityAfter': ?e.intensityAfter,
  'reasons': [
    for (final r in CravingReason.values)
      if (e.reasons.contains(r)) r.name,
  ],
  'tookMinute': e.tookMinute,
  'outcome': e.outcome.name,
};

/// Decodes what [encodeCravingFile] wrote. Throws a [FormatException] for
/// anything else: a different shape, an unknown version or enum name, or an
/// intensity outside 1 to 5.
List<CravingEvent> decodeCravingFile(Object? json) {
  if (json is! Map<String, Object?>) {
    throw const FormatException('Craving file is not a JSON object');
  }
  final version = json['version'];
  if (version != cravingFileVersion) {
    throw FormatException('Unsupported craving file version', version);
  }
  final cravings = json['cravings'];
  if (cravings is! List<Object?>) {
    throw const FormatException('Craving file has no "cravings" list');
  }
  return [for (final c in cravings) _decode(c)];
}

CravingEvent _decode(Object? json) {
  if (json is! Map<String, Object?>) {
    throw FormatException('Craving entry is not a JSON object', json);
  }
  T field<T>(String key) {
    final value = json[key];
    if (value is! T) throw FormatException('Bad craving field "$key"', value);
    return value;
  }

  DateTime time(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) throw FormatException('Bad craving time', value);
    return parsed.toLocal();
  }

  int intensity(int value) {
    if (!isValidCravingIntensity(value)) {
      throw FormatException('Craving intensity outside 1-5', value);
    }
    return value;
  }

  E byName<E extends Enum>(List<E> values, String name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    throw FormatException('Unknown craving value', name);
  }

  final endedAt = field<String?>('endedAt');
  final after = field<int?>('intensityAfter');
  return CravingEvent(
    id: field<String>('id'),
    startedAt: time(field<String>('startedAt')),
    endedAt: endedAt == null ? null : time(endedAt),
    intensityBefore: intensity(field<int>('intensityBefore')),
    intensityAfter: after == null ? null : intensity(after),
    reasons: {
      for (final r in field<List<Object?>>('reasons'))
        if (r is String)
          byName(CravingReason.values, r)
        else
          throw FormatException('Bad craving reason', r),
    },
    tookMinute: field<bool>('tookMinute'),
    outcome: byName(CravingOutcome.values, field<String>('outcome')),
  );
}
