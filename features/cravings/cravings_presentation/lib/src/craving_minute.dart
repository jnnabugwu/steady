import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The guided imagery minute: short on-screen prompts that keep the mind's
/// eye busy somewhere else (a calm place, its colors, sounds and light), a
/// slowly pulsing circle to follow and a calm countdown. "Skip" and "Done
/// early" are always there.
///
/// Why imagery: a craving is largely vivid mental imagery, and a short
/// visual task competes with it (docs/research/craving_support.md §2,
/// moderate lab evidence). No claim is made that it works.
///
/// **Reduced motion** (`MediaQuery.disableAnimationsOf`): the circle is
/// static, and the last prompt doesn't ask you to follow it.
///
/// **Screen readers**: each prompt is announced as it appears, plus "about
/// 30 seconds left" once. The countdown itself is silent; focusing it
/// reads the time left in 15-second steps.
class CravingMinute extends StatefulWidget {
  /// Creates the minute. [onEnded] is called once: when it runs out, or on
  /// "Skip" or "Done early".
  const CravingMinute({required this.onEnded, super.key});

  /// How long the minute lasts: 75 seconds, inside the 60 to 90 asked for.
  static const duration = Duration(seconds: 75);

  /// How long each prompt stays up.
  static const promptDuration = Duration(seconds: 15);

  /// The prompts, in order, one per [promptDuration].
  static const prompts = [
    'Picture a calm place you know well.',
    'Look around it. Find three colors.',
    'Listen for two sounds there.',
    'Notice the light. Where is it coming from?',
    'Stay there a little longer. Let the circle set your pace.',
  ];

  /// The last prompt when motion is reduced (the circle doesn't move).
  static const stillLastPrompt = 'Stay there a little longer.';

  /// Called once when the minute ends, however it ends.
  final VoidCallback onEnded;

  @override
  State<CravingMinute> createState() => _CravingMinuteState();
}

class _CravingMinuteState extends State<CravingMinute>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  Timer? _timer;
  int _elapsed = 0;
  bool _ended = false;
  int? _announcedPrompt;

  int get _total => CravingMinute.duration.inSeconds;
  int get _remaining => _total - _elapsed;
  int get _promptIndex => (_elapsed ~/ CravingMinute.promptDuration.inSeconds)
      .clamp(0, CravingMinute.prompts.length - 1);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse
        ..stop()
        ..value = 0.5;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
    _announcePrompt();
  }

  void _tick() {
    if (_ended) return;
    setState(() => _elapsed++);
    if (_remaining <= 0) {
      _end();
      return;
    }
    _announcePrompt(extra: _remaining == 30 ? 'About 30 seconds left.' : null);
  }

  /// Announces the current prompt if it hasn't been yet, only while a
  /// screen reader is on.
  void _announcePrompt({String? extra}) {
    if (!MediaQuery.accessibleNavigationOf(context)) return;
    final index = _promptIndex;
    final parts = [if (_announcedPrompt != index) _prompt(index), ?extra];
    _announcedPrompt = index;
    if (parts.isEmpty) return;
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        parts.join(' '),
        Directionality.of(context),
      ),
    );
  }

  String _prompt(int index) {
    final last = index == CravingMinute.prompts.length - 1;
    if (last && MediaQuery.disableAnimationsOf(context)) {
      return CravingMinute.stillLastPrompt;
    }
    return CravingMinute.prompts[index];
  }

  void _end() {
    if (_ended) return;
    _ended = true;
    _timer?.cancel();
    widget.onEnded();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining.clamp(0, _total);
    final clock =
        '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}';
    // Rounded up to 15 seconds, so focusing it gives a calm estimate.
    final spokenSeconds = ((remaining + 14) ~/ 15) * 15;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Take a minute'.toUpperCase(), style: SteadyType.eyebrow),
        const SizedBox(height: 12),
        SizedBox(
          // Room for two lines, so the layout doesn't jump between prompts.
          height: 64,
          child: Semantics(
            container: true,
            child: Text(
              _prompt(_promptIndex),
              key: const Key('cravingMinutePrompt'),
              style: SteadyType.cardTitle,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: ExcludeSemantics(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.78, end: 1).animate(
                  CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                ),
                child: const _CalmCircle(key: Key('cravingMinuteCircle')),
              ),
            ),
          ),
        ),
        Semantics(
          container: true,
          label: remaining <= 0
              ? 'Time is up'
              : 'About $spokenSeconds seconds left',
          child: ExcludeSemantics(
            child: Text(
              clock,
              key: const Key('cravingMinuteClock'),
              textAlign: TextAlign.center,
              style: SteadyType.metricValue.copyWith(
                color: SteadyColors.textTertiary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: GhostButton(
                  key: const Key('cravingMinuteSkip'),
                  onPressed: _end,
                  child: const Center(child: Text('Skip')),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlineButton(
                  key: const Key('cravingMinuteDoneEarly'),
                  onPressed: _end,
                  child: const Center(child: Text('Done early')),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A soft teal circle with a faint ring: the shape to follow.
class _CalmCircle extends StatelessWidget {
  const _CalmCircle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            SteadyColors.accentTealTint(0.38),
            SteadyColors.accentTealTint(0.10),
          ],
        ),
        border: Border.all(color: SteadyColors.accentTealTint(0.28)),
      ),
    );
  }
}
