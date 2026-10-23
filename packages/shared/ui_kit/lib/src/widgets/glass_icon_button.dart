import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:ui_kit/src/design_tokens.dart';
import 'package:ui_kit/src/widgets/glass_paint.dart';

/// A 44×44 round glass icon button (§10, Pass 02): the screen header's
/// import button. Fill [SteadyColors.glassControlFill], a 1px
/// [SteadyColors.glassControlBorder] border, a 1px inner top highlight and
/// a 20px [SteadyColors.textPrimary] icon.
///
/// Built on shadcn_flutter's [Clickable], which supplies the tap handling,
/// keyboard focus and focus outline. An icon alone says nothing to a
/// screen reader, so [semanticLabel] is required; it's announced as a
/// button with that label.
class GlassIconButton extends StatelessWidget {
  /// Creates a round glass button showing [icon]. A null [onPressed]
  /// disables it.
  const GlassIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    super.key,
  });

  /// The diameter, and the touch target: 44pt, Apple's minimum.
  static const double size = 44;

  /// The glyph, drawn at 20px.
  final IconData icon;

  /// What the button does, for screen readers (e.g. "Import Cal AI PDF").
  final String semanticLabel;

  /// Called on tap. Null disables the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: size,
        child: Clickable(
          enabled: enabled,
          onPressed: onPressed,
          mouseCursor: WidgetStatePropertyAll(
            enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          ),
          decoration: const WidgetStatePropertyAll(
            BoxDecoration(
              color: SteadyColors.glassControlFill,
              shape: BoxShape.circle,
              border: Border.fromBorderSide(
                BorderSide(color: SteadyColors.glassControlBorder),
              ),
            ),
          ),
          child: CustomPaint(
            // The artboard's highlight here is rgba(255,255,255,0.08), the
            // same value as glassBorder (cards use glassHighlight, 0.06).
            foregroundPainter: const GlassHighlightPainter(
              radius: size / 2,
              color: SteadyColors.glassBorder,
            ),
            child: Center(
              child: Icon(
                icon,
                size: 20,
                color: enabled
                    ? SteadyColors.textPrimary
                    : SteadyColors.textDisabled,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
