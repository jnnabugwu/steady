import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/src/date_labels.dart';
import 'package:failures/failures.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// One message in a coach conversation, in the Pass 01 chat bubble: the
/// coach's on the left in [SteadyColors.bgInput] with the
/// [SteadyRadii.chatBubble] tail, the person's on the right in the teal
/// tint with [SteadyRadii.chatBubbleMirrored]. Teal and neutral only: no
/// status colours, nothing that grades what was said.
///
/// Screen readers hear "Coach: …" or "You: …".
class CoachMessageBubble extends StatelessWidget {
  /// Creates a bubble for [text], said by [role].
  const CoachMessageBubble({
    required this.role,
    required this.text,
    this.semanticLabel,
    super.key,
  });

  /// Who said it.
  final CoachMessageRole role;

  /// What was said.
  final String text;

  /// Overrides what screen readers hear.
  final String? semanticLabel;

  /// The person's bubble fill: the teal tint at 0.16 (Pass 01).
  static final Color userFill = SteadyColors.accentTealTint(0.16);

  /// The person's bubble border: the teal tint at 0.32 (Pass 01).
  static final Color userBorder = SteadyColors.accentTealTint(0.32);

  @override
  Widget build(BuildContext context) {
    final coach = role == CoachMessageRole.coach;
    return Semantics(
      container: true,
      label: semanticLabel ?? '${coach ? 'Coach' : 'You'}: $text',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: coach ? Alignment.centerLeft : Alignment.centerRight,
          child: ConstrainedBox(
            // At most 82% of the row, as on the Pass 01 artboard.
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.82),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: coach ? SteadyColors.bgInput : userFill,
                borderRadius: coach
                    ? SteadyRadii.chatBubble
                    : SteadyRadii.chatBubbleMirrored,
                border: Border.all(
                  color: coach ? SteadyColors.borderSubtle : userBorder,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Text(
                  text,
                  style: SteadyType.body.copyWith(
                    color: SteadyColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The coach's "typing" bubble: three teal dots, fading in turn. Still
/// with Reduce Motion on. Screen readers hear [semanticLabel] once.
class CoachTypingIndicator extends StatefulWidget {
  /// Creates the indicator.
  const CoachTypingIndicator({
    this.semanticLabel = 'The coach is replying',
    super.key,
  });

  /// What screen readers hear.
  final String semanticLabel;

  @override
  State<CoachTypingIndicator> createState() => _CoachTypingIndicatorState();
}

class _CoachTypingIndicatorState extends State<CoachTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: DecoratedBox(
          key: const Key('coachTyping'),
          decoration: BoxDecoration(
            color: SteadyColors.bgInput,
            borderRadius: SteadyRadii.chatBubble,
            border: Border.all(color: SteadyColors.borderSubtle),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 5,
                children: [
                  for (var i = 0; i < 3; i++)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: SteadyColors.accentTealTint(
                          still ? 1 - i * 0.35 : _alpha(i),
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const SizedBox(width: 6, height: 6),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Each dot peaks a third of a cycle after the one before it.
  double _alpha(int i) {
    final t = (_pulse.value - i / 3) % 1;
    return 0.3 + 0.7 * (t < 0.5 ? 1 - t * 2 : (t - 0.5) * 2);
  }
}

/// `CoachCopy.notMedicalAdvice`, small and quiet: on the Coach tab and at
/// the top of every live session (#82).
class CoachMedicalNote extends StatelessWidget {
  /// Creates the note.
  const CoachMedicalNote({super.key});

  @override
  Widget build(BuildContext context) => Text(
    CoachCopy.notMedicalAdvice,
    key: const Key('coachMedicalNote'),
    textAlign: TextAlign.center,
    style: SteadyType.body.copyWith(
      fontSize: 13,
      color: SteadyColors.textMuted,
    ),
  );
}

/// `CoachCopy.helpLine` in the coach card style: shown when the model
/// refuses a reply (`CoachRefusalFailure`), which can be what a hard moment
/// looks like from here (#82).
class CoachHelpCard extends StatelessWidget {
  /// Creates the card.
  const CoachHelpCard({super.key});

  @override
  Widget build(BuildContext context) => const GlassCard(
    key: Key('coachHelpCard'),
    tint: GlassCardTint.coach,
    child: Text(CoachCopy.helpLine, style: SteadyType.body),
  );
}

/// What the coach screens say when the coach can't run, per reason: a
/// title and a plain, kind line, and whether checking again could help.
///
/// Reads the typed `CoachModelFailure`s (#151). Any other failure gets a
/// generic "couldn't reach".
({String title, String body, bool canRetry}) coachUnavailableCopy(
  Failure failure,
) => switch (failure) {
  // Until the consent screen lands (#153), this is where the coach stops.
  CoachConsentNotGivenFailure() => (
    title: "The coach isn't set up yet",
    body:
        'It needs your OK before it sends anything, and that step isn’t '
        'here yet. Everything else in Steady works as usual.',
    canRetry: false,
  ),
  CoachTurnedOffFailure() => (
    title: 'The coach is off right now',
    body: 'Try again later. Everything else in Steady works as usual.',
    canRetry: true,
  ),
  CoachDeviceNotVerifiedFailure() => (
    title: "The coach can't run on this iPhone",
    body:
        'Steady couldn’t verify this iPhone, which the coach needs. '
        'Everything else in Steady works as usual.',
    canRetry: false,
  ),
  CoachOfflineFailure() => (
    title: "Can't reach the coach",
    body: 'Check your internet connection, then try again.',
    canRetry: true,
  ),
  CoachRateLimitedFailure(:final retryAfter) => (
    title: "That's all for the coach today",
    body:
        'The coach has a daily limit, and it’s been reached. Try again '
        '${coachRetryAfterLabel(retryAfter)}.',
    canRetry: true,
  ),
  _ => (
    title: "Couldn't reach the coach",
    body: 'Try again in a moment.',
    canRetry: true,
  ),
};

/// When a rate limit lifts, in words: "in a few minutes", "in about an
/// hour", "in about 5 hours", or "later" when the proxy didn't say.
String coachRetryAfterLabel(Duration? retryAfter) {
  if (retryAfter == null) return 'later';
  final minutes = (retryAfter.inSeconds / 60).ceil();
  if (minutes <= 10) return 'in a few minutes';
  if (minutes < 60) return 'in about $minutes minutes';
  final hours = (minutes / 60).round();
  return hours == 1 ? 'in about an hour' : 'in about $hours hours';
}

/// The unavailable state as a coach-tinted card: [coachUnavailableCopy]'s
/// title and line, and "Check again" (44pt) when that could help.
class CoachUnavailableCard extends StatelessWidget {
  /// Creates the card for [failure]. [onRetry] null hides "Check again".
  const CoachUnavailableCard({required this.failure, this.onRetry, super.key});

  /// Why the coach can't run.
  final Failure failure;

  /// Checks again.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final copy = coachUnavailableCopy(failure);
    return GlassCard(
      key: const Key('coachUnavailableCard'),
      tint: GlassCardTint.coach,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(copy.title, style: SteadyType.cardTitle),
          ),
          const SizedBox(height: 8),
          Text(copy.body, style: SteadyType.body),
          if (copy.canRetry && onRetry != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: OutlineButton(
                key: const Key('coachCheckAgain'),
                onPressed: onRetry,
                child: const Text('Check again'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A session's kind as the coach screens name it.
String coachSessionKindLabel(CoachSessionKind kind) => switch (kind) {
  CoachSessionKind.chat => 'Chat',
  CoachSessionKind.weekly => 'Weekly check-in',
};

/// A session's date, e.g. "Sat, Oct 24", in local time.
String coachSessionDateLabel(DateTime at) {
  final local = at.toLocal();
  return '${shortWeekday(local)}, ${shortMonth(local)} ${local.day}';
}
