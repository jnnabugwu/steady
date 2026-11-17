import 'package:flutter/physics.dart';
import 'package:onboarding_presentation/src/onboarding_copy.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// Screen 1's stone: the person taps it, or drags it down, onto the
/// ground, where it wobbles and settles (docs/design/onboarding.md,
/// "Animation"). Steady's version of hatching Finch's egg.
///
/// Drawn with [CairnStone], like every other stone. A tap drops it; a drag
/// moves it with the finger and, let go past halfway (or flicked down),
/// drops it, otherwise it springs back up. Landing starts a wobble: an
/// underdamped [SpringSimulation] on the stone's tilt. [onPlaced] is called
/// as it lands, once.
///
/// **Reduced motion** (`MediaQuery.disableAnimationsOf`): a tap or a
/// release past halfway puts the stone straight on the ground, with no
/// fall and no wobble. A drag still follows the finger: that's the
/// person's own movement, not an animation.
///
/// Screen readers get one button: [OnboardingCopy.stoneToPlace], then
/// [OnboardingCopy.stonePlaced].
class FirstStone extends StatefulWidget {
  /// Creates the stone, already on the ground when [placed].
  const FirstStone({required this.placed, required this.onPlaced, super.key});

  /// Whether the stone starts on the ground (a resumed or revisited screen).
  final bool placed;

  /// Called once, as the stone lands.
  final VoidCallback onPlaced;

  /// The scene's height: the stone's fall plus the ground.
  static const double height = 200;

  /// The stone's width.
  static const double stoneWidth = 120;

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

  @override
  State<FirstStone> createState() => _FirstStoneState();
}

class _FirstStoneState extends State<FirstStone> with TickerProviderStateMixin {
  /// 0: the stone at the top; 1: on the ground.
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

  static const double _groundHeight = 6;

  /// The ground's distance from the scene's bottom.
  static const double _groundInset = 12;

  /// The padding around the stone that widens its touch target.
  static const double _touchPadding = 14;

  /// How far the stone falls, in logical pixels: from the top until it
  /// rests on the ground.
  static const double _travel =
      FirstStone.height -
      _groundInset -
      _groundHeight -
      _touchPadding -
      CairnStone.height;

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
    return Semantics(
      container: true,
      button: !_placed,
      label: _placed ? OnboardingCopy.stonePlaced : OnboardingCopy.stoneToPlace,
      onTap: _placed ? null : _drop,
      excludeSemantics: true,
      child: SizedBox(
        height: FirstStone.height,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Where the stone goes: a dashed outline on the ground until
            // it's there.
            Positioned(
              bottom: _groundInset + _groundHeight,
              child: _placed
                  ? const SizedBox.shrink()
                  : const CairnStone(
                      status: null,
                      width: FirstStone.stoneWidth,
                    ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: _groundInset,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: SteadyColors.glassControlFill,
                  borderRadius: BorderRadius.circular(_groundHeight),
                  border: Border.all(color: SteadyColors.glassControlBorder),
                ),
                child: const SizedBox(height: _groundHeight),
              ),
            ),
            AnimatedBuilder(
              animation: Listenable.merge([_fall, _wobble]),
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _fall.value * _travel),
                child: Transform.rotate(
                  // Rock about the stone's bottom edge, as if on the ground.
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
                // A larger touch target than the 15pt stone.
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: _touchPadding,
                    horizontal: 10,
                  ),
                  child: CairnStone(
                    status: LoggingStatus.logged,
                    width: FirstStone.stoneWidth,
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
