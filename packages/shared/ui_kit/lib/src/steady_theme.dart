import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'design_tokens.dart';

/// Steady's `shadcn_flutter` [ThemeData], built from the tokens in
/// [SteadyColors]/[SteadyType]/[SteadyRadii] (design source:
/// `docs/steady_product_overview.md` §10). Dark-mode only — the design
/// handoff defines no light variant.
final steadyTheme = ThemeData(
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    background: SteadyColors.bgScreen,
    foreground: SteadyColors.textPrimary,
    card: SteadyColors.bgCard,
    cardForeground: SteadyColors.textPrimary,
    popover: SteadyColors.bgCard,
    popoverForeground: SteadyColors.textPrimary,
    primary: SteadyColors.accentTeal,
    primaryForeground: SteadyColors.bgBase,
    secondary: SteadyColors.bgInputAlt,
    secondaryForeground: SteadyColors.textPrimary,
    muted: SteadyColors.bgChip,
    mutedForeground: SteadyColors.textMuted,
    accent: SteadyColors.bgInputAlt,
    accentForeground: SteadyColors.textPrimary,
    // Not specified by §10 — the product's logging-status ladder is
    // deliberately single-hue with no red (no "shame" visuals), so there's
    // no design-spec destructive color to draw from. This is a reasonable
    // framework default (e.g. a delete confirmation still needs *some*
    // color) rather than a value transcribed from the design doc.
    destructive: Color(0xFFB05C5C),
    border: SteadyColors.borderSubtle,
    input: SteadyColors.bgInput,
    ring: SteadyColors.accentTeal,
    chart1: SteadyColors.caloriesEaten,
    chart2: SteadyColors.caloriesBurned,
    chart3: SteadyColors.steps,
    chart4: SteadyColors.accentTeal,
    chart5: SteadyColors.textMuted,
  ),
  // shadcn_flutter's `radius` is a multiplier, not a px value: radiusLg =
  // radius * 16. 1.125 makes radiusLg == SteadyRadii.card (18px) — the scale
  // §10 specifies for cards/screens. Which internal component uses which
  // named radius (lg vs xl) hasn't been individually audited against §10;
  // revisit per-component if a rendered radius looks off.
  radius: 1.125,
  typography: Typography.geist(
    sans: const TextStyle(fontFamilyFallback: SteadyType.fontFamilyFallback),
  ),
);
