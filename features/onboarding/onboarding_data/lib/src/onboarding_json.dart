import 'package:onboarding_domain/onboarding_domain.dart';

/// The `schemaVersion` [encodeOnboardingFile] writes.
const onboardingSchemaVersion = 1;

/// Encodes [state] as the onboarding file's JSON object:
///
/// ```json
/// {
///   "schemaVersion": 1,
///   "completed": true,
///   "aboutMe": {
///     "voice": "gentle",
///     "tracking": "calAi",
///     "activities": ["tennis", "walks"],
///     "weekends": "busier",
///     "hardParts": ["eatingOut", "lateNights"],
///     "note": "I work nights twice a month"
///   }
/// }
/// ```
///
/// `aboutMe` is the shape the coach proxy will receive
/// (docs/design/onboarding.md): enum values by `name`, the wire code. A
/// skipped single answer or note is left out; a skipped multi-select is
/// `[]`. Lists are in each enum's declaration order, so the same answers
/// always write the same bytes.
Map<String, Object?> encodeOnboardingFile(OnboardingState state) => {
  'schemaVersion': onboardingSchemaVersion,
  'completed': state.completed,
  'aboutMe': encodeAboutMe(state.aboutMe),
};

/// Encodes [aboutMe] as the `aboutMe` object in [encodeOnboardingFile].
Map<String, Object?> encodeAboutMe(AboutMe aboutMe) => {
  'voice': ?aboutMe.voice?.name,
  'tracking': ?aboutMe.tracking?.name,
  'activities': _codes(OnboardingActivity.values, aboutMe.activities),
  'weekends': ?aboutMe.weekends?.name,
  'hardParts': _codes(HardPart.values, aboutMe.hardParts),
  'note': ?aboutMe.note,
};

List<String> _codes<E extends Enum>(List<E> values, Set<E> chosen) => [
  for (final v in values)
    if (chosen.contains(v)) v.name,
];

/// Decodes the onboarding file's JSON. Throws a [FormatException] if it
/// isn't the shape [encodeOnboardingFile] writes: not an object, no whole
/// `schemaVersion` of at least 1, no boolean `completed`, no `aboutMe`
/// object, or a field of the wrong type.
///
/// Tolerant of a newer Steady, whose additions should be additive: a
/// higher `schemaVersion` is read the same way, unknown keys are ignored,
/// an unknown code is dropped (a single answer reads as skipped, a list
/// loses that entry), and a note over [aboutMeNoteMaxChars] code points is
/// cut to the limit.
OnboardingState decodeOnboardingFile(Object? json) {
  if (json is! Map<String, Object?>) {
    throw const FormatException('Onboarding file is not a JSON object');
  }
  final version = json['schemaVersion'];
  if (version is! int || version < 1) {
    throw FormatException('Bad onboarding schemaVersion', version);
  }
  final completed = json['completed'];
  if (completed is! bool) {
    throw FormatException('Bad onboarding "completed"', completed);
  }
  return OnboardingState(
    completed: completed,
    aboutMe: _decodeAboutMe(json['aboutMe']),
  );
}

AboutMe _decodeAboutMe(Object? json) {
  if (json is! Map<String, Object?>) {
    throw FormatException('Onboarding "aboutMe" is not an object', json);
  }

  T? field<T>(String key) {
    final value = json[key];
    if (value is! T?) {
      throw FormatException('Bad About me field "$key"', value);
    }
    return value;
  }

  E? one<E extends Enum>(List<E> values, String key) {
    final code = field<String>(key);
    if (code == null) return null;
    return _byCode(values, code);
  }

  Set<E> many<E extends Enum>(List<E> values, String key) => {
    for (final code in field<List<Object?>>(key) ?? const [])
      if (code is String)
        ?_byCode(values, code)
      else
        throw FormatException('Bad About me code in "$key"', code),
  };

  final note = field<String>('note');
  return AboutMe(
    voice: one(CoachVoice.values, 'voice'),
    tracking: one(FoodTracking.values, 'tracking'),
    activities: many(OnboardingActivity.values, 'activities'),
    weekends: one(WeekendShape.values, 'weekends'),
    hardParts: many(HardPart.values, 'hardParts'),
    note: note == null || isValidAboutMeNote(note)
        ? note
        : String.fromCharCodes(note.runes.take(aboutMeNoteMaxChars)),
  );
}

/// The value whose wire code is [code], or `null` for a code this version
/// doesn't know.
E? _byCode<E extends Enum>(List<E> values, String code) {
  for (final v in values) {
    if (v.name == code) return v;
  }
  return null;
}
