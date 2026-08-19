// Sunburst Pop — the complete token layer for MindForge.
//
// Shown here as one file so it reads top-to-bottom. In the repo it splits into:
//   lib/theme/sunburst_primitives.dart  -> _P                (the only hex in the app)
//   lib/theme/sunburst_colors.dart      -> SunburstColors
//   lib/theme/sunburst_shape.dart       -> SunburstShape
//   lib/theme/sunburst_motion.dart      -> SunburstMotion
//   lib/theme/sunburst_type.dart        -> SunburstType
//   lib/theme/sunburst_theme.dart       -> buildSunburstTheme()
//
// Values are transcribed from design/sunburst-pop/system.html. Anything derived
// rather than transcribed is marked DERIVED with the reason.
//
// The `// @contrast <fg> <bg> <min>` lines below are machine-read by
// scripts/check_palette_contrast.sh: it resolves each name through the const
// instance to a primitive hex and recomputes WCAG relative luminance.

import 'dart:ui' show FontFeature, lerpDouble;

import 'package:flutter/material.dart';

/// Tier 1 — primitives. The one place in MindForge a raw colour may appear.
/// Named by the design system's own primitive names, not by rank or appearance,
/// because those names are how designers and this file stay in sync.
abstract final class _P {
  static const cream = Color(0xFFFFF8EC);
  static const creamSunk = Color(0xFFFFEEDA);
  static const creamEdge = Color(0xFFF6E3C6);
  static const dot = Color(0xFFF2DFC0);
  static const paper = Color(0xFFFFFFFF);
  static const ink = Color(0xFF2B1B4D);
  static const inkSoft = Color(0xFF5A4A7D);
  static const inkMuted = Color(0xFF8E80AE);
  static const sunshine = Color(0xFFFFC53D);
  static const sunshineDeep = Color(0xFFF2A81E);
  static const coral = Color(0xFFFF6B5A);
  static const coralDeep = Color(0xFFE8452F);
  static const turquoise = Color(0xFF22C7B8);
  static const turquoiseDeep = Color(0xFF12A79A);
  static const grape = Color(0xFF6A45E8);
  static const grapePop = Color(0xFF7C5CFF);
  static const leaf = Color(0xFF4CC86A);
  static const leafDeep = Color(0xFF2FA64F);
  static const tangerine = Color(0xFFFF9330);

  // Gameplay tier — tuned for telling-apart-at-speed on cream, NOT for brand
  // harmony. Never wire one of these into a chrome slot by name; wire the
  // primitive, so the colour-blind swap below cannot reach it.
  static const playRed = Color(0xFFD81E2C);
  static const playBlue = Color(0xFF1F6BE0);
  static const playGreen = Color(0xFF157A39);
  static const playYellow = Color(0xFFF5B301);
  static const playPurple = Color(0xFF6A45E8);
  static const playOrange = Color(0xFFC24409);
  static const playPink = Color(0xFFC2185B);
}

/// The non-hue channel every answer colour also carries. Under deuteranopia
/// playRed and playGreen both simulate to olive (dE76 27.0) and in greyscale
/// red/blue/green sit within 1.09:1 — stripe and dot never collapse.
enum PlayFill { solid, stripe, dot, ring }

/// The four default Stroop answers plus the two Blitz extras, each permanently
/// bound to its fill. A widget asks for [PlayAnswer.red] and gets a colour *and*
/// a pattern; it never receives a bare Color it has to remember to decorate.
enum PlayAnswer {
  red(PlayFill.stripe),
  blue(PlayFill.solid),
  green(PlayFill.dot),
  yellow(PlayFill.ring),
  purple(PlayFill.solid),
  orange(PlayFill.stripe);

  const PlayAnswer(this.fill);

  final PlayFill fill;
}

// ---------------------------------------------------------------------------
// Colours
// ---------------------------------------------------------------------------

/// Tier 2 — semantic slots. Widgets read these and never `_P`.
@immutable
class SunburstColors extends ThemeExtension<SunburstColors> {
  const SunburstColors({
    required this.surface, required this.surfaceSunk,
    required this.surfaceRaised, required this.surfaceInvert,
    required this.textPrimary, required this.textSecondary,
    required this.textDisabled, required this.textInvert,
    required this.border, required this.borderDisabled,
    required this.divider, required this.dotPattern,
    required this.accent, required this.accentDeep, required this.accentAlt,
    required this.success, required this.successDeep,
    required this.warning, required this.danger, required this.focusRing,
    required this.gameStroop, required this.gameStroopDeep,
    required this.gameSchulte, required this.gameSchulteDeep,
    required this.playRed, required this.playBlue, required this.playGreen,
    required this.playYellow, required this.playPurple, required this.playOrange,
    required this.cbBlue, required this.cbYellow,
    required this.cbOrange, required this.cbPink,
  });

  // Chrome slots.
  final Color surface, surfaceSunk, surfaceRaised, surfaceInvert;
  final Color textPrimary, textSecondary, textDisabled, textInvert;
  final Color border, borderDisabled, divider, dotPattern;
  final Color accent, accentDeep, accentAlt;
  final Color success, successDeep, warning, danger, focusRing;

  // Per-game identity. A new game adds a pair here, nothing else.
  final Color gameStroop, gameStroopDeep, gameSchulte, gameSchulteDeep;

  // Gameplay tier. Legal only inside a board/answer widget — see the boundary
  // note on `answerColour`. Never paints chrome.
  final Color playRed, playBlue, playGreen, playYellow, playPurple, playOrange;

  // Colour-blind answer palette (Settings -> "Colour-blind friendly palette").
  final Color cbBlue, cbYellow, cbOrange, cbPink;

  /// The ONLY place the colour-blind setting is applied. The flag is read from
  /// settings state by the board's ViewModel and passed in; no widget branches
  /// on it, and no chrome slot can be reached from here.
  Color answerColour(PlayAnswer a, {bool colourBlind = false}) => switch (a) {
    PlayAnswer.red => colourBlind ? cbPink : playRed,
    PlayAnswer.blue => colourBlind ? cbBlue : playBlue,
    PlayAnswer.green => colourBlind ? cbOrange : playGreen,
    PlayAnswer.yellow => colourBlind ? cbYellow : playYellow,
    PlayAnswer.purple => playPurple,
    PlayAnswer.orange => playOrange,
  };

  /// Label colour for an answer fill — never "pick one at the call site".
  /// Holds in both palettes: only the yellow slot stays light enough to need
  /// ink (8.3:1); every other answer takes paper (>= 5.0:1).
  Color answerLabel(PlayAnswer a) =>
      a == PlayAnswer.yellow ? textPrimary : surfaceRaised;

  /// Asserting accessor. A missing extension is a wiring bug, not a case to
  /// paper over with a fallback palette no golden has ever rendered.
  static SunburstColors of(BuildContext context) {
    final ext = Theme.of(context).extension<SunburstColors>();
    assert(ext != null, 'SunburstColors missing. Build via buildSunburstTheme().');
    return ext!;
  }

  // @contrast textPrimary surface       4.5  body text on the screen background
  // @contrast textPrimary surfaceRaised 4.5  body text on a card
  // @contrast textPrimary surfaceSunk   4.5  body text in an inset well
  // @contrast textSecondary surface     4.5  captions on the screen background
  // @contrast textSecondary surfaceRaised 4.5 captions on a card
  // @contrast textSecondary surfaceSunk 4.5  captions in an inset well
  // @contrast textInvert surfaceInvert  4.5  cream on the ink sheet
  // @contrast textPrimary accent        4.5  ink label on a sunshine button
  // @contrast textPrimary success       4.5  ink label on a leaf Play button
  // @contrast textPrimary warning       4.5  ink label on a tangerine chip
  // @contrast textPrimary gameStroop    4.5  ink label on the Stroop band
  // @contrast textPrimary gameSchulte   4.5  ink label on the Schulte band
  // @contrast textPrimary gameSchulteDeep 4.5 ink glyph on a found tile
  // @contrast textPrimary accentDeep    4.5  ink on the dark half of a stripe
  // @contrast textInvert accentAlt      4.5  cream label on grape
  // @contrast surfaceRaised danger      4.5  paper label on a destructive button
  // @contrast textPrimary playYellow    4.5  ink label on the yellow answer key
  // @contrast surfaceRaised playRed     4.5  paper label, default palette
  // @contrast surfaceRaised playBlue    4.5  paper label, default palette
  // @contrast surfaceRaised playGreen   4.5  paper label, default palette
  // @contrast textInvert playPurple     4.5  cream label, Blitz palette
  // @contrast surfaceRaised playOrange  4.5  paper label, Blitz palette
  // @contrast surfaceRaised cbPink      4.5  paper label, colour-blind palette
  // @contrast focusRing surface         3.0  focus ring is a UI component (SC 1.4.11)
  // @contrast border surface            3.0  the 3px structural border
  // @contrast textDisabled surface      3.0  disabled only; SC 1.4.3 exempts it,
  //                                          and it always ships a shape change

  List<Object?> get _props => [
    surface, surfaceSunk, surfaceRaised, surfaceInvert,
    textPrimary, textSecondary, textDisabled, textInvert,
    border, borderDisabled, divider, dotPattern,
    accent, accentDeep, accentAlt,
    success, successDeep, warning, danger, focusRing,
    gameStroop, gameStroopDeep, gameSchulte, gameSchulteDeep,
    playRed, playBlue, playGreen, playYellow, playPurple, playOrange,
    cbBlue, cbYellow, cbOrange, cbPink,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SunburstColors &&
          runtimeType == other.runtimeType &&
          _sameProps(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);

  static bool _sameProps(List<Object?> a, List<Object?> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  SunburstColors copyWith({
    Color? surface, Color? surfaceSunk, Color? surfaceRaised, Color? surfaceInvert,
    Color? textPrimary, Color? textSecondary, Color? textDisabled, Color? textInvert,
    Color? border, Color? borderDisabled, Color? divider, Color? dotPattern,
    Color? accent, Color? accentDeep, Color? accentAlt,
    Color? success, Color? successDeep, Color? warning, Color? danger, Color? focusRing,
    Color? gameStroop, Color? gameStroopDeep, Color? gameSchulte, Color? gameSchulteDeep,
    Color? playRed, Color? playBlue, Color? playGreen, Color? playYellow,
    Color? playPurple, Color? playOrange,
    Color? cbBlue, Color? cbYellow, Color? cbOrange, Color? cbPink,
  }) => SunburstColors(
    surface: surface ?? this.surface, surfaceSunk: surfaceSunk ?? this.surfaceSunk,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    surfaceInvert: surfaceInvert ?? this.surfaceInvert,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textDisabled: textDisabled ?? this.textDisabled,
    textInvert: textInvert ?? this.textInvert,
    border: border ?? this.border,
    borderDisabled: borderDisabled ?? this.borderDisabled,
    divider: divider ?? this.divider, dotPattern: dotPattern ?? this.dotPattern,
    accent: accent ?? this.accent, accentDeep: accentDeep ?? this.accentDeep,
    accentAlt: accentAlt ?? this.accentAlt, success: success ?? this.success,
    successDeep: successDeep ?? this.successDeep,
    warning: warning ?? this.warning, danger: danger ?? this.danger,
    focusRing: focusRing ?? this.focusRing,
    gameStroop: gameStroop ?? this.gameStroop,
    gameStroopDeep: gameStroopDeep ?? this.gameStroopDeep,
    gameSchulte: gameSchulte ?? this.gameSchulte,
    gameSchulteDeep: gameSchulteDeep ?? this.gameSchulteDeep,
    playRed: playRed ?? this.playRed, playBlue: playBlue ?? this.playBlue,
    playGreen: playGreen ?? this.playGreen,
    playYellow: playYellow ?? this.playYellow,
    playPurple: playPurple ?? this.playPurple,
    playOrange: playOrange ?? this.playOrange,
    cbBlue: cbBlue ?? this.cbBlue, cbYellow: cbYellow ?? this.cbYellow,
    cbOrange: cbOrange ?? this.cbOrange, cbPink: cbPink ?? this.cbPink,
  );

  /// Honest per-field interpolation. MindForge ships one ThemeData and never
  /// animates a theme change, so this does not run in production — but golden
  /// harnesses and previews drive it, and a field silently missing here is the
  /// classic way a design system rots. Add every new slot to this list.
  @override
  SunburstColors lerp(covariant SunburstColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return SunburstColors(
      surface: c(surface, other.surface),
      surfaceSunk: c(surfaceSunk, other.surfaceSunk),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      surfaceInvert: c(surfaceInvert, other.surfaceInvert),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textDisabled: c(textDisabled, other.textDisabled),
      textInvert: c(textInvert, other.textInvert),
      border: c(border, other.border),
      borderDisabled: c(borderDisabled, other.borderDisabled),
      divider: c(divider, other.divider),
      dotPattern: c(dotPattern, other.dotPattern),
      accent: c(accent, other.accent), accentDeep: c(accentDeep, other.accentDeep),
      accentAlt: c(accentAlt, other.accentAlt),
      success: c(success, other.success),
      successDeep: c(successDeep, other.successDeep),
      warning: c(warning, other.warning), danger: c(danger, other.danger),
      focusRing: c(focusRing, other.focusRing),
      gameStroop: c(gameStroop, other.gameStroop),
      gameStroopDeep: c(gameStroopDeep, other.gameStroopDeep),
      gameSchulte: c(gameSchulte, other.gameSchulte),
      gameSchulteDeep: c(gameSchulteDeep, other.gameSchulteDeep),
      playRed: c(playRed, other.playRed), playBlue: c(playBlue, other.playBlue),
      playGreen: c(playGreen, other.playGreen),
      playYellow: c(playYellow, other.playYellow),
      playPurple: c(playPurple, other.playPurple),
      playOrange: c(playOrange, other.playOrange),
      cbBlue: c(cbBlue, other.cbBlue), cbYellow: c(cbYellow, other.cbYellow),
      cbOrange: c(cbOrange, other.cbOrange), cbPink: c(cbPink, other.cbPink),
    );
  }

  /// The one instance. `danger` and `accentAlt` deliberately read the PRIMITIVE
  /// `_P.playRed` / `_P.grape` rather than the `playRed` / `playPurple` slots:
  /// the colour-blind setting re-points answers, and a destructive-confirm
  /// button or the Daily Mix header must not move when a player flips it.
  ///
  /// Keep ONE `slot: _P.primitive,` per line. check_palette_contrast.sh reads
  /// this block to resolve slot names down to hexes, and it matches line by
  /// line — two slots on one line makes the second invisible to the gate.
  static const SunburstColors sunburstPop = SunburstColors(
    surface: _P.cream,
    surfaceSunk: _P.creamSunk,
    surfaceRaised: _P.paper,
    surfaceInvert: _P.ink,
    textPrimary: _P.ink,
    textSecondary: _P.inkSoft,
    textDisabled: _P.inkMuted,
    textInvert: _P.cream,
    border: _P.ink,
    // DERIVED: system.html §11 says a disabled surface drops its border to
    // "ink-3" and its shadow to "soft-ink". ink-3 is inkMuted; "soft-ink" has
    // no token, so the disabled shadow reuses this same slot.
    borderDisabled: _P.inkMuted,
    divider: _P.creamEdge,
    dotPattern: _P.dot,
    accent: _P.sunshine,
    accentDeep: _P.sunshineDeep,
    accentAlt: _P.grape,
    success: _P.leaf,
    successDeep: _P.leafDeep,
    warning: _P.tangerine,
    danger: _P.playRed,
    focusRing: _P.grapePop,
    gameStroop: _P.coral,
    gameStroopDeep: _P.coralDeep,
    gameSchulte: _P.turquoise,
    gameSchulteDeep: _P.turquoiseDeep,
    playRed: _P.playRed,
    playBlue: _P.playBlue,
    playGreen: _P.playGreen,
    playYellow: _P.playYellow,
    playPurple: _P.playPurple,
    playOrange: _P.playOrange,
    cbBlue: _P.playBlue,
    cbYellow: _P.playYellow,
    cbOrange: _P.playOrange,
    cbPink: _P.playPink,
  );
}

// ---------------------------------------------------------------------------
// Shape
// ---------------------------------------------------------------------------

/// Border width, radius scale, hard-offset elevation, press physics, focus ring.
/// `blurRadius` is absent by construction: `shadow()` is the only constructor of
/// a BoxShadow in the app and it hardcodes 0.
@immutable
class SunburstShape extends ThemeExtension<SunburstShape> {
  const SunburstShape({
    required this.borderWidth,
    required this.radiusSm, required this.radiusMd, required this.radiusLg,
    required this.radiusXl, required this.radiusPill,
    required this.e1, required this.e2, required this.e3, required this.e4,
    required this.pressScale, required this.pressScaleSmall,
    required this.focusGap, required this.focusWidth,
    required this.stripePitch, required this.stripeAngle,
  });

  final double borderWidth;
  final Radius radiusSm, radiusMd, radiusLg, radiusXl, radiusPill;

  /// Hard-offset elevation. The absence of a shadow is `const <BoxShadow>[]`;
  /// in Dart it is named `PopElevation.flat` (`sunburst-components`), which is
  /// the same thing system.html calls `--sh-0`. There is no `e0` field.
  final Offset e1, e2, e3, e4;

  /// Two press scales, both transcribed: `.btn/.ans/.gcard:active` shrink to
  /// 0.98, `.tile/.tgl/.tab/.seg-i:active` to 0.97. The e1 family is small
  /// enough that 0.98 is imperceptible, so the smaller surfaces shrink harder.
  /// `PopElevation.pressScale(shape)` is the only thing that picks between them.
  final double pressScale, pressScaleSmall;

  final double focusGap, focusWidth, stripePitch, stripeAngle;

  /// Spacing is layout rhythm, not a themeable value — it is identical in every
  /// conceivable variant and interpolating a gutter mid-animation is meaningless,
  /// so it is static rather than an instance field.
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 28;
  static const double space7 = 40;

  /// The three constants app.html holds fixed on all eight screens.
  static const double gutter = space5; // 20 — screen gutter, no exceptions
  static const double cardGap = space4; // 16 — gap between stacked cards
  static const double cardPadding = space4; // 16 — card inner padding

  /// The only BoxShadow factory in MindForge. Blur and spread are 0, always:
  /// light comes from the top-left and the shadow is the same ink as the border,
  /// so a surface reads as die-cut card stock rather than as a floating panel.
  List<BoxShadow> shadow(Offset elevation, Color ink) => <BoxShadow>[
    BoxShadow(color: ink, offset: elevation, blurRadius: 0, spreadRadius: 0),
  ];

  /// A pressed surface moves (offset - 1) on both axes and keeps a 1px shadow,
  /// so it reads as pushed INTO the page. e2 moves 4px, e1 moves 2px.
  Offset pressTranslate(Offset elevation) =>
      Offset(elevation.dx - 1, elevation.dy - 1);
  static const Offset pressedShadow = Offset(1, 1);

  static SunburstShape of(BuildContext context) {
    final ext = Theme.of(context).extension<SunburstShape>();
    assert(ext != null, 'SunburstShape missing. Build via buildSunburstTheme().');
    return ext!;
  }

  @override
  SunburstShape copyWith({
    double? borderWidth,
    Radius? radiusSm, Radius? radiusMd, Radius? radiusLg, Radius? radiusXl,
    Radius? radiusPill,
    Offset? e1, Offset? e2, Offset? e3, Offset? e4,
    double? pressScale, double? pressScaleSmall,
    double? focusGap, double? focusWidth,
    double? stripePitch, double? stripeAngle,
  }) => SunburstShape(
    borderWidth: borderWidth ?? this.borderWidth,
    radiusSm: radiusSm ?? this.radiusSm, radiusMd: radiusMd ?? this.radiusMd,
    radiusLg: radiusLg ?? this.radiusLg, radiusXl: radiusXl ?? this.radiusXl,
    radiusPill: radiusPill ?? this.radiusPill,
    e1: e1 ?? this.e1, e2: e2 ?? this.e2, e3: e3 ?? this.e3, e4: e4 ?? this.e4,
    pressScale: pressScale ?? this.pressScale,
    pressScaleSmall: pressScaleSmall ?? this.pressScaleSmall,
    focusGap: focusGap ?? this.focusGap, focusWidth: focusWidth ?? this.focusWidth,
    stripePitch: stripePitch ?? this.stripePitch,
    stripeAngle: stripeAngle ?? this.stripeAngle,
  );

  @override
  SunburstShape lerp(covariant SunburstShape? other, double t) {
    if (other == null) return this;
    double d(double a, double b) => lerpDouble(a, b, t)!;
    Radius r(Radius a, Radius b) => Radius.lerp(a, b, t)!;
    Offset o(Offset a, Offset b) => Offset.lerp(a, b, t)!;
    return SunburstShape(
      borderWidth: d(borderWidth, other.borderWidth),
      radiusSm: r(radiusSm, other.radiusSm), radiusMd: r(radiusMd, other.radiusMd),
      radiusLg: r(radiusLg, other.radiusLg), radiusXl: r(radiusXl, other.radiusXl),
      radiusPill: r(radiusPill, other.radiusPill),
      e1: o(e1, other.e1), e2: o(e2, other.e2),
      e3: o(e3, other.e3), e4: o(e4, other.e4),
      pressScale: d(pressScale, other.pressScale),
      pressScaleSmall: d(pressScaleSmall, other.pressScaleSmall),
      focusGap: d(focusGap, other.focusGap),
      focusWidth: d(focusWidth, other.focusWidth),
      stripePitch: d(stripePitch, other.stripePitch),
      stripeAngle: d(stripeAngle, other.stripeAngle),
    );
  }

  static const SunburstShape sunburstPop = SunburstShape(
    borderWidth: 3,
    radiusSm: Radius.circular(10), radiusMd: Radius.circular(16),
    radiusLg: Radius.circular(22), radiusXl: Radius.circular(28),
    radiusPill: Radius.circular(999),
    e1: Offset(3, 3), e2: Offset(5, 5), e3: Offset(8, 8), e4: Offset(10, 10),
    pressScale: 0.98, pressScaleSmall: 0.97,
    focusGap: 3, focusWidth: 4,
    stripePitch: 9, stripeAngle: 45,
  );
}

// ---------------------------------------------------------------------------
// Motion
// ---------------------------------------------------------------------------

/// Four durations and three curves. Nothing in Sunburst Pop runs past 240ms.
/// `sunburst-motion-and-haptics` owns which moment spends which token; this
/// class owns the numbers.
@immutable
class SunburstMotion extends ThemeExtension<SunburstMotion> {
  const SunburstMotion({
    required this.durTap,
    required this.durState,
    required this.durMove,
    required this.durCelebrate,
    required this.easePop,
    required this.easeOut,
    required this.easeInOut,
  });

  /// Press down / release.
  final Duration durTap;

  /// Toggles, selection, HUD value swaps — every colour transition.
  final Duration durState;

  /// Sheets and page transitions.
  final Duration durMove;

  /// Personal-best badge, streak bump. The ceiling: nothing may exceed it.
  final Duration durCelebrate;

  /// Overshooting spring. Legal on transform and scale ONLY — it returns values
  /// above 1.0, and a colour or opacity tween driven past its endpoint is not a
  /// meaningful value.
  final Curve easePop;

  final Curve easeOut, easeInOut;

  /// The single place a widget asks "should I animate?". Reduced motion means
  /// stop, not "gentler": the pressed colour and shadow still apply instantly,
  /// so the acknowledgement survives with zero duration.
  Duration resolve(BuildContext context, Duration full) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : full;

  static SunburstMotion of(BuildContext context) {
    final ext = Theme.of(context).extension<SunburstMotion>();
    assert(ext != null, 'SunburstMotion missing. Build via buildSunburstTheme().');
    return ext!;
  }

  @override
  SunburstMotion copyWith({
    Duration? durTap, Duration? durState, Duration? durMove,
    Duration? durCelebrate,
    Curve? easePop, Curve? easeOut, Curve? easeInOut,
  }) => SunburstMotion(
    durTap: durTap ?? this.durTap,
    durState: durState ?? this.durState,
    durMove: durMove ?? this.durMove,
    durCelebrate: durCelebrate ?? this.durCelebrate,
    easePop: easePop ?? this.easePop,
    easeOut: easeOut ?? this.easeOut,
    easeInOut: easeInOut ?? this.easeInOut,
  );

  /// Deliberate step, not an unfinished implementation. Durations and curves
  /// are not meaningfully interpolable mid-transition, and MindForge has exactly
  /// one theme, so this snaps at the midpoint and lands on the correct endpoint
  /// at both ends. Do not "fix" this into a per-field interpolation.
  @override
  SunburstMotion lerp(covariant SunburstMotion? other, double t) =>
      t < 0.5 ? this : (other ?? this);

  static const SunburstMotion sunburstPop = SunburstMotion(
    durTap: Duration(milliseconds: 120),
    durState: Duration(milliseconds: 160),
    durMove: Duration(milliseconds: 180),
    durCelebrate: Duration(milliseconds: 240),
    easePop: Cubic(0.2, 1.5, 0.4, 1),
    easeOut: Cubic(0.2, 0.8, 0.2, 1),
    easeInOut: Cubic(0.6, 0, 0.3, 1),
  );
}

// ---------------------------------------------------------------------------
// Type
// ---------------------------------------------------------------------------

/// Ten steps. There is no eleventh: a size that is not on this list is a design
/// decision that has not been made yet.
///
/// Weights follow system.html §04 (the rendered specimen), which disagrees with
/// the transcription in §12 on `title` and `button`. §04 wins: it is what the
/// mockups actually show. Fredoka 600 + 700 and Nunito 700 + 800 are the four
/// faces bundled; the 400/500 web weights in the reference page's Google Fonts
/// URL are for that page only and are not shipped.
@immutable
class SunburstType extends ThemeExtension<SunburstType> {
  const SunburstType({
    required this.scoreHero, required this.displayXl, required this.displayL,
    required this.title, required this.numericHud, required this.button,
    required this.body, required this.caption, required this.label,
    required this.stimulus,
  });

  static const String display = 'Fredoka';
  static const String bodyFace = 'Nunito';

  /// DERIVED: system.html names "Baloo 2" as the display fallback, but MindForge
  /// is offline and ships no third face — so the display cascade falls back to
  /// the bundled body face, which is the closest round sans on the device.
  static const List<String> displayFallback = <String>[bodyFace];

  final TextStyle scoreHero, displayXl, displayL, title, numericHud;
  final TextStyle button, body, caption, label, stimulus;

  static SunburstType of(BuildContext context) {
    final ext = Theme.of(context).extension<SunburstType>();
    assert(ext != null, 'SunburstType missing. Build via buildSunburstTheme().');
    return ext!;
  }

  @override
  SunburstType copyWith({
    TextStyle? scoreHero, TextStyle? displayXl, TextStyle? displayL,
    TextStyle? title, TextStyle? numericHud, TextStyle? button,
    TextStyle? body, TextStyle? caption, TextStyle? label, TextStyle? stimulus,
  }) => SunburstType(
    scoreHero: scoreHero ?? this.scoreHero, displayXl: displayXl ?? this.displayXl,
    displayL: displayL ?? this.displayL, title: title ?? this.title,
    numericHud: numericHud ?? this.numericHud, button: button ?? this.button,
    body: body ?? this.body, caption: caption ?? this.caption,
    label: label ?? this.label, stimulus: stimulus ?? this.stimulus,
  );

  @override
  SunburstType lerp(covariant SunburstType? other, double t) {
    if (other == null) return this;
    TextStyle s(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return SunburstType(
      scoreHero: s(scoreHero, other.scoreHero),
      displayXl: s(displayXl, other.displayXl),
      displayL: s(displayL, other.displayL), title: s(title, other.title),
      numericHud: s(numericHud, other.numericHud), button: s(button, other.button),
      body: s(body, other.body), caption: s(caption, other.caption),
      label: s(label, other.label), stimulus: s(stimulus, other.stimulus),
    );
  }

  static const List<FontFeature> _tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static const SunburstType sunburstPop = SunburstType(
    // 76/72, -4% tracking. Results score only, one per screen.
    scoreHero: TextStyle(
      fontFamily: display, fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w700, fontSize: 76, height: 0.95,
      letterSpacing: -3.04, fontFeatures: _tabular,
    ),
    displayXl: TextStyle(
      fontFamily: display, fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w700, fontSize: 42, height: 1, letterSpacing: -1.26,
    ),
    displayL: TextStyle(
      fontFamily: display, fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w700, fontSize: 33, height: 1.02, letterSpacing: -0.83,
    ),
    title: TextStyle(
      fontFamily: display, fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w600, fontSize: 21, height: 1.1, letterSpacing: -0.32,
    ),
    // Tabular is mandatory: an HUD value that reflows mid-run reads as a glitch.
    numericHud: TextStyle(
      fontFamily: display, fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w700, fontSize: 22, height: 1.18,
      letterSpacing: -0.44, fontFeatures: _tabular,
    ),
    button: TextStyle(
      fontFamily: display, fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w600, fontSize: 18, height: 1.22,
    ),
    body: TextStyle(
      fontFamily: bodyFace, fontWeight: FontWeight.w700, fontSize: 15, height: 1.4,
    ),
    caption: TextStyle(
      fontFamily: bodyFace, fontWeight: FontWeight.w700, fontSize: 13, height: 1.38,
    ),
    // The only place caps are allowed. Fredoka blurs below ~12px, so this step
    // buys legibility back with +14% tracking.
    label: TextStyle(
      fontFamily: display, fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w600, fontSize: 10, height: 1.4, letterSpacing: 1.4,
    ),
    // Stroop stimulus. MUST be painted as three passes: an ink stroke, the
    // answer hue, then the PlayFill pattern clipped to the glyph. A bare fill
    // is 1.76:1 on cream. See sunburst-game-surfaces.
    stimulus: TextStyle(
      fontFamily: display, fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w700, fontSize: 78, height: 1, letterSpacing: 0.78,
    ),
  );
}

// ---------------------------------------------------------------------------
// ThemeData
// ---------------------------------------------------------------------------

/// Hand-authored ColorScheme. Never `ColorScheme.fromSeed`: a seed would derive
/// ~40 roles from one hue, and every one of them would be a colour nobody in
/// this system measured. M3 role names are kept so Material's own widgets
/// (TextField, SnackBar, Dialog) theme themselves without per-widget patching.
ColorScheme _sunburstColorScheme(SunburstColors c) => ColorScheme(
  brightness: Brightness.light,
  primary: c.accent, onPrimary: c.textPrimary,
  secondary: c.accentAlt, onSecondary: c.textInvert,
  tertiary: c.success, onTertiary: c.textPrimary,
  error: c.danger, onError: c.surfaceRaised,
  surface: c.surface, onSurface: c.textPrimary,
  surfaceContainerLowest: c.surfaceRaised,
  surfaceContainerLow: c.surfaceRaised,
  surfaceContainer: c.surfaceSunk,
  surfaceContainerHigh: c.surfaceSunk,
  surfaceContainerHighest: c.surfaceSunk,
  onSurfaceVariant: c.textSecondary,
  outline: c.border, outlineVariant: c.border,
  inverseSurface: c.surfaceInvert, onInverseSurface: c.textInvert,
  shadow: c.border, scrim: c.border,
  // M3's elevation tint would wash a tint over cream and paper. This system
  // expresses elevation as an ink rectangle, so the tint must be nothing.
  surfaceTint: Colors.transparent,
);

/// The composition root builds this once and hands it to MaterialApp. There is
/// no `darkTheme:` and no `themeMode:` — see the light-only section of SKILL.md.
ThemeData buildSunburstTheme() {
  const colors = SunburstColors.sunburstPop;
  const shape = SunburstShape.sunburstPop;
  const type = SunburstType.sunburstPop;
  const motion = SunburstMotion.sunburstPop;
  final scheme = _sunburstColorScheme(colors);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.surface,
    extensions: const <ThemeExtension<dynamic>>[colors, shape, type, motion],

    // The press in Sunburst Pop is a translate, not a ripple. A Material ink
    // splash would spread a soft radial under a hard-edged die-cut object.
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,

    textTheme: TextTheme(
      displayLarge: type.scoreHero,
      displayMedium: type.displayXl,
      headlineLarge: type.displayL,
      titleLarge: type.title,
      titleMedium: type.numericHud,
      labelLarge: type.button,
      bodyLarge: type.body,
      bodyMedium: type.caption,
      labelSmall: type.label,
    ).apply(bodyColor: colors.textPrimary, displayColor: colors.textPrimary),

    // Row dividers are ink at the structural border width. `colors.divider`
    // (creamEdge) is 1.3:1 on paper and is the toggle-track inset ONLY.
    dividerTheme: DividerThemeData(
      color: colors.border,
      thickness: shape.borderWidth,
      space: shape.borderWidth,
    ),

    // Material draws its own soft elevation shadow; every Sunburst surface
    // draws a hard one itself, so Material's is switched off everywhere.
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      foregroundColor: colors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: type.title.copyWith(color: colors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: colors.surfaceRaised,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(shape.radiusLg),
        side: BorderSide(color: colors.border, width: shape.borderWidth),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: shape.radiusXl),
        side: BorderSide(color: colors.border, width: shape.borderWidth),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(shape.radiusXl),
        side: BorderSide(color: colors.border, width: shape.borderWidth),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.surfaceInvert,
      contentTextStyle: type.body.copyWith(color: colors.textInvert),
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(shape.radiusMd),
        side: BorderSide(color: colors.border, width: shape.borderWidth),
      ),
    ),
    // MindForge's buttons, tiles, pills and toggles are custom widgets owned by
    // `sunburst-components`; Material's button themes are deliberately left at
    // their defaults so nobody is tempted to reach for an ElevatedButton.
  );
}
