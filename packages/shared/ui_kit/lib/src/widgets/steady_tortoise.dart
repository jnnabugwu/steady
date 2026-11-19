import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:ui_kit/src/design_tokens.dart';

/// Steady's mascot (#176, "Cairn carrier"): a tortoise, side view, facing
/// right, carrying the app icon's three stones on its back. It carries the
/// habit one stone at a time: slow and steady.
///
/// - [stones] is how many of the three it carries, 0 to 3, bottom first:
///   tan ([SteadyColors.caloriesEaten]), mauve
///   ([SteadyColors.caloriesBurned]), blue ([SteadyColors.steps]), as in
///   the icon.
/// - When [stones] goes up and [animateStones] is true, each new stone
///   drops onto the stack and settles, over [dropDuration]. With reduced
///   motion on (`MediaQuery.disableAnimationsOf`) it just appears. Stones
///   there on the first build don't drop.
/// - [size] is the widget's height; its width follows
///   ([widthFor]). Below [smallFormBelow] the stones would be a few pixels
///   of noise, so the tortoise is drawn without them (the small form,
///   [isSmallForm]): the smooth teal shell, head, legs and tail, a bigger
///   eye and no smile or catchlight. The small form also drops the space
///   above the shell that holds the stones, so it's wider for its height.
///
/// One calm expression, always: the tortoise is never sad or hurt, and its
/// stones never fall (product doc §1, no shame visuals). No streak or
/// weight imagery.
///
/// Screen readers get one label ([semanticsLabel], or
/// [defaultSemanticsLabel]); the painted parts are excluded from
/// semantics.
class SteadyTortoise extends StatefulWidget {
  /// Creates the tortoise, [size] tall, carrying [stones] of its three.
  const SteadyTortoise({
    this.size = 120,
    this.stones = maxStones,
    this.animateStones = true,
    this.semanticsLabel,
    super.key,
  }) : assert(size > 0, 'SteadyTortoise needs a positive size.'),
       assert(
         stones >= 0 && stones <= maxStones,
         'SteadyTortoise carries 0 to $maxStones stones.',
       );

  /// The widget's height. The width is [widthFor] this.
  final double size;

  /// How many stones it carries, 0 to [maxStones], bottom first. Not drawn
  /// in the small form.
  final int stones;

  /// Whether a stone added (by [stones] going up) drops into place. When
  /// false, or with reduced motion on, it just appears.
  final bool animateStones;

  /// Overrides the screen-reader label ([defaultSemanticsLabel]).
  final String? semanticsLabel;

  /// The most stones it carries: the icon's three.
  static const maxStones = 3;

  /// Heights below this draw the small form, without stones.
  static const double smallFormBelow = 48;

  /// How long a new stone takes to drop and settle.
  static const dropDuration = Duration(milliseconds: 560);

  /// Whether a tortoise [size] tall is drawn in the small form.
  static bool isSmallForm(double size) => size < smallFormBelow;

  /// The width of a tortoise [size] tall.
  static double widthFor(double size) {
    final view = _Geometry.viewFor(small: isSmallForm(size));
    return size * view.width / view.height;
  }

  /// Where stone [index] (0 at the bottom) rests on a tortoise [size] tall,
  /// in the tortoise's own coordinates: the stone's unrotated bounds. For
  /// placing a [TortoiseStone] exactly where the tortoise carries it, e.g.
  /// to drop a stone onto its back by hand. The small form carries no
  /// stones; this describes the full form at any size.
  static Rect stoneRect(int index, double size) {
    RangeError.checkValidIndex(index, _Geometry.stones, 'index');
    const view = _Geometry.large;
    final scale = size / view.height;
    final stone = _Geometry.stones[index];
    return Rect.fromCenter(
      center: (stone.center - view.topLeft) * scale,
      width: stone.rx * 2 * scale,
      height: stone.ry * 2 * scale,
    );
  }

  /// The label read when no [semanticsLabel] is given: how many stones it
  /// carries, or just "A tortoise" in the small form (which draws none).
  static String defaultSemanticsLabel({
    required int stones,
    bool small = false,
  }) => switch (small ? 0 : stones) {
    0 => 'A tortoise',
    1 => 'A tortoise carrying one stone on its back',
    2 => 'A tortoise carrying two stones on its back',
    _ => 'A tortoise carrying three stones on its back',
  };

  @override
  State<SteadyTortoise> createState() => _SteadyTortoiseState();
}

class _SteadyTortoiseState extends State<SteadyTortoise>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drop = AnimationController(
    vsync: this,
    duration: SteadyTortoise.dropDuration,
    value: 1,
  );

  /// Stones at or above this index are the ones dropping.
  late int _dropFrom = widget.stones;

  @override
  void didUpdateWidget(SteadyTortoise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stones <= oldWidget.stones) return;
    final animate =
        widget.animateStones &&
        !SteadyTortoise.isSmallForm(widget.size) &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (animate) {
      // Stones still landing from an earlier drop land with the new ones.
      _dropFrom = _drop.isAnimating
          ? math.min(_dropFrom, oldWidget.stones)
          : oldWidget.stones;
      _drop.forward(from: 0);
    } else {
      _drop.value = 1;
      _dropFrom = widget.stones;
    }
  }

  @override
  void dispose() {
    _drop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final small = SteadyTortoise.isSmallForm(widget.size);
    return Semantics(
      container: true,
      image: true,
      label:
          widget.semanticsLabel ??
          SteadyTortoise.defaultSemanticsLabel(
            stones: widget.stones,
            small: small,
          ),
      excludeSemantics: true,
      child: CustomPaint(
        size: Size(SteadyTortoise.widthFor(widget.size), widget.size),
        painter: _TortoisePainter(
          small: small,
          stones: widget.stones,
          dropFrom: _dropFrom,
          drop: _drop,
        ),
      ),
    );
  }
}

/// One of the tortoise's stones on its own, drawn as it is on a tortoise
/// [tortoiseSize] tall: [SteadyTortoise.stoneRect]'s size, rotated as on
/// the stack. For a stone the person moves before it's on the tortoise's
/// back (onboarding's first stone); place it at
/// [SteadyTortoise.stoneRect] to land it exactly where the tortoise
/// carries it.
class TortoiseStone extends StatelessWidget {
  /// Creates stone [index] (0, the bottom, tan) at [tortoiseSize]'s scale.
  const TortoiseStone({
    required this.index,
    required this.tortoiseSize,
    super.key,
  });

  /// Which stone, 0 (bottom, tan) to 2 (top, blue).
  final int index;

  /// The height of the tortoise it belongs on.
  final double tortoiseSize;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: SteadyTortoise.stoneRect(index, tortoiseSize).size,
      painter: _StonePainter(index),
    );
  }
}

/// The drawing, in design units: a 100-unit-wide space the tortoise was
/// laid out in. [large] and [small] are the parts of it each form shows.
abstract final class _Geometry {
  /// The full form's view: the tortoise and the stones above it.
  static const large = Rect.fromLTRB(6, 25, 94, 91);

  /// The small form's view: the tortoise only.
  static const small = Rect.fromLTRB(6, 47, 94, 91);

  static Rect viewFor({required bool small}) => small ? _Geometry.small : large;

  /// The shell's dome: the top half of this ellipse.
  static const dome = Rect.fromLTRB(17, 50, 77, 98);
  static const domeBase = 74.0;

  /// The darker band along the bottom of the shell.
  static final rim = Rect.fromCenter(
    center: const Offset(47, domeBase),
    width: 64,
    height: 6.4,
  );

  static const headCenter = Offset(80.5, 65.5);
  static const headRadius = 9.5;

  static const eyeCenter = Offset(83.8, 62.6);
  static const eyeRadius = 1.7;
  static const smallEyeRadius = 2.3;
  static const catchlightCenter = Offset(84.35, 62.05);
  static const catchlightRadius = 0.6;

  static const backLeg = Rect.fromLTRB(25, 72, 34, 86.5);
  static const frontLeg = Rect.fromLTRB(57, 72, 66, 86.5);
  static const legRadius = Radius.circular(4.5);

  static final shadow = Rect.fromCenter(
    center: const Offset(50, 86.5),
    width: 80,
    height: 6.4,
  );

  static const highlightCenter = Offset(35, 58.5);
  static const highlightSize = Size(17, 7.4);
  static const double highlightRotation = -20 * math.pi / 180;

  /// The stones, bottom first: centre, radii, rotation (degrees) and
  /// colour. Centred slightly left of the dome's top; each overlaps the
  /// one under it a little, so they sit rather than float. Rotations are
  /// the icon's (mauve −4°, blue 3°).
  static const stones =
      <({Offset center, double rx, double ry, double rotation, Color color})>[
        (
          center: Offset(44, 46.3),
          rx: 15,
          ry: 4.4,
          rotation: 0,
          color: SteadyColors.caloriesEaten,
        ),
        (
          center: Offset(45, 38.6),
          rx: 11,
          ry: 3.8,
          rotation: -4,
          color: SteadyColors.caloriesBurned,
        ),
        (
          center: Offset(44.2, 31.6),
          rx: 7.6,
          ry: 3.4,
          rotation: 3,
          color: SteadyColors.steps,
        ),
      ];

  /// How far above its resting place a dropping stone starts.
  static const dropHeight = 16.0;

  static Path tail() => Path()
    ..moveTo(22, 69.5)
    ..quadraticBezierTo(15, 70.5, 10.5, 75.5)
    ..quadraticBezierTo(16.5, 76.8, 22, 75.5)
    ..close();

  static Path smile() => Path()
    ..moveTo(83, 68.6)
    ..quadraticBezierTo(85.8, 70.6, 88.4, 67.9);
}

/// A dropping stone's pose at [t] (0 to 1): it falls (ease-in) for the
/// first 60%, fading in over the first 30%, then rebounds a hair and rocks
/// to rest. Never past its resting place, and never off the stack.
({double dy, double angle, double opacity}) _dropPose(double t) {
  if (t >= 1) return (dy: 0, angle: 0, opacity: 1);
  const fall = 0.6;
  if (t < fall) {
    final k = Curves.easeIn.transform(t / fall);
    return (
      dy: -_Geometry.dropHeight * (1 - k),
      angle: 0,
      opacity: (t / 0.3).clamp(0.0, 1.0),
    );
  }
  final k = (t - fall) / (1 - fall);
  final decay = 1 - k;
  return (
    dy: -1.2 * math.sin(math.pi * k) * decay,
    angle: 0.07 * math.sin(3 * math.pi * k) * decay,
    opacity: 1,
  );
}

void _paintStone(
  Canvas canvas,
  int index, {
  double dy = 0,
  double rockAngle = 0,
  double opacity = 1,
}) {
  final stone = _Geometry.stones[index];
  final base = stone.center.translate(0, stone.ry + dy);
  canvas
    ..save()
    // Rock about the stone's bottom, as if on the stone under it.
    ..translate(base.dx, base.dy)
    ..rotate(rockAngle)
    ..translate(0, -stone.ry)
    ..rotate(stone.rotation * math.pi / 180)
    ..drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: stone.rx * 2,
        height: stone.ry * 2,
      ),
      Paint()..color = stone.color.withValues(alpha: opacity),
    )
    ..restore();
}

class _TortoisePainter extends CustomPainter {
  _TortoisePainter({
    required this.small,
    required this.stones,
    required this.dropFrom,
    required this.drop,
  }) : super(repaint: drop);

  final bool small;
  final int stones;
  final int dropFrom;
  final Animation<double> drop;

  @override
  void paint(Canvas canvas, Size size) {
    final view = _Geometry.viewFor(small: small);
    canvas
      ..save()
      ..scale(size.height / view.height)
      ..translate(-view.left, -view.top);
    _paintBody(canvas);
    if (!small) {
      final pose = _dropPose(drop.value);
      for (var i = 0; i < stones; i++) {
        if (i < dropFrom) {
          _paintStone(canvas, i);
        } else {
          _paintStone(
            canvas,
            i,
            dy: pose.dy,
            rockAngle: pose.angle,
            opacity: pose.opacity,
          );
        }
      }
    }
    canvas.restore();
  }

  void _paintBody(Canvas canvas) {
    Paint fill(Color color) => Paint()..color = color;

    canvas
      ..drawOval(_Geometry.shadow, fill(SteadyColors.mascotShadow))
      ..drawPath(_Geometry.tail(), fill(SteadyColors.mascotSage))
      ..drawRRect(
        RRect.fromRectAndRadius(_Geometry.backLeg, _Geometry.legRadius),
        fill(SteadyColors.mascotOliveSage),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(_Geometry.frontLeg, _Geometry.legRadius),
        fill(SteadyColors.mascotOliveSage),
      );

    // The dome: the top half of the ellipse, lit from above.
    final dome = Path()
      ..addArc(_Geometry.dome, math.pi, math.pi)
      ..close();
    canvas
      ..drawPath(
        dome,
        Paint()
          ..shader = ui.Gradient.linear(
            _Geometry.dome.topCenter,
            Offset(_Geometry.dome.center.dx, _Geometry.domeBase),
            const [
              SteadyColors.mascotShellLight,
              SteadyColors.accentTeal,
              SteadyColors.mascotShellDeep,
            ],
            const [0, 0.5, 1],
          ),
      )
      ..save()
      ..translate(_Geometry.highlightCenter.dx, _Geometry.highlightCenter.dy)
      ..rotate(_Geometry.highlightRotation)
      ..drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: _Geometry.highlightSize.width,
          height: _Geometry.highlightSize.height,
        ),
        fill(SteadyColors.mascotShellHighlight),
      )
      ..restore()
      ..drawOval(_Geometry.rim, fill(SteadyColors.mascotShellRim))
      ..drawCircle(
        _Geometry.headCenter,
        _Geometry.headRadius,
        fill(SteadyColors.mascotSage),
      )
      ..drawCircle(
        _Geometry.eyeCenter,
        small ? _Geometry.smallEyeRadius : _Geometry.eyeRadius,
        fill(SteadyColors.bgBase),
      );
    if (small) return;
    canvas
      ..drawCircle(
        _Geometry.catchlightCenter,
        _Geometry.catchlightRadius,
        fill(SteadyColors.textPrimary),
      )
      ..drawPath(
        _Geometry.smile(),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round
          ..color = SteadyColors.mascotSageDeep,
      );
  }

  @override
  bool shouldRepaint(_TortoisePainter oldDelegate) =>
      oldDelegate.small != small ||
      oldDelegate.stones != stones ||
      oldDelegate.dropFrom != dropFrom ||
      oldDelegate.drop != drop;
}

class _StonePainter extends CustomPainter {
  const _StonePainter(this.index);

  final int index;

  @override
  void paint(Canvas canvas, Size size) {
    final stone = _Geometry.stones[index];
    final scale = size.width / (stone.rx * 2);
    canvas
      ..save()
      ..scale(scale)
      // Put the stone's centre at the box's centre, then draw it as the
      // tortoise does.
      ..translate(stone.rx - stone.center.dx, stone.ry - stone.center.dy);
    _paintStone(canvas, index);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StonePainter oldDelegate) => oldDelegate.index != index;
}
