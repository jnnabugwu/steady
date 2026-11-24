import 'package:flutter/physics.dart';
import 'package:onboarding_presentation/src/onboarding_copy.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// Screen 1's stone: the person taps it, or drags it down, onto the
/// tortoise's back (the mascot, [SteadyTortoise], #176), where it wobbles
/// and settles (docs/design/onboarding.md, "Animation"). Steady's version
/// of hatching Finch's egg.
///
/// The stone is the tortoise's own bottom stone ([TortoiseStone], tan),
/// and it lands exactly where the tortoise carries it
/// ([SteadyTortoise.stoneRect]); a faint copy marks that place until it's
/// there. The tortoise itself never moves. A tap drops the stone; a drag
/// moves it with the finger and, let go past halfway (or flicked down),
/// drops it, otherwise it springs back up. Landing starts a wobble: an
/// underdamped [SpringSimulation] on the stone's tilt. [onPlaced] is called
/// as it lands, once.
///
/// **Reduced motion** (`MediaQuery.disableAnimationsOf`): a tap or a
/// release past halfway puts the stone straight on the tortoise's back,
/// with no fall and no wobble. A drag still follows the finger: that's the
/// person's own movement, not an animation.
///
/// Screen readers get one button: [OnboardingCopy.stoneToPlace], then
/// [OnboardingCopy.stonePlaced]. The tortoise and the stones are inside
/// it, excluded.
class FirstStone extends StatefulWidget {
  /// Creates the stone, already on the tortoise's back when [placed].
  const FirstStone({required this.placed, required this.onPlaced, super.key});

  /// Whether the stone starts on the tortoise's back (a resumed or
  /// revisited screen).
  final bool placed;

  /// Called once, as the stone lands.
  final VoidCallback onPlaced;

  /// The scene's height: the stone's fall plus the tortoise.
  static const double height = 260;

  /// The tortoise's height ([SteadyTortoise.size]), standing at the
  /// scene's bottom.
  static const double tortoiseSize = 160;

  /// Which of the tortoise's stones this is: the bottom one.
  static const stoneIndex = 0;

  /// How long the fall takes, from the top.
  static const fallDuration = Duration(milliseconds: 380);

  /// The wobble's spring: underdamped, so the stone rocks a few times and
  /// settles in about a second.
  static const wobbleSpring = SpringDescription(
    mass: 1,
    stiffness: 260,
    damping: 7,
  );

  /// The wobble's starting tilt, in radians.
  static const wobbleTilt = 0.14;

  /// The faint copy marking where the stone goes, as an opacity.
  static const targetOpacity = 0.22;

  @override
  State<FirstStone> createState() => _FirstStoneState();
}

class _FirstStoneState extends State<FirstStone> with TickerProviderStateMixin {
  /// 0: the stone at the top; 1: on the tortoise's back.
  late final AnimationController _fall = AnimationController(
    vsync: this,
    duration: FirstStone.fallDuration,
    value: widget.placed ? 1 : 0,
  );

  /// The tilt, as a share of [FirstStone.wobbleTilt]; 0 at rest.
  late final AnimationController _wobble = AnimationController.unbounded(
    vsync: this,
  );

  late bool _placed = widget.placed;

  /// The padding around the stone that widens its touch target.
  static const EdgeInsets _touchPadding = EdgeInsets.symmetric(
    vertical: 16,
    horizontal: 12,
  );

  /// Where the stone rests on the tortoise, in the tortoise's coordinates.
  static final Rect _rest = SteadyTortoise.stoneRect(
    FirstStone.stoneIndex,
    FirstStone.tortoiseSize,
  );

  /// The tortoise's top, in the scene.
  static const double _tortoiseTop =
      FirstStone.height - FirstStone.tortoiseSize;

  /// How far the stone falls, in logical pixels: from the top until it
  /// rests on the tortoise's back.
  static final double _travel = _tortoiseTop + _rest.top - _touchPadding.top;

  bool get _reducedMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void dispose() {
    _fall.dispose();
    _wobble.dispose();
    super.dispose();
  }

  void _land() {
    if (_placed) return;
    setState(() => _placed = true);
    widget.onPlaced();
    if (_reducedMotion) return;
    _wobble.animateWith(SpringSimulation(FirstStone.wobbleSpring, 1, 0, 0));
  }

  void _drop() {
    if (_placed) return;
    if (_reducedMotion) {
      _fall.value = 1;
      _land();
      return;
    }
    _fall.animateTo(1, curve: Curves.easeIn).whenCompleteOrCancel(() {
      if (mounted && _fall.value >= 1) _land();
    });
  }

  void _dragUpdate(DragUpdateDetails details) {
    if (_placed) return;
    _fall
      ..stop()
      ..value = (_fall.value + details.delta.dy / _travel).clamp(0, 1);
  }

  void _dragEnd(DragEndDetails details) {
    if (_placed) return;
    final flicked = details.velocity.pixelsPerSecond.dy > 600;
    if (_fall.value >= 0.5 || flicked) {
      _drop();
    } else if (_reducedMotion) {
      _fall.value = 0;
    } else {
      _fall.animateTo(0, curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    const stone = TortoiseStone(
      index: FirstStone.stoneIndex,
      tortoiseSize: FirstStone.tortoiseSize,
    );
    return Semantics(
      container: true,
      button: !_placed,
      label: _placed ? OnboardingCopy.stonePlaced : OnboardingCopy.stoneToPlace,
      onTap: _placed ? null : _drop,
      excludeSemantics: true,
      child: SizedBox(
        height: FirstStone.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tortoiseLeft =
                (constraints.maxWidth -
                    SteadyTortoise.widthFor(FirstStone.tortoiseSize)) /
                2;
            final stoneLeft = tortoiseLeft + _rest.left;
            return Stack(
              children: [
                Positioned(
                  left: tortoiseLeft,
                  bottom: 0,
                  child: const SteadyTortoise(
                    size: FirstStone.tortoiseSize,
                    stones: 0,
                  ),
                ),
                // Where the stone goes: a faint copy on the tortoise's
                // back until it's there.
                if (!_placed)
                  Positioned(
                    left: stoneLeft,
                    top: _tortoiseTop + _rest.top,
                    child: const Opacity(
                      opacity: FirstStone.targetOpacity,
                      child: stone,
                    ),
                  ),
                Positioned(
                  left: stoneLeft - _touchPadding.left,
                  top: 0,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_fall, _wobble]),
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _fall.value * _travel),
                      child: Transform.rotate(
                        // Rock about the stone's bottom edge, as if on the
                        // shell.
                        alignment: Alignment.bottomCenter,
                        angle: _wobble.value * FirstStone.wobbleTilt,
                        child: child,
                      ),
                    ),
                    child: GestureDetector(
                      key: const Key('onboardingFirstStone'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _drop,
                      onVerticalDragUpdate: _dragUpdate,
                      onVerticalDragEnd: _dragEnd,
                      // A larger touch target than the stone itself.
                      child: const Padding(
                        padding: _touchPadding,
                        child: stone,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
