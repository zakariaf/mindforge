import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Border width, the radius scale, hard-offset elevation, press physics, the
/// focus ring, and the spacing rhythm.
///
/// `blurRadius` is absent by construction: [shadow] is the only constructor of
/// a `BoxShadow` in the app and it hardcodes zero.
@immutable
class SunburstShape extends ThemeExtension<SunburstShape> {
  /// Creates a shape scale.
  const SunburstShape({
    required this.borderWidth,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.radiusPill,
    required this.e1,
    required this.e2,
    required this.e3,
    required this.e4,
    required this.pressScale,
    required this.pressScaleSmall,
    required this.badgeTiltDegrees,
    required this.wordmarkTile,
    required this.wordmarkTileRadius,
    required this.wordmarkDot,
    required this.wordmarkDotRadius,
    required this.shakeAmplitude,
    required this.celebrationScaleFrom,
    required this.celebrationScalePeak,
    required this.focusGap,
    required this.focusWidth,
    required this.stripePitch,
    required this.stripeAngle,
    required this.eChip,
    required this.chartBarRadiusTop,
    required this.chartBarRadiusBottom,
    required this.settingsChipRadius,
    required this.paletteSwatchRadius,
    required this.miniTileGapValue,
    required this.miniTileRadius,
    required this.miniTileBorderWidth,
    required this.heroSwatchSize,
    required this.heroSwatchRadius,
    required this.heroSwatchShadow,
    required this.countdownRing,
    required this.countdownDot,
    required this.countdownReadyShadow,
    required this.gameArtFrame,
    required this.lockedChip,
    required this.cardChipRadius,
    required this.dotPitch,
    required this.dotRadius,
    required this.ringPitch,
    required this.ringBandWidth,
    required this.glyphStrokeWidth,
    required this.answerKeyHeight,
    required this.answerKeyPanelWidth,
    required this.answerStrikeHeight,
    required this.borderWidthNested,
    required this.dashOn,
    required this.dashOff,
    required this.glyphStrokeNav,
    required this.glyphStrokeControl,
  });

  /// The ink border on every raised surface. Three logical pixels, everywhere.
  final double borderWidth;

  /// The smallest corner: chips, tiles, small keys.
  final Radius radiusSm;

  /// The default corner: buttons, list rows.
  final Radius radiusMd;

  /// Cards.
  final Radius radiusLg;

  /// Sheets and the largest surfaces.
  final Radius radiusXl;

  /// A fully rounded end, for pills and toggles.
  final Radius radiusPill;

  /// The lowest hard-offset elevation.
  ///
  /// The **absence** of a shadow is `const <BoxShadow>[]` — what `system.html`
  /// calls `--sh-0`. There is deliberately no `e0` field: a zero-offset shadow
  /// still paints, and a surface that should be flat must draw nothing.
  final Offset e1;

  /// The second elevation step.
  final Offset e2;

  /// The third elevation step.
  final Offset e3;

  /// The highest elevation step.
  final Offset e4;

  /// How far a large pressable shrinks: buttons, answer keys, game cards.
  final double pressScale;

  /// How far a small pressable shrinks: tiles, toggles, tabs, segments.
  ///
  /// Two scales, both transcribed. The e1 family is small enough that the
  /// larger scale is imperceptible on it, so the smaller surfaces shrink harder.
  final double pressScaleSmall;

  /// The angle a "new best" badge sits at, in degrees.
  ///
  /// `system.html` §09: `.badge.new{transform:rotate(-2.5deg)}`. A RESTING
  /// TRANSFORM, not motion — it survives reduce motion, because a badge that
  /// sat straight for a player with animation off would be a different badge.
  ///
  /// Negative, and it stays negative in every locale. The tilt is a shape
  /// constant of the badge, the same class of decision as the hard offset
  /// shadow: mirroring it would tilt the Persian badge the other way for no
  /// reason a reader could name.
  final double badgeTiltDegrees;

  /// The wordmark tile's side. `app.html`: `.wordmark i{width:26px;height:26px}`.
  final double wordmarkTile;

  /// Its corner. `app.html`: `border-radius:9px`.
  final Radius wordmarkTileRadius;

  /// The cream square inside it. `app.html`: `.wordmark i b{width:8px}`.
  final double wordmarkDot;

  /// That square's corner. `app.html`: `border-radius:2px`.
  final Radius wordmarkDotRadius;

  /// How far the wrong-answer shake travels to each side.
  ///
  /// `system.html`: `@keyframes shake{0%,100%{translateX(0)}
  /// 25%{translateX(-4px)}75%{translateX(4px)}}`.
  ///
  /// A DISTANCE, so it lives here beside `e1`..`e4` and `focusGap` rather than
  /// on `SunburstMotion`, which is four durations and three curves — a *when*,
  /// not a *how far*. It sat there briefly, and the field-list test had to
  /// carry a sentence calling it "the one non-timing member", which is a test
  /// pinning an anomaly instead of resolving it.
  final double shakeAmplitude;

  /// Where the celebration pop starts.
  ///
  /// `system.html` section 10: scale 0.86 -> 1.06 -> 1.0. A magnitude, by the
  /// same rule as [shakeAmplitude] and [pressScale] — and a token rather than a
  /// literal in `lib/shared/motion/`, where working agreement 2 does not allow
  /// one.
  final double celebrationScaleFrom;

  /// The nominal top of the celebration pop.
  ///
  /// Nominal because the moment's curve is chained onto each segment and
  /// overshoots inside it: the measured peak is 1.0753.
  final double celebrationScalePeak;

  /// The gap between a surface's edge and its focus ring.
  final double focusGap;

  /// The focus ring's stroke width.
  final double focusWidth;

  /// The distance between stripe centres in a striped fill.
  final double stripePitch;

  /// The stripe angle, in degrees.
  final double stripeAngle;

  /// The half-step below [e1].
  ///
  /// DERIVED only in the sense that `system.html` has no `--sh-chip` custom
  /// property; the VALUE is transcribed, from
  /// `.seg-i.on{box-shadow:2px 2px 0 var(--ink)}` in section 07. That selected
  /// segment is the one surface in the stylesheet drawn at 2px, and it pairs
  /// the offset with a `translate(-1px,-1px)` lift — the `difficultySelect`
  /// moment.
  ///
  /// The doc here used to say the badges in section 09 were drawn at 2px. They
  /// are not: `.badge` carries `--sh-1` and `.badge.new` carries `--sh-2`. The
  /// badges were built against that sentence, so all three variants shipped a
  /// step too low, and the segment that does want 2px was built at 3px.
  final Offset eChip;

  /// A chart bar's top corners. `app.html`: `.bar i{border-radius:8px 8px ...}`.
  ///
  /// Its own pair rather than the radius scale: 8 and 3 are BELOW `radiusSm`,
  /// and they are not a smaller version of a card corner — they are the shape
  /// of a bar standing on an axis, rounded where it ends and square where it
  /// meets the line.
  final Radius chartBarRadiusTop;

  /// A chart bar's bottom corners, where it sits on the axis.
  final Radius chartBarRadiusBottom;

  /// The icon chip on a settings row.
  ///
  /// `app.html`: `.srow .si{border-radius:11px}`. Eleven, not [radiusSm]'s ten.
  /// A point either way is invisible in isolation and obvious in a column of
  /// six chips beside a 22pt card corner, which is why the design states it
  /// separately.
  final Radius settingsChipRadius;

  /// A palette swatch. `app.html`: `.cbprev i{border-radius:5px}`.
  final Radius paletteSwatchRadius;

  /// The gap between cells of a Home-card mini grid.
  ///
  /// `app.html`: `.gart .mini{gap:3px}`. Exposed as a value AND as the const
  /// [miniTileGap] because a `Row` needs it in a `const SizedBox`, where a
  /// theme lookup cannot go.
  final double miniTileGapValue;

  /// One mini cell's corner. `app.html`: `.gart .mini i{border-radius:3px}`.
  final Radius miniTileRadius;

  /// A mini cell's edge. `app.html`: `.gart .mini i{border:1.5px}` — thinner
  /// than every other border in the app, because at 18pt the standard 3pt edge
  /// leaves almost no fill to see.
  final double miniTileBorderWidth;

  /// One hero swatch chip. `app.html`: `.swatchrow i{width:38px;height:38px}`.
  ///
  /// The four chips under a game's tagline on its detail screen: the game's
  /// answer colours, each carrying its ink FILL PATTERN. They are the legend
  /// for the second channel, met before the first round rather than during it.
  final double heroSwatchSize;

  /// A hero swatch's corner. `app.html`: `.swatchrow i{border-radius:12px}`.
  final Radius heroSwatchRadius;

  /// A hero swatch's hard offset. `app.html`: `.swatchrow i{box-shadow:2px 2px
  /// 0 var(--ink)}` — smaller than [e1], because a 38pt chip carrying the full
  /// 3px edge takes e1 as a slab rather than a lift.
  final Offset heroSwatchShadow;

  /// The countdown ring's diameter. `app.html`: `.bigring{width:238px}`.
  final double countdownRing;

  /// One beat dot. `app.html`: `.count .dotsrow i{width:14px;height:14px}`.
  final double countdownDot;

  /// The hard ink shadow behind "Get ready".
  ///
  /// `app.html`: `.count .ready{text-shadow:4px 4px 0 var(--ink)}`. Four, not
  /// the five the results score casts — a bigger word on a smaller type step
  /// takes a shorter throw. **It does not mirror**, by the same light-source
  /// rule as every box shadow in the app.
  final Offset countdownReadyShadow;

  /// The cream frame a game's preview is drawn inside, on a home card.
  ///
  /// `app.html`: `.gart{width:64px;height:64px}`. **The frame is the CARD's,
  /// not the game's** — a definition contributes what goes inside it, and the
  /// shell decides how it is mounted, which is why the size lives here.
  final double gameArtFrame;

  /// The padlock chip on a locked slot. `app.html`: `.locked .lk{width:44px}`.
  final double lockedChip;

  /// The corner on a chip drawn INSIDE a card.
  ///
  /// Fourteen. `app.html` uses it twice — `.bestcard .bv{border-radius:14px}`
  /// and `.locked .lk{border-radius:14px}` — and it sits between [radiusSm]'s
  /// ten and [radiusMd]'s sixteen, so neither is a rounding away.
  final Radius cardChipRadius;

  /// The spacing of a dotted `PlayFill` lattice. `system.html` §03:
  /// `radial-gradient(var(--ink) 2.6px, var(--play) 2.7px)` at `background-size:10px 10px`.
  ///
  /// **DERIVED** from `system.html` §03, which states the pattern in CSS and
  /// not as tokens.
  final double dotPitch;

  /// The radius of one dot in a dotted `PlayFill`.
  ///
  /// **DERIVED** from `system.html` §03, which states the pattern in CSS and
  /// not as tokens.
  final double dotRadius;

  /// The distance between ring centres in a ringed `PlayFill`.
  /// `system.html` §03: `repeating-radial-gradient(... 0 4px, var(--ink) 4px 7px)`.
  ///
  /// **DERIVED** from `system.html` §03, which states the pattern in CSS and
  /// not as tokens.
  final double ringPitch;

  /// The painted width of one ink ring — the `4px 7px` band above.
  ///
  /// **DERIVED** from `system.html` §03, which states the pattern in CSS and
  /// not as tokens.
  final double ringBandWidth;

  /// The ink outline grown around the stimulus glyph.
  ///
  /// **DERIVED**, and the reason the stimulus is never a bare `Text`: the
  /// outline is what makes a yellow word read at ink-on-cream contrast instead
  /// of yellow-on-white. `system.html` §12 draws it as a stack of text shadows,
  /// which is a CSS technique for a stroke this paints directly.
  final double glyphStrokeWidth;

  /// One answer key's height. `app.html`: `.ans{height:92px}`.
  ///
  /// **DERIVED** from `app.html`'s answer-key rules.
  final double answerKeyHeight;

  /// The ink-bordered pattern panel inside a key.
  /// `app.html`: `.ans .key{width:56px}` — the second channel, at a size that
  /// reads at arm's length.
  ///
  /// **DERIVED** from `app.html`'s answer-key rules.
  final double answerKeyPanelWidth;

  /// The ink strike bar a rejected key wears.
  ///
  /// The NON-MOTION RESIDUE of a wrong answer: it survives reduce motion, when
  /// the shake does not, so the wrong key still says so to a player who has
  /// animation off.
  ///
  /// **DERIVED** from `app.html`'s answer-key rules.
  final double answerStrikeHeight;

  /// The ink edge on a surface drawn **inside** another surface.
  ///
  /// DERIVED: two logical pixels, not three. A segment inside its track and a
  /// knob inside its rail put two borders within a few pixels of each other,
  /// and at the full [borderWidth] the pair reads as one thick smudge rather
  /// than as two edges. `system.html` §06 and §09 draw these nested edges at
  /// 2px throughout.
  final double borderWidthNested;

  /// The painted length of one dash in a dashed ink edge.
  ///
  /// DERIVED: `system.html` §04's "coming soon" card is drawn with
  /// `stroke-dasharray: 9 7`. Neither number is a `:root` custom property.
  final double dashOn;

  /// The gap between dashes in a dashed ink edge.
  final double dashOff;

  /// The stroke width of a glyph drawn at nav size, 22pt and up.
  ///
  /// Transcribed from `system.html` §08, where every nav and status glyph is
  /// `stroke-width="2.6"` — 40 sites across `app.html`.
  final double glyphStrokeNav;

  /// The stroke width of a glyph drawn below nav size.
  ///
  /// Transcribed from `system.html` §08: `stroke-width="3"`, 14 sites across
  /// `app.html`. The **smaller** glyph takes the **heavier** stroke, because a
  /// thin line at 16pt disappears against a saturated fill. That is why the
  /// resolver's rule is `< 22 -> 3.0` rather than `18-20 -> 3.0`: the 16px
  /// disclosure chevron in the settings rows is drawn at 3.0 too.
  final double glyphStrokeControl;

  /// 4 — the smallest step.
  ///
  /// Spacing is layout **rhythm**, not a themeable value: it is identical in
  /// every conceivable variant, and interpolating a gutter mid-animation is
  /// meaningless. So it is static rather than an instance field, and does not
  /// appear in [copyWith], [lerp] or equality.
  static const double space1 = 4;

  /// 8.
  static const double space2 = 8;

  /// 12.
  static const double space3 = 12;

  /// The mini grid's gap, as a compile-time constant.
  ///
  /// `app.html`: `.gart .mini{gap:3px}`. The same number as
  /// [miniTileGapValue], which is the themed slot; this one exists because a
  /// `const SizedBox` cannot read a theme.
  static const double miniTileGap = 3;

  /// 16.
  static const double space4 = 16;

  /// 20.
  static const double space5 = 20;

  /// 28.
  static const double space6 = 28;

  /// 40 — the largest step.
  static const double space7 = 40;

  /// The screen gutter, on all eight screens, with no exceptions.
  static const double gutter = space5;

  /// The gap between stacked cards.
  static const double cardGap = space4;

  /// A card's inner padding.
  static const double cardPadding = space4;

  /// The **only** `BoxShadow` factory in MindForge.
  ///
  /// Blur and spread are zero, always: the light comes from one fixed direction
  /// and the shadow is the same ink as the border, so a surface reads as
  /// die-cut card stock rather than as a floating panel.
  ///
  /// The offset **does not mirror in RTL**. It is a light-source constant — one
  /// imaginary light for the whole app — not a reading-direction property. A
  /// Persian build lit from the other side would disagree with every reference
  /// screenshot, and `test/policy/directional_geometry_test.dart` pins it.
  List<BoxShadow> shadow(Offset elevation, Color ink) => <BoxShadow>[
    // The two zeros are written out even though they are BoxShadow's defaults.
    // avoid_redundant_argument_values wants them gone; making them implicit
    // would hide the single most load-bearing invariant in the design system
    // at the one place it is enforced.
    // ignore: avoid_redundant_argument_values
    BoxShadow(color: ink, offset: elevation, blurRadius: 0, spreadRadius: 0),
  ];

  /// The shadow a pressed surface keeps.
  ///
  /// One logical pixel, not none: dropping to zero reads as the surface
  /// vanishing rather than as it being pushed into the page.
  ///
  /// How far a pressed surface *travels* is not here. That is press behaviour
  /// rather than a token, and it lives on `PressGeometry.travel` — one place,
  /// where the hit-area rule that goes with it also lives.
  static const Offset pressedShadow = Offset(1, 1);

  /// The shape scale attached to [context]'s theme.
  ///
  /// Asserts rather than falling back, for the same reason `SunburstColors.of`
  /// does.
  static SunburstShape of(BuildContext context) {
    final extension = Theme.of(context).extension<SunburstShape>();
    assert(
      extension != null,
      'SunburstShape is missing from the theme. Build it with '
      'buildSunburstTheme().',
    );
    return extension!;
  }

  List<Object?> get _props => <Object?>[
    borderWidth,
    radiusSm,
    radiusMd,
    radiusLg,
    radiusXl,
    radiusPill,
    e1,
    e2,
    e3,
    e4,
    pressScale,
    pressScaleSmall,
    badgeTiltDegrees,
    wordmarkTile,
    wordmarkTileRadius,
    wordmarkDot,
    wordmarkDotRadius,
    shakeAmplitude,
    celebrationScaleFrom,
    celebrationScalePeak,
    focusGap,
    focusWidth,
    stripePitch,
    stripeAngle,
    eChip,
    chartBarRadiusTop,
    chartBarRadiusBottom,
    settingsChipRadius,
    paletteSwatchRadius,
    miniTileGapValue,
    miniTileRadius,
    miniTileBorderWidth,
    heroSwatchSize,
    heroSwatchRadius,
    heroSwatchShadow,
    countdownRing,
    countdownDot,
    countdownReadyShadow,
    gameArtFrame,
    lockedChip,
    cardChipRadius,
    dotPitch,
    dotRadius,
    ringPitch,
    ringBandWidth,
    glyphStrokeWidth,
    answerKeyHeight,
    answerKeyPanelWidth,
    answerStrikeHeight,
    borderWidthNested,
    dashOn,
    dashOff,
    glyphStrokeNav,
    glyphStrokeControl,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SunburstShape &&
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
  SunburstShape copyWith({
    double? borderWidth,
    Radius? radiusSm,
    Radius? radiusMd,
    Radius? radiusLg,
    Radius? radiusXl,
    Radius? radiusPill,
    Offset? e1,
    Offset? e2,
    Offset? e3,
    Offset? e4,
    double? pressScale,
    double? pressScaleSmall,
    double? badgeTiltDegrees,
    double? wordmarkTile,
    Radius? wordmarkTileRadius,
    double? wordmarkDot,
    Radius? wordmarkDotRadius,
    double? shakeAmplitude,
    double? celebrationScaleFrom,
    double? celebrationScalePeak,
    double? focusGap,
    double? focusWidth,
    double? stripePitch,
    double? stripeAngle,
    Offset? eChip,
    Radius? chartBarRadiusTop,
    Radius? chartBarRadiusBottom,
    Radius? settingsChipRadius,
    Radius? paletteSwatchRadius,
    double? miniTileGapValue,
    Radius? miniTileRadius,
    double? miniTileBorderWidth,
    double? heroSwatchSize,
    Radius? heroSwatchRadius,
    Offset? heroSwatchShadow,
    double? countdownRing,
    double? countdownDot,
    Offset? countdownReadyShadow,
    double? gameArtFrame,
    double? lockedChip,
    Radius? cardChipRadius,
    double? dotPitch,
    double? dotRadius,
    double? ringPitch,
    double? ringBandWidth,
    double? glyphStrokeWidth,
    double? answerKeyHeight,
    double? answerKeyPanelWidth,
    double? answerStrikeHeight,
    double? borderWidthNested,
    double? dashOn,
    double? dashOff,
    double? glyphStrokeNav,
    double? glyphStrokeControl,
  }) => SunburstShape(
    borderWidth: borderWidth ?? this.borderWidth,
    radiusSm: radiusSm ?? this.radiusSm,
    radiusMd: radiusMd ?? this.radiusMd,
    radiusLg: radiusLg ?? this.radiusLg,
    radiusXl: radiusXl ?? this.radiusXl,
    radiusPill: radiusPill ?? this.radiusPill,
    e1: e1 ?? this.e1,
    e2: e2 ?? this.e2,
    e3: e3 ?? this.e3,
    e4: e4 ?? this.e4,
    pressScale: pressScale ?? this.pressScale,
    pressScaleSmall: pressScaleSmall ?? this.pressScaleSmall,
    badgeTiltDegrees: badgeTiltDegrees ?? this.badgeTiltDegrees,
    wordmarkTile: wordmarkTile ?? this.wordmarkTile,
    wordmarkTileRadius: wordmarkTileRadius ?? this.wordmarkTileRadius,
    wordmarkDot: wordmarkDot ?? this.wordmarkDot,
    wordmarkDotRadius: wordmarkDotRadius ?? this.wordmarkDotRadius,
    shakeAmplitude: shakeAmplitude ?? this.shakeAmplitude,
    celebrationScaleFrom: celebrationScaleFrom ?? this.celebrationScaleFrom,
    celebrationScalePeak: celebrationScalePeak ?? this.celebrationScalePeak,
    focusGap: focusGap ?? this.focusGap,
    focusWidth: focusWidth ?? this.focusWidth,
    stripePitch: stripePitch ?? this.stripePitch,
    stripeAngle: stripeAngle ?? this.stripeAngle,
    eChip: eChip ?? this.eChip,
    chartBarRadiusTop: chartBarRadiusTop ?? this.chartBarRadiusTop,
    chartBarRadiusBottom: chartBarRadiusBottom ?? this.chartBarRadiusBottom,
    settingsChipRadius: settingsChipRadius ?? this.settingsChipRadius,
    paletteSwatchRadius: paletteSwatchRadius ?? this.paletteSwatchRadius,
    miniTileGapValue: miniTileGapValue ?? this.miniTileGapValue,
    miniTileRadius: miniTileRadius ?? this.miniTileRadius,
    miniTileBorderWidth: miniTileBorderWidth ?? this.miniTileBorderWidth,
    heroSwatchSize: heroSwatchSize ?? this.heroSwatchSize,
    heroSwatchRadius: heroSwatchRadius ?? this.heroSwatchRadius,
    heroSwatchShadow: heroSwatchShadow ?? this.heroSwatchShadow,
    countdownRing: countdownRing ?? this.countdownRing,
    countdownDot: countdownDot ?? this.countdownDot,
    countdownReadyShadow: countdownReadyShadow ?? this.countdownReadyShadow,
    gameArtFrame: gameArtFrame ?? this.gameArtFrame,
    lockedChip: lockedChip ?? this.lockedChip,
    cardChipRadius: cardChipRadius ?? this.cardChipRadius,
    dotPitch: dotPitch ?? this.dotPitch,
    dotRadius: dotRadius ?? this.dotRadius,
    ringPitch: ringPitch ?? this.ringPitch,
    ringBandWidth: ringBandWidth ?? this.ringBandWidth,
    glyphStrokeWidth: glyphStrokeWidth ?? this.glyphStrokeWidth,
    answerKeyHeight: answerKeyHeight ?? this.answerKeyHeight,
    answerKeyPanelWidth: answerKeyPanelWidth ?? this.answerKeyPanelWidth,
    answerStrikeHeight: answerStrikeHeight ?? this.answerStrikeHeight,
    borderWidthNested: borderWidthNested ?? this.borderWidthNested,
    dashOn: dashOn ?? this.dashOn,
    dashOff: dashOff ?? this.dashOff,
    glyphStrokeNav: glyphStrokeNav ?? this.glyphStrokeNav,
    glyphStrokeControl: glyphStrokeControl ?? this.glyphStrokeControl,
  );

  @override
  SunburstShape lerp(covariant SunburstShape? other, double t) {
    if (other == null) return this;
    double d(double a, double b) => lerpDouble(a, b, t)!;
    Radius r(Radius a, Radius b) => Radius.lerp(a, b, t)!;
    Offset o(Offset a, Offset b) => Offset.lerp(a, b, t)!;

    return SunburstShape(
      borderWidth: d(borderWidth, other.borderWidth),
      radiusSm: r(radiusSm, other.radiusSm),
      radiusMd: r(radiusMd, other.radiusMd),
      radiusLg: r(radiusLg, other.radiusLg),
      radiusXl: r(radiusXl, other.radiusXl),
      radiusPill: r(radiusPill, other.radiusPill),
      e1: o(e1, other.e1),
      e2: o(e2, other.e2),
      e3: o(e3, other.e3),
      e4: o(e4, other.e4),
      pressScale: d(pressScale, other.pressScale),
      pressScaleSmall: d(pressScaleSmall, other.pressScaleSmall),
      badgeTiltDegrees: d(badgeTiltDegrees, other.badgeTiltDegrees),
      wordmarkTile: d(wordmarkTile, other.wordmarkTile),
      wordmarkTileRadius: r(wordmarkTileRadius, other.wordmarkTileRadius),
      wordmarkDot: d(wordmarkDot, other.wordmarkDot),
      wordmarkDotRadius: r(wordmarkDotRadius, other.wordmarkDotRadius),
      shakeAmplitude: d(shakeAmplitude, other.shakeAmplitude),
      celebrationScaleFrom: d(celebrationScaleFrom, other.celebrationScaleFrom),
      celebrationScalePeak: d(celebrationScalePeak, other.celebrationScalePeak),
      focusGap: d(focusGap, other.focusGap),
      focusWidth: d(focusWidth, other.focusWidth),
      stripePitch: d(stripePitch, other.stripePitch),
      stripeAngle: d(stripeAngle, other.stripeAngle),
      eChip: o(eChip, other.eChip),
      chartBarRadiusTop: r(chartBarRadiusTop, other.chartBarRadiusTop),
      chartBarRadiusBottom: r(
        chartBarRadiusBottom,
        other.chartBarRadiusBottom,
      ),
      settingsChipRadius: r(settingsChipRadius, other.settingsChipRadius),
      paletteSwatchRadius: r(paletteSwatchRadius, other.paletteSwatchRadius),
      miniTileGapValue: d(miniTileGapValue, other.miniTileGapValue),
      miniTileRadius: r(miniTileRadius, other.miniTileRadius),
      miniTileBorderWidth: d(miniTileBorderWidth, other.miniTileBorderWidth),
      heroSwatchSize: d(heroSwatchSize, other.heroSwatchSize),
      heroSwatchRadius: r(heroSwatchRadius, other.heroSwatchRadius),
      heroSwatchShadow: o(heroSwatchShadow, other.heroSwatchShadow),
      countdownRing: d(countdownRing, other.countdownRing),
      countdownDot: d(countdownDot, other.countdownDot),
      countdownReadyShadow: o(
        countdownReadyShadow,
        other.countdownReadyShadow,
      ),
      gameArtFrame: d(gameArtFrame, other.gameArtFrame),
      lockedChip: d(lockedChip, other.lockedChip),
      cardChipRadius: r(cardChipRadius, other.cardChipRadius),
      dotPitch: d(dotPitch, other.dotPitch),
      dotRadius: d(dotRadius, other.dotRadius),
      ringPitch: d(ringPitch, other.ringPitch),
      ringBandWidth: d(ringBandWidth, other.ringBandWidth),
      glyphStrokeWidth: d(glyphStrokeWidth, other.glyphStrokeWidth),
      answerKeyHeight: d(answerKeyHeight, other.answerKeyHeight),
      answerKeyPanelWidth: d(answerKeyPanelWidth, other.answerKeyPanelWidth),
      answerStrikeHeight: d(answerStrikeHeight, other.answerStrikeHeight),
      borderWidthNested: d(borderWidthNested, other.borderWidthNested),
      dashOn: d(dashOn, other.dashOn),
      dashOff: d(dashOff, other.dashOff),
      glyphStrokeNav: d(glyphStrokeNav, other.glyphStrokeNav),
      glyphStrokeControl: d(glyphStrokeControl, other.glyphStrokeControl),
    );
  }

  /// The one shape scale, transcribed from `system.html`.
  static const SunburstShape sunburstPop = SunburstShape(
    borderWidth: 3,
    radiusSm: Radius.circular(10),
    radiusMd: Radius.circular(16),
    radiusLg: Radius.circular(22),
    radiusXl: Radius.circular(28),
    radiusPill: Radius.circular(999),
    e1: Offset(3, 3),
    e2: Offset(5, 5),
    e3: Offset(8, 8),
    e4: Offset(10, 10),
    pressScale: 0.98,
    pressScaleSmall: 0.97,
    badgeTiltDegrees: -2.5,
    wordmarkTile: 26,
    wordmarkTileRadius: Radius.circular(9),
    wordmarkDot: 8,
    wordmarkDotRadius: Radius.circular(2),
    shakeAmplitude: 4,
    celebrationScaleFrom: 0.86,
    celebrationScalePeak: 1.06,
    // DERIVED: system.html §12 draws the focus ring as a 4px grape-pop outline
    // offset 3px from the surface. Neither number is a :root custom property.
    focusGap: 3,
    focusWidth: 4,
    // DERIVED: the striped answer fill in system.html §7 repeats every 9px at
    // 45 degrees. Neither is a :root custom property.
    stripePitch: 9,
    stripeAngle: 45,
    // DERIVED: half of e1. See the field docs for the evidence behind each.
    eChip: Offset(2, 2),
    chartBarRadiusTop: Radius.circular(8),
    chartBarRadiusBottom: Radius.circular(3),
    settingsChipRadius: Radius.circular(11),
    paletteSwatchRadius: Radius.circular(5),
    miniTileGapValue: 3,
    miniTileRadius: Radius.circular(3),
    miniTileBorderWidth: 1.5,
    heroSwatchSize: 38,
    heroSwatchRadius: Radius.circular(12),
    heroSwatchShadow: Offset(2, 2),
    countdownRing: 238,
    countdownDot: 14,
    countdownReadyShadow: Offset(4, 4),
    gameArtFrame: 64,
    lockedChip: 44,
    cardChipRadius: Radius.circular(14),
    dotPitch: 10,
    dotRadius: 2.6,
    ringPitch: 7,
    ringBandWidth: 3,
    glyphStrokeWidth: 6,
    answerKeyHeight: 92,
    answerKeyPanelWidth: 56,
    answerStrikeHeight: 6,
    borderWidthNested: 2,
    // DERIVED: system.html §04, stroke-dasharray: 9 7.
    dashOn: 9,
    dashOff: 7,
    // Transcribed from system.html §08.
    glyphStrokeNav: 2.6,
    glyphStrokeControl: 3,
  );
}
