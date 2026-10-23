import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:ui_kit/src/widgets/glass_card.dart';

/// Pass 01's name for the card, now a thin forwarder to [GlassCard] (the
/// default [GlassCardTint.glass] look) that keeps its 16px default padding
/// so existing callers render exactly as before.
///
/// Prefer [GlassCard] in new code. Feature screens move over as each
/// screen is rebuilt for Pass 02; `SteadyCard` isn't marked `@Deprecated`
/// until then, because `flutter analyze` treats every deprecated use as a
/// failing issue.
class SteadyCard extends StatelessWidget {
  /// Creates a glass card around [child]. [padding] defaults to 16 on all
  /// sides.
  const SteadyCard({required this.child, this.padding, super.key});

  /// The card's content.
  final Widget child;

  /// Space between the border and [child]. Defaults to 16 on all sides.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}
