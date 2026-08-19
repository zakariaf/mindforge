import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
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
  /// shape as `AppLocalizations.of`. An unparseable tag falls back to `en`
  /// rather than throwing: `supportedLocales` cannot deliver one, so reaching
  /// the fallback would mean the delegate list was rewired — a visibly wrong
  /// language beats a crash in a number formatter.
  factory LocaleNumbers.of(BuildContext context) => LocaleNumbers(
    SupportedLocale.tryParse(Localizations.localeOf(context).languageCode) ??
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

  /// A percentage from a ratio in `[0.0, 1.0]`, with no fractional part.
  ///
  /// `0.92` renders `92%` in `en`. The percent sign is placed by the locale's
  /// own pattern, not concatenated — in `fa` it goes on the other side.
  String percent(double ratio) => NumberFormat.decimalPercentPattern(
    locale: _symbols,
    decimalDigits: 0,
  ).format(ratio);

  /// A duration in milliseconds as seconds with one decimal, e.g. `18.6`.
  ///
  /// The unit marker is **not** included: `unitMilliseconds` and the seconds
  /// suffix are separate ARB keys rendered as their own runs, because a value
  /// hand-glued to its unit is what breaks in RTL.
  String seconds(int milliseconds) => NumberFormat.decimalPatternDigits(
    locale: _symbols,
    decimalDigits: 1,
  ).format(milliseconds / 1000);

  /// A clock as `m:ss`, e.g. `0:23`, with digits in [locale]'s numbering
  /// system.
  ///
  /// The colon is a literal because it is a clock separator rather than a
  /// number, and both Persian and Sorani use it.
  String clock(int milliseconds) {
    final totalSeconds = milliseconds ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    final digits = NumberFormat.decimalPatternDigits(
      locale: _symbols,
      decimalDigits: 0,
    )..turnOffGrouping();

    return '${digits.format(minutes)}:'
        '${seconds < 10 ? digits.format(0) : ''}${digits.format(seconds)}';
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
  /// Used by tests and by any future import path that must refuse a value it
  /// cannot interpret rather than guessing.
  static bool hasNonAsciiDigits(String input) => input.runes.any(
    (rune) =>
        (rune >= _easternArabicZero && rune <= _easternArabicZero + 9) ||
        (rune >= _arabicIndicZero && rune <= _arabicIndicZero + 9),
  );
}
