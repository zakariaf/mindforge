import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/number_symbols_data.dart' show numberFormatSymbols;

/// Proves the reason `LocaleNumbers` pins `ckb` to `fa`, rather than asserting
/// it in a comment.
void main() {
  group('intl has no ckb number symbols', () {
    test('and it THROWS rather than falling back', () {
      expect(numberFormatSymbols.containsKey('ckb'), isFalse);

      // Measured 2026-08-19, and it corrects the plan's stated risk. The
      // expectation was a SILENT fallback to Latin digits; what actually
      // happens is an ArgumentError. That is louder and worse: any number
      // formatted under Sorani would crash the app, not merely render 1480
      // where ۱٬۴۸۰ belongs.
      //
      // The fix is the same either way — pin ckb to fa's symbols — but it is
      // now load-bearing against a crash rather than against wrong glyphs.
      expect(
        () => NumberFormat.decimalPattern('ckb'),
        throwsArgumentError,
        reason:
            'if a future intl adds ckb symbols this goes red and the pin '
            'in LocaleNumbers gets revisited on purpose',
      );
    });

    test('including through the ambient locale, not just an explicit one', () {
      // The realistic path: the app sets Intl.defaultLocale and formats. It
      // throws there too, so there is no accidental escape.
      final previous = Intl.defaultLocale;
      Intl.defaultLocale = 'ckb';
      addTearDown(() => Intl.defaultLocale = previous);

      expect(NumberFormat.decimalPattern, throwsArgumentError);
    });
  });

  group('fa is the right donor and ar is not', () {
    test('fa formats Eastern Arabic digits', () {
      expect(NumberFormat.decimalPattern('fa').format(1480), '۱٬۴۸۰');
    });

    test('ar formats LATIN digits, so borrowing ar would not help', () {
      expect(
        NumberFormat.decimalPattern('ar').format(1480),
        '1,480',
        reason:
            "CLDR's ar default is Latin digits. Borrowing ar would produce "
            'exactly the bug the pin exists to avoid, which is why ADR 0002 '
            'names fa and rules ar out explicitly',
      );
    });

    test('fa uses the Eastern Arabic block, not the Arabic-Indic one', () {
      final symbols = numberFormatSymbols['fa']!;

      // U+06F0, NOT U+0660: the Arabic-Indic 4, 5 and 6 are different glyphs
      // from the ones Persian and Sorani readers expect.
      expect(symbols.ZERO_DIGIT.codeUnitAt(0), 0x06F0);
      expect(symbols.DECIMAL_SEP.codeUnitAt(0), 0x066B);
      expect(symbols.GROUP_SEP.codeUnitAt(0), 0x066C);
    });
  });
}
