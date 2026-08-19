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
      expect(LocaleNumbers.count(1480, SupportedLocale.en), '1,480');
      expect(LocaleNumbers.count(1480, SupportedLocale.de), '1.480');
      expect(LocaleNumbers.count(1480, SupportedLocale.fa), '۱٬۴۸۰');
      expect(
        LocaleNumbers.count(1480, SupportedLocale.ckb),
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
        final rendered = LocaleNumbers.count(4560, locale);

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
          (i) => LocaleNumbers.count(i + 21, SupportedLocale.fa),
        ),
        <String>['۲۱', '۲۲', '۲۳', '۲۴', '۲۵'],
      );
    });
  });

  group('percent', () {
    test('places the sign by the locale pattern, never by concatenation', () {
      expect(LocaleNumbers.percent(0.92, SupportedLocale.en), '92%');

      // German puts a NON-BREAKING space (U+00A0) before the sign, not a plain
      // one. Asserting the codepoint rather than eyeballing the string is the
      // point: a hand-concatenated '92' + '%' would produce neither, and would
      // also let the number wrap away from its sign at a line break.
      expect(
        LocaleNumbers.percent(0.92, SupportedLocale.de),
        '92\u00A0%',
      );
      expect(
        LocaleNumbers.percent(0.92, SupportedLocale.fa),
        contains('۹۲'),
        reason: 'the digits are Eastern Arabic; the sign placement is CLDRs',
      );
    });
  });

  group('seconds and clock', () {
    test('seconds renders one decimal with no unit glued on', () {
      expect(LocaleNumbers.seconds(18600, SupportedLocale.en), '18.6');
      expect(LocaleNumbers.seconds(18600, SupportedLocale.de), '18,6');
      expect(LocaleNumbers.seconds(18600, SupportedLocale.fa), '۱۸٫۶');
    });

    test('clock pads the seconds and localises the digits', () {
      expect(LocaleNumbers.clock(23000, SupportedLocale.en), '0:23');
      expect(LocaleNumbers.clock(65000, SupportedLocale.en), '1:05');
      expect(LocaleNumbers.clock(23000, SupportedLocale.fa), '۰:۲۳');
      expect(LocaleNumbers.clock(65000, SupportedLocale.ckb), '۱:۰۵');
    });

    test('clock does not group the minutes', () {
      // A 100-minute run must read 100:00, not 1,00:00.
      expect(LocaleNumbers.clock(6000000, SupportedLocale.en), '100:00');
      expect(LocaleNumbers.clock(6000000, SupportedLocale.fa), '۱۰۰:۰۰');
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

    test('round-trips every formatted count back to the stored integer', () {
      // The invariant working agreement 12 states: a value that has been
      // through a formatter and back must equal what the store holds.
      for (final value in <int>[0, 7, 25, 1480, 9999]) {
        for (final locale in SupportedLocale.values) {
          final rendered = LocaleNumbers.count(value, locale);
          final normalized = AsciiNumerals.normalize(
            rendered,
          ).replaceAll(RegExp('[^0-9]'), '');

          expect(
            int.parse(normalized),
            value,
            reason: '$value under $locale rendered "$rendered"',
          );
        }
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
}
