import 'package:flutter/widgets.dart';

/// Colour tokens from `docs/steady_product_overview.md` §10 (Pass 02,
/// "Native Glass"). Dark-mode only: the spec defines no light variant.
///
/// Pass 02 keeps Pass 01's palette (backgrounds, teal, the metric colours,
/// the status ladder) and adds translucent glass surfaces. The one palette
/// change is [textMuted], raised for WCAG AA contrast.
abstract final class SteadyColors {
  // Backgrounds

  /// Outer canvas, behind the screen.
  static const bgBase = Color(0xFF060807);

  /// Screen background. Glass surfaces are tuned against this colour.
  static const bgScreen = Color(0xFF0A0C0C);

  /// Opaque card/panel fill (Pass 01). Pass 02 cards use [glassFill]; this
  /// stays for surfaces that must not show what's behind them (popovers,
  /// dialogs).
  static const bgCard = Color(0xFF141817);

  /// Small chip/legend fill.
  static const bgChip = Color(0xFF121615);

  /// Message input / coach chat bubble fill.
  static const bgInput = Color(0xFF171C1B);

  /// Secondary button / unselected option fill (opaque).
  static const bgInputAlt = Color(0xFF191E1D);

  /// rgba(255,255,255,0.06): default hairline border.
  static const borderSubtle = Color(0x0FFFFFFF);

  /// rgba(255,255,255,0.08): button/input border.
  static const borderSubtleStrong = Color(0x14FFFFFF);

  // Glass surfaces (Pass 02)

  /// Glass card and tile fill, rgba(255,255,255,0.045). Over [bgScreen] it
  /// composites to about #151717, close to Pass 01's opaque [bgCard].
  static const glassFill = Color.fromRGBO(255, 255, 255, 0.045);

  /// Glass card and tile border, rgba(255,255,255,0.08), 1px.
  static const glassBorder = Color.fromRGBO(255, 255, 255, 0.08);

  /// The 1px inner top highlight on glass cards, rgba(255,255,255,0.06)
  /// (CSS `box-shadow: inset 0 1px 0`). Flutter has no inset shadow, so
  /// paint it as a 1px line inside the top edge.
  static const glassHighlight = Color.fromRGBO(255, 255, 255, 0.06);

  /// Fill for glass controls: the round icon button and the secondary pill
  /// button ("Not tonight"), rgba(255,255,255,0.06).
  static const glassControlFill = Color.fromRGBO(255, 255, 255, 0.06);

  /// Border for glass controls and the tab bar, rgba(255,255,255,0.10).
  static const glassControlBorder = Color.fromRGBO(255, 255, 255, 0.10);

  /// Floating tab bar fill, rgba(28,34,33,0.72), drawn over a 28px backdrop
  /// blur.
  static const tabBarFill = Color.fromRGBO(28, 34, 33, 0.72);

  /// Coach card fill: the teal tint at 0.10 ([accentTealTint]`(0.10)`).
  static const coachCardFill = Color.fromRGBO(109, 168, 160, 0.10);

  /// Coach card border: the teal tint at 0.28 ([accentTealTint]`(0.28)`).
  static const coachCardBorder = Color.fromRGBO(109, 168, 160, 0.28);

  // Text

  /// Headlines and primary values. 16.6:1 on [bgScreen].
  static const textPrimary = Color(0xFFE9EDEC);

  /// Body and secondary values. 9.0:1 on [bgScreen].
  static const textSecondary = Color(0xFFA9B2B0);

  /// Descriptions, coach message text. 6.2:1 on [bgScreen].
  static const textTertiary = Color(0xFF8A9391);

  /// Labels and uppercase eyebrows. Pass 02 raised this from Pass 01's
  /// #6A7472 (4.07:1 on [bgScreen], failing WCAG AA for 11–13px text) to
  /// #7E8886: 5.37:1 on [bgScreen], 4.93:1 on a [glassFill] card, 4.91:1 on
  /// [bgCard].
  static const textMuted = Color(0xFF7E8886);

  /// Unlogged/placeholder values. Decorative only: 2.6:1, below AA.
  static const textDisabled = Color(0xFF4E5756);

  // Accent: primary (coach and key actions)

  /// Primary accent: coach, key actions, "logged" status.
  static const accentTeal = Color(0xFF6DA8A0);

  /// Light teal: hover, the date line above the screen title, today's
  /// label, the selected tab.
  static const accentTealHover = Color(0xFF8FC4BC);

  /// rgba(109,168,160, α) at the given [alpha]. Alphas used by the Pass 02
  /// artboards: 0.10 coach card fill, 0.16 selected option fill, 0.18
  /// selected tab fill, 0.20 the screen's top glow, 0.28 coach card border,
  /// 0.65 selected option border, 0.75 today's dashed ring.
  static Color accentTealTint(double alpha) =>
      accentTeal.withValues(alpha: alpha);

  // Accent: metrics (full saturation for logged data, ~35% alpha dimmed
  // variant for future/unlogged days)

  /// Calories eaten (tan/gold).
  static const caloriesEaten = Color(0xFFC2A57B);

  /// [caloriesEaten] at 0.35 alpha.
  static const caloriesEatenDimmed = Color(0x59C2A57B);

  /// Calories burned (mauve).
  static const caloriesBurned = Color(0xFFA98FA8);

  /// [caloriesBurned] at 0.35 alpha.
  static const caloriesBurnedDimmed = Color(0x59A98FA8);

  /// Steps (blue).
  static const steps = Color(0xFF7F9AC2);

  /// [steps] at 0.35 alpha.
  static const stepsDimmed = Color(0x597F9AC2);

  // Logging status ladder: deliberately single-hue, no red/yellow/green
  // (product non-goal: no shame visuals, see §1 of the product overview).

  /// Logged fully.
  static const statusLogged = Color(0xFF6DA8A0);

  /// Partially logged.
  static const statusPartial = Color(0xFF3E605C);

  /// Skipped.
  static const statusSkipped = Color(0xFF212827);
}

/// Type scale from §10 (Pass 02).
abstract final class SteadyType {
  /// SF Pro Text, Apple's system font (Pass 02 is set in it, like the
  /// artboards). Flutter's engine maps this name to the system font on iOS
  /// and macOS; elsewhere it falls back to the platform default. Named
  /// explicitly so the font can't change if the theme's default does.
  static const fontFamily = 'CupertinoSystemText';

  /// SF Pro Display, the system font's cut for large sizes. Apple switches
  /// to it at about 20pt; the engine's name for it is used for the screen
  /// title.
  static const displayFontFamily = 'CupertinoSystemDisplay';

  /// Used if neither family name resolves.
  static const fontFamilyFallback = <String>[
    '-apple-system',
    'SF Pro Text',
    'system-ui',
  ];

  /// Screen title: 34px, weight 700, tracking -0.8px, line height 1.05.
  static const headline = TextStyle(
    fontFamily: displayFontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.05,
    color: SteadyColors.textPrimary,
  );

  /// Card title: 20px, weight 600, tracking -0.3px.
  static const cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: SteadyColors.textPrimary,
  );

  /// Metric value (the big number on a metric tile, the week headline):
  /// 21px, weight 600, tracking -0.4px, tabular figures so digits line up
  /// and don't shift as values change.
  static const metricValue = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 21,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    fontFeatures: [FontFeature.tabularFigures()],
    color: SteadyColors.textPrimary,
  );

  /// Body: 15px, line height 1.5.
  static const body = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 15,
    height: 1.5,
    color: SteadyColors.textSecondary,
  );

  /// Eyebrow above a card title: 11px, weight 600, tracking 0.12em
  /// (1.32px), [SteadyColors.textMuted]. The spec sets eyebrows in
  /// uppercase; `TextStyle` has no text-transform, so uppercase the string
  /// at the call site.
  static const eyebrow = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.32,
    color: SteadyColors.textMuted,
  );

  /// Pass 01's name for [eyebrow]; same style. Kept so existing callers
  /// compile. Prefer [eyebrow] in new code.
  static const TextStyle label = eyebrow;
}

/// Corner-radius scale from §10 (Pass 02).
abstract final class SteadyRadii {
  /// Glass cards: 28px.
  static const card = 28.0;

  /// Metric tiles (the three-across grid): 22px.
  static const tile = 22.0;

  /// Check-in option buttons: 20px.
  static const option = 20.0;

  /// Pill buttons and chips: 22px, a full pill at the 44px button height.
  /// Shorter widgets clamp to a full pill too.
  static const pill = 22.0;

  /// Floating tab bar: 32px (64px tall, so a full pill).
  static const tabBar = 32.0;

  /// Chat bubbles: asymmetric radius for a tail effect,
  /// 18px 18px 18px 6px (incoming). Unchanged from Pass 01.
  static const chatBubble = BorderRadius.only(
    topLeft: Radius.circular(18),
    topRight: Radius.circular(18),
    bottomLeft: Radius.circular(18),
    bottomRight: Radius.circular(6),
  );

  /// [chatBubble] mirrored, for outgoing messages.
  static const chatBubbleMirrored = BorderRadius.only(
    topLeft: Radius.circular(18),
    topRight: Radius.circular(18),
    bottomLeft: Radius.circular(6),
    bottomRight: Radius.circular(18),
  );

  /// Small indicators (status dots, legend swatches): 5px. Unchanged from
  /// Pass 01.
  static const indicator = 5.0;
}
