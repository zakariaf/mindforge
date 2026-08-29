import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:mindforge/core/numeral_script.dart';
import 'package:mindforge/core/supported_locale.dart';

/// The **one** `NumberFormat` construction site in `lib/`.
///
/// Every score, clock, tile, percentage and duration in MindForge is formatted
/// through an instance of this class. `test/policy/canonical_storage_test.dart`
/// proves `NumberFormat` cannot be reached from `lib/data/` or `lib/core/`, and
/// `test/policy/number_format_sites_test.dart` proves it is not constructed
/// anywhere else in `lib/` either.
///
/// **It is bound to a locale rather than taking one per call.** A Schulte board
/// formats twenty-five tiles in one paint and a HUD formats a clock every
/// frame; threading the locale through each call is twenty-five chances to
/// thread the wrong one. Widgets get an instance from [LocaleNumbers.of], code
/// with no `BuildContext` gets one from `localeNumbersProvider` in
/// `l10n_providers.dart`, and neither picks a locale of its own.
///
/// **The numbering system is pinned per locale, explicitly.** That is not
/// belt-and-braces: measured on `intl` 0.20.2, both
/// `NumberFormat.decimalPattern('ckb')` and the ambient-locale form **throw**
/// `ArgumentError: Invalid locale "ckb"`. Without the pin, any number formatted
/// under Sorani would crash the app.
@immutable
final class LocaleNumbers {
  /// Formats numbers for [locale].
  const LocaleNumbers(this.locale);

  /// The formatter for the locale [context] resolved to.
  ///
  /// The widget-tier counterpart of `localeNumbersProvider`, and the same
  /// shape as `AppLocalizations.of`. An unparseable tag — or **no
  /// `Localizations` ancestor at all**, which is how a component test that
  /// pumps a widget bare reaches this — falls back to `en` rather than
  /// throwing: `supportedLocales` cannot deliver one, so reaching
  /// the fallback would mean the delegate list was rewired — a visibly wrong
  /// language beats a crash in a number formatter.
  factory LocaleNumbers.of(BuildContext context) => LocaleNumbers(
    SupportedLocale.tryParse(
          Localizations.maybeLocaleOf(context)?.languageCode ?? '',
        ) ??
        SupportedLocale.en,
  );

  /// The locale every method here formats for.
  final SupportedLocale locale;

  /// The locale whose CLDR symbol data actually formats [locale].
  ///
  /// `ckb` borrows `fa` because `intl` ships no Sorani symbols. `fa` and not
  /// `ar`: CLDR's Arabic default is **Latin** digits, so borrowing `ar` would
  /// produce exactly the bug being avoided.
  static String symbolLocaleFor(SupportedLocale locale) => switch (locale) {
    SupportedLocale.en => 'en',
    SupportedLocale.de => 'de',
    SupportedLocale.fa => 'fa',
    SupportedLocale.ckb => 'fa',
  };

  String get _symbols => symbolLocaleFor(locale);

  /// A whole number, grouped for [locale].
  ///
  /// `1480` renders `1,480` in `en`, `1.480` in `de`, and `۱٬۴۸۰` in both `fa`
  /// and `ckb` — Eastern Arabic digits U+06F0–U+06F9 with the U+066C group
  /// separator.
  String count(int value) =>
      NumberFormat.decimalPattern(_symbols).format(value);

  /// A whole number as an **ungrouped** run of digits in [locale]'s script.
  ///
  /// `4723` renders `4723` in `en` and `۴۷۲۳` in `fa` — the same digits
  /// [count] would use, without the group separator.
  ///
  /// **Not a stylistic variant of [count].** A grouped numeral is two things to
  /// read, and Digit Bridge asks a player to match one numeral against six
  /// candidates at speed: the separator carries no information and is a second
  /// glyph to reject. It is also the wrong shape for the question — `4,723`
  /// against `۴٬۷۲۳` invites a comparison of separators rather than of digits.
  ///
  /// Use [count] for a score, a total or anything a reader parses as a
  /// quantity; use this for a numeral that IS the content.
  String digits(int value) => _ungrouped(_symbols).format(value);

  /// A whole number as an ungrouped run in [script], whatever [locale] is.
  ///
  /// **The one place in MindForge where a numeral's script is not the reader's,
  /// and the exception is deliberate.** Working agreement 12 resolves numerals
  /// from the locale at render, which is right for every surface that shows a
  /// value. Digit Bridge shows the same value in two systems and asks which
  /// candidate matches: if both sides took the locale's answer they would
  /// render identically and the board would have no question on it.
  ///
  /// The exception is to **which** script renders, never to how one is
  /// constructed — this routes through the same pinned formatter every other
  /// method here uses, so there is still exactly one `NumberFormat` site in
  /// `lib/`, which `test/policy/number_format_sites_test.dart` proves.
  ///
  /// It is scoped to the board's two numeral runs. The HUD, the score, the
  /// results and the BEST pill all keep taking [digits] and [count].
  String digitsInScript(int value, NumeralScript script) =>
      _ungrouped(_scriptSymbols(script)).format(value);

  /// The symbol locale whose CLDR data renders [script].
  ///
  /// `fa` rather than `ar` for Eastern Arabic, for the reason
  /// [symbolLocaleFor] already records: CLDR's Arabic default is **Latin**
  /// digits, so borrowing `ar` would render the wrong side of the bridge.
  static String _scriptSymbols(NumeralScript script) => switch (script) {
    NumeralScript.latin => 'en',
    NumeralScript.easternArabic => 'fa',
  };

  /// A digits-only formatter for `symbols`, with grouping off.
  ///
  /// The construction [clock] already used, extracted so the two cannot drift:
  /// a clock and a bridge numeral are both runs of digits with no separator.
  ///
  /// **Memoised, because these are built on a hot path.** `NumberFormat` is
  /// immutable once `turnOffGrouping` has run, and constructing one measures
  /// 1.10us against 0.75us to format with it — so the construction was the
  /// larger half of the cost. The HUD's clock builds one per frame at 10Hz, and
  /// a Digit Bridge board builds seven per frame (a target and six chips),
  /// which is what made this worth a cache rather than a comment.
  ///
  /// The map is bounded at two entries by construction: [symbolLocaleFor] maps
  /// four locales onto `en`, `de` and `fa`, and [_scriptSymbols] onto `en` and
  /// `fa`. There is nothing to evict.
  static final Map<String, NumberFormat> _ungroupedCache =
      <String, NumberFormat>{};

  static NumberFormat _ungrouped(String symbols) =>
      _ungroupedCache[symbols] ??= NumberFormat.decimalPatternDigits(
        locale: symbols,
        decimalDigits: 0,
      )..turnOffGrouping();

  /// A percentage from a ratio in `[0.0, 1.0]`, with no fractional part.
  ///
  /// `0.92` renders `92%` in `en`. The percent sign is placed by the locale's
  /// own pattern, not concatenated — in `fa` it goes on the other side.
  ///
  /// **Truncated, not rounded, and clamped.** Rounding made 199 correct out of
  /// 200 render `100%`, which sits directly beside `newPersonalBest` on the
  /// results screen: a run that dropped one reading as perfect is a
  /// credibility bug, not a rounding nicety. The clamp covers a ratio computed
  /// from a zero denominator, which is `NaN` and rendered as `NaN` / `ناعدد`.
  String percent(double ratio) {
    final safe = ratio.isNaN ? 0.0 : ratio.clamp(0.0, 1.0);

    return NumberFormat.decimalPercentPattern(
      locale: _symbols,
      decimalDigits: 0,
    ).format(_truncate(safe * 100, 0) / 100);
  }

  /// A duration in milliseconds as seconds with one decimal, e.g. `18.6`.
  ///
  /// The unit marker is **not** included: `unitMilliseconds` and the seconds
  /// suffix are separate ARB keys rendered as their own runs, because a value
  /// hand-glued to its unit is what breaks in RTL.
  ///
  /// **Truncated like [clock], and floored at zero like it.** These two are the
  /// same duration shown two ways, and they used to disagree: `seconds` rounded
  /// while `clock` floored, so a Blitz round ending at 59,999 ms read `0:59` on
  /// the play HUD and `60.0` on the results card, for one run.
  String seconds(int milliseconds) => NumberFormat.decimalPatternDigits(
    locale: _symbols,
    decimalDigits: 1,
  ).format(_truncate(_atLeastZero(milliseconds) / 1000, 1));

  /// A clock as `m:ss`, e.g. `0:23`, with digits in [locale]'s numbering
  /// system.
  ///
  /// The colon is a literal because it is a clock separator rather than a
  /// number, and both Persian and Sorani use it.
  /// **Floored at zero.** `~/` truncates toward zero while `%` is Euclidean and
  /// never negative, so the two disagreed for a negative input and
  /// `clock(-1500)` rendered `0:59` — a timer appearing to GAIN A MINUTE at the
  /// moment the round ended. E06's HUD computes `limit - elapsed` off the
  /// injected `Clock`, and any frame landing after the deadline but before
  /// `RunNotifier` flips to `over` passes a small negative.
  String clock(int milliseconds) {
    final totalSeconds = _atLeastZero(milliseconds) ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    final digits = _ungrouped(_symbols);

    return '${digits.format(minutes)}:'
        '${seconds < 10 ? digits.format(0) : ''}${digits.format(seconds)}';
  }

  /// Reads a number back that this locale's formatter produced.
  ///
  /// The inverse of [count], and the **only** parse path — it is locale-aware
  /// because the separators are: `1.480` is one thousand four hundred and
  /// eighty in `de` and one-point-four-eight in `en`, so a locale-blind
  /// converter cannot be written. It handles the Eastern Arabic digits, the
  /// `U+066C` grouping separator, and the `U+200E U+2212` prefix `intl` gives a
  /// negative under `fa` and `ckb`.
  ///
  /// Throws `FormatException` on input this locale did not produce, which is
  /// the right failure for a value that should never have reached it.
  num parse(String formatted) =>
      NumberFormat.decimalPattern(_symbols).parse(formatted);

  /// A duration never runs backwards on screen.
  static int _atLeastZero(int milliseconds) =>
      milliseconds < 0 ? 0 : milliseconds;

  /// [value] truncated to [digits] decimal places, toward zero.
  static double _truncate(double value, int digits) {
    final scale = math.pow(10, digits);

    return (value * scale).truncateToDouble() / scale;
  }

  @override
  bool operator ==(Object other) =>
      other is LocaleNumbers && other.locale == locale;

  @override
  int get hashCode => locale.hashCode;

  @override
  String toString() => 'LocaleNumbers(${locale.tag})';
}

/// Converts any localized digits back to ASCII.
///
/// **Normalise through here before any parse, comparison or write.** Working
/// agreement 12: the store holds ASCII, and a value that has been through a
/// formatter and back is otherwise a string SQLite will happily accept and
/// nothing can read.
abstract final class AsciiNumerals {
  /// Eastern Arabic digits, U+06F0–U+06F9. What `fa` and `ckb` render.
  static const int _easternArabicZero = 0x06F0;

  /// Arabic-Indic digits, U+0660–U+0669.
  ///
  /// MindForge never *renders* these — their 4, 5 and 6 are different glyphs
  /// from the Eastern Arabic ones — but a value pasted in from elsewhere, or
  /// typed on an Arabic keyboard, can carry them. Normalising them costs one
  /// branch and prevents a parse failure nobody could diagnose from the log.
  static const int _arabicIndicZero = 0x0660;

  /// [input] with every localized digit replaced by its ASCII equivalent.
  ///
  /// Non-digit characters pass through untouched, so a grouped or decimal-
  /// separated string keeps its separators — strip those separately if the
  /// parse needs to.
  static String normalize(String input) {
    final buffer = StringBuffer();

    for (final rune in input.runes) {
      if (rune >= _easternArabicZero && rune <= _easternArabicZero + 9) {
        buffer.writeCharCode(0x30 + (rune - _easternArabicZero));
      } else if (rune >= _arabicIndicZero && rune <= _arabicIndicZero + 9) {
        buffer.writeCharCode(0x30 + (rune - _arabicIndicZero));
      } else {
        buffer.writeCharCode(rune);
      }
    }

    return buffer.toString();
  }

  /// Whether [input] contains any digit outside ASCII `0`–`9`.
  ///
  /// Answers exactly that and nothing more — a separator or a sign is not a
  /// digit, so `1٬480` is `false` here, and [normalize]'s output is **not**
  /// parseable. To read a formatted number back, use `LocaleNumbers.parse`,
  /// which knows the locale: stripping every non-digit instead looks right and
  /// silently drops the sign, because under `fa` a negative is `U+200E U+2212`
  /// and not an ASCII hyphen.
  static bool hasNonAsciiDigits(String input) => input.runes.any(
    (rune) =>
        (rune >= _easternArabicZero && rune <= _easternArabicZero + 9) ||
        (rune >= _arabicIndicZero && rune <= _arabicIndicZero + 9),
  );
}
