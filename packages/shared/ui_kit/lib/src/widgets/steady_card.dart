import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:ui_kit/src/design_tokens.dart';

/// Thin wrapper around shadcn_flutter's [Card], pinned to the §10 card
/// corner-radius token and a sensible default content padding. Fill/border
/// colors come from the ambient [ColorScheme] (see `steady_theme.dart`),
/// not repeated here.
class SteadyCard extends StatelessWidget {
  const SteadyCard({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      borderRadius: BorderRadius.circular(SteadyRadii.card),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}
