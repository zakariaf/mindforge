import 'package:flutter/material.dart';

/// Which writing system a step is being rendered in.
///
/// A closed set, payload-free: MindForge ships two scripts and adding a third
/// is a design decision, not a runtime lookup.
enum SunburstScript {
  /// English and German.
  latin,

  /// Persian and Kurdish Sorani.
  arabic;

  /// The script [locale] is written in.
  ///
  /// The **only** place a locale becomes a font decision. No widget branches on
  /// locale to pick a family, and no widget names a family at all.
  static SunburstScript forLocale(Locale locale) =>
      switch (locale.languageCode) {
        'fa' || 'ckb' => arabic,
        _ => latin,
      };
}

/// The ten type steps, resolved for the script being rendered.
///
/// The same semantic step — `displayL`, `body`, `numericHud` — resolves to a
/// different family, a different weight and a different line box depending on
/// the script, because Fredoka and Nunito have **no Arabic-script coverage** at
/// all. `SunburstType.of(context)` does that resolution from the ambient
/// `Locale`, so no call site ever picks a font.
@immutable
@immutable
class SunburstType extends ThemeExtension<SunburstType> {
  /// Creates a type scale.
  const SunburstType({
    required this.scoreHero,
    required this.displayXl,
    required this.displayL,
    required this.title,
    required this.numericHud,
    required this.button,
    required this.buttonLarge,
    required this.chip,
    required this.body,
    required this.caption,
    required this.label,
    required this.stimulus,
    required this.titleBar,
    required this.greeting,
    required this.sectionLabel,
    required this.heroTitle,
    required this.countdownNumeral,
    required this.statValue,
    required this.slabLabel,
    required this.resultStatLabel,
    required this.resultStatValue,
    required this.bestGameName,
    required this.bestValue,
    required this.dailyTitle,
    required this.sectionTitle,
    required this.sectionCount,
    required this.chartValueLabel,
    required this.countdownReady,
    required this.lockedTitle,
    required this.stimulusCompact,
    required this.buttonCompact,
  });

  /// The Latin display face.
  static const String display = 'Fredoka';

  /// The Latin body face.
  static const String bodyFace = 'Nunito';

  /// The Arabic-script face, in **both** roles.
  ///
  /// One family, not two. Lalezar is the closest OFL echo of Fredoka's chunky
  /// display voice and was measured against its own `cmap`: it is missing five
  /// of the seven letters that distinguish Sorani from Persian — ڕ ڵ ۆ ێ ە —
  /// so it is refused. `test/theme/font_coverage_test.dart` records that.
  static const String arabicFace = 'Vazirmatn';

  /// DERIVED: `system.html` names "Baloo 2" as the display fallback, but
  /// MindForge is offline and ships no third Latin face — so the display
  /// cascade falls back to the bundled body face, the closest round sans
  /// available.
  ///
  /// Every cascade **ends in a face that can draw the script being rendered**.
  /// A glyph falling through to an OS font is a defect, not a graceful
  /// fallback, and it is invisible on a developer's device.
  static const List<String> displayFallback = <String>[bodyFace, arabicFace];

  /// The body cascade. Ends in the Arabic face for the same reason.
  static const List<String> bodyFallback = <String>[arabicFace];

  /// The Arabic cascade. There is nothing after Vazirmatn, because there is
  /// nothing else bundled that can draw the script.
  static const List<String> arabicFallback = <String>[arabicFace];

  /// The weight Vazirmatn carries the **display** role at.
  ///
  /// Heavier than the Latin display weight: Vazirmatn is a text face rather
  /// than a display face, so it needs more weight to read as loud. This does
  /// not make it Fredoka, and no weight would.
  static const FontWeight arabicDisplayWeight = FontWeight.w900;

  /// The weight Vazirmatn carries the **body** role at.
  static const FontWeight arabicBodyWeight = FontWeight.w500;

  /// How much taller an Arabic line box must be than its Latin counterpart.
  ///
  /// Arabic script has deeper descenders and taller diacritics than Latin at
  /// the same point size, so a `height` tuned for Fredoka **shears** them. This
  /// factor is applied to every step by [forScript]; it is not a per-step
  /// judgement call at a widget.
  static const double arabicLineFactor = 1.35;

  /// The results score. One per screen, and the largest thing in the app.
  final TextStyle scoreHero;

  /// The largest heading.
  final TextStyle displayXl;

  /// A screen heading.
  final TextStyle displayL;

  /// A section or card heading.
  final TextStyle title;

  /// A live HUD value. Tabular by construction — see the const instance.
  final TextStyle numericHud;

  /// A button label.
  final TextStyle button;

  /// The label on a full-width primary action.
  ///
  /// DERIVED: `system.html` §03 draws the large Play button's label three
  /// steps above [button] rather than scaling [button] up at the call site. A
  /// component that reached for `button.copyWith(fontSize: 21)` would be
  /// typing a literal, which is what this slot exists to prevent.
  final TextStyle buttonLarge;

  /// The label inside a chip or a pill.
  ///
  /// DERIVED: `system.html` §04's chips sit between [caption] and [button] in
  /// size but carry the display face and its weight, so neither of those steps
  /// can stand in for it.
  final TextStyle chip;

  /// Body copy.
  final TextStyle body;

  /// Supporting copy.
  final TextStyle caption;

  /// The one step where capitals are allowed.
  final TextStyle label;

  /// The Stroop stimulus word.
  final TextStyle stimulus;

  /// The play and detail top-bar title.
  ///
  /// DERIVED from `app.html` `.topbar .tt`: Fredoka 600 at 17, tracking
  /// -.01em. `system.html` section 04 names ten steps and this is not among
  /// them, which is why every step below carries its evidence.
  final TextStyle titleBar;

  /// The home hub's greeting line.
  ///
  /// DERIVED from `app.html` `.greet`: Nunito 800 at 14, tracking .02em. A
  /// BODY step — it is the one new step that is not Fredoka.
  final TextStyle greeting;

  /// The small upper label above a section.
  ///
  /// DERIVED from `app.html` `.hero .kicker`: Fredoka 600 at 10, tracking
  /// .16em, uppercase.
  ///
  /// **The uppercase is authored into the ARB value, not applied in Dart.**
  /// `fa` and `ckb` have no case, and `toUpperCase()` on a Persian string is a
  /// no-op that still says the author thought casing was a rendering
  /// decision. The tracking is zeroed for Arabic script by [forScript], because
  /// .16em on a cursive script breaks the joins — `کۆ` spaced out is not a
  /// style, it is broken text.
  final TextStyle sectionLabel;

  /// The game detail hero title.
  ///
  /// DERIVED from `app.html` `.hero .ht`: Fredoka 700 at 38, line 0.98,
  /// tracking -.03em.
  final TextStyle heroTitle;

  /// The 3-2-1 numeral.
  ///
  /// DERIVED from `app.html` `.bigring b`: Fredoka 700 at 132, line 1,
  /// tracking -.04em. Tabular, so 3 and 2 and 1 occupy the same box and the
  /// ring does not appear to breathe as it counts.
  final TextStyle countdownNumeral;

  /// A stat box's value, and each cell of the results trio.
  ///
  /// DERIVED from `app.html` `.statbox b`: Fredoka 700 at 26, tracking -.02em,
  /// `font-variant-numeric: tabular-nums`. Tabular because a stats grid whose
  /// columns shift when a digit changes reads as a layout bug.
  final TextStyle statValue;

  /// The FINAL SCORE caption above the results slab.
  ///
  /// `app.html`: `.scoreslab s` — 11/600, `.16em`, uppercase. One point larger
  /// than [sectionLabel] and tracked the same, because it sits alone over a
  /// 76pt number and a 10pt caption disappears under it.
  final TextStyle slabLabel;

  /// The caption inside one of the three results cells.
  ///
  /// `app.html`: `.tri s` — 10/600 at `.09em`, line 1.3. The loosest tracking
  /// in the type scale is deliberately NOT used here: these three captions
  /// wrap to two lines in German, and 1.6 of tracking pushes them to three.
  final TextStyle resultStatLabel;

  /// The value inside one of the three results cells.
  ///
  /// `app.html`: `.tri b` — 23/700, `-.02em`, tabular.
  final TextStyle resultStatValue;

  /// The game's name on a Stats best card.
  ///
  /// `app.html`: `.bestcard .bl b` — 18/600, `-.01em`.
  final TextStyle bestGameName;

  /// The value chip on a Stats best card.
  ///
  /// `app.html`: `.bestcard .bv` — 28/700, `-.03em`, tabular.
  final TextStyle bestValue;

  /// The Daily Mix card's title.
  ///
  /// `app.html`: `.daily .ct` — 22/700, `-.015em`. The card's paper variant on
  /// game detail overrides this to 19; the variant carries the step, because a
  /// screen writing `fontSize: 19` is the raw value the token gates refuse.
  final TextStyle dailyTitle;

  /// A section heading inside a pane: "Your games", "Last 7 runs".
  ///
  /// `app.html`: `.seclab b` — 15/600 at `.01em`. Not [title], which is 21 and
  /// is what a CARD's name uses.
  final TextStyle sectionTitle;

  /// The count that trails a section heading: "2 unlocked".
  ///
  /// `app.html`: `.seclab s` — 12/800, body face.
  final TextStyle sectionCount;

  /// The value printed above a chart bar.
  ///
  /// `app.html`: `.bar u` — 10/600 with **no tracking** and tabular figures.
  /// Not [label] with its tracking zeroed out: a step is a role, and a widget
  /// overriding one field of another role is a raw value wearing a token's
  /// name.
  final TextStyle chartValueLabel;

  /// The "Get ready" line under the countdown ring.
  ///
  /// `app.html`: `.count .ready` — 30/700, `-.01em`. Its own step because the
  /// scale had nothing at 30: [displayL] is 33 and [title] is 21, and rounding
  /// to either changes the one line on the screen that is not a numeral.
  final TextStyle countdownReady;

  /// A locked slot's game name.
  ///
  /// `app.html`: `.locked .ct` — 19/600, `-.01em`. Two points under [title],
  /// because a slot is quieter than a card and the design says so rather than
  /// leaving both at 21.
  final TextStyle lockedTitle;

  /// The stimulus at the size a long word needs.
  ///
  /// **A SMALLER BASE STYLE, never a shrink.** `accessibility-as-code` rule 5
  /// bans scaling text down to fit; a board that meets a word it cannot draw
  /// at [stimulus] draws it at this step instead, which is a typographic
  /// decision made once here rather than one a box makes per frame by scaling
  /// the glyphs down to whatever is left.
  ///
  /// DERIVED: **56** against [stimulus]'s 78, and measured rather than
  /// guessed. With the bundled Fredoka, at the 72pt content inset the
  /// reference screens use:
  ///
  /// | size | YELLOW | ORANGE | نارەنجی |
  /// |---|---|---|---|
  /// | 78 | 320 | 317 | 232 |
  /// | 62 | 256 | 253 | 185 |
  /// | 56 | **231** | **229** | 167 |
  ///
  /// A 320pt device leaves 248. 62 was the first guess and misses by eight
  /// points on the longest English word — which is exactly the kind of number
  /// that looks fine on the 390pt reference and clips on the phone somebody
  /// actually owns.
  ///
  /// It also says something about [stimulus]: at 78, YELLOW is 320 points wide
  /// and even a 390pt screen leaves only 318. The full step fits BLUE, RED and
  /// GREEN — which is what the reference screen draws — and not the two longest
  /// words, which is why the compact step is not an edge case.
  final TextStyle stimulusCompact;

  /// A button or key label at the size a long word needs.
  ///
  /// The same rule as [stimulusCompact], one step down: DERIVED 15 against
  /// [button]'s 18, for the answer key that has to hold `پرتەقاڵی` beside a
  /// 56pt pattern panel.
  final TextStyle buttonCompact;

  /// The type scale attached to [context]'s theme, resolved for the ambient
  /// locale's script.
  ///
  /// This is the whole point: a widget asks for `SunburstType.of(context).body`
  /// and gets a style that can draw whatever language it is about to render.
  static SunburstType of(BuildContext context) {
    final extension = Theme.of(context).extension<SunburstType>();
    assert(
      extension != null,
      'SunburstType is missing from the theme. Build it with '
      'buildSunburstTheme().',
    );
    return extension!.forScript(
      SunburstScript.forLocale(Localizations.localeOf(context)),
    );
  }

  /// This scale, re-resolved for [script].
  ///
  /// [SunburstScript.latin] returns `this` unchanged. [SunburstScript.arabic]
  /// re-points every step at [arabicFace], swaps in the Arabic weights, scales
  /// the line box by [arabicLineFactor], and **zeroes `letterSpacing`**.
  ///
  /// Zeroing the tracking is not a stylistic preference. Arabic script is
  /// cursive: adjacent letters join, and positive or negative tracking breaks
  /// those joins, turning a word into disconnected shapes. Every negative
  /// tracking value in the Latin scale exists to tighten Fredoka's wide
  /// counters and means nothing here.
  SunburstType forScript(SunburstScript script) {
    if (script == SunburstScript.latin) return this;
    // The one instance that is ever attached to the theme, resolved once.
    // [of] calls this on EVERY build, and without the cache each call
    // allocates ten TextStyles in the two RTL locales — a 25-tile Schulte grid
    // reads the scale once per tile, so that is 250 allocations per frame for
    // a value that never changes. `identical` rather than `==` because the
    // latter compares ten TextStyles and would cost more than it saves.
    if (identical(this, sunburstPop)) return _arabicSunburstPop;
    return _buildArabic();
  }

  SunburstType _buildArabic() {
    TextStyle arabic(TextStyle latin, {required bool isDisplay}) =>
        latin.copyWith(
          fontFamily: arabicFace,
          fontFamilyFallback: arabicFallback,
          fontWeight: isDisplay ? arabicDisplayWeight : arabicBodyWeight,
          height: (latin.height ?? 1.0) * arabicLineFactor,
          letterSpacing: 0,
        );

    return SunburstType(
      scoreHero: arabic(scoreHero, isDisplay: true),
      displayXl: arabic(displayXl, isDisplay: true),
      displayL: arabic(displayL, isDisplay: true),
      title: arabic(title, isDisplay: true),
      numericHud: arabic(numericHud, isDisplay: true),
      button: arabic(button, isDisplay: true),
      buttonLarge: arabic(buttonLarge, isDisplay: true),
      chip: arabic(chip, isDisplay: true),
      body: arabic(body, isDisplay: false),
      caption: arabic(caption, isDisplay: false),
      label: arabic(label, isDisplay: false),
      stimulus: arabic(stimulus, isDisplay: true),
      titleBar: arabic(titleBar, isDisplay: true),
      greeting: arabic(greeting, isDisplay: false),
      sectionLabel: arabic(sectionLabel, isDisplay: true),
      heroTitle: arabic(heroTitle, isDisplay: true),
      countdownNumeral: arabic(countdownNumeral, isDisplay: true),
      statValue: arabic(statValue, isDisplay: true),
      slabLabel: arabic(slabLabel, isDisplay: true),
      resultStatLabel: arabic(resultStatLabel, isDisplay: true),
      resultStatValue: arabic(resultStatValue, isDisplay: true),
      bestGameName: arabic(bestGameName, isDisplay: true),
      bestValue: arabic(bestValue, isDisplay: true),
      dailyTitle: arabic(dailyTitle, isDisplay: true),
      sectionTitle: arabic(sectionTitle, isDisplay: true),
      sectionCount: arabic(sectionCount, isDisplay: false),
      chartValueLabel: arabic(chartValueLabel, isDisplay: true),
      countdownReady: arabic(countdownReady, isDisplay: true),
      lockedTitle: arabic(lockedTitle, isDisplay: true),
      stimulusCompact: arabic(stimulusCompact, isDisplay: true),
      buttonCompact: arabic(buttonCompact, isDisplay: true),
    );
  }

  List<Object?> get _props => <Object?>[
    scoreHero,
    displayXl,
    displayL,
    title,
    numericHud,
    button,
    buttonLarge,
    chip,
    body,
    caption,
    label,
    stimulus,
    titleBar,
    greeting,
    sectionLabel,
    heroTitle,
    countdownNumeral,
    statValue,
    slabLabel,
    resultStatLabel,
    resultStatValue,
    bestGameName,
    bestValue,
    dailyTitle,
    sectionTitle,
    sectionCount,
    chartValueLabel,
    countdownReady,
    lockedTitle,
    stimulusCompact,
    buttonCompact,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SunburstType &&
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
  SunburstType copyWith({
    TextStyle? scoreHero,
    TextStyle? displayXl,
    TextStyle? displayL,
    TextStyle? title,
    TextStyle? numericHud,
    TextStyle? button,
    TextStyle? buttonLarge,
    TextStyle? chip,
    TextStyle? body,
    TextStyle? caption,
    TextStyle? label,
    TextStyle? stimulus,
    TextStyle? titleBar,
    TextStyle? greeting,
    TextStyle? sectionLabel,
    TextStyle? heroTitle,
    TextStyle? countdownNumeral,
    TextStyle? statValue,
    TextStyle? slabLabel,
    TextStyle? resultStatLabel,
    TextStyle? resultStatValue,
    TextStyle? bestGameName,
    TextStyle? bestValue,
    TextStyle? dailyTitle,
    TextStyle? sectionTitle,
    TextStyle? sectionCount,
    TextStyle? chartValueLabel,
    TextStyle? countdownReady,
    TextStyle? lockedTitle,
    TextStyle? stimulusCompact,
    TextStyle? buttonCompact,
  }) => SunburstType(
    scoreHero: scoreHero ?? this.scoreHero,
    displayXl: displayXl ?? this.displayXl,
    displayL: displayL ?? this.displayL,
    title: title ?? this.title,
    numericHud: numericHud ?? this.numericHud,
    button: button ?? this.button,
    buttonLarge: buttonLarge ?? this.buttonLarge,
    chip: chip ?? this.chip,
    body: body ?? this.body,
    caption: caption ?? this.caption,
    label: label ?? this.label,
    stimulus: stimulus ?? this.stimulus,
    titleBar: titleBar ?? this.titleBar,
    greeting: greeting ?? this.greeting,
    sectionLabel: sectionLabel ?? this.sectionLabel,
    heroTitle: heroTitle ?? this.heroTitle,
    countdownNumeral: countdownNumeral ?? this.countdownNumeral,
    statValue: statValue ?? this.statValue,
    slabLabel: slabLabel ?? this.slabLabel,
    resultStatLabel: resultStatLabel ?? this.resultStatLabel,
    resultStatValue: resultStatValue ?? this.resultStatValue,
    bestGameName: bestGameName ?? this.bestGameName,
    bestValue: bestValue ?? this.bestValue,
    dailyTitle: dailyTitle ?? this.dailyTitle,
    sectionTitle: sectionTitle ?? this.sectionTitle,
    sectionCount: sectionCount ?? this.sectionCount,
    chartValueLabel: chartValueLabel ?? this.chartValueLabel,
    countdownReady: countdownReady ?? this.countdownReady,
    lockedTitle: lockedTitle ?? this.lockedTitle,
    stimulusCompact: stimulusCompact ?? this.stimulusCompact,
    buttonCompact: buttonCompact ?? this.buttonCompact,
  );

  @override
  SunburstType lerp(covariant SunburstType? other, double t) {
    if (other == null) return this;
    TextStyle s(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;

    return SunburstType(
      scoreHero: s(scoreHero, other.scoreHero),
      displayXl: s(displayXl, other.displayXl),
      displayL: s(displayL, other.displayL),
      title: s(title, other.title),
      numericHud: s(numericHud, other.numericHud),
      button: s(button, other.button),
      buttonLarge: s(buttonLarge, other.buttonLarge),
      chip: s(chip, other.chip),
      body: s(body, other.body),
      caption: s(caption, other.caption),
      label: s(label, other.label),
      stimulus: s(stimulus, other.stimulus),
      titleBar: s(titleBar, other.titleBar),
      greeting: s(greeting, other.greeting),
      sectionLabel: s(sectionLabel, other.sectionLabel),
      heroTitle: s(heroTitle, other.heroTitle),
      countdownNumeral: s(countdownNumeral, other.countdownNumeral),
      statValue: s(statValue, other.statValue),
      slabLabel: s(slabLabel, other.slabLabel),
      resultStatLabel: s(resultStatLabel, other.resultStatLabel),
      resultStatValue: s(resultStatValue, other.resultStatValue),
      bestGameName: s(bestGameName, other.bestGameName),
      bestValue: s(bestValue, other.bestValue),
      dailyTitle: s(dailyTitle, other.dailyTitle),
      sectionTitle: s(sectionTitle, other.sectionTitle),
      sectionCount: s(sectionCount, other.sectionCount),
      chartValueLabel: s(chartValueLabel, other.chartValueLabel),
      countdownReady: s(countdownReady, other.countdownReady),
      lockedTitle: s(lockedTitle, other.lockedTitle),
      stimulusCompact: s(stimulusCompact, other.stimulusCompact),
      buttonCompact: s(buttonCompact, other.buttonCompact),
    );
  }

  /// Tabular figures: every digit the same advance width.
  static const List<FontFeature> _tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  /// The one type scale, in its Latin form. [forScript] derives the Arabic one.
  static const SunburstType sunburstPop = SunburstType(
    // 76/72, -4% tracking. The results score only, one per screen.
    scoreHero: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w700,
      fontSize: 76,
      height: 0.95,
      letterSpacing: -3.04,
      fontFeatures: _tabular,
    ),
    displayXl: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w700,
      fontSize: 42,
      height: 1,
      letterSpacing: -1.26,
    ),
    displayL: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w700,
      fontSize: 33,
      height: 1.02,
      letterSpacing: -0.83,
    ),
    title: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w600,
      fontSize: 21,
      height: 1.1,
      letterSpacing: -0.32,
    ),
    // Tabular is mandatory here: an HUD value that reflows mid-run reads as a
    // glitch, and the player is watching it while doing something else.
    numericHud: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w700,
      fontSize: 22,
      height: 1.18,
      letterSpacing: -0.44,
      fontFeatures: _tabular,
    ),
    button: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w600,
      fontSize: 18,
      height: 1.22,
    ),
    // DERIVED: system.html §03, the full-width primary action.
    buttonLarge: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w600,
      fontSize: 21,
      height: 24 / 21,
    ),
    // DERIVED: system.html §04, the chip label.
    chip: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w600,
      fontSize: 14,
      height: 18 / 14,
    ),
    body: TextStyle(
      fontFamily: bodyFace,
      fontFamilyFallback: bodyFallback,
      fontWeight: FontWeight.w700,
      fontSize: 15,
      height: 1.4,
    ),
    caption: TextStyle(
      fontFamily: bodyFace,
      fontFamilyFallback: bodyFallback,
      fontWeight: FontWeight.w700,
      fontSize: 13,
      height: 1.38,
    ),
    // The only place capitals are allowed. Fredoka blurs below about 12px, so
    // this step buys the legibility back with +14% tracking.
    label: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w600,
      fontSize: 10,
      height: 1.4,
      letterSpacing: 1.4,
    ),
    // The Stroop stimulus. MUST be painted as three passes — an ink stroke, the
    // answer hue, then the PlayFill pattern clipped to the glyph. A bare fill
    // is 1.76:1 on cream.
    stimulus: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w700,
      fontSize: 78,
      height: 1,
      letterSpacing: 0.78,
    ),
    // .topbar .tt — 17/600, -.01em.
    titleBar: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w600,
      fontSize: 17,
      height: 1.2,
      letterSpacing: -0.17,
    ),
    // .greet — Nunito 800 at 14, +.02em. The one new step that is BODY, so it
    // takes the body fallback cascade rather than the display one.
    greeting: TextStyle(
      fontFamily: bodyFace,
      fontFamilyFallback: bodyFallback,
      fontWeight: FontWeight.w800,
      fontSize: 14,
      height: 1.3,
      letterSpacing: 0.28,
    ),
    // .hero .kicker — 10/600, +.16em, uppercase authored into the ARB.
    sectionLabel: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w600,
      fontSize: 10,
      height: 1.2,
      letterSpacing: 1.6,
    ),
    // .hero .ht — 38/700, line .98, -.03em.
    heroTitle: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w700,
      fontSize: 38,
      height: 0.98,
      letterSpacing: -1.14,
    ),
    // .bigring b — 132/700, line 1, -.04em. Tabular, so the ring does not
    // appear to breathe as the numeral changes.
    countdownNumeral: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w700,
      fontSize: 132,
      height: 1,
      letterSpacing: -5.28,
      fontFeatures: _tabular,
    ),
    // .statbox b — 26/700, -.02em, tabular-nums.
    statValue: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w700,
      fontSize: 26,
      height: 1.1,
      letterSpacing: -0.52,
      fontFeatures: _tabular,
    ),

    // .scoreslab s — 11/600, .16em, uppercase.
    slabLabel: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w600,
      fontSize: 11,
      height: 1.2,
      letterSpacing: 1.76,
    ),
    // .tri s — 10/600, .09em, line 1.3.
    resultStatLabel: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w600,
      fontSize: 10,
      height: 1.3,
      letterSpacing: 0.9,
    ),
    // .tri b — 23/700, -.02em, tabular-nums.
    resultStatValue: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w700,
      fontSize: 23,
      height: 1.1,
      letterSpacing: -0.46,
      fontFeatures: _tabular,
    ),
    // .bestcard .bl b — 18/600, -.01em.
    bestGameName: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w600,
      fontSize: 18,
      height: 1.15,
      letterSpacing: -0.18,
    ),
    // .bestcard .bv — 28/700, -.03em, tabular-nums.
    bestValue: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w700,
      fontSize: 28,
      height: 1.1,
      letterSpacing: -0.84,
      fontFeatures: _tabular,
    ),
    // .daily .ct — 22/700, -.015em, line 1.1.
    dailyTitle: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w700,
      fontSize: 22,
      height: 1.1,
      letterSpacing: -0.33,
    ),
    // .seclab b — 15/600, .01em.
    sectionTitle: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w600,
      fontSize: 15,
      height: 1.2,
      letterSpacing: 0.15,
    ),
    // .seclab s — 12/800, body face.
    sectionCount: TextStyle(
      fontFamily: bodyFace,
      fontFamilyFallback: bodyFallback,
      fontWeight: FontWeight.w800,
      fontSize: 12,
      height: 1.2,
    ),
    // .bar u — 10/600, no tracking, tabular-nums.
    chartValueLabel: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w600,
      fontSize: 10,
      height: 1.2,
      fontFeatures: _tabular,
    ),
    // .count .ready — 30/700, -.01em.
    countdownReady: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w700,
      fontSize: 30,
      height: 1.15,
      letterSpacing: -0.3,
    ),
    // DERIVED: the stimulus at the size a long word needs. 56 against 78,
    // measured against the longest word in the longest locale at 320pt.
    stimulusCompact: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w700,
      fontSize: 56,
      height: 1,
      letterSpacing: 0.56,
    ),
    // DERIVED: a key label at the size a long word needs. 15 against 18.
    buttonCompact: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w600,
      fontSize: 15,
      height: 1.22,
    ),
    // .locked .ct — 19/600, -.01em.
    lockedTitle: TextStyle(
      fontFamily: display,
      fontFamilyFallback: displayFallback,
      fontWeight: FontWeight.w600,
      fontSize: 19,
      height: 1.15,
      letterSpacing: -0.19,
    ),
  );
}

/// The Arabic resolution of [SunburstType.sunburstPop], built once and reused.
///
/// A lazy top-level `final` rather than a field, because `SunburstType` is
/// `@immutable` with a `const` constructor and a mutable memo would forfeit
/// both.
final SunburstType _arabicSunburstPop = SunburstType.sunburstPop._buildArabic();
