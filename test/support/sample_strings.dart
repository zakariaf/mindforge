import 'package:flutter/foundation.dart';

/// One locale's worth of **specimen** strings for the component catalog.
///
/// **These are not translations.** They are specimens chosen for *length* and
/// *script*, and they exist to stress layout: the German set is deliberately
/// long, the Persian and Sorani sets are Arabic script with Eastern Arabic
/// numerals, and the Sorani set uses letters no other shipped locale has. The
/// real strings arrive from the ARB files in E08, through
/// `AppLocalizations`; nothing here is user-facing and nothing here should be
/// copied into one.
///
/// A component's numeral contract is that it renders whatever digits it is
/// handed — **no component formats a number**, so every numeral field here is
/// already formatted, exactly as `LocaleNumbers` would deliver it from the
/// shell.
@immutable
final class SampleStrings {
  /// Creates a specimen set.
  const SampleStrings({
    required this.button,
    required this.chip,
    required this.cardTitle,
    required this.cardSubtitle,
    required this.hudLabel,
    required this.difficultyChill,
    required this.difficultyClassic,
    required this.difficultyBlitz,
    required this.navPlay,
    required this.navStats,
    required this.navSettings,
    required this.toggleOn,
    required this.toggleOff,
    required this.score,
    required this.duration,
    required this.tile,
  });

  /// A primary action label.
  final String button;

  /// A chip label.
  final String chip;

  /// A game card's name.
  final String cardTitle;

  /// A game card's tagline — the longest single run in the set.
  final String cardSubtitle;

  /// A HUD pill's caption.
  final String hudLabel;

  /// The easiest difficulty.
  final String difficultyChill;

  /// The default difficulty.
  final String difficultyClassic;

  /// The hardest difficulty.
  final String difficultyBlitz;

  /// The play tab.
  final String navPlay;

  /// The stats tab.
  final String navStats;

  /// The settings tab.
  final String navSettings;

  /// A toggle's on-state word.
  final String toggleOn;

  /// A toggle's off-state word.
  final String toggleOff;

  /// A grouped score, already formatted.
  final String score;

  /// A duration in seconds, already formatted.
  final String duration;

  /// A Schulte tile's number, already formatted.
  final String tile;

  /// Every field by name, for a test that asserts over all of them.
  Map<String, String> get byField => <String, String>{
    'button': button,
    'chip': chip,
    'cardTitle': cardTitle,
    'cardSubtitle': cardSubtitle,
    'hudLabel': hudLabel,
    'difficultyChill': difficultyChill,
    'difficultyClassic': difficultyClassic,
    'difficultyBlitz': difficultyBlitz,
    'navPlay': navPlay,
    'navStats': navStats,
    'navSettings': navSettings,
    'toggleOn': toggleOn,
    'toggleOff': toggleOff,
    'score': score,
    'duration': duration,
    'tile': tile,
  };

  /// The combined character count, which is how the expansion ratio is checked.
  int get totalLength =>
      byField.values.fold(0, (sum, value) => sum + value.length);
}

/// The specimen sets, keyed by language code, in `SupportedLocale` order.
const Map<String, SampleStrings> sampleStrings = <String, SampleStrings>{
  'en': SampleStrings(
    button: 'Play',
    chip: 'Reaction',
    cardTitle: 'Stroop Rush',
    cardSubtitle: 'Tap the colour, not the word',
    hudLabel: 'Score',
    difficultyChill: 'Chill',
    difficultyClassic: 'Classic',
    difficultyBlitz: 'Blitz',
    navPlay: 'Play',
    navStats: 'Stats',
    navSettings: 'Settings',
    toggleOn: 'ON',
    toggleOff: 'OFF',
    score: '1,480',
    duration: '18.6',
    tile: '25',
  ),
  // The expansion stress case. Every field is the longest plausible German
  // rendering, because a catalog that fits English and breaks in German is a
  // catalog that gets rebuilt.
  'de': SampleStrings(
    button: 'Spielen',
    chip: 'Reaktionszeit',
    cardTitle: 'Stroop-Ansturm',
    cardSubtitle: 'Tippe die Farbe, nicht das geschriebene Wort',
    hudLabel: 'Punktzahl',
    difficultyChill: 'Gemütlich',
    difficultyClassic: 'Klassisch',
    difficultyBlitz: 'Blitzschnell',
    navPlay: 'Spielen',
    navStats: 'Statistiken',
    navSettings: 'Einstellungen',
    toggleOn: 'AN',
    toggleOff: 'AUS',
    score: '1.480',
    duration: '18,6',
    tile: '25',
  ),
  'fa': SampleStrings(
    button: 'شروع',
    chip: 'واکنش',
    cardTitle: 'شتاب استروپ',
    cardSubtitle: 'رنگ را بزن، نه واژه را',
    hudLabel: 'امتیاز',
    difficultyChill: 'آرام',
    difficultyClassic: 'کلاسیک',
    difficultyBlitz: 'برق‌آسا',
    navPlay: 'بازی',
    navStats: 'آمار',
    navSettings: 'تنظیمات',
    toggleOn: 'روشن',
    toggleOff: 'خاموش',
    score: '۱٬۴۸۰',
    duration: '۱۸٫۶',
    tile: '۲۵',
  ),
  // Sorani. Every field uses at least one letter Persian does not have, so the
  // ckb contact sheet can show a font-fallback failure that the fa sheet
  // cannot.
  'ckb': SampleStrings(
    button: 'دەستپێکردن',
    chip: 'کاردانەوە',
    cardTitle: 'خێرایی ستروپ',
    cardSubtitle: 'ڕەنگەکە دابگرە، نەک وشەکە',
    hudLabel: 'خاڵ',
    difficultyChill: 'ئارام',
    difficultyClassic: 'کلاسیک',
    difficultyBlitz: 'خێرا',
    navPlay: 'یاری',
    navStats: 'ئامار',
    navSettings: 'ڕێکخستن',
    toggleOn: 'کارا',
    toggleOff: 'ناکارا',
    score: '۱٬۴۸۰',
    duration: '۱۸٫۶',
    tile: '۲۵',
  ),
};
