import 'package:coach_domain/src/coach_model_failures.dart';
import 'package:failures/failures.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'coach_model.freezed.dart';

/// The on-device language model the coach talks through: Apple Foundation
/// Models, on the iPhone only (CLAUDE.md §11). Nothing on the Mac implements
/// this, and the app binds it only on iOS.
///
/// Every failure is a typed [Failure]: [CoachModelUnavailableFailure] (one
/// subtype per reason) when the model can't run, [CoachInferenceFailure]
/// when a response fails, [ValidationFailure] for an empty prompt or empty
/// instructions.
abstract class CoachModel {
  /// `Ok` with the model's [CoachModelInfo] if it can run now, else
  /// `Err(CoachModelUnavailableFailure)` saying why. Cheap; call it before
  /// offering a session, and again when the app comes back to the
  /// foreground (the user may have turned Apple Intelligence on).
  ResultFuture<CoachModelInfo> checkAvailability();

  /// Starts a model session primed with [instructions] (one of
  /// `CoachInstructions`'s). The session keeps every prompt and reply in
  /// its context until [endSession], which counts against
  /// [CoachModelInfo.contextSize].
  ResultFuture<CoachModelSession> startSession({required String instructions});

  /// Streams the reply to [prompt] in [session].
  ///
  /// Each `Ok` is a **snapshot**: the whole reply so far, not just the new
  /// text, so show the latest one and replace the previous. The stream
  /// closes after the last snapshot. On failure it emits one `Err` and
  /// closes. Cancelling the subscription, or [cancelResponse], stops the
  /// model; the stream then closes without an `Err`.
  ///
  /// One response at a time across the app: starting another stream
  /// cancels the one in flight.
  Stream<Result<String>> streamResponse(
    CoachModelSession session,
    String prompt,
  );

  /// Stops the response in flight in [session], if any. Its stream closes.
  /// `Ok` even when nothing was in flight.
  ResultFuture<Unit> cancelResponse(CoachModelSession session);

  /// Ends [session] and frees the model's context. Using it afterwards
  /// fails with `CoachInferenceFailureReason.sessionEnded`.
  ResultFuture<Unit> endSession(CoachModelSession session);
}

/// What the available model offers.
@freezed
abstract class CoachModelInfo with _$CoachModelInfo {
  /// Creates the info.
  const factory CoachModelInfo({
    /// The model's context window, in tokens: everything in one session
    /// (instructions, data, prompts and replies) has to fit. 4,096 on
    /// iOS 26; read from the device, since a later iOS can change it.
    required int contextSize,
  }) = _CoachModelInfo;
}

/// A live session with the on-device model: its context, on the native
/// side. Not the stored record of a coach conversation (that's the coach
/// session store, #78); this handle is gone when the app quits.
@freezed
abstract class CoachModelSession with _$CoachModelSession {
  /// Creates a handle for the native session [id].
  const factory CoachModelSession({
    /// The native side's id for the session.
    required String id,
  }) = _CoachModelSession;
}
