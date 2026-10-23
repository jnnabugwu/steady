import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:ui_kit/src/design_tokens.dart';
import 'package:ui_kit/src/widgets/logging_status_indicator.dart';

/// One of the check-in options ("Logged fully" / "Partial" / "Skipped"),
/// per the Pass 02 A2 artboard: a 72px-tall, [SteadyRadii.option] (20px)
/// tile with the status's 22×9 pill swatch at the top and the [label] at
/// the bottom.
///
/// Unselected, it's a faint glass tile (white at 0.03, 1px
/// [SteadyColors.glassBorder]). [selected] switches to the teal tint at
/// 0.16 with a 1px teal border at 0.65. The swatch colour comes from the
/// single-hue status ladder ([SteadyColors.statusLogged] /
/// [SteadyColors.statusPartial] / [SteadyColors.statusSkipped]).
///
/// It fills the width it's given; the check-in card lays three out in a
/// row with 8px gaps. Screen readers get a button with [label] and its
/// selected state.
class StatusOptionTile extends StatelessWidget {
  /// Creates an option for [status]. A null [onPressed] disables it.
  const StatusOptionTile({
    required this.status,
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  /// The tile's height on the A2 artboard.
  static const double height = 72;

  /// Unselected fill, rgba(255,255,255,0.03), from the A2 artboard.
  static const unselectedFill = Color.fromRGBO(255, 255, 255, 0.03);

  /// The 1px ring around the swatch, rgba(255,255,255,0.16), which keeps
  /// the near-black "skipped" swatch visible.
  static const swatchRing = Color.fromRGBO(255, 255, 255, 0.16);

  /// Which status this option logs; picks the swatch colour.
  final LoggingStatus status;

  /// The option's text, also its screen-reader label.
  final String label;

  /// Whether this is the day's current status.
  final bool selected;

  /// Called on tap. Null disables the tile.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final swatch = switch (status) {
      LoggingStatus.logged => SteadyColors.statusLogged,
      LoggingStatus.partial => SteadyColors.statusPartial,
      LoggingStatus.skipped => SteadyColors.statusSkipped,
    };
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      child: SizedBox(
        height: height,
        child: Clickable(
          enabled: enabled,
          onPressed: onPressed,
          mouseCursor: WidgetStatePropertyAll(
            enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          ),
          decoration: WidgetStatePropertyAll(
            BoxDecoration(
              color: selected
                  ? SteadyColors.accentTealTint(0.16)
                  : unselectedFill,
              borderRadius: BorderRadius.circular(SteadyRadii.option),
              border: Border.all(
                color: selected
                    ? SteadyColors.accentTealTint(0.65)
                    : SteadyColors.glassBorder,
              ),
            ),
          ),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: swatch,
                  borderRadius: BorderRadius.circular(SteadyRadii.indicator),
                  boxShadow: const [
                    BoxShadow(color: swatchRing, spreadRadius: 1),
                  ],
                ),
                child: const SizedBox(width: 22, height: 9),
              ),
              ExcludeSemantics(
                // Two lines fit under the swatch in 72px, so "Logged fully"
                // wraps on a narrow phone instead of truncating.
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamilyFallback: SteadyType.fontFamilyFallback,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? SteadyColors.textPrimary
                        : SteadyColors.textDisabled,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
