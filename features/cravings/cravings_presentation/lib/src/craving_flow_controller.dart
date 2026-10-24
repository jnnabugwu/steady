import 'package:cravings_domain/cravings_domain.dart';
import 'package:cravings_presentation/src/craving_flow_state.dart';
import 'package:cravings_presentation/src/craving_week_controller.dart';
import 'package:cravings_presentation/src/providers.dart';
import 'package:failures/failures.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'craving_flow_controller.g.dart';

/// One run of the craving flow, from "Having a craving?" to its ending.
///
/// Auto-dispose (CLAUDE.md §4): one flow per visit to the screen, gone when
/// it closes. Nothing is stored until the flow reaches an ending (hungry,
/// or an outcome at "Still want it?"); closing partway records nothing.
///
/// Every public method is one domain event (CLAUDE.md §4) and is ignored
/// unless the flow is at the step it belongs to, so a double tap can't
/// skip a step or save twice.
@riverpod
class CravingFlowController extends _$CravingFlowController {
  @override
  CravingFlowState build() => CravingFlowState(
    id: ref.read(cravingIdGeneratorProvider)(),
    startedAt: ref.read(cravingClockProvider)(),
  );

  /// Domain event: CravingRated.
  ///
  /// The first rating, 1 (mild) to 5 (strong). Moves on to the reasons.
  void rateCraving(int intensity) {
    if (state.step != CravingStep.intensity) return;
    if (!isValidCravingIntensity(intensity)) return;
    state = state.copyWith(
      intensityBefore: intensity,
      step: CravingStep.reasons,
    );
  }

  /// Picks or unpicks [reason]. Only a selection: the reasons become part
  /// of the event at [noteReasons].
  void toggleReason(CravingReason reason) {
    if (state.step != CravingStep.reasons) return;
    final reasons = {...state.reasons};
    if (!reasons.remove(reason)) reasons.add(reason);
    state = state.copyWith(reasons: reasons);
  }

  /// Domain event: CravingReasonsNoted.
  ///
  /// Confirms the picked reasons (none is fine). If one of them is
  /// [CravingReason.hungry], the flow ends here with the hungry outcome and
  /// no minute is offered: hunger is a reason to eat, not something to wait
  /// out. Otherwise it offers the minute.
  Future<void> noteReasons() async {
    if (state.step != CravingStep.reasons) return;
    if (state.reasons.contains(CravingReason.hungry)) {
      await _finish(CravingOutcome.hungry, CravingStep.hungry);
    } else {
      state = state.copyWith(step: CravingStep.offer);
    }
  }

  /// Domain event: CravingMinuteStarted.
  ///
  /// The person chose to take the guided minute.
  void startMinute() {
    if (state.step != CravingStep.offer) return;
    state = state.copyWith(tookMinute: true, step: CravingStep.minute);
  }

  /// Domain event: CravingMinuteSkipped.
  ///
  /// The person passed on the minute ("Not now"). Straight to "Still want
  /// it?".
  void skipMinute() {
    if (state.step != CravingStep.offer) return;
    state = state.copyWith(step: CravingStep.stillWant);
  }

  /// Domain event: CravingMinuteEnded.
  ///
  /// The minute ran out, or the person tapped "Done early" or "Skip". The
  /// minute still counts as taken.
  void endMinute() {
    if (state.step != CravingStep.minute) return;
    state = state.copyWith(step: CravingStep.stillWant);
  }

  /// Domain event: CravingReRated.
  ///
  /// The second rating at "Still want it?", 1 to 5. Optional, and can be
  /// changed until an outcome is chosen.
  void rateAgain(int intensity) {
    if (state.step != CravingStep.stillWant) return;
    if (!isValidCravingIntensity(intensity)) return;
    state = state.copyWith(intensityAfter: intensity);
  }

  /// Domain event: CravingHavingIt / CravingPassed / CravingNotSure.
  ///
  /// Ends the flow with [outcome] and saves the event. Every outcome is
  /// equally fine. [CravingOutcome.hungry] isn't chosen here (see
  /// [noteReasons]) and is ignored.
  Future<void> chooseOutcome(CravingOutcome outcome) async {
    if (state.step != CravingStep.stillWant) return;
    if (outcome == CravingOutcome.hungry) return;
    await _finish(outcome, CravingStep.finished);
  }

  /// Saves the finished event again after a failed save. Same id, so it
  /// can't be stored twice.
  Future<void> retrySave() async {
    if (state.outcome == null || state.saving || state.saveFailure == null) {
      return;
    }
    await _save();
  }

  Future<void> _finish(CravingOutcome outcome, CravingStep step) async {
    state = state.copyWith(
      outcome: outcome,
      endedAt: ref.read(cravingClockProvider)(),
      step: step,
    );
    await _save();
  }

  Future<void> _save() async {
    final event = state.event;
    if (event == null) return;
    state = state.copyWith(saving: true, saveFailure: null);
    // Read before the await: the provider may be disposed by the time the
    // save returns (the person tapped Done), and the save still lands.
    final repository = ref.read(cravingRepositoryProvider);
    final Result<Unit> result;
    try {
      result = await repository.save(event);
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        saving: false,
        saveFailure: error is Failure
            ? error
            : UnknownFailure('Saving the craving failed.', cause: error),
      );
      return;
    }
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => state.copyWith(saving: false),
      Err(:final failure) => state.copyWith(
        saving: false,
        saveFailure: failure,
      ),
    };
    if (result is Ok<Unit>) ref.invalidate(cravingWeekControllerProvider);
  }
}
