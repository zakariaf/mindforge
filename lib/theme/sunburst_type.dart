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
    required this.body,
    required this.caption,
    required this.label,
    required this.stimulus,
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

  /// Body copy.
  final TextStyle body;

  /// Supporting copy.
  final TextStyle caption;

  /// The one step where capitals are allowed.
  final TextStyle label;

  /// The Stroop stimulus word.
  final TextStyle stimulus;

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
      body: arabic(body, isDisplay: false),
      caption: arabic(caption, isDisplay: false),
      label: arabic(label, isDisplay: false),
      stimulus: arabic(stimulus, isDisplay: true),
    );
  }

  List<Object?> get _props => <Object?>[
    scoreHero,
    displayXl,
    displayL,
    title,
    numericHud,
    button,
    body,
    caption,
    label,
    stimulus,
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
    TextStyle? body,
    TextStyle? caption,
    TextStyle? label,
    TextStyle? stimulus,
  }) => SunburstType(
    scoreHero: scoreHero ?? this.scoreHero,
    displayXl: displayXl ?? this.displayXl,
    displayL: displayL ?? this.displayL,
    title: title ?? this.title,
    numericHud: numericHud ?? this.numericHud,
    button: button ?? this.button,
    body: body ?? this.body,
    caption: caption ?? this.caption,
    label: label ?? this.label,
    stimulus: stimulus ?? this.stimulus,
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
      body: s(body, other.body),
      caption: s(caption, other.caption),
      label: s(label, other.label),
      stimulus: s(stimulus, other.stimulus),
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
  );
}

/// The Arabic resolution of [SunburstType.sunburstPop], built once and reused.
///
/// A lazy top-level `final` rather than a field, because `SunburstType` is
/// `@immutable` with a `const` constructor and a mutable memo would forfeit
/// both.
final SunburstType _arabicSunburstPop = SunburstType.sunburstPop._buildArabic();
