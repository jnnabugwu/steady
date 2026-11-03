// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A live coach session on the iPhone: a chat or the weekly session, from
/// opening the screen to its stored summary.
///
/// **The weekly session** (#81) looks back on the last completed
/// Friday→Thursday week ([coachWeeklyWindow]). It doesn't start if fewer
/// than 4 of its 7 days have a check-in ([CheckWeeklyReadiness], checked
/// before the coach is touched and again in [startWeeklySession]). Its
/// topics are separate threads ([weeklyTopicsFor]: logging, steps, the
/// cravings when there were any, next week), each opened by an app turn
/// (`CoachTurn.app`, which the proxy expands into the topic's prompt) and
/// moved on by [moveToNextWeeklyTopic]. It ends like a chat, with a stored
/// summary.
///
/// A family keyed by the session's [kind] and a fresh `sessionId` per
/// opening of the screen, so a session still writing its summary after its
/// screen closed is never handed to the next one. Auto-dispose; from its
/// first line to its last, [endCoachSession] holds a `KeepAliveLink`
/// (closed in `finally`), so closing the screen doesn't lose the summary
/// (CLAUDE.md §4).
///
/// **One operation at a time.** A turn (the person's message: save, the
/// reply, save) and a retried start are each one in-flight operation
/// ([_operation]). The phase isn't the lock: `replying` covers a save as
/// well as the reply. Ending marks the session as ending at once, stops
/// whatever is streaming, and waits for the operation to finish before it
/// summarises; an operation that resumes after that point stops without
/// touching the coach or the transcript further.
///
/// **Stateless model.** Nothing is started or ended on the model's side:
/// every reply sends the session's kind, the week's compact context
/// ([BuildCoachWeekContext], [formatCoachWeek]) and the whole conversation
/// so far ([_turns]), app turns in place. The summary is one request of its
/// own kind (`CoachRequestKind.summary`) over the transcript.
///
/// **Nothing is sent without consent** ([coachConsentGivenProvider],
/// through [checkCoachAvailable] at the start and before a retry; the
/// hosted model checks it again before every request).
///
/// **Saving.** The transcript is saved through `CoachRepository` after the
/// person's message and after each reply (an upsert by id), and once more
/// with the summary when the session ends. Nothing is stored until the
/// person has said something, and never again for a session that was
/// still open when "Delete coach history" ran ([coachHistoryEpochProvider]).

@ProviderFor(CoachSessionController)
final coachSessionControllerProvider = CoachSessionControllerFamily._();

/// A live coach session on the iPhone: a chat or the weekly session, from
/// opening the screen to its stored summary.
///
/// **The weekly session** (#81) looks back on the last completed
/// Friday→Thursday week ([coachWeeklyWindow]). It doesn't start if fewer
/// than 4 of its 7 days have a check-in ([CheckWeeklyReadiness], checked
/// before the coach is touched and again in [startWeeklySession]). Its
/// topics are separate threads ([weeklyTopicsFor]: logging, steps, the
/// cravings when there were any, next week), each opened by an app turn
/// (`CoachTurn.app`, which the proxy expands into the topic's prompt) and
/// moved on by [moveToNextWeeklyTopic]. It ends like a chat, with a stored
/// summary.
///
/// A family keyed by the session's [kind] and a fresh `sessionId` per
/// opening of the screen, so a session still writing its summary after its
/// screen closed is never handed to the next one. Auto-dispose; from its
/// first line to its last, [endCoachSession] holds a `KeepAliveLink`
/// (closed in `finally`), so closing the screen doesn't lose the summary
/// (CLAUDE.md §4).
///
/// **One operation at a time.** A turn (the person's message: save, the
/// reply, save) and a retried start are each one in-flight operation
/// ([_operation]). The phase isn't the lock: `replying` covers a save as
/// well as the reply. Ending marks the session as ending at once, stops
/// whatever is streaming, and waits for the operation to finish before it
/// summarises; an operation that resumes after that point stops without
/// touching the coach or the transcript further.
///
/// **Stateless model.** Nothing is started or ended on the model's side:
/// every reply sends the session's kind, the week's compact context
/// ([BuildCoachWeekContext], [formatCoachWeek]) and the whole conversation
/// so far ([_turns]), app turns in place. The summary is one request of its
/// own kind (`CoachRequestKind.summary`) over the transcript.
///
/// **Nothing is sent without consent** ([coachConsentGivenProvider],
/// through [checkCoachAvailable] at the start and before a retry; the
/// hosted model checks it again before every request).
///
/// **Saving.** The transcript is saved through `CoachRepository` after the
/// person's message and after each reply (an upsert by id), and once more
/// with the summary when the session ends. Nothing is stored until the
/// person has said something, and never again for a session that was
/// still open when "Delete coach history" ran ([coachHistoryEpochProvider]).
final class CoachSessionControllerProvider
    extends $NotifierProvider<CoachSessionController, CoachSessionState> {
  /// A live coach session on the iPhone: a chat or the weekly session, from
  /// opening the screen to its stored summary.
  ///
  /// **The weekly session** (#81) looks back on the last completed
  /// Friday→Thursday week ([coachWeeklyWindow]). It doesn't start if fewer
  /// than 4 of its 7 days have a check-in ([CheckWeeklyReadiness], checked
  /// before the coach is touched and again in [startWeeklySession]). Its
  /// topics are separate threads ([weeklyTopicsFor]: logging, steps, the
  /// cravings when there were any, next week), each opened by an app turn
  /// (`CoachTurn.app`, which the proxy expands into the topic's prompt) and
  /// moved on by [moveToNextWeeklyTopic]. It ends like a chat, with a stored
  /// summary.
  ///
  /// A family keyed by the session's [kind] and a fresh `sessionId` per
  /// opening of the screen, so a session still writing its summary after its
  /// screen closed is never handed to the next one. Auto-dispose; from its
  /// first line to its last, [endCoachSession] holds a `KeepAliveLink`
  /// (closed in `finally`), so closing the screen doesn't lose the summary
  /// (CLAUDE.md §4).
  ///
  /// **One operation at a time.** A turn (the person's message: save, the
  /// reply, save) and a retried start are each one in-flight operation
  /// ([_operation]). The phase isn't the lock: `replying` covers a save as
  /// well as the reply. Ending marks the session as ending at once, stops
  /// whatever is streaming, and waits for the operation to finish before it
  /// summarises; an operation that resumes after that point stops without
  /// touching the coach or the transcript further.
  ///
  /// **Stateless model.** Nothing is started or ended on the model's side:
  /// every reply sends the session's kind, the week's compact context
  /// ([BuildCoachWeekContext], [formatCoachWeek]) and the whole conversation
  /// so far ([_turns]), app turns in place. The summary is one request of its
  /// own kind (`CoachRequestKind.summary`) over the transcript.
  ///
  /// **Nothing is sent without consent** ([coachConsentGivenProvider],
  /// through [checkCoachAvailable] at the start and before a retry; the
  /// hosted model checks it again before every request).
  ///
  /// **Saving.** The transcript is saved through `CoachRepository` after the
  /// person's message and after each reply (an upsert by id), and once more
  /// with the summary when the session ends. Nothing is stored until the
  /// person has said something, and never again for a session that was
  /// still open when "Delete coach history" ran ([coachHistoryEpochProvider]).
  CoachSessionControllerProvider._({
    required CoachSessionControllerFamily super.from,
    required (CoachSessionKind, String) super.argument,
  }) : super(
         retry: null,
         name: r'coachSessionControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$coachSessionControllerHash();

  @override
  String toString() {
    return r'coachSessionControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  CoachSessionController create() => CoachSessionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoachSessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoachSessionState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CoachSessionControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$coachSessionControllerHash() =>
    r'21cb95da8f269f6d2fdfdac3922b3b6deb7c3842';

/// A live coach session on the iPhone: a chat or the weekly session, from
/// opening the screen to its stored summary.
///
/// **The weekly session** (#81) looks back on the last completed
/// Friday→Thursday week ([coachWeeklyWindow]). It doesn't start if fewer
/// than 4 of its 7 days have a check-in ([CheckWeeklyReadiness], checked
/// before the coach is touched and again in [startWeeklySession]). Its
/// topics are separate threads ([weeklyTopicsFor]: logging, steps, the
/// cravings when there were any, next week), each opened by an app turn
/// (`CoachTurn.app`, which the proxy expands into the topic's prompt) and
/// moved on by [moveToNextWeeklyTopic]. It ends like a chat, with a stored
/// summary.
///
/// A family keyed by the session's [kind] and a fresh `sessionId` per
/// opening of the screen, so a session still writing its summary after its
/// screen closed is never handed to the next one. Auto-dispose; from its
/// first line to its last, [endCoachSession] holds a `KeepAliveLink`
/// (closed in `finally`), so closing the screen doesn't lose the summary
/// (CLAUDE.md §4).
///
/// **One operation at a time.** A turn (the person's message: save, the
/// reply, save) and a retried start are each one in-flight operation
/// ([_operation]). The phase isn't the lock: `replying` covers a save as
/// well as the reply. Ending marks the session as ending at once, stops
/// whatever is streaming, and waits for the operation to finish before it
/// summarises; an operation that resumes after that point stops without
/// touching the coach or the transcript further.
///
/// **Stateless model.** Nothing is started or ended on the model's side:
/// every reply sends the session's kind, the week's compact context
/// ([BuildCoachWeekContext], [formatCoachWeek]) and the whole conversation
/// so far ([_turns]), app turns in place. The summary is one request of its
/// own kind (`CoachRequestKind.summary`) over the transcript.
///
/// **Nothing is sent without consent** ([coachConsentGivenProvider],
/// through [checkCoachAvailable] at the start and before a retry; the
/// hosted model checks it again before every request).
///
/// **Saving.** The transcript is saved through `CoachRepository` after the
/// person's message and after each reply (an upsert by id), and once more
/// with the summary when the session ends. Nothing is stored until the
/// person has said something, and never again for a session that was
/// still open when "Delete coach history" ran ([coachHistoryEpochProvider]).

final class CoachSessionControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          CoachSessionController,
          CoachSessionState,
          CoachSessionState,
          CoachSessionState,
          (CoachSessionKind, String)
        > {
  CoachSessionControllerFamily._()
    : super(
        retry: null,
        name: r'coachSessionControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A live coach session on the iPhone: a chat or the weekly session, from
  /// opening the screen to its stored summary.
  ///
  /// **The weekly session** (#81) looks back on the last completed
  /// Friday→Thursday week ([coachWeeklyWindow]). It doesn't start if fewer
  /// than 4 of its 7 days have a check-in ([CheckWeeklyReadiness], checked
  /// before the coach is touched and again in [startWeeklySession]). Its
  /// topics are separate threads ([weeklyTopicsFor]: logging, steps, the
  /// cravings when there were any, next week), each opened by an app turn
  /// (`CoachTurn.app`, which the proxy expands into the topic's prompt) and
  /// moved on by [moveToNextWeeklyTopic]. It ends like a chat, with a stored
  /// summary.
  ///
  /// A family keyed by the session's [kind] and a fresh `sessionId` per
  /// opening of the screen, so a session still writing its summary after its
  /// screen closed is never handed to the next one. Auto-dispose; from its
  /// first line to its last, [endCoachSession] holds a `KeepAliveLink`
  /// (closed in `finally`), so closing the screen doesn't lose the summary
  /// (CLAUDE.md §4).
  ///
  /// **One operation at a time.** A turn (the person's message: save, the
  /// reply, save) and a retried start are each one in-flight operation
  /// ([_operation]). The phase isn't the lock: `replying` covers a save as
  /// well as the reply. Ending marks the session as ending at once, stops
  /// whatever is streaming, and waits for the operation to finish before it
  /// summarises; an operation that resumes after that point stops without
  /// touching the coach or the transcript further.
  ///
  /// **Stateless model.** Nothing is started or ended on the model's side:
  /// every reply sends the session's kind, the week's compact context
  /// ([BuildCoachWeekContext], [formatCoachWeek]) and the whole conversation
  /// so far ([_turns]), app turns in place. The summary is one request of its
  /// own kind (`CoachRequestKind.summary`) over the transcript.
  ///
  /// **Nothing is sent without consent** ([coachConsentGivenProvider],
  /// through [checkCoachAvailable] at the start and before a retry; the
  /// hosted model checks it again before every request).
  ///
  /// **Saving.** The transcript is saved through `CoachRepository` after the
  /// person's message and after each reply (an upsert by id), and once more
  /// with the summary when the session ends. Nothing is stored until the
  /// person has said something, and never again for a session that was
  /// still open when "Delete coach history" ran ([coachHistoryEpochProvider]).

  CoachSessionControllerProvider call(
    CoachSessionKind kind,
    String sessionId,
  ) =>
      CoachSessionControllerProvider._(argument: (kind, sessionId), from: this);

  @override
  String toString() => r'coachSessionControllerProvider';
}

/// A live coach session on the iPhone: a chat or the weekly session, from
/// opening the screen to its stored summary.
///
/// **The weekly session** (#81) looks back on the last completed
/// Friday→Thursday week ([coachWeeklyWindow]). It doesn't start if fewer
/// than 4 of its 7 days have a check-in ([CheckWeeklyReadiness], checked
/// before the coach is touched and again in [startWeeklySession]). Its
/// topics are separate threads ([weeklyTopicsFor]: logging, steps, the
/// cravings when there were any, next week), each opened by an app turn
/// (`CoachTurn.app`, which the proxy expands into the topic's prompt) and
/// moved on by [moveToNextWeeklyTopic]. It ends like a chat, with a stored
/// summary.
///
/// A family keyed by the session's [kind] and a fresh `sessionId` per
/// opening of the screen, so a session still writing its summary after its
/// screen closed is never handed to the next one. Auto-dispose; from its
/// first line to its last, [endCoachSession] holds a `KeepAliveLink`
/// (closed in `finally`), so closing the screen doesn't lose the summary
/// (CLAUDE.md §4).
///
/// **One operation at a time.** A turn (the person's message: save, the
/// reply, save) and a retried start are each one in-flight operation
/// ([_operation]). The phase isn't the lock: `replying` covers a save as
/// well as the reply. Ending marks the session as ending at once, stops
/// whatever is streaming, and waits for the operation to finish before it
/// summarises; an operation that resumes after that point stops without
/// touching the coach or the transcript further.
///
/// **Stateless model.** Nothing is started or ended on the model's side:
/// every reply sends the session's kind, the week's compact context
/// ([BuildCoachWeekContext], [formatCoachWeek]) and the whole conversation
/// so far ([_turns]), app turns in place. The summary is one request of its
/// own kind (`CoachRequestKind.summary`) over the transcript.
///
/// **Nothing is sent without consent** ([coachConsentGivenProvider],
/// through [checkCoachAvailable] at the start and before a retry; the
/// hosted model checks it again before every request).
///
/// **Saving.** The transcript is saved through `CoachRepository` after the
/// person's message and after each reply (an upsert by id), and once more
/// with the summary when the session ends. Nothing is stored until the
/// person has said something, and never again for a session that was
/// still open when "Delete coach history" ran ([coachHistoryEpochProvider]).

abstract class _$CoachSessionController extends $Notifier<CoachSessionState> {
  late final _$args = ref.$arg as (CoachSessionKind, String);
  CoachSessionKind get kind => _$args.$1;
  String get sessionId => _$args.$2;

  CoachSessionState build(CoachSessionKind kind, String sessionId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CoachSessionState, CoachSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CoachSessionState, CoachSessionState>,
              CoachSessionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
