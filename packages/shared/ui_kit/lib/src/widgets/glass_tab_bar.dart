import 'dart:ui' show ImageFilter;

import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:ui_kit/src/design_tokens.dart';
import 'package:ui_kit/src/widgets/glass_paint.dart';

/// One destination in a [GlassTabBar].
@immutable
class GlassTabItem {
  /// Creates a tab with an [icon] and a [label].
  const GlassTabItem({required this.icon, required this.label});

  /// The tab's glyph, drawn at 22px.
  final IconData icon;

  /// The tab's name, shown at 10px under the icon and announced to screen
  /// readers.
  final String label;
}

/// The Pass 02 floating pill navigation bar (§10): 64px tall, a full pill
/// ([SteadyRadii.tabBar]), [SteadyColors.tabBarFill] over a 28px backdrop
/// blur, a 1px [SteadyColors.glassControlBorder] border, a 1px inner top
/// highlight and a `0 12 32` black shadow at 0.45.
///
/// This is the only Native Glass widget with a live `BackdropFilter`: one
/// small, fixed blur region is cheap, where blurring every card in a
/// scrolling list is not (issue #64). Cards fake the glass with fills.
///
/// The items share the width equally with 4px gaps inside 6px of padding;
/// the selected one sits in a teal tint pill (0.18) with its icon and
/// label in [SteadyColors.accentTealHover]. Every item is at least 44pt
/// tall (50pt at the 64px bar height), Apple's minimum touch target.
///
/// The bar is self-contained and has no idea where it sits: [margin]
/// (default 18 left, right and bottom, as on the artboard) insets it from
/// whatever the caller places it in, typically the bottom of a `Stack`
/// over the scrolling content. Tapping any tab, the selected one included,
/// calls [onSelected], so the app layer can treat a re-tap as "scroll to
/// top" or ignore it.
///
/// Screen readers get each tab as a button with its label and selected
/// state, inside a container labelled [semanticLabel].
class GlassTabBar extends StatelessWidget {
  /// Creates a tab bar for [items] with [selectedIndex] selected.
  const GlassTabBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.margin = const EdgeInsets.fromLTRB(18, 0, 18, 18),
    this.semanticLabel = 'Main',
    super.key,
  });

  /// The bar's height on the artboard.
  static const double height = 64;

  /// The backdrop blur's sigma (CSS `blur(28px)`; CSS blur takes the
  /// Gaussian's standard deviation, as `ImageFilter.blur` does).
  static const double blurSigma = 28;

  /// The bar's drop shadow, painted outside the pill only.
  static const shadow = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.45),
    offset: Offset(0, 12),
    blurRadius: 32,
  );

  /// The destinations, in order.
  final List<GlassTabItem> items;

  /// The index of the current destination in [items].
  final int selectedIndex;

  /// Called with a tab's index when it's tapped.
  final ValueChanged<int> onSelected;

  /// Space around the bar. Defaults to the artboard's 18px inset from the
  /// screen's sides and bottom.
  final EdgeInsetsGeometry margin;

  /// The navigation region's screen-reader label.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    // Checked here, not in the constructor: a const constructor can't read
    // a list's length.
    assert(
      selectedIndex >= 0 && selectedIndex < items.length,
      'selectedIndex must index into items.',
    );
    final borderRadius = BorderRadius.circular(SteadyRadii.tabBar);
    final tabs = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) tabs.add(const SizedBox(width: 4));
      tabs.add(
        Expanded(
          child: _GlassTab(
            item: items[i],
            selected: i == selectedIndex,
            onPressed: () => onSelected(i),
          ),
        ),
      );
    }
    return Padding(
      padding: margin,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: semanticLabel,
        child: CustomPaint(
          painter: const OuterShadowPainter(
            radius: SteadyRadii.tabBar,
            shadow: shadow,
          ),
          foregroundPainter: const GlassHighlightPainter(
            radius: SteadyRadii.tabBar,
            // rgba(255,255,255,0.08) on the artboard: glassBorder's value.
            color: SteadyColors.glassBorder,
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: SteadyColors.tabBarFill,
                  borderRadius: borderRadius,
                  border: Border.all(color: SteadyColors.glassControlBorder),
                ),
                child: SizedBox(
                  height: height,
                  child: Padding(
                    // 6px inside the 1px border.
                    padding: const EdgeInsets.all(7),
                    child: Row(children: tabs),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassTab extends StatelessWidget {
  const _GlassTab({
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  final GlassTabItem item;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? SteadyColors.accentTealHover
        : SteadyColors.textSecondary;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: item.label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        child: Clickable(
          onPressed: onPressed,
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          decoration: WidgetStatePropertyAll(
            BoxDecoration(
              color: selected
                  ? SteadyColors.accentTealTint(0.18)
                  : const Color(0x00000000),
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: 22, color: color),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamilyFallback: SteadyType.fontFamilyFallback,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
