import 'dart:math' as math;

import 'package:shadcn_flutter/shadcn_flutter.dart';

// Internal painters shared by the Native Glass widgets. Not exported from
// `ui_kit.dart`: callers get the look through the widgets, not the paint.

/// Paints CSS's `box-shadow: inset 0 1px 0 <color>`: the sliver between the
/// surface's inner rounded rect (inside its 1px border) and the same rect
/// moved down 1px, so the highlight follows the top corners' curve. Flutter
/// has no inset shadow, so the glass widgets draw it with this as a
/// foreground painter.
class GlassHighlightPainter extends CustomPainter {
  /// Creates a highlight for a surface with outer corner [radius].
  const GlassHighlightPainter({required this.radius, required this.color});

  /// The surface's outer corner radius. A radius of at least half the
  /// shortest side gives a full pill or circle.
  final double radius;

  /// The highlight colour.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Inside the 1px border.
    final inner = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      Radius.circular(radius - 1),
    );
    final highlight = Path.combine(
      PathOperation.difference,
      Path()..addRRect(inner),
      Path()..addRRect(inner.shift(const Offset(0, 1))),
    );
    canvas.drawPath(highlight, Paint()..color = color);
  }

  @override
  bool shouldRepaint(GlassHighlightPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.color != color;
}

/// Paints [shadow] only outside a rounded rect, like a CSS outer
/// `box-shadow`. A plain [BoxShadow] in a [BoxDecoration] also paints under
/// the box, which shows through a translucent fill (and gets picked up by a
/// [BackdropFilter] above it) and darkens the surface.
class OuterShadowPainter extends CustomPainter {
  /// Creates an outer-only [shadow] for a surface with corner [radius].
  const OuterShadowPainter({required this.radius, required this.shadow});

  /// The surface's corner radius.
  final double radius;

  /// The shadow to paint outside the surface.
  final BoxShadow shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final surface = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    // How far past the surface the shadow can land: its blur, its offset,
    // and any positive spread (a negative spread only pulls it in).
    final reach =
        shadow.blurRadius * 2 +
        shadow.offset.distance +
        math.max(0, shadow.spreadRadius);
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect.inflate(reach)),
      Path()..addRRect(surface),
    );
    canvas
      ..save()
      ..clipPath(outside)
      ..drawRRect(
        surface.shift(shadow.offset).inflate(shadow.spreadRadius),
        shadow.toPaint(),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(OuterShadowPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.shadow != shadow;
}
