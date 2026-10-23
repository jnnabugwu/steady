import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:ui_kit/src/design_tokens.dart';

/// Steady's `shadcn_flutter` [ThemeData], built from the tokens in
/// [SteadyColors]/[SteadyType]/[SteadyRadii] (design source:
/// `docs/steady_product_overview.md` §10, Pass 02). Dark-mode only — the design
/// handoff defines no light variant.
const steadyTheme = ThemeData(
  colorScheme: ColorScheme(
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
  // shadcn_flutter's `radius` is a multiplier, not a px value. In 0.0.55:
  // radiusXs = r*4, Sm = r*8, Md = r*12, Lg = r*16, Xl = r*20, Xxl = r*24.
  // Buttons (Primary/Outline/Ghost) and text fields use radiusMd; Card and
  // OutlinedContainer default to radiusXl, AlertDialog to radiusXxl, Select
  // popups to radiusLg, checkboxes to radiusSm.
  //
  // No single multiplier hits every Pass 02 radius (option 20, pill 22,
  // card 28, tab bar 32 aren't one scale), so this picks the component the
  // feature screens use most, the button: r = 22/12 makes radiusMd ==
  // SteadyRadii.pill, so every shadcn button is a full pill (44px buttons
  // exactly, the 38px default size clamped). The rest follow: Lg 29.3, Xl
  // 36.7, Xxl 44 (round, like iOS 26's alerts and menus), Sm 14.7.
  //
  // Surfaces with their own Pass 02 radius pass the SteadyRadii token
  // explicitly (SteadyCard passes SteadyRadii.card); no feature uses a bare
  // shadcn Card. Pass 01's 1.125 assumed cards read radiusLg; they read
  // radiusXl.
  radius: SteadyRadii.pill / 12,
  typography: Typography.geist(
    sans: TextStyle(
      fontFamily: SteadyType.fontFamily,
      fontFamilyFallback: SteadyType.fontFamilyFallback,
    ),
  ),
);
