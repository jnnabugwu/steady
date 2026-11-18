import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:ui_kit/src/design_tokens.dart';

/// A small pill marking something Steady will charge for: the coach,
/// including the weekly check-in (docs/design/onboarding.md, "The coach
/// steps are marked paid").
///
/// The wording is [text], one constant, so it changes in one place once
/// what's free and what's paid is decided. Never "Plus" or "upgrade": the
/// coach is the main thing Steady does, not an add-on.
///
/// Drawn in the coach card's colours (the teal tint), so it reads as part
/// of the coach rather than as a warning. Screen readers hear [text].
class PaidBadge extends StatelessWidget {
  /// Creates the badge.
  const PaidBadge({super.key});

  /// The badge's wording.
  static const text = 'Paid';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: SteadyColors.coachCardFill,
          borderRadius: BorderRadius.circular(SteadyRadii.pill),
          border: Border.all(color: SteadyColors.coachCardBorder),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          child: Text(
            text,
            maxLines: 1,
            style: TextStyle(
              fontFamily: SteadyType.fontFamily,
              fontFamilyFallback: SteadyType.fontFamilyFallback,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: SteadyColors.accentTealHover,
            ),
          ),
        ),
      ),
    );
  }
}
