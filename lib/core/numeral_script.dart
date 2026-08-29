import 'package:mindforge/core/supported_locale.dart';

/// Which of the two numeral systems MindForge renders a run of digits in.
///
/// The app ships four locales across exactly two numeral systems: `en` and `de`
/// render Latin `0123456789`, `fa` and `ckb` render Eastern Arabic
/// `۰۱۲۳۴۵۶۷۸۹` (U+06F0–U+06F9). Working agreement 12 makes that a property of
/// the locale, resolved at render and never stored.
///
/// **This enum exists because one board needs to say it out loud.** Digit
/// Bridge shows the same number in two systems at once and asks which
/// candidate matches, so its two halves cannot both take the locale's answer —
/// if they did, both sides would render identically and there would be no
/// question. The round names a script per side; every other surface in the app
/// keeps taking [NumeralScript.of].
///
/// It lives in `lib/core/` rather than beside the game because
/// `LocaleNumbers` has to accept one, and `lib/games/**` may not be imported
/// from `lib/l10n/**`.
enum NumeralScript {
  /// `0123456789`. What `en` and `de` render.
  latin,

  /// `۰۱۲۳۴۵۶۷۸۹`, U+06F0–U+06F9. What `fa` and `ckb` render.
  ///
  /// **Not** the Arabic-Indic block U+0660–U+0669: its 4, 5 and 6 are
  /// different glyphs, and shipping them to a Persian reader is a defect
  /// rather than a near miss.
  easternArabic;

  /// The script [locale] reads.
  ///
  /// Exhaustive with no `default:`, so a fifth shipped locale is a compile
  /// error here rather than a silent Latin fallback — which is exactly the
  /// failure `intl` produces for `ckb` on its own.
  static NumeralScript of(SupportedLocale locale) => switch (locale) {
    SupportedLocale.en || SupportedLocale.de => latin,
    SupportedLocale.fa || SupportedLocale.ckb => easternArabic,
  };

  /// The other side of the bridge.
  ///
  /// Meaningful only while there are exactly two scripts, which
  /// `numeral_script_test.dart` asserts rather than assumes.
  NumeralScript get other => this == latin ? easternArabic : latin;
}
