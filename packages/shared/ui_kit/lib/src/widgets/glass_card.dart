import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:ui_kit/src/design_tokens.dart';
import 'package:ui_kit/src/widgets/glass_paint.dart';

/// The surface colours a [GlassCard] uses.
enum GlassCardTint {
  /// The default frosted card: [SteadyColors.glassFill], a 1px
  /// [SteadyColors.glassBorder] border and the 1px
  /// [SteadyColors.glassHighlight] inner top highlight.
  glass,

  /// The coach card: [SteadyColors.coachCardFill] with a 1px
  /// [SteadyColors.coachCardBorder] border. The Pass 02 artboards draw it
  /// without the inner highlight, so it has none.
  coach,
}

/// The Pass 02 "Native Glass" card (§10): shadcn_flutter's [Card] with a
/// translucent fill, a 1px border, the [SteadyRadii.card] (28px) radius
/// and, for [GlassCardTint.glass], a 1px inner top highlight.
///
/// The glass look comes from fills and borders only. A [GlassCard] never
/// blurs what's behind it (no `BackdropFilter`), so a scrolling list of
/// cards stays cheap; the floating `GlassTabBar` is the one surface that
/// blurs (issue #64's performance note).
///
/// `SteadyCard` forwards here with its own 16px default padding, so
/// existing callers keep their layout.
class GlassCard extends StatelessWidget {
  /// Creates a glass card around [child]. [padding] defaults to 18 on all
  /// sides, the check-in card's padding on the Pass 02 artboard.
  const GlassCard({
    required this.child,
    this.padding,
    this.tint = GlassCardTint.glass,
    super.key,
  });

  /// The card's content.
  final Widget child;

  /// Space between the border and [child]. Defaults to 18 on all sides.
  final EdgeInsetsGeometry? padding;

  /// Which surface colours to use; [GlassCardTint.glass] by default.
  final GlassCardTint tint;

  @override
  Widget build(BuildContext context) {
    final (fill, border) = switch (tint) {
      GlassCardTint.glass => (SteadyColors.glassFill, SteadyColors.glassBorder),
      GlassCardTint.coach => (
        SteadyColors.coachCardFill,
        SteadyColors.coachCardBorder,
      ),
    };
    final card = Card(
      theme: CardTheme(
        filled: true,
        fillColor: fill,
        borderColor: border,
        borderWidth: 1,
        borderRadius: BorderRadius.circular(SteadyRadii.card),
        padding: padding ?? const EdgeInsets.all(18),
        // Explicitly no blur: cards render glass with fills, never with a
        // live backdrop blur.
        surfaceBlur: 0,
      ),
      child: child,
    );
    return switch (tint) {
      GlassCardTint.glass => CustomPaint(
        foregroundPainter: const GlassHighlightPainter(
          radius: SteadyRadii.card,
          color: SteadyColors.glassHighlight,
        ),
        child: card,
      ),
      GlassCardTint.coach => card,
    };
  }
}
