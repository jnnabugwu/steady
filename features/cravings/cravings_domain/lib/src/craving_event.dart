import 'package:freezed_annotation/freezed_annotation.dart';

part 'craving_event.freezed.dart';

/// What the person said was behind a craving. Optional and multi-select:
/// an event can carry none, some or all of them.
enum CravingReason {
  /// Hungry. Ends the flow with "eating something is a good call": hunger
  /// is never something to wait out.
  hungry,

  /// Bored.
  bored,

  /// Stressed.
  stressed,

  /// Tired.
  tired,

  /// Habit, or saw (or smelled) it.
  habit,

  /// Not sure.
  notSure,
}

/// How a craving check-in ended. Every value is equally fine: none is a
/// success or a failure, and nothing in Steady counts or scores them.
enum CravingOutcome {
  /// "Having it".
  havingIt,

  /// "It passed".
  passed,

  /// "Not sure".
  notSure,

  /// The person was hungry, so the flow ended at "eating something is a
  /// good call", before any minute or second rating was offered.
  hungry,
}

/// The lowest craving strength, "mild".
const int minCravingIntensity = 1;

/// The highest craving strength, "strong".
const int maxCravingIntensity = 5;

/// Whether [intensity] is a valid craving strength (1 to 5).
bool isValidCravingIntensity(int intensity) =>
    intensity >= minCravingIntensity && intensity <= maxCravingIntensity;

/// One finished craving check-in.
///
/// Deliberately minimal (App Store 5.1.1 data minimisation): no food, no
/// calories, no location, no notes. Recorded only once the flow reaches an
/// outcome; a flow closed partway records nothing.
@freezed
abstract class CravingEvent with _$CravingEvent {
  /// Creates a [CravingEvent].
  // Inline comparisons, not isValidCravingIntensity: a const constructor's
  // asserts can't call functions.
  @Assert(
    'intensityBefore >= 1 && intensityBefore <= 5',
    'intensityBefore must be 1 to 5',
  )
  @Assert(
    'intensityAfter == null || (intensityAfter >= 1 && intensityAfter <= 5)',
    'intensityAfter must be 1 to 5',
  )
  const factory CravingEvent({
    /// Identity, unique per event.
    required String id,

    /// When the flow was opened. Drives the time-of-day summary.
    required DateTime startedAt,

    /// How strong it was at the start, 1 (mild) to 5 (strong).
    required int intensityBefore,

    /// What was behind it, if the person said. Empty is fine.
    required Set<CravingReason> reasons,

    /// Whether the person chose to take the guided minute.
    required bool tookMinute,

    /// How it ended.
    required CravingOutcome outcome,

    /// When the flow reached its outcome.
    DateTime? endedAt,

    /// How strong it was at "Still want it?", 1 to 5, if rated. Always
    /// `null` for [CravingOutcome.hungry], which skips that question.
    int? intensityAfter,
  }) = _CravingEvent;
}
