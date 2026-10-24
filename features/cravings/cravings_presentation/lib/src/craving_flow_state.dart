import 'package:cravings_domain/cravings_domain.dart';
import 'package:failures/failures.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'craving_flow_state.freezed.dart';

/// Where the craving flow is.
enum CravingStep {
  /// "Having a craving?": how strong is it, 1 to 5.
  intensity,

  /// "What's behind it?": optional, multi-select reasons.
  reasons,

  /// Hungry was picked: "eating something is a good call". The end.
  hungry,

  /// "Want to take a minute with it?": offered, never imposed.
  offer,

  /// The guided imagery minute.
  minute,

  /// "Still want it?": the second rating and the outcome.
  stillWant,

  /// The outcome's neutral line. The end.
  finished,
}

/// The craving flow's state: the answers so far, and the save of the
/// finished event.
@freezed
abstract class CravingFlowState with _$CravingFlowState {
  /// Creates a [CravingFlowState].
  const factory CravingFlowState({
    /// The event's id, fixed when the flow opens, so saving again replaces
    /// rather than duplicates.
    required String id,

    /// When the flow opened.
    required DateTime startedAt,

    /// The current step.
    @Default(CravingStep.intensity) CravingStep step,

    /// The first rating, once given.
    int? intensityBefore,

    /// The reasons picked so far.
    @Default(<CravingReason>{}) Set<CravingReason> reasons,

    /// Whether the guided minute was started.
    @Default(false) bool tookMinute,

    /// The second rating, if given.
    int? intensityAfter,

    /// How it ended, once it has.
    CravingOutcome? outcome,

    /// When it ended, once it has.
    DateTime? endedAt,

    /// Whether the finished event is being saved right now.
    @Default(false) bool saving,

    /// Why the last save failed, if it did.
    Failure? saveFailure,
  }) = _CravingFlowState;

  const CravingFlowState._();

  /// The finished event, once there's an outcome; otherwise `null`.
  CravingEvent? get event {
    final before = intensityBefore;
    final ended = outcome;
    if (before == null || ended == null) return null;
    return CravingEvent(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt,
      intensityBefore: before,
      intensityAfter: intensityAfter,
      reasons: reasons,
      tookMinute: tookMinute,
      outcome: ended,
    );
  }

  /// Whether the finished event is safely stored.
  bool get saved => outcome != null && !saving && saveFailure == null;
}
