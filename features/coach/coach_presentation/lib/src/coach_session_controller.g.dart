// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A live coach session on the iPhone: one chat, from opening the screen to
/// its stored summary.
///
/// A family keyed by the session's [kind] and a fresh `sessionId` per
/// opening of the screen, so a session still writing its summary after its
/// screen closed is never handed to the next one. Auto-dispose; from its
/// first line to its last, [endCoachSession] holds a `KeepAliveLink`
/// (closed in `finally`), so closing the screen doesn't lose the summary
/// (CLAUDE.md §4).
///
/// **One operation at a time.** A turn (the person's message: save,
/// perhaps a move to a fresh model session, the reply, save) and a retried
/// start are each one in-flight operation ([_operation]). The phase isn't
/// the lock: `replying` covers a save and a session move as well as the
/// reply. Ending marks the session as ending at once, stops whatever is
/// streaming, and waits for the operation to finish before it summarises;
/// an operation that resumes after that point stops without touching the
/// model or the transcript further.
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
/// person has said something, and never again for a session that was
/// still open when "Delete coach history" ran ([coachHistoryEpochProvider]).

@ProviderFor(CoachSessionController)
final coachSessionControllerProvider = CoachSessionControllerFamily._();

/// A live coach session on the iPhone: one chat, from opening the screen to
/// its stored summary.
///
/// A family keyed by the session's [kind] and a fresh `sessionId` per
/// opening of the screen, so a session still writing its summary after its
/// screen closed is never handed to the next one. Auto-dispose; from its
/// first line to its last, [endCoachSession] holds a `KeepAliveLink`
/// (closed in `finally`), so closing the screen doesn't lose the summary
/// (CLAUDE.md §4).
///
/// **One operation at a time.** A turn (the person's message: save,
/// perhaps a move to a fresh model session, the reply, save) and a retried
/// start are each one in-flight operation ([_operation]). The phase isn't
/// the lock: `replying` covers a save and a session move as well as the
/// reply. Ending marks the session as ending at once, stops whatever is
/// streaming, and waits for the operation to finish before it summarises;
/// an operation that resumes after that point stops without touching the
/// model or the transcript further.
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
/// person has said something, and never again for a session that was
/// still open when "Delete coach history" ran ([coachHistoryEpochProvider]).
final class CoachSessionControllerProvider
    extends $NotifierProvider<CoachSessionController, CoachSessionState> {
  /// A live coach session on the iPhone: one chat, from opening the screen to
  /// its stored summary.
  ///
  /// A family keyed by the session's [kind] and a fresh `sessionId` per
  /// opening of the screen, so a session still writing its summary after its
  /// screen closed is never handed to the next one. Auto-dispose; from its
  /// first line to its last, [endCoachSession] holds a `KeepAliveLink`
  /// (closed in `finally`), so closing the screen doesn't lose the summary
  /// (CLAUDE.md §4).
  ///
  /// **One operation at a time.** A turn (the person's message: save,
  /// perhaps a move to a fresh model session, the reply, save) and a retried
  /// start are each one in-flight operation ([_operation]). The phase isn't
  /// the lock: `replying` covers a save and a session move as well as the
  /// reply. Ending marks the session as ending at once, stops whatever is
  /// streaming, and waits for the operation to finish before it summarises;
  /// an operation that resumes after that point stops without touching the
  /// model or the transcript further.
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
    r'5b0ec9c08981c6f1183de5fafcb8e31f6900e6fd';

/// A live coach session on the iPhone: one chat, from opening the screen to
/// its stored summary.
///
/// A family keyed by the session's [kind] and a fresh `sessionId` per
/// opening of the screen, so a session still writing its summary after its
/// screen closed is never handed to the next one. Auto-dispose; from its
/// first line to its last, [endCoachSession] holds a `KeepAliveLink`
/// (closed in `finally`), so closing the screen doesn't lose the summary
/// (CLAUDE.md §4).
///
/// **One operation at a time.** A turn (the person's message: save,
/// perhaps a move to a fresh model session, the reply, save) and a retried
/// start are each one in-flight operation ([_operation]). The phase isn't
/// the lock: `replying` covers a save and a session move as well as the
/// reply. Ending marks the session as ending at once, stops whatever is
/// streaming, and waits for the operation to finish before it summarises;
/// an operation that resumes after that point stops without touching the
/// model or the transcript further.
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

  /// A live coach session on the iPhone: one chat, from opening the screen to
  /// its stored summary.
  ///
  /// A family keyed by the session's [kind] and a fresh `sessionId` per
  /// opening of the screen, so a session still writing its summary after its
  /// screen closed is never handed to the next one. Auto-dispose; from its
  /// first line to its last, [endCoachSession] holds a `KeepAliveLink`
  /// (closed in `finally`), so closing the screen doesn't lose the summary
  /// (CLAUDE.md §4).
  ///
  /// **One operation at a time.** A turn (the person's message: save,
  /// perhaps a move to a fresh model session, the reply, save) and a retried
  /// start are each one in-flight operation ([_operation]). The phase isn't
  /// the lock: `replying` covers a save and a session move as well as the
  /// reply. Ending marks the session as ending at once, stops whatever is
  /// streaming, and waits for the operation to finish before it summarises;
  /// an operation that resumes after that point stops without touching the
  /// model or the transcript further.
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

/// A live coach session on the iPhone: one chat, from opening the screen to
/// its stored summary.
///
/// A family keyed by the session's [kind] and a fresh `sessionId` per
/// opening of the screen, so a session still writing its summary after its
/// screen closed is never handed to the next one. Auto-dispose; from its
/// first line to its last, [endCoachSession] holds a `KeepAliveLink`
/// (closed in `finally`), so closing the screen doesn't lose the summary
/// (CLAUDE.md §4).
///
/// **One operation at a time.** A turn (the person's message: save,
/// perhaps a move to a fresh model session, the reply, save) and a retried
/// start are each one in-flight operation ([_operation]). The phase isn't
/// the lock: `replying` covers a save and a session move as well as the
/// reply. Ending marks the session as ending at once, stops whatever is
/// streaming, and waits for the operation to finish before it summarises;
/// an operation that resumes after that point stops without touching the
/// model or the transcript further.
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
