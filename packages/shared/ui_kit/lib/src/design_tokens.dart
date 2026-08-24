import 'package:flutter/widgets.dart';

/// Design tokens transcribed from `docs/steady_product_overview.md` §10
/// (Claude Design handoff, Pass 01). Dark-mode only — every value in that
/// spec is a dark-palette value, no light variant is defined.
abstract final class SteadyColors {
  // Backgrounds
  static const bgBase = Color(0xFF060807);
  static const bgScreen = Color(0xFF0A0C0C);
  static const bgCard = Color(0xFF141817);
  static const bgChip = Color(0xFF121615);
  static const bgInput = Color(0xFF171C1B);
  static const bgInputAlt = Color(0xFF191E1D);
  static const borderSubtle = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  static const borderSubtleStrong = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

  // Text
  static const textPrimary = Color(0xFFE9EDEC);
  static const textSecondary = Color(0xFFA9B2B0);
  static const textTertiary = Color(0xFF8A9391);
  static const textMuted = Color(0xFF6A7472);
  static const textDisabled = Color(0xFF4E5756);

  // Accent — primary (coach & key actions)
  static const accentTeal = Color(0xFF6DA8A0);
  static const accentTealHover = Color(0xFF8FC4BC);

  /// rgba(109,168,160, α) at the given alpha (spec range 0.14–0.6
  /// depending on emphasis — selected states, borders, chat bubble fill).
  static Color accentTealTint(double alpha) =>
      const Color(0xFF6DA8A0).withValues(alpha: alpha);

  // Accent — metrics (full-saturation for logged data, ~35% alpha dimmed
  // variant for future/unlogged days)
  static const caloriesEaten = Color(0xFFC2A57B);
  static const caloriesEatenDimmed = Color(0x59C2A57B); // 0.35 alpha
  static const caloriesBurned = Color(0xFFA98FA8);
  static const caloriesBurnedDimmed = Color(0x59A98FA8); // 0.35 alpha
  static const steps = Color(0xFF7F9AC2);
  static const stepsDimmed = Color(0x597F9AC2); // 0.35 alpha

  // Logging status ladder — deliberately single-hue, no red/yellow/green
  // (product non-goal: no shame visuals — see §1 of the product overview).
  static const statusLogged = Color(0xFF6DA8A0);
  static const statusPartial = Color(0xFF3E605C);
  static const statusSkipped = Color(0xFF212827);
}

/// Typography scale from §10. Font sizes/weights/tracking are given as
/// ranges in the spec; each constant picks the value used by default,
/// documented alongside the range it was drawn from.
abstract final class SteadyType {
  static const fontFamilyFallback = <String>[
    '-apple-system',
    'SF Pro Text',
    'system-ui',
  ];

  /// Headline (screen title): 27–34px, weight 600, tracking -0.4 to -0.6px.
  static const headline = TextStyle(
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 30,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: SteadyColors.textPrimary,
  );

  /// Card title/value: 19–24px, weight 500–600.
  static const cardTitle = TextStyle(
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 21,
    fontWeight: FontWeight.w600,
    color: SteadyColors.textPrimary,
  );

  /// Body: 15px, line-height 1.55.
  static const body = TextStyle(
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 15,
    height: 1.55,
    color: SteadyColors.textSecondary,
  );

  /// Labels/eyebrows: 11–13px, uppercase, tracking 0.1–0.14em, text.muted.
  static const label = TextStyle(
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.4, // ~0.12em at fontSize 12
    color: SteadyColors.textMuted,
  );
}

/// Corner-radius and shape scale from §10.
abstract final class SteadyRadii {
  /// Cards/screens: 16–20px corner radius.
  static const card = 18.0;

  /// Buttons/chips/options: 12–14px.
  static const control = 13.0;

  /// Chat bubbles: asymmetric radius for a tail effect —
  /// 18px 18px 18px 6px (incoming), mirrored for outgoing.
  static const chatBubble = BorderRadius.only(
    topLeft: Radius.circular(18),
    topRight: Radius.circular(18),
    bottomLeft: Radius.circular(18),
    bottomRight: Radius.circular(6),
  );
  static const chatBubbleMirrored = BorderRadius.only(
    topLeft: Radius.circular(18),
    topRight: Radius.circular(18),
    bottomLeft: Radius.circular(6),
    bottomRight: Radius.circular(18),
  );

  /// Small indicators (status dots, legend swatches): 3–8px.
  static const indicator = 5.0;
}
