import 'package:flutter/material.dart';

part 'sunburst_primitives.dart';

/// The non-hue channel every answer colour also carries.
///
/// Hue is never the only signal (`CLAUDE.md` working agreement 4). Under
/// deuteranopia `playRed` and `playGreen` both simulate towards olive, and in
/// greyscale red, blue and green sit within 1.09:1 of each other — but a
/// stripe, a dot and a ring never collapse into one another.
enum PlayFill {
  /// A flat fill. No pattern.
  solid,

  /// Diagonal ink stripes over the fill.
  stripe,

  /// A field of ink dots over the fill.
  dot,

  /// An ink ring inset from the edge.
  ring,
}

/// The four default Stroop answers plus the two Blitz extras, each permanently
/// bound to its [PlayFill].
///
/// A widget asks for [PlayAnswer.red] and gets a colour **and** a pattern; it
/// never receives a bare `Color` it has to remember to decorate.
///
/// Deliberately carries **no display string**. The colour *word* is an ARB key
/// resolved in E04 and rendered by E09; a `String get label` here would
/// hardcode English into the theme layer and make the Stroop stimulus
/// untranslatable.
enum PlayAnswer {
  /// Red, striped.
  red(PlayFill.stripe),

  /// Blue, solid.
  blue(PlayFill.solid),

  /// Green, dotted.
  green(PlayFill.dot),

  /// Yellow, ringed. The one answer light enough to need an ink label.
  yellow(PlayFill.ring),

  /// Purple, solid. Blitz only.
  purple(PlayFill.solid),

  /// Orange, striped. Blitz only.
  orange(PlayFill.stripe);

  const PlayAnswer(this.fill);

  /// The non-hue channel this answer always carries.
  final PlayFill fill;
}

/// Tier 2 — semantic slots. Widgets read these and never `_P`.
@immutable
class SunburstColors extends ThemeExtension<SunburstColors> {
  /// Creates a palette. Every slot is required: a default here would be a
  /// colour nobody reviewed.
  const SunburstColors({
    required this.surface,
    required this.surfaceSunk,
    required this.surfaceRaised,
    required this.surfaceInvert,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.textInvert,
    required this.border,
    required this.borderDisabled,
    required this.divider,
    required this.dotPattern,
    required this.accent,
    required this.accentDeep,
    required this.headerRay,
    required this.headerDots,
    required this.heroDots,
    required this.boardDots,
    required this.headerRayResults,
    required this.headerRaySettings,
    required this.countdownRay,
    required this.countdownDotIdle,
    required this.bandRayStroop,
    required this.bandRaySchulte,
    required this.accentAlt,
    required this.accentWarm,
    required this.accentCool,
    required this.success,
    required this.successDeep,
    required this.warning,
    required this.danger,
    required this.focusRing,
    required this.gameStroop,
    required this.gameStroopDeep,
    required this.gameSchulte,
    required this.gameSchulteDeep,
    required this.playRed,
    required this.playBlue,
    required this.playGreen,
    required this.playYellow,
    required this.playPurple,
    required this.playOrange,
    required this.cbBlue,
    required this.cbYellow,
    required this.cbOrange,
    required this.cbPink,
  });

  /// The screen background everything sits on.
  final Color surface;

  /// An inset well — a field that reads as pressed into the page.
  final Color surfaceSunk;

  /// A raised surface: a card, a sheet, a key.
  final Color surfaceRaised;

  /// An inverted sheet, for a surface that must dominate the page.
  final Color surfaceInvert;

  /// Body and heading text on any light surface.
  final Color textPrimary;

  /// Captions and supporting text. Still clears 4.5:1 on every light surface.
  final Color textSecondary;

  /// Text on a disabled control. **Never the only signal** — a disabled state
  /// always ships a shape change too.
  final Color textDisabled;

  /// Text on [surfaceInvert].
  final Color textInvert;

  /// The 3px structural border on every raised surface. The single line that
  /// makes the whole system read as one thing.
  final Color border;

  /// The border of a disabled surface.
  final Color borderDisabled;

  /// A hairline between rows.
  final Color divider;

  /// The dotted texture behind a play field.
  final Color dotPattern;

  /// The primary brand accent — the colour of a default action.
  final Color accent;

  /// The darker half of [accent], for a pressed face or a stripe.
  final Color accentDeep;

  /// The ray sweep behind a header, alpha already applied.
  ///
  /// `app.html`: `.hdr .rays{background:...var(--sunshine-deep)...;opacity:.5}`.
  ///
  /// Pre-composed HERE rather than by the painter, because applying an alpha at
  /// a call site is the raw-value rule the token gates enforce — and because a
  /// texture's strength is a design decision, not something a widget should be
  /// free to tune.
  final Color headerRay;

  /// The dot lattice behind a header, alpha already applied.
  ///
  /// `app.html`: `.hdr .dots{opacity:.16}` over `var(--ink)`.
  final Color headerDots;

  /// The dot lattice inside the game hero panel, alpha already applied.
  ///
  /// Half the header's strength. `app.html`: `.hero .dots{opacity:.08}`, with
  /// the reason on the rule — ink text on the composite needs 4.5:1.
  final Color heroDots;

  /// The dot lattice behind a board field and inside its stimulus card.
  ///
  /// `app.html`: `.playfill .wdots{opacity:.14}` and `.stim .dots{opacity:.14}`
  /// over `var(--ink)`. Between the header's .16 and the hero's .08 — the
  /// field is the largest expanse of one colour in the app, and a lattice is
  /// what stops it reading as a blank.
  final Color boardDots;

  /// The dot lattice behind a board field and inside its stimulus card.
  ///
  /// `app.html`: `.playfill .wdots{opacity:.14}` and `.stim .dots{opacity:.14}`
  /// over `var(--ink)`. Between the header's .16 and the hero's .08 — the
  /// field is the largest expanse of one colour in the app, and a lattice is
  /// what stops it reading as a blank.

  /// The ray sweep behind the results header, alpha already applied.
  ///
  /// `app.html`: `.res-hdr .rays` — `var(--leaf-deep)` at `.55`, not `.5`, and
  /// not the sunshine of the home header. Each header's ray strength is its
  /// own decision; one shared slot would flatten all three.
  final Color headerRayResults;

  /// The ray sweep behind the settings header, alpha already applied.
  ///
  /// `app.html`: `.set-hdr .rays` — `var(--grape-pop)` at `.3`. The dimmest of
  /// the three, because Settings is a reading screen.
  final Color headerRaySettings;

  /// The full-bleed burst behind the countdown, alpha already applied.
  ///
  /// `app.html`: `.count .rays` — `var(--grape-pop)` at `.55`, radiating from
  /// the centre of the screen rather than from above its top edge.
  final Color countdownRay;

  /// A countdown beat that has not fired yet.
  ///
  /// `app.html`: `.count .dotsrow i{background:var(--grape-pop)}` — the FULL
  /// pop, not the dimmed ray colour. An idle dot at the ray's opacity all but
  /// disappears into the burst behind it, which is how a three-beat meter
  /// becomes a one-beat one.
  final Color countdownDotIdle;

  /// The ray sweep behind Stroop Rush's play band, alpha already applied.
  final Color bandRayStroop;

  /// The ray sweep behind Schulte Grid's play band, alpha already applied.
  final Color bandRaySchulte;

  /// The secondary accent, for a surface that must not read as the primary
  /// action.
  final Color accentAlt;

  /// The warm chrome accent: the wordmark tile.
  ///
  /// **It shares a primitive with `gameStroop` and is deliberately a separate
  /// slot.** Chrome must not move when a game's accent does — if Stroop Rush
  /// were re-skinned tomorrow the product lockup would follow it, and nobody
  /// would have decided that.
  final Color accentWarm;

  /// The cool chrome accent: the Stats header.
  ///
  /// The same separation as [accentWarm], for the same reason: a tab header is
  /// not a game surface, even where the design picked the same hue.
  final Color accentCool;

  /// A positive outcome, and the Play button.
  final Color success;

  /// The darker half of [success].
  final Color successDeep;

  /// A caution that is not an error.
  final Color warning;

  /// A destructive action or a real alarm.
  ///
  /// Wired to the **primitive**, never to the [playRed] slot: the colour-blind
  /// setting re-points answer slots, and an alarm aliased to one would turn
  /// magenta for exactly the players who need it most.
  final Color danger;

  /// The focus ring. A UI component under WCAG SC 1.4.11, so 3:1 is its floor.
  final Color focusRing;

  /// Stroop Rush's identity colour.
  final Color gameStroop;

  /// The darker half of [gameStroop].
  final Color gameStroopDeep;

  /// Schulte Grid's identity colour.
  final Color gameSchulte;

  /// The darker half of [gameSchulte].
  final Color gameSchulteDeep;

  /// The red answer key. Gameplay tier — legal only inside a board or answer
  /// widget, and it never paints chrome.
  final Color playRed;

  /// The blue answer key.
  final Color playBlue;

  /// The green answer key.
  final Color playGreen;

  /// The yellow answer key. The one that takes an ink label rather than paper.
  final Color playYellow;

  /// The purple answer key. Blitz only.
  final Color playPurple;

  /// The orange answer key. Blitz only.
  final Color playOrange;

  /// The blue slot under the colour-blind-safe palette.
  final Color cbBlue;

  /// The yellow slot under the colour-blind-safe palette.
  final Color cbYellow;

  /// What green becomes under the colour-blind-safe palette.
  final Color cbOrange;

  /// What red becomes under the colour-blind-safe palette.
  final Color cbPink;

  /// The colour of [answer], honouring the colour-blind palette.
  ///
  /// **The only place the colour-blind setting is applied.** The flag is read
  /// from settings by the board's notifier and passed in; no widget branches on
  /// it, and no chrome slot can be reached from here.
  Color answerColour(PlayAnswer answer, {bool colourBlind = false}) =>
      switch (answer) {
        PlayAnswer.red => colourBlind ? cbPink : playRed,
        PlayAnswer.blue => colourBlind ? cbBlue : playBlue,
        PlayAnswer.green => colourBlind ? cbOrange : playGreen,
        PlayAnswer.yellow => colourBlind ? cbYellow : playYellow,
        PlayAnswer.purple => playPurple,
        PlayAnswer.orange => playOrange,
      };

  /// The label colour to draw on [answer] — never "pick one at the call site".
  ///
  /// Holds in both palettes: only the yellow slot stays light enough to need
  /// ink; every other answer takes paper.
  Color answerLabel(PlayAnswer answer) =>
      answer == PlayAnswer.yellow ? textPrimary : surfaceRaised;

  /// The palette attached to [context]'s theme.
  ///
  /// Asserts rather than falling back. A missing extension is a wiring bug, and
  /// a fallback palette is one no golden has ever rendered.
  static SunburstColors of(BuildContext context) {
    final extension = Theme.of(context).extension<SunburstColors>();
    assert(
      extension != null,
      'SunburstColors is missing from the theme. Build it with '
      'buildSunburstTheme().',
    );
    return extension!;
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
  // @contrast surfaceRaised playPurple   4.5  paper label, Blitz palette
  //   (was textInvert: answerLabel returns paper for every answer except
  //    yellow, so the cream pairing was a row the code never renders)
  // @contrast surfaceRaised playOrange  4.5  paper label, Blitz palette
  // @contrast surfaceRaised cbPink      4.5  paper label, colour-blind palette
  // @contrast focusRing surface         3.0  focus ring is a UI component (SC 1.4.11)
  // @contrast border surface            3.0  the 3px structural border
  // @contrast textDisabled surface      3.0  disabled only; SC 1.4.3 exempts it,
  //                                          and it always ships a shape change

  List<Object?> get _props => <Object?>[
    surface,
    surfaceSunk,
    surfaceRaised,
    surfaceInvert,
    textPrimary,
    textSecondary,
    textDisabled,
    textInvert,
    border,
    borderDisabled,
    divider,
    dotPattern,
    accent,
    accentDeep,
    headerRay,
    headerDots,
    heroDots,
    boardDots,
    headerRayResults,
    headerRaySettings,
    countdownRay,
    countdownDotIdle,
    bandRayStroop,
    bandRaySchulte,
    accentAlt,
    accentWarm,
    accentCool,
    success,
    successDeep,
    warning,
    danger,
    focusRing,
    gameStroop,
    gameStroopDeep,
    gameSchulte,
    gameSchulteDeep,
    playRed,
    playBlue,
    playGreen,
    playYellow,
    playPurple,
    playOrange,
    cbBlue,
    cbYellow,
    cbOrange,
    cbPink,
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
    Color? surface,
    Color? surfaceSunk,
    Color? surfaceRaised,
    Color? surfaceInvert,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? textInvert,
    Color? border,
    Color? borderDisabled,
    Color? divider,
    Color? dotPattern,
    Color? accent,
    Color? accentDeep,
    Color? headerRay,
    Color? headerDots,
    Color? heroDots,
    Color? boardDots,
    Color? headerRayResults,
    Color? headerRaySettings,
    Color? countdownRay,
    Color? countdownDotIdle,
    Color? bandRayStroop,
    Color? bandRaySchulte,
    Color? accentAlt,
    Color? accentWarm,
    Color? accentCool,
    Color? success,
    Color? successDeep,
    Color? warning,
    Color? danger,
    Color? focusRing,
    Color? gameStroop,
    Color? gameStroopDeep,
    Color? gameSchulte,
    Color? gameSchulteDeep,
    Color? playRed,
    Color? playBlue,
    Color? playGreen,
    Color? playYellow,
    Color? playPurple,
    Color? playOrange,
    Color? cbBlue,
    Color? cbYellow,
    Color? cbOrange,
    Color? cbPink,
  }) => SunburstColors(
    surface: surface ?? this.surface,
    surfaceSunk: surfaceSunk ?? this.surfaceSunk,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    surfaceInvert: surfaceInvert ?? this.surfaceInvert,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textDisabled: textDisabled ?? this.textDisabled,
    textInvert: textInvert ?? this.textInvert,
    border: border ?? this.border,
    borderDisabled: borderDisabled ?? this.borderDisabled,
    divider: divider ?? this.divider,
    dotPattern: dotPattern ?? this.dotPattern,
    accent: accent ?? this.accent,
    accentDeep: accentDeep ?? this.accentDeep,
    headerRay: headerRay ?? this.headerRay,
    headerDots: headerDots ?? this.headerDots,
    heroDots: heroDots ?? this.heroDots,
    boardDots: boardDots ?? this.boardDots,
    headerRayResults: headerRayResults ?? this.headerRayResults,
    headerRaySettings: headerRaySettings ?? this.headerRaySettings,
    countdownRay: countdownRay ?? this.countdownRay,
    countdownDotIdle: countdownDotIdle ?? this.countdownDotIdle,
    bandRayStroop: bandRayStroop ?? this.bandRayStroop,
    bandRaySchulte: bandRaySchulte ?? this.bandRaySchulte,
    accentAlt: accentAlt ?? this.accentAlt,
    accentWarm: accentWarm ?? this.accentWarm,
    accentCool: accentCool ?? this.accentCool,
    success: success ?? this.success,
    successDeep: successDeep ?? this.successDeep,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
    focusRing: focusRing ?? this.focusRing,
    gameStroop: gameStroop ?? this.gameStroop,
    gameStroopDeep: gameStroopDeep ?? this.gameStroopDeep,
    gameSchulte: gameSchulte ?? this.gameSchulte,
    gameSchulteDeep: gameSchulteDeep ?? this.gameSchulteDeep,
    playRed: playRed ?? this.playRed,
    playBlue: playBlue ?? this.playBlue,
    playGreen: playGreen ?? this.playGreen,
    playYellow: playYellow ?? this.playYellow,
    playPurple: playPurple ?? this.playPurple,
    playOrange: playOrange ?? this.playOrange,
    cbBlue: cbBlue ?? this.cbBlue,
    cbYellow: cbYellow ?? this.cbYellow,
    cbOrange: cbOrange ?? this.cbOrange,
    cbPink: cbPink ?? this.cbPink,
  );

  /// Honest per-field interpolation.
  ///
  /// MindForge ships one `ThemeData` and never animates a theme change, so this
  /// does not run in production — but golden harnesses and previews drive it,
  /// and a field silently missing here is the classic way a design system rots.
  /// Every new slot goes in this list too.
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
      accent: c(accent, other.accent),
      accentDeep: c(accentDeep, other.accentDeep),
      headerRay: c(headerRay, other.headerRay),
      headerDots: c(headerDots, other.headerDots),
      heroDots: c(heroDots, other.heroDots),
      boardDots: c(boardDots, other.boardDots),
      headerRayResults: c(headerRayResults, other.headerRayResults),
      headerRaySettings: c(headerRaySettings, other.headerRaySettings),
      countdownRay: c(countdownRay, other.countdownRay),
      countdownDotIdle: c(countdownDotIdle, other.countdownDotIdle),
      bandRayStroop: c(bandRayStroop, other.bandRayStroop),
      bandRaySchulte: c(bandRaySchulte, other.bandRaySchulte),
      accentAlt: c(accentAlt, other.accentAlt),
      accentWarm: c(accentWarm, other.accentWarm),
      accentCool: c(accentCool, other.accentCool),
      success: c(success, other.success),
      successDeep: c(successDeep, other.successDeep),
      warning: c(warning, other.warning),
      danger: c(danger, other.danger),
      focusRing: c(focusRing, other.focusRing),
      gameStroop: c(gameStroop, other.gameStroop),
      gameStroopDeep: c(gameStroopDeep, other.gameStroopDeep),
      gameSchulte: c(gameSchulte, other.gameSchulte),
      gameSchulteDeep: c(gameSchulteDeep, other.gameSchulteDeep),
      playRed: c(playRed, other.playRed),
      playBlue: c(playBlue, other.playBlue),
      playGreen: c(playGreen, other.playGreen),
      playYellow: c(playYellow, other.playYellow),
      playPurple: c(playPurple, other.playPurple),
      playOrange: c(playOrange, other.playOrange),
      cbBlue: c(cbBlue, other.cbBlue),
      cbYellow: c(cbYellow, other.cbYellow),
      cbOrange: c(cbOrange, other.cbOrange),
      cbPink: c(cbPink, other.cbPink),
    );
  }

  /// The one palette.
  ///
  /// `danger` and `accentAlt` deliberately read the **primitive** `_P.playRed`
  /// and `_P.grape` rather than the `playRed` / `playPurple` slots: the
  /// colour-blind setting re-points answers, and a destructive-confirm button
  /// or the Daily Mix header must not move when a player flips it.
  ///
  /// Keep **one `slot: _P.primitive,` per line**. `check_palette_contrast.sh`
  /// reads this block to resolve slot names down to hexes and it matches line by
  /// line, so two slots on one line makes the second invisible to the gate.
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
    // ink-3 and its shadow to "soft-ink". ink-3 is inkMuted; "soft-ink" has no
    // token, so the disabled shadow reuses this same slot.
    borderDisabled: _P.inkMuted,
    divider: _P.creamEdge,
    dotPattern: _P.dot,
    accent: _P.sunshine,
    accentDeep: _P.sunshineDeep,
    headerRay: _P.sunshineDeepHalf,
    headerDots: _P.inkHalftone,
    heroDots: _P.inkHalftoneSoft,
    boardDots: _P.inkHalftoneBoard,
    headerRayResults: _P.leafDeepStrong,
    headerRaySettings: _P.grapePopSoft,
    countdownRay: _P.grapePopStrong,
    countdownDotIdle: _P.grapePop,
    bandRayStroop: _P.coralDeepBand,
    bandRaySchulte: _P.turquoiseDeepBand,
    accentAlt: _P.grape,
    accentWarm: _P.coral,
    accentCool: _P.turquoise,
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
