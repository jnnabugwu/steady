import 'dart:math' as math;

import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:ui_kit/src/widgets/cairn_week.dart';
import 'package:ui_kit/src/widgets/logging_status_indicator.dart';

/// What one slot of an [OnboardingCairn] shows.
enum OnboardingStone {
  /// A placed stone: an answered step. Drawn like a fully logged day.
  placed,

  /// A dimmer stone: a skipped step. Drawn like a skipped day: **still a
  /// stone**, never a gap (product doc §1, no shame visuals).
  dimmed,

  /// The stone still to place: the step the person is on. A dashed teal
  /// outline, like today's stone before check-in.
  pending,

  /// Nothing yet. The slot keeps its height, so the stack doesn't shift as
  /// stones are added.
  none,
}

/// Onboarding's progress bar, as a cairn: each step places a stone, and a
/// skipped step places a dimmer one (docs/design/onboarding.md, "The flow").
///
/// Built from [CairnStone], the same stone drawing as [CairnWeek] (and so
/// Today and the share card), without the week's day letters or calories.
/// [stones] holds one entry per slot, bottom first; widths, x-offsets and
/// rotations are fixed per slot (the first seven are [CairnWeek]'s), never
/// random, so the stack looks hand-balanced and stays stable.
///
/// When a slot goes from [OnboardingStone.pending] or
/// [OnboardingStone.none] to placed or dimmed, its stone drops into place
/// over [CairnWeek.dropDuration]. Stones already there on the first build
/// don't drop (a resumed flow shows its stack as it was). With reduced
/// motion on (`MediaQuery.disableAnimationsOf`) a new stone just appears.
///
/// Screen readers get one label for the whole stack ([semanticsLabel]).
class OnboardingCairn extends StatelessWidget {
  /// Creates the stack. [stones] holds at most [maxStones] entries, bottom
  /// first.
  const OnboardingCairn({required this.stones, this.semanticsLabel, super.key});

  /// The slots, bottom first.
  final List<OnboardingStone> stones;

  /// Overrides the default screen-reader label ([defaultSemanticsLabel]).
  final String? semanticsLabel;

  /// The stone shapes, bottom to top: width, x-offset (px) and rotation
  /// (degrees). The first seven are [CairnWeek]'s artboard values; the rest
  /// keep narrowing so a ten-stone stack still tapers.
  static const shapes = <({double width, double dx, double rotation})>[
    (width: 100, dx: 0, rotation: 0),
    (width: 90, dx: 4, rotation: -2),
    (width: 84, dx: -3, rotation: 1.5),
    (width: 88, dx: 2, rotation: -1),
    (width: 76, dx: -4, rotation: 2),
    (width: 68, dx: 3, rotation: -1.5),
    (width: 58, dx: 0, rotation: 1),
    (width: 52, dx: -2, rotation: -1),
    (width: 46, dx: 2, rotation: 1.5),
    (width: 40, dx: 0, rotation: -1),
  ];

  /// The most stones a stack holds: one per entry in [shapes].
  static const maxStones = 10;

  /// The stack's width: the widest stone plus room for the offsets and
  /// rotations.
  static const double width = 112;

  /// The height of a stack of [count] slots.
  static double heightFor(int count) => count <= 0
      ? 0
      : count * CairnStone.height + (count - 1) * CairnWeek.stoneGap;

  /// The label read for [stones] when no [semanticsLabel] is given, e.g.
  /// "Your cairn: 4 stones, 1 of them dimmer for a skipped step. The next
  /// stone is still to place."
  static String defaultSemanticsLabel(List<OnboardingStone> stones) {
    final placed = stones.where((s) => s == OnboardingStone.placed).length;
    final dimmed = stones.where((s) => s == OnboardingStone.dimmed).length;
    final total = placed + dimmed;
    final buffer = StringBuffer(
      total == 0
          ? 'Your cairn: no stones yet.'
          : 'Your cairn: $total ${total == 1 ? 'stone' : 'stones'}',
    );
    if (total > 0) {
      buffer.write(
        dimmed == 0
            ? '.'
            : ', $dimmed of them dimmer for '
                  '${dimmed == 1 ? 'a skipped step' : 'skipped steps'}.',
      );
    }
    if (stones.contains(OnboardingStone.pending)) {
      buffer.write(' The next stone is still to place.');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Checked here, not in the constructor: a const constructor can't read
    // a list's length.
    assert(
      stones.length <= maxStones,
      'OnboardingCairn holds at most $maxStones stones.',
    );
    return Semantics(
      container: true,
      image: true,
      label: semanticsLabel ?? defaultSemanticsLabel(stones),
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: CairnWeek.stoneGap,
          children: [
            // Top to bottom, so the first slot lands at the bottom.
            for (var i = stones.length - 1; i >= 0; i--) _slot(i),
          ],
        ),
      ),
    );
  }

  Widget _slot(int i) {
    final shape = shapes[i];
    final stone = stones[i];
    return SizedBox(
      // Keyed by slot, so a stack that grows a slot keeps each slot's drop
      // state with its own stone.
      key: ValueKey<int>(i),
      height: CairnStone.height,
      child: Center(
        // Same element per slot (positional state), so a slot's drop state
        // survives rebuilds; only its child changes.
        child: _StoneDrop(
          stone: stone,
          child: stone == OnboardingStone.none
              ? SizedBox(width: shape.width, height: CairnStone.height)
              : Transform.translate(
                  offset: Offset(shape.dx, 0),
                  child: Transform.rotate(
                    angle: shape.rotation * math.pi / 180,
                    child: CairnStone(
                      status: switch (stone) {
                        OnboardingStone.placed => LoggingStatus.logged,
                        OnboardingStone.dimmed => LoggingStatus.skipped,
                        OnboardingStone.pending || OnboardingStone.none => null,
                      },
                      width: shape.width,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Drops a slot's stone into place when it goes from pending or empty to
/// placed or dimmed: slides down from above and fades in, ease-out. Idle
/// (fully shown) otherwise, and skipped when reduced motion is on.
class _StoneDrop extends StatefulWidget {
  const _StoneDrop({required this.stone, required this.child});

  final OnboardingStone stone;
  final Widget child;

  @override
  State<_StoneDrop> createState() => _StoneDropState();
}

class _StoneDropState extends State<_StoneDrop>
    with SingleTickerProviderStateMixin {
  /// How far above its resting place the stone starts, in stone heights.
  static const _dropFrom = 1.6;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: CairnWeek.dropDuration,
    value: 1,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, -_dropFrom),
    end: Offset.zero,
  ).animate(_curve);

  static bool _isStone(OnboardingStone s) =>
      s == OnboardingStone.placed || s == OnboardingStone.dimmed;

  @override
  void didUpdateWidget(_StoneDrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    final dropped = !_isStone(oldWidget.stone) && _isStone(widget.stone);
    if (!dropped) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
