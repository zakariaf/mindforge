import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/l10n/locale_numbers.dart';

void main() {
  group('the numbering system is pinned per locale', () {
    test('ckb borrows fa, and every other locale is itself', () {
      expect(LocaleNumbers.symbolLocaleFor(SupportedLocale.en), 'en');
      expect(LocaleNumbers.symbolLocaleFor(SupportedLocale.de), 'de');
      expect(LocaleNumbers.symbolLocaleFor(SupportedLocale.fa), 'fa');
      expect(
        LocaleNumbers.symbolLocaleFor(SupportedLocale.ckb),
        'fa',
        reason:
            'intl ships no ckb symbols and THROWS on the tag. fa and not '
            "ar: CLDR's Arabic default is Latin digits",
      );
    });
  });

  group('count', () {
    test('groups 1480 the way each locale does', () {
      expect(const LocaleNumbers(SupportedLocale.en).count(1480), '1,480');
      expect(const LocaleNumbers(SupportedLocale.de).count(1480), '1.480');
      expect(const LocaleNumbers(SupportedLocale.fa).count(1480), '۱٬۴۸۰');
      expect(
        const LocaleNumbers(SupportedLocale.ckb).count(1480),
        '۱٬۴۸۰',
        reason: 'Sorani renders the same Eastern Arabic digits as Persian',
      );
    });

    test('the RTL locales use the EASTERN block, not Arabic-Indic', () {
      // U+06F0-U+06F9, never U+0660-U+0669: the Arabic-Indic 4, 5 and 6 are
      // different glyphs from the ones Persian and Sorani readers expect.
      for (final locale in <SupportedLocale>[
        SupportedLocale.fa,
        SupportedLocale.ckb,
      ]) {
        final rendered = LocaleNumbers(locale).count(4560);

        for (final rune in rendered.runes) {
          final isArabicIndic = rune >= 0x0660 && rune <= 0x0669;
          expect(
            isArabicIndic,
            isFalse,
            reason: '$locale rendered U+${rune.toRadixString(16)}',
          );
        }
        expect(rendered.runes.first, greaterThanOrEqualTo(0x06F0));
      }
    });

    test('the Schulte range renders as tiles a player can read', () {
      // The tiles ARE the numbers, so this is the game, not decoration.
      expect(
        List.generate(
          5,
          (i) => const LocaleNumbers(SupportedLocale.fa).count(i + 21),
        ),
        <String>['۲۱', '۲۲', '۲۳', '۲۴', '۲۵'],
      );
    });
  });

  group('percent', () {
    test('places the sign by the locale pattern, never by concatenation', () {
      expect(const LocaleNumbers(SupportedLocale.en).percent(0.92), '92%');

      // German puts a NON-BREAKING space (U+00A0) before the sign, not a plain
      // one. Asserting the codepoint rather than eyeballing the string is the
      // point: a hand-concatenated '92' + '%' would produce neither, and would
      // also let the number wrap away from its sign at a line break.
      expect(
        const LocaleNumbers(SupportedLocale.de).percent(0.92),
        '92\u00A0%',
      );
      expect(
        const LocaleNumbers(SupportedLocale.fa).percent(0.92),
        contains('۹۲'),
        reason: 'the digits are Eastern Arabic; the sign placement is CLDRs',
      );
    });
  });

  group('seconds and clock', () {
    test('seconds renders one decimal with no unit glued on', () {
      expect(const LocaleNumbers(SupportedLocale.en).seconds(18600), '18.6');
      expect(const LocaleNumbers(SupportedLocale.de).seconds(18600), '18,6');
      expect(const LocaleNumbers(SupportedLocale.fa).seconds(18600), '۱۸٫۶');
    });

    test('clock pads the seconds and localises the digits', () {
      expect(const LocaleNumbers(SupportedLocale.en).clock(23000), '0:23');
      expect(const LocaleNumbers(SupportedLocale.en).clock(65000), '1:05');
      expect(const LocaleNumbers(SupportedLocale.fa).clock(23000), '۰:۲۳');
      expect(const LocaleNumbers(SupportedLocale.ckb).clock(65000), '۱:۰۵');
    });

    test('clock does not group the minutes', () {
      // A 100-minute run must read 100:00, not 1,00:00.
      expect(const LocaleNumbers(SupportedLocale.en).clock(6000000), '100:00');
      expect(const LocaleNumbers(SupportedLocale.fa).clock(6000000), '۱۰۰:۰۰');
    });
  });

  group('AsciiNumerals.normalize', () {
    test('converts Eastern Arabic digits back to ASCII', () {
      expect(AsciiNumerals.normalize('۱۴۸۰'), '1480');
    });

    test('converts Arabic-Indic digits too', () {
      // Never rendered by MindForge, but a pasted or keyboard-typed value can
      // carry them, and a parse failure from those is undiagnosable from a log.
      expect(AsciiNumerals.normalize('١٤٨٠'), '1480');
    });

    test('leaves everything else untouched', () {
      expect(AsciiNumerals.normalize('۱٬۴۸۰'), '1٬480');
      expect(AsciiNumerals.normalize('stroop_rush'), 'stroop_rush');
      expect(AsciiNumerals.normalize(''), '');
    });

    test('leaves every separator in place, which is why it cannot parse', () {
      // Stated as a property rather than demonstrated with a strip-and-parse
      // recipe. The recipe that used to live here — normalize, then remove
      // every non-digit — passes for these five values and SILENTLY DROPS THE
      // SIGN on a negative, because under fa the minus is U+2212 and not an
      // ASCII hyphen. LocaleNumbers.parse is the round trip; see its group.
      for (final locale in SupportedLocale.values) {
        final rendered = LocaleNumbers(locale).count(1480);
        final normalized = AsciiNumerals.normalize(rendered);

        expect(
          RegExp('[0-9]').allMatches(normalized).length,
          4,
          reason: '$locale rendered "$rendered"',
        );
        expect(
          normalized.length,
          rendered.length,
          reason: 'normalize converts digits and changes nothing else',
        );
      }
    });
  });

  group('hasNonAsciiDigits', () {
    test('is true for a rendered RTL value and false for a stored one', () {
      expect(AsciiNumerals.hasNonAsciiDigits('۱۴۸۰'), isTrue);
      expect(AsciiNumerals.hasNonAsciiDigits('1480'), isFalse);
      expect(AsciiNumerals.hasNonAsciiDigits('stroop_rush'), isFalse);
    });
  });

  group('the edges a run timer actually reaches', () {
    // Every one of these was measured wrong before the fix beside it.
    test('a negative duration reads zero, not most of a minute', () {
      // -1500 ~/ 1000 is -1 (truncates toward zero) while -1 % 60 is 59
      // (Dart's remainder is Euclidean and never negative), so the two
      // disagreed and clock(-1500) rendered "0:59". E06's HUD computes
      // limit - elapsed off the injected Clock; any frame landing after the
      // deadline but before RunNotifier flips to `over` — a resume from
      // background, a dropped frame, a GC pause — passes a small negative, and
      // the timer APPEARED TO GAIN A MINUTE at the moment the round ended.
      for (final locale in SupportedLocale.values) {
        final numbers = LocaleNumbers(locale);

        expect(numbers.clock(-1500), numbers.clock(0), reason: '$locale');
        expect(numbers.clock(-60000), numbers.clock(0), reason: '$locale');
        expect(numbers.seconds(-500), numbers.seconds(0), reason: '$locale');
      }
    });

    test('clock and seconds never disagree about the same duration', () {
      // clock floored and seconds ROUNDED, so a Blitz round ending at 59,999 ms
      // showed 0:59 on the play HUD and 60.0 s on the results card, for one
      // run. A stopwatch truncates; both do now.
      const numbers = LocaleNumbers(SupportedLocale.en);

      expect(numbers.seconds(59999), '59.9');
      expect(numbers.clock(59999), '0:59');
      expect(numbers.seconds(999), '0.9');
      expect(numbers.clock(999), '0:00');
      expect(numbers.seconds(18600), '18.6');
    });

    test('an accuracy just short of perfect does not read 100%', () {
      // decimalDigits: 0 ROUNDED, so 199 of 200 correct rendered "100%" —
      // beside newPersonalBest, which is a credibility bug rather than a
      // rounding nicety. It truncates now.
      const numbers = LocaleNumbers(SupportedLocale.en);

      expect(numbers.percent(0.996), '99%');
      expect(numbers.percent(1), '100%');
      expect(numbers.percent(0), '0%');
      expect(numbers.percent(0.005), '0%');
    });

    test('a ratio outside 0..1 is clamped rather than rendered', () {
      const numbers = LocaleNumbers(SupportedLocale.en);

      expect(numbers.percent(1.5), '100%');
      expect(numbers.percent(-0.2), '0%');
      expect(numbers.percent(double.nan), '0%');
      expect(numbers.percent(double.infinity), '100%');
    });
  });

  group('LocaleNumbers.parse', () {
    test('reads back every value count formats, sign included', () {
      // normalize() converts DIGITS only, by design — separators pass through
      // so a grouped string keeps its shape. That makes its output unsuitable
      // for int.parse, and the obvious follow-up (strip every non-digit) is
      // worse: under fa, count(-1480) is LRM + U+2212 MINUS + digits, so
      // stripping non-digits turns -1480 into 1480. This file used to
      // demonstrate exactly that recipe.
      //
      // The inverse has to be locale-aware, because the separators are: 1.480
      // is one thousand four hundred and eighty in de and one-point-four-eight
      // in en.
      for (final locale in SupportedLocale.values) {
        final numbers = LocaleNumbers(locale);

        for (final value in <int>[0, 7, 25, 1480, 9999, -1480, -7]) {
          expect(
            numbers.parse(numbers.count(value)),
            value,
            reason: '$locale round trip of $value',
          );
        }
      }
    });

    test('and refuses a value this locale did not produce', () {
      expect(
        () => const LocaleNumbers(SupportedLocale.en).parse('۱٬۴۸۰'),
        throwsFormatException,
      );
    });
  });
}
