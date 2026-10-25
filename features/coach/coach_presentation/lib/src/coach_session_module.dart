import 'dart:async';

import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/src/coach_session_controller.dart';
import 'package:coach_presentation/src/coach_session_state.dart';
import 'package:coach_presentation/src/coach_weekly_cards.dart';
import 'package:coach_presentation/src/coach_widgets.dart';
import 'package:coach_presentation/src/providers.dart';
import 'package:failures/failures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// A live coach session on the iPhone ([CoachSessionController]): the
/// transcript, the coach's reply streaming in, the message box with its
/// send / stop button, and "End", which writes the summary.
///
/// - **Streaming:** the model sends cumulative snapshots; the reply bubble
///   shows the latest one. Before the first, three teal dots.
/// - **Stop:** while the coach replies, the send button becomes a stop
///   button. What it had said stays in the transcript.
/// - **Ending:** "End" asks for the summary and shows it, with "Done".
///   Closing (X) ends the session too, in the background, and leaves at
///   once; a session where the person said nothing records nothing.
/// - **Unavailable:** the model's typed failure, through
///   [CoachUnavailableCard].
/// - **Safety:** `CoachCopy.notMedicalAdvice` at the top, and
///   `CoachCopy.helpLine` when Apple's guardrails stop a reply (#82).
/// - **Accessibility:** every target at least 44pt; screen readers hear
///   each finished coach reply once (never a partial snapshot); Reduce
///   Motion keeps the dots still and jumps instead of scrolling.
///
/// Knows nothing about routing (CLAUDE.md §5): [onClosed] is the app
/// layer's. Built from `shadcn_flutter` and `ui_kit` only.
class CoachSessionModule extends ConsumerStatefulWidget {
  /// Creates the screen for a new session of [kind].
  const CoachSessionModule({
    required this.onClosed,
    this.kind = CoachSessionKind.chat,
    super.key,
  });

  /// The kind of session.
  final CoachSessionKind kind;

  /// Called when the person closes the screen or taps "Done".
  final void Function() onClosed;

  @override
  ConsumerState<CoachSessionModule> createState() => _CoachSessionModuleState();
}

class _CoachSessionModuleState extends ConsumerState<CoachSessionModule> {
  late final String _sessionId = ref.read(coachIdGeneratorProvider)();
  final _input = TextEditingController();
  final _scroll = ScrollController();

  CoachSessionControllerProvider get _provider =>
      coachSessionControllerProvider(widget.kind, _sessionId);

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    unawaited(ref.read(_provider.notifier).sendCoachMessage(text));
  }

  void _close() {
    unawaited(ref.read(_provider.notifier).endCoachSession());
    widget.onClosed();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (MediaQuery.disableAnimationsOf(context)) {
        _scroll.jumpTo(end);
      } else {
        _scroll.animateTo(
          end,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Announces a finished coach reply once, only while a screen reader is
  /// on. Snapshots are never announced.
  void _announce(CoachSessionState? previous, CoachSessionState next) {
    if (!MediaQuery.accessibleNavigationOf(context)) return;
    final before = previous?.session.messages.length ?? 0;
    final messages = next.session.messages;
    if (messages.length <= before) return;
    final last = messages.last;
    if (last.role != CoachMessageRole.coach) return;
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        'Coach: ${last.text}',
        Directionality.of(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(_provider, (previous, next) {
      _announce(previous, next);
      if (previous?.session.messages.length != next.session.messages.length ||
          previous?.reply != next.reply ||
          previous?.phase != next.phase) {
        _scrollToEnd();
      }
    });
    final session = ref.watch(_provider);
    final controller = ref.read(_provider.notifier);
    final canEnd =
        session.hasUserMessages &&
        (session.phase == CoachSessionPhase.ready ||
            session.phase == CoachSessionPhase.replying);

    return Scaffold(
      headers: [
        AppBar(
          leading: [
            Semantics(
              label: 'Close',
              button: true,
              child: IconButton.ghost(
                key: const Key('coachSessionClose'),
                icon: const Icon(LucideIcons.x),
                onPressed: _close,
              ),
            ),
          ],
          title: Text(coachSessionKindLabel(widget.kind)),
          subtitle: Text(
            session.weekFirst == null
                ? 'On this iPhone'
                : '${_weekLabel(session)} · about 15 minutes',
          ),
          trailing: [
            if (canEnd)
              SizedBox(
                height: 44,
                child: GhostButton(
                  key: const Key('coachSessionEnd'),
                  onPressed: () => unawaited(controller.endCoachSession()),
                  child: const Text(
                    'End',
                    style: TextStyle(color: SteadyColors.accentTeal),
                  ),
                ),
              ),
          ],
        ),
      ],
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: switch (session.phase) {
              CoachSessionPhase.starting => const _Centered(
                key: Key('coachStarting'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 16,
                  children: [
                    CircularProgressIndicator(),
                    Text('Getting the coach ready…', style: SteadyType.body),
                  ],
                ),
              ),
              CoachSessionPhase.unavailable => _Centered(
                child: CoachUnavailableCard(
                  failure:
                      session.failure ??
                      const CoachModelUnavailableUnknownFailure(),
                ),
              ),
              CoachSessionPhase.failedToStart => const _Centered(
                child: _NoteCard(
                  key: Key('coachFailedToStart'),
                  title: "Couldn't start the coach",
                  body: 'Close this and try again in a moment.',
                ),
              ),
              CoachSessionPhase.notEnoughCheckIns => _Centered(
                child: _NoteCard(
                  key: const Key('coachNotEnoughCheckIns'),
                  title: 'Not enough of the week to look back on',
                  body:
                      'The weekly check-in needs at least four days with a '
                      'check-in, so there’s enough to talk about. '
                      '${_weekLabel(session)} had fewer. A chat works any '
                      'time.',
                ),
              ),
              CoachSessionPhase.awaitingStart => _WeeklyIntro(
                state: session,
                onBegin: () => unawaited(controller.startWeeklySession()),
              ),
              _ => _Conversation(
                state: session,
                scroll: _scroll,
                input: _input,
                onSend: _send,
                onStop: () => unawaited(controller.stopCoachReply()),
                onRetrySave: () => unawaited(controller.retryCoachSave()),
                onNextTopic: () =>
                    unawaited(controller.moveToNextWeeklyTopic()),
                onDone: widget.onClosed,
              ),
            },
          ),
        ),
      ),
    );
  }
}

/// The weekly session's week, e.g. "Oct 16 – 22".
String _weekLabel(CoachSessionState state) =>
    coachWeekLabel(state.weekFirst!, state.weekLast!);

/// A short title and line in a coach card.
class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => GlassCard(
    tint: GlassCardTint.coach,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: SteadyType.cardTitle),
        ),
        Text(body, style: SteadyType.body),
      ],
    ),
  );
}

/// What the weekly session covers, before it begins: its week, its topics
/// in order, and **Begin** (`startWeeklySession`).
class _WeeklyIntro extends StatelessWidget {
  const _WeeklyIntro({required this.state, required this.onBegin});

  final CoachSessionState state;
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    final topics = [
      for (final topic in state.topics) weeklyTopicLabel(topic).toLowerCase(),
    ];
    final list = topics.length < 2
        ? topics.join()
        : '${topics.sublist(0, topics.length - 1).join(', ')} and '
              '${topics.last}';
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CoachMedicalNote(),
        const SizedBox(height: 16),
        GlassCard(
          key: const Key('coachWeeklyIntro'),
          tint: GlassCardTint.coach,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Look back on ${_weekLabel(state)}',
                  style: SteadyType.cardTitle,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'About 15 minutes, one topic at a time: $list. You can '
                'end whenever you like.',
                style: SteadyType.body,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: PrimaryButton(
                  key: const Key('coachWeeklyBegin'),
                  onPressed: onBegin,
                  child: const Center(child: Text('Begin')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A weekly topic's name on screen.
String weeklyTopicLabel(WeeklyTopic topic) => switch (topic) {
  WeeklyTopic.logging => 'Logging',
  WeeklyTopic.steps => 'Steps',
  WeeklyTopic.cravings => 'Cravings',
  WeeklyTopic.nextWeek => 'Next week',
};

/// Where the weekly session is: one chip per topic, the current one in the
/// teal tint. Position only, never a checkmark or a grade.
class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.state});

  final CoachSessionState state;

  @override
  Widget build(BuildContext context) {
    final current = state.topic;
    return Semantics(
      container: true,
      label: current == null
          ? null
          : 'Topic ${state.topicIndex + 1} of ${state.topics.length}: '
                '${weeklyTopicLabel(current)}',
      excludeSemantics: true,
      child: Padding(
        key: const Key('coachTopicRow'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final topic in state.topics)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: topic == current
                      ? SteadyColors.accentTealTint(0.16)
                      : StatusOptionTile.unselectedFill,
                  borderRadius: BorderRadius.circular(SteadyRadii.pill),
                  border: Border.all(
                    color: topic == current
                        ? SteadyColors.accentTealTint(0.65)
                        : SteadyColors.glassBorder,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    weeklyTopicLabel(topic),
                    style: SteadyType.body.copyWith(
                      fontSize: 13,
                      color: topic == current
                          ? SteadyColors.accentTealHover
                          : SteadyColors.textTertiary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Center(child: child),
  );
}

class _Conversation extends StatelessWidget {
  const _Conversation({
    required this.state,
    required this.scroll,
    required this.input,
    required this.onSend,
    required this.onStop,
    required this.onRetrySave,
    required this.onNextTopic,
    required this.onDone,
  });

  final CoachSessionState state;
  final ScrollController scroll;
  final TextEditingController input;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final VoidCallback onRetrySave;
  final VoidCallback onNextTopic;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final phase = state.phase;
    final replying = phase == CoachSessionPhase.replying;
    final over =
        phase == CoachSessionPhase.ending || phase == CoachSessionPhase.ended;
    final failure = state.failure;
    final messages = state.session.messages;

    final weekly = state.topics.isNotEmpty;
    final next = state.hasNextTopic ? state.topics[state.topicIndex + 1] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (weekly && state.topicIndex >= 0) _TopicRow(state: state),
        Expanded(
          child: ListView(
            key: const Key('coachTranscript'),
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            children: [
              const CoachMedicalNote(),
              const SizedBox(height: 16),
              if (!weekly && messages.isEmpty && !replying)
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text(
                    'Ask about your last seven days: logging, steps, '
                    'check-ins, or anything on your mind about tracking.',
                    key: Key('coachSessionHint'),
                    textAlign: TextAlign.center,
                    style: SteadyType.body,
                  ),
                ),
              for (final (i, message) in messages.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: CoachMessageBubble(
                    key: Key('coachMessage_$i'),
                    role: message.role,
                    text: message.text,
                  ),
                ),
              if (replying)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: switch (state.reply) {
                    final reply? when reply.trim().isNotEmpty =>
                      CoachMessageBubble(
                        key: const Key('coachReply'),
                        role: CoachMessageRole.coach,
                        text: reply,
                        // Partial: never read out snapshot by snapshot.
                        semanticLabel: 'The coach is replying',
                      ),
                    _ => const CoachTypingIndicator(),
                  },
                ),
              if (failure != null && phase == CoachSessionPhase.ready) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    _replyFailureLine(failure),
                    key: const Key('coachReplyFailure'),
                    style: SteadyType.body.copyWith(
                      color: SteadyColors.textTertiary,
                    ),
                  ),
                ),
                if (state.guardrailTripped)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: CoachHelpCard(),
                  ),
              ],
              if (state.saveFailed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "This conversation couldn't be saved on your "
                          'iPhone.',
                          key: Key('coachSaveFailed'),
                          style: SteadyType.body,
                        ),
                      ),
                      SizedBox(
                        height: 44,
                        child: OutlineButton(
                          key: const Key('coachRetrySave'),
                          onPressed: onRetrySave,
                          child: const Text('Try again'),
                        ),
                      ),
                    ],
                  ),
                ),
              if (phase == CoachSessionPhase.ending)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    key: Key('coachEnding'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 12,
                    children: [
                      CircularProgressIndicator(),
                      Text('Writing a short summary…', style: SteadyType.body),
                    ],
                  ),
                ),
              if (phase == CoachSessionPhase.ended)
                _EndedCard(state: state, onDone: onDone),
            ],
          ),
        ),
        if (next != null && phase == CoachSessionPhase.ready)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: SizedBox(
              height: 44,
              child: OutlineButton(
                key: const Key('coachNextTopic'),
                onPressed: onNextTopic,
                child: Center(
                  child: Text('Next: ${weeklyTopicLabel(next).toLowerCase()}'),
                ),
              ),
            ),
          ),
        if (!over)
          _Composer(
            input: input,
            replying: replying,
            enabled: phase == CoachSessionPhase.ready || replying,
            onSend: onSend,
            onStop: onStop,
          ),
      ],
    );
  }

  static String _replyFailureLine(Failure failure) => switch (failure) {
    CoachInferenceFailure(
      reason: CoachInferenceFailureReason.guardrailViolation,
    ) =>
      "The coach can't reply to that one.",
    CoachInferenceFailure(reason: CoachInferenceFailureReason.refusal) =>
      "The coach can't help with that one. You can ask something else.",
    CoachInferenceFailure(
      reason: CoachInferenceFailureReason.unsupportedLanguage,
    ) =>
      "The coach can't reply in this language yet.",
    CoachInferenceFailure(
      reason: CoachInferenceFailureReason.rateLimited ||
          CoachInferenceFailureReason.busy ||
          CoachInferenceFailureReason.timeout,
    ) =>
      "The coach couldn't reply just now. Try sending it again.",
    CoachModelUnavailableFailure() => coachUnavailableCopy(failure).body,
    _ => "The coach couldn't reply. Try sending it again.",
  };
}

class _EndedCard extends StatelessWidget {
  const _EndedCard({required this.state, required this.onDone});

  final CoachSessionState state;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final summary = state.session.summary;
    final saidAnything = state.hasUserMessages;
    return GlassCard(
      key: const Key('coachEndedCard'),
      tint: GlassCardTint.coach,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (saidAnything) ...[
            const Text('SUMMARY', style: SteadyType.eyebrow),
            const SizedBox(height: 8),
            Text(
              summary ??
                  "The coach couldn't write a summary this time. The "
                      'conversation is saved.',
              key: const Key('coachSummary'),
              style: SteadyType.body.copyWith(color: SteadyColors.textPrimary),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            height: 52,
            child: PrimaryButton(
              key: const Key('coachSessionDone'),
              onPressed: onDone,
              child: const Center(child: Text('Done')),
            ),
          ),
        ],
      ),
    );
  }
}

/// The message box and its send / stop button (44pt), as on the Pass 01
/// artboard.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.input,
    required this.replying,
    required this.enabled,
    required this.onSend,
    required this.onStop,
  });

  final TextEditingController input;
  final bool replying;
  final bool enabled;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: SteadyColors.borderSubtle)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 10,
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: TextField(
                  key: const Key('coachMessageField'),
                  controller: input,
                  enabled: enabled,
                  placeholder: const Text('Message'),
                  minLines: 1,
                  maxLines: 4,
                  maxLength: coachMaxMessageChars,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (!replying) onSend();
                  },
                ),
              ),
            ),
            Semantics(
              button: true,
              label: replying ? 'Stop reply' : 'Send',
              excludeSemantics: true,
              child: SizedBox.square(
                dimension: 44,
                child: Clickable(
                  key: Key(replying ? 'coachStop' : 'coachSend'),
                  enabled: enabled,
                  onPressed: replying ? onStop : onSend,
                  mouseCursor: const WidgetStatePropertyAll(
                    SystemMouseCursors.click,
                  ),
                  decoration: WidgetStatePropertyAll(
                    BoxDecoration(
                      color: SteadyColors.accentTealTint(0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: SteadyColors.accentTealTint(0.5),
                      ),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      replying ? LucideIcons.square : LucideIcons.arrowUp,
                      size: replying ? 14 : 20,
                      color: SteadyColors.accentTeal,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
