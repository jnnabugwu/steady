import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:ui_kit/src/design_tokens.dart';

/// The Pass 02 glass card (§10): shadcn_flutter's [Card] with the
/// [SteadyColors.glassFill] fill, a 1px [SteadyColors.glassBorder] border,
/// the [SteadyRadii.card] radius, and a 1px [SteadyColors.glassHighlight]
/// inner top highlight.
class SteadyCard extends StatelessWidget {
  /// Creates a glass card around [child]. [padding] defaults to 16 on all
  /// sides.
  const SteadyCard({required this.child, this.padding, super.key});

  /// The card's content.
  final Widget child;

  /// Space between the border and [child].
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: const _GlassHighlightPainter(
        radius: SteadyRadii.card,
        color: SteadyColors.glassHighlight,
      ),
      child: Card(
        theme: CardTheme(
          filled: true,
          fillColor: SteadyColors.glassFill,
          borderColor: SteadyColors.glassBorder,
          borderWidth: 1,
          borderRadius: BorderRadius.circular(SteadyRadii.card),
          padding: padding ?? const EdgeInsets.all(16),
        ),
        child: child,
      ),
    );
  }
}

/// Paints CSS's `box-shadow: inset 0 1px 0 <color>`: the sliver between the
/// card's inner rounded rect and the same rect moved down 1px, so the
/// highlight follows the top corners' curve.
class _GlassHighlightPainter extends CustomPainter {
  const _GlassHighlightPainter({required this.radius, required this.color});

  final double radius;
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
  bool shouldRepaint(_GlassHighlightPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.color != color;
}
