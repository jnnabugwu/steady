import 'package:coach_presentation/src/coach_history_providers.dart';
import 'package:coach_presentation/src/coach_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// A past coach session, read-only, from this iPhone's coach history
/// ([coachStoredSessionProvider]): its summary, then the conversation.
///
/// Knows nothing about routing (CLAUDE.md §5): [onBack] is the app
/// layer's. Scrolls under the tab bar, like the Coach tab.
class CoachTranscriptModule extends ConsumerWidget {
  /// Creates the transcript of session [sessionId].
  const CoachTranscriptModule({
    required this.sessionId,
    required this.onBack,
    super.key,
  });

  /// The stored session's id.
  final String sessionId;

  /// Called when the back button is tapped.
  final void Function() onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stored = ref.watch(coachStoredSessionProvider(sessionId));
    final padding = MediaQuery.paddingOf(context);
    final session = stored.value;

    return Scaffold(
      headers: [
        AppBar(
          leading: [
            Semantics(
              label: 'Back',
              button: true,
              child: IconButton.ghost(
                key: const Key('coachTranscriptBack'),
                icon: const Icon(LucideIcons.chevronLeft),
                onPressed: onBack,
              ),
            ),
          ],
          title: Text(
            session == null
                ? 'Conversation'
                : coachSessionKindLabel(session.kind),
          ),
          subtitle: session == null
              ? null
              : Text(coachSessionDateLabel(session.startedAt)),
        ),
      ],
      child: switch (stored) {
        AsyncData(value: null) => const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "This conversation isn't on this iPhone any more.",
            key: Key('coachTranscriptMissing'),
            style: SteadyType.body,
          ),
        ),
        AsyncData(value: final session?) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              key: const Key('coachTranscriptList'),
              padding: EdgeInsets.fromLTRB(20, 16, 20, padding.bottom),
              children: [
                if (session.summary case final summary?) ...[
                  GlassCard(
                    key: const Key('coachTranscriptSummary'),
                    tint: GlassCardTint.coach,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        const Text('SUMMARY', style: SteadyType.eyebrow),
                        Text(
                          summary,
                          style: SteadyType.body.copyWith(
                            color: SteadyColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                for (final (i, message) in session.messages.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: CoachMessageBubble(
                      key: Key('coachTranscriptMessage_$i'),
                      role: message.role,
                      text: message.text,
                    ),
                  ),
              ],
            ),
          ),
        ),
        AsyncError() => const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "Couldn't read this conversation on this iPhone.",
            key: Key('coachTranscriptError'),
            style: SteadyType.body,
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
