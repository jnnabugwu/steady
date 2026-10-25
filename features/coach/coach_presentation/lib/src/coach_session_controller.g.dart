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
/// before the model is touched and again in [startWeeklySession]). Its
/// topics are separate threads ([weeklyTopicsFor]: logging, steps, the
/// cravings when there were any, next week), each opened by an app prompt
/// ([weeklyTopicPrompt]) and moved on by [moveToNextWeeklyTopic]. It ends
/// like a chat, with a stored summary.
///
/// A family keyed by the session's [kind] and a fresh `sessionId` per
/// opening of the screen, so a session still writing its summary after its
/// screen closed is never handed to the next one. Auto-dispose; while
/// [endCoachSession] runs it holds a `KeepAliveLink` (closed in `finally`),
/// so closing the screen doesn't lose the summary (CLAUDE.md §4).
///
/// **Context budget.** The model sees the instructions for [kind] with a
/// compact summary of the person's last seven days
/// ([BuildCoachWeekContext], [formatCoachWeek]). Before every message,
/// [CoachConversation] checks the turn fits the device's context window
/// (`CoachModelInfo.contextSize`) with room for a full reply; when it
/// doesn't, the older turns are summarised in a separate model session and
/// the conversation moves to a fresh one, carrying that summary and the
/// last few messages. A reply that still overflows (`contextExceeded`) or
/// finds its native session gone moves on once more, without the summary,
/// and is retried once.
///
/// **Saving.** The transcript is saved through `CoachRepository` after the
/// person's message and after each reply (an upsert by id), and once more
/// with the summary when the session ends. Nothing is stored until the
/// person has said something.

@ProviderFor(CoachSessionController)
final coachSessionControllerProvider = CoachSessionControllerFamily._();

/// A live coach session on the iPhone: a chat or the weekly session, from
/// opening the screen to its stored summary.
///
/// **The weekly session** (#81) looks back on the last completed
/// Friday→Thursday week ([coachWeeklyWindow]). It doesn't start if fewer
/// than 4 of its 7 days have a check-in ([CheckWeeklyReadiness], checked
/// before the model is touched and again in [startWeeklySession]). Its
/// topics are separate threads ([weeklyTopicsFor]: logging, steps, the
/// cravings when there were any, next week), each opened by an app prompt
/// ([weeklyTopicPrompt]) and moved on by [moveToNextWeeklyTopic]. It ends
/// like a chat, with a stored summary.
///
/// A family keyed by the session's [kind] and a fresh `sessionId` per
/// opening of the screen, so a session still writing its summary after its
/// screen closed is never handed to the next one. Auto-dispose; while
/// [endCoachSession] runs it holds a `KeepAliveLink` (closed in `finally`),
/// so closing the screen doesn't lose the summary (CLAUDE.md §4).
///
/// **Context budget.** The model sees the instructions for [kind] with a
/// compact summary of the person's last seven days
/// ([BuildCoachWeekContext], [formatCoachWeek]). Before every message,
/// [CoachConversation] checks the turn fits the device's context window
/// (`CoachModelInfo.contextSize`) with room for a full reply; when it
/// doesn't, the older turns are summarised in a separate model session and
/// the conversation moves to a fresh one, carrying that summary and the
/// last few messages. A reply that still overflows (`contextExceeded`) or
/// finds its native session gone moves on once more, without the summary,
/// and is retried once.
///
/// **Saving.** The transcript is saved through `CoachRepository` after the
/// person's message and after each reply (an upsert by id), and once more
/// with the summary when the session ends. Nothing is stored until the
/// person has said something.
final class CoachSessionControllerProvider
    extends $NotifierProvider<CoachSessionController, CoachSessionState> {
  /// A live coach session on the iPhone: a chat or the weekly session, from
  /// opening the screen to its stored summary.
  ///
  /// **The weekly session** (#81) looks back on the last completed
  /// Friday→Thursday week ([coachWeeklyWindow]). It doesn't start if fewer
  /// than 4 of its 7 days have a check-in ([CheckWeeklyReadiness], checked
  /// before the model is touched and again in [startWeeklySession]). Its
  /// topics are separate threads ([weeklyTopicsFor]: logging, steps, the
  /// cravings when there were any, next week), each opened by an app prompt
  /// ([weeklyTopicPrompt]) and moved on by [moveToNextWeeklyTopic]. It ends
  /// like a chat, with a stored summary.
  ///
  /// A family keyed by the session's [kind] and a fresh `sessionId` per
  /// opening of the screen, so a session still writing its summary after its
  /// screen closed is never handed to the next one. Auto-dispose; while
  /// [endCoachSession] runs it holds a `KeepAliveLink` (closed in `finally`),
  /// so closing the screen doesn't lose the summary (CLAUDE.md §4).
  ///
  /// **Context budget.** The model sees the instructions for [kind] with a
  /// compact summary of the person's last seven days
  /// ([BuildCoachWeekContext], [formatCoachWeek]). Before every message,
  /// [CoachConversation] checks the turn fits the device's context window
  /// (`CoachModelInfo.contextSize`) with room for a full reply; when it
  /// doesn't, the older turns are summarised in a separate model session and
  /// the conversation moves to a fresh one, carrying that summary and the
  /// last few messages. A reply that still overflows (`contextExceeded`) or
  /// finds its native session gone moves on once more, without the summary,
  /// and is retried once.
  ///
  /// **Saving.** The transcript is saved through `CoachRepository` after the
  /// person's message and after each reply (an upsert by id), and once more
  /// with the summary when the session ends. Nothing is stored until the
  /// person has said something.
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
    r'074e7ad82a4d16b792424eba83620d08b0e42079';

/// A live coach session on the iPhone: a chat or the weekly session, from
/// opening the screen to its stored summary.
///
/// **The weekly session** (#81) looks back on the last completed
/// Friday→Thursday week ([coachWeeklyWindow]). It doesn't start if fewer
/// than 4 of its 7 days have a check-in ([CheckWeeklyReadiness], checked
/// before the model is touched and again in [startWeeklySession]). Its
/// topics are separate threads ([weeklyTopicsFor]: logging, steps, the
/// cravings when there were any, next week), each opened by an app prompt
/// ([weeklyTopicPrompt]) and moved on by [moveToNextWeeklyTopic]. It ends
/// like a chat, with a stored summary.
///
/// A family keyed by the session's [kind] and a fresh `sessionId` per
/// opening of the screen, so a session still writing its summary after its
/// screen closed is never handed to the next one. Auto-dispose; while
/// [endCoachSession] runs it holds a `KeepAliveLink` (closed in `finally`),
/// so closing the screen doesn't lose the summary (CLAUDE.md §4).
///
/// **Context budget.** The model sees the instructions for [kind] with a
/// compact summary of the person's last seven days
/// ([BuildCoachWeekContext], [formatCoachWeek]). Before every message,
/// [CoachConversation] checks the turn fits the device's context window
/// (`CoachModelInfo.contextSize`) with room for a full reply; when it
/// doesn't, the older turns are summarised in a separate model session and
/// the conversation moves to a fresh one, carrying that summary and the
/// last few messages. A reply that still overflows (`contextExceeded`) or
/// finds its native session gone moves on once more, without the summary,
/// and is retried once.
///
/// **Saving.** The transcript is saved through `CoachRepository` after the
/// person's message and after each reply (an upsert by id), and once more
/// with the summary when the session ends. Nothing is stored until the
/// person has said something.

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
  /// before the model is touched and again in [startWeeklySession]). Its
  /// topics are separate threads ([weeklyTopicsFor]: logging, steps, the
  /// cravings when there were any, next week), each opened by an app prompt
  /// ([weeklyTopicPrompt]) and moved on by [moveToNextWeeklyTopic]. It ends
  /// like a chat, with a stored summary.
  ///
  /// A family keyed by the session's [kind] and a fresh `sessionId` per
  /// opening of the screen, so a session still writing its summary after its
  /// screen closed is never handed to the next one. Auto-dispose; while
  /// [endCoachSession] runs it holds a `KeepAliveLink` (closed in `finally`),
  /// so closing the screen doesn't lose the summary (CLAUDE.md §4).
  ///
  /// **Context budget.** The model sees the instructions for [kind] with a
  /// compact summary of the person's last seven days
  /// ([BuildCoachWeekContext], [formatCoachWeek]). Before every message,
  /// [CoachConversation] checks the turn fits the device's context window
  /// (`CoachModelInfo.contextSize`) with room for a full reply; when it
  /// doesn't, the older turns are summarised in a separate model session and
  /// the conversation moves to a fresh one, carrying that summary and the
  /// last few messages. A reply that still overflows (`contextExceeded`) or
  /// finds its native session gone moves on once more, without the summary,
  /// and is retried once.
  ///
  /// **Saving.** The transcript is saved through `CoachRepository` after the
  /// person's message and after each reply (an upsert by id), and once more
  /// with the summary when the session ends. Nothing is stored until the
  /// person has said something.

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
/// before the model is touched and again in [startWeeklySession]). Its
/// topics are separate threads ([weeklyTopicsFor]: logging, steps, the
/// cravings when there were any, next week), each opened by an app prompt
/// ([weeklyTopicPrompt]) and moved on by [moveToNextWeeklyTopic]. It ends
/// like a chat, with a stored summary.
///
/// A family keyed by the session's [kind] and a fresh `sessionId` per
/// opening of the screen, so a session still writing its summary after its
/// screen closed is never handed to the next one. Auto-dispose; while
/// [endCoachSession] runs it holds a `KeepAliveLink` (closed in `finally`),
/// so closing the screen doesn't lose the summary (CLAUDE.md §4).
///
/// **Context budget.** The model sees the instructions for [kind] with a
/// compact summary of the person's last seven days
/// ([BuildCoachWeekContext], [formatCoachWeek]). Before every message,
/// [CoachConversation] checks the turn fits the device's context window
/// (`CoachModelInfo.contextSize`) with room for a full reply; when it
/// doesn't, the older turns are summarised in a separate model session and
/// the conversation moves to a fresh one, carrying that summary and the
/// last few messages. A reply that still overflows (`contextExceeded`) or
/// finds its native session gone moves on once more, without the summary,
/// and is retried once.
///
/// **Saving.** The transcript is saved through `CoachRepository` after the
/// person's message and after each reply (an upsert by id), and once more
/// with the summary when the session ends. Nothing is stored until the
/// person has said something.

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
