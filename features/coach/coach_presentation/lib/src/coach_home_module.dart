import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/src/coach_history_providers.dart';
import 'package:coach_presentation/src/coach_weekly_cards.dart';
import 'package:coach_presentation/src/coach_widgets.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The Coach tab (iPhone only): start a chat or the weekly check-in, or
/// read a past session.
///
/// Top to bottom: the title, the coach card (a chat, or why the coach
/// can't run here: [coachAvailabilityProvider]'s typed failure, through
/// [CoachUnavailableCard]), the weekly check-in ([CoachWeeklyCard], while
/// the model is available), the "not medical advice" note, and the past
/// sessions, newest first ([coachSessionListProvider]), each opening its
/// read-only transcript.
///
/// Knows nothing about routing (CLAUDE.md §5): [onChatRequested],
/// [onWeeklyRequested] and [onSessionSelected] are wired by the app layer.
/// Only ever built on the iPhone; the app has no route to it on the Mac.
///
/// **Scrolls under the tab bar**, padding its end by
/// `MediaQuery.paddingOf(context).bottom` like the Today screen.
class CoachHomeModule extends ConsumerWidget {
  /// Creates the Coach tab.
  const CoachHomeModule({
    required this.onChatRequested,
    required this.onWeeklyRequested,
    required this.onSessionSelected,
    super.key,
  });

  /// Called when "Start a chat" is tapped.
  final void Function() onChatRequested;

  /// Called when the weekly card's "Start the check-in" is tapped.
  final void Function() onWeeklyRequested;

  /// Called with a past session's id when it's tapped.
  final void Function(String sessionId) onSessionSelected;

  /// Keeps the cards phone-width on a wide window.
  static const double maxWidth = 480;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(coachAvailabilityProvider);
    final sessions = ref.watch(coachSessionListProvider);
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      child: SingleChildScrollView(
        key: const Key('coachHomeScroll'),
        padding: EdgeInsets.fromLTRB(18, padding.top + 16, 18, padding.bottom),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
                  child: Semantics(
                    header: true,
                    child: const Text('Coach', style: SteadyType.headline),
                  ),
                ),
                switch (availability) {
                  AsyncData() => _ChatCard(onChatRequested: onChatRequested),
                  AsyncError(:final error) => CoachUnavailableCard(
                    failure: error is Failure
                        ? error
                        : const CoachModelUnavailableUnknownFailure(),
                    onRetry: () => ref.invalidate(coachAvailabilityProvider),
                  ),
                  _ => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                },
                if (availability is AsyncData)
                  CoachWeeklyCard(onWeeklyRequested: onWeeklyRequested),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: CoachMedicalNote(),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Semantics(
                    header: true,
                    child: const Text(
                      'PAST CONVERSATIONS',
                      style: SteadyType.eyebrow,
                    ),
                  ),
                ),
                ...switch (sessions) {
                  AsyncData(:final value) when value.isEmpty => [
                    const Text(
                      'Your conversations with the coach will show up here. '
                      'They stay on this iPhone.',
                      key: Key('coachHistoryEmpty'),
                      style: SteadyType.body,
                    ),
                  ],
                  AsyncData(:final value) => [
                    for (final session in value)
                      _SessionTile(
                        session: session,
                        onPressed: () => onSessionSelected(session.id),
                      ),
                  ],
                  AsyncError() => [
                    const Text(
                      "Couldn't read past conversations on this iPhone.",
                      key: Key('coachHistoryError'),
                      style: SteadyType.body,
                    ),
                  ],
                  _ => [const Center(child: CircularProgressIndicator())],
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({required this.onChatRequested});

  final void Function() onChatRequested;

  @override
  Widget build(BuildContext context) => GlassCard(
    key: const Key('coachChatCard'),
    tint: GlassCardTint.coach,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: const Text('Talk it through', style: SteadyType.cardTitle),
        ),
        const SizedBox(height: 8),
        const Text(
          'A short chat about your own tracking, with your last seven days '
          'in view. The coach runs on this iPhone, and the conversation '
          'stays here.',
          style: SteadyType.body,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: PrimaryButton(
            key: const Key('coachStartChat'),
            onPressed: onChatRequested,
            child: const Center(child: Text('Start a chat')),
          ),
        ),
      ],
    ),
  );
}

/// One past session: its kind and date, and its summary (or, without one,
/// the person's first message), two lines at most.
class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onPressed});

  final CoachSession session;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final title =
        '${coachSessionKindLabel(session.kind)} · '
        '${coachSessionDateLabel(session.startedAt)}';
    final preview =
        session.summary ??
        session.messages
            .where((m) => m.role == CoachMessageRole.user)
            .map((m) => m.text)
            .firstOrNull ??
        '';
    return Semantics(
      container: true,
      button: true,
      label: preview.isEmpty ? title : '$title. $preview',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Clickable(
          key: Key('coachSession_${session.id}'),
          onPressed: onPressed,
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          decoration: WidgetStatePropertyAll(
            BoxDecoration(
              color: SteadyColors.glassFill,
              borderRadius: BorderRadius.circular(SteadyRadii.tile),
              border: Border.all(color: SteadyColors.glassBorder),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    Text(
                      title,
                      style: SteadyType.body.copyWith(
                        color: SteadyColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (preview.isNotEmpty)
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SteadyType.body.copyWith(
                          fontSize: 14,
                          color: SteadyColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: SteadyColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
