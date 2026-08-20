import 'package:flutter/material.dart';
import 'package:mindforge/core/supported_locale.dart';

/// One locale, with everything a test needs to name it and check it.
///
/// `LocaleCase.all` is **the** locale matrix for widget-tier tests, and it is a
/// projection of [SupportedLocale] rather than a second list — the same rule
/// `lib/l10n/supported_locales.dart` follows on the production side and
/// `test/support/locale_matrix.dart` follows for the data suite.
@immutable
final class LocaleCase {
  /// Builds a case for [locale].
  const LocaleCase(this.locale);

  /// The locale this case covers.
  final SupportedLocale locale;

  /// The BCP-47 tag, e.g. `ckb`.
  String get tag => locale.tag;

  /// The Flutter locale to pump with.
  Locale get flutterLocale => Locale(locale.tag);

  /// The direction this locale must resolve to.
  ///
  /// Asserted rather than assumed by every direction-sensitive test: it is the
  /// expectation, not an input.
  TextDirection get direction =>
      locale.isRightToLeft ? TextDirection.rtl : TextDirection.ltr;

  /// Whether this locale renders Eastern Arabic numerals.
  bool get usesEasternArabicNumerals => locale.isRightToLeft;

  /// Every shipped locale, in enum order.
  static final List<LocaleCase> all = SupportedLocale.values
      .map(LocaleCase.new)
      .toList(growable: false);

  /// The two right-to-left locales.
  static final List<LocaleCase> rightToLeft = all
      .where((c) => c.locale.isRightToLeft)
      .toList(growable: false);

  /// English, the template locale.
  static const LocaleCase english = LocaleCase(SupportedLocale.en);

  /// German, the text-expansion stress case.
  static const LocaleCase german = LocaleCase(SupportedLocale.de);

  /// Persian, the right-to-left case.
  static const LocaleCase persian = LocaleCase(SupportedLocale.fa);

  /// Sorani, the case with letters no other shipped locale has.
  static const LocaleCase sorani = LocaleCase(SupportedLocale.ckb);

  /// The pair every golden lane runs: one direction each.
  ///
  /// Named because the two-element literal spelling it out was written four
  /// times in one file.
  static const List<LocaleCase> bothDirections = <LocaleCase>[english, persian];

  @override
  String toString() => 'LocaleCase(${locale.tag})';
}
