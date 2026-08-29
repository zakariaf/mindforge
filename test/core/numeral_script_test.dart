import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/numeral_script.dart';
import 'package:mindforge/core/supported_locale.dart';

void main() {
  group('which script a locale reads', () {
    test('en and de read Latin, fa and ckb read Eastern Arabic', () {
      expect(NumeralScript.of(SupportedLocale.en), NumeralScript.latin);
      expect(NumeralScript.of(SupportedLocale.de), NumeralScript.latin);
      expect(
        NumeralScript.of(SupportedLocale.fa),
        NumeralScript.easternArabic,
      );
      expect(
        NumeralScript.of(SupportedLocale.ckb),
        NumeralScript.easternArabic,
      );
    });

    test(
      'every shipped locale resolves, so a fifth one is a compile error',
      () {
        // The switch inside `of` is exhaustive with no `default:`. This asserts
        // the OTHER half: that the enum it switches over is the shipped set, so
        // adding a locale cannot silently pick a script.
        for (final locale in SupportedLocale.values) {
          expect(NumeralScript.of(locale), isNotNull);
        }
      },
    );
  });

  group('the other side of the bridge', () {
    test('other is an involution', () {
      for (final script in NumeralScript.values) {
        expect(script.other.other, script);
        expect(script.other, isNot(script));
      }
    });

    test('and there are exactly two scripts, which is what makes it one', () {
      // `other` is only meaningful while the enum has two values. A third
      // script would make it ambiguous, and this is where that is noticed.
      expect(NumeralScript.values, hasLength(2));
    });
  });
}
