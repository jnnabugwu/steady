import 'package:flutter/foundation.dart';

/// Why the coach can or can't run on this iPhone, for
/// [AnalyticsEvent.coachAvailability]. Mirrors the coach's typed
/// unavailable failures (`coach_domain`), without depending on them.
enum CoachAvailabilityReason {
  /// The coach can run: the build has its proxy address and this iPhone can
  /// be verified.
  available,

  /// The coach is off: no proxy address in this build, or the kill switch.
  turnedOff,

  /// This iPhone can't be verified (App Attest isn't available).
  deviceNotVerified,

  /// Unavailable for a reason Steady doesn't know, or the check failed.
  unknown,
}

/// Which step of a PDF import failed, for [AnalyticsEvent.pdfImportFailed].
enum PdfImportStage {
  /// Reading the chosen file, or the file picker itself.
  parse,

  /// Saving the previewed days.
  save,
}

/// The codes [AnalyticsEvent.onboardingSource] accepts: onboarding screen
/// 3's answers to "Where did you hear about Steady?". Mirrors
/// `OnboardingSource`'s codes (`onboarding_presentation`), without
/// depending on it; `app/test/onboarding_test.dart` checks the two match.
const onboardingSourceCodes = {
  'friend',
  'instagram',
  'reddit',
  'appStore',
  'tiktok',
  'other',
};

/// What [AnalyticsEvent.onboardingExited] sends when the screen isn't
/// known ("Not now" after the stored answers couldn't be read).
const onboardingStepUnknown = 'unknown';

/// The codes [AnalyticsEvent.onboardingExited] sends: the onboarding
/// screens, by `OnboardingStep` code (`onboarding_domain`), mirrored
/// without depending on it, plus [onboardingStepUnknown].
/// `app/test/onboarding_test.dart` checks they're exactly the enum's codes
/// and `unknown`.
const onboardingStepCodes = <String>{
  onboardingStepUnknown,
  'firstStone',
  'tracking',
  'source',
  'health',
  'week',
  'hardParts',
  'voice',
  'meetCoach',
  'firstWeek',
  'cairn',
};

/// One usage event Steady may send (TestFlight builds only; see
/// `app/lib/usage_sharing.dart`).
///
/// **This file is the whole list.** An event is a fixed name, and its
/// properties are only ever a fixed label, a yes/no or a count. Never a
/// Health value, a calorie number, a date, a craving, a coach message or
/// anything the person typed: App Store guideline 5.1.3 and
/// `docs/PRIVACY.md`. A new event or property goes here, so what can leave
/// the phone stays readable in one place.
@immutable
final class AnalyticsEvent {
  const AnalyticsEvent._(this.name, [this.properties = const {}]);

  /// Once per launch, after Steady has read Apple Health: whether the last
  /// seven days had any [steps], and any [caloriesEaten] (logged by another
  /// app, such as Cal AI). Yes/no only, never the numbers. HealthKit never
  /// says whether read access was allowed, so data coming back is the only
  /// sign it was: `steps: true` means Health is connected.
  factory AnalyticsEvent.healthConnected({
    required bool steps,
    required bool caloriesEaten,
  }) => AnalyticsEvent._('health_connected', {
    'steps': steps,
    'calories_eaten': caloriesEaten,
  });

  /// An end-of-day check-in was saved, for any day. [status] is the
  /// check-in's name: `logged`, `partial` or `skipped`.
  factory AnalyticsEvent.checkInLogged({required String status}) {
    assert(
      const {'logged', 'partial', 'skipped'}.contains(status),
      'Unknown check-in status: $status',
    );
    return AnalyticsEvent._('check_in_logged', {'status': status});
  }

  /// A Cal AI PDF import was saved: how many [days] it held, and whether it
  /// was the bundled [sample] export.
  factory AnalyticsEvent.pdfImported({
    required int days,
    required bool sample,
  }) => AnalyticsEvent._('pdf_imported', {'days': days, 'sample': sample});

  /// A PDF import failed at [stage].
  factory AnalyticsEvent.pdfImportFailed({required PdfImportStage stage}) =>
      AnalyticsEvent._('pdf_import_failed', {'stage': stage.name});

  /// Whether the coach can run on this iPhone, checked once per launch.
  factory AnalyticsEvent.coachAvailability({
    required CoachAvailabilityReason reason,
  }) => AnalyticsEvent._('coach_availability', {
    'available': reason == CoachAvailabilityReason.available,
    'reason': reason.name,
  });

  /// Onboarding screen 3 was answered: where the person heard about
  /// Steady, as one of [onboardingSourceCodes]. A fixed code only, never
  /// free text; a skip sends nothing.
  factory AnalyticsEvent.onboardingSource({required String source}) {
    assert(
      onboardingSourceCodes.contains(source),
      'Unknown onboarding source: $source',
    );
    return AnalyticsEvent._('onboarding_source', {'source': source});
  }

  /// The person left onboarding early ("Not now") on [step], an
  /// `OnboardingStep` code from [onboardingStepCodes], or `null` when the
  /// screen isn't known, sent as [onboardingStepUnknown]. Not sent on
  /// finishing.
  factory AnalyticsEvent.onboardingExited({required String? step}) {
    final code = step ?? onboardingStepUnknown;
    assert(
      onboardingStepCodes.contains(code),
      'Unknown onboarding step: $code',
    );
    return AnalyticsEvent._('onboarding_exited', {'step': code});
  }

  /// The craving flow reached its end and was saved. Which outcome was
  /// chosen is left out.
  static const cravingFlowFinished = AnalyticsEvent._('craving_flow_finished');

  /// The event's name in PostHog.
  final String name;

  /// Labels, yes/nos and counts only (see the class comment).
  final Map<String, Object> properties;

  @override
  bool operator ==(Object other) =>
      other is AnalyticsEvent &&
      other.name == name &&
      mapEquals(other.properties, properties);

  @override
  int get hashCode => Object.hash(
    name,
    Object.hashAllUnordered(
      properties.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() => 'AnalyticsEvent($name, $properties)';
}
