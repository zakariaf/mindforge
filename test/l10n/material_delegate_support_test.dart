import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/number_symbols_data.dart' show numberFormatSymbols;

/// Characterization tests carrying the two measurements ADR 0001 records.
///
/// Every expectation below is written **from an observed run** on Flutter
/// 3.44.6 / intl 0.20.2 on 2026-08-19, not from a reference document. They
/// exist so that a future SDK closing either gap turns the E04 workaround red
/// instead of letting it rot in place.
void main() {
  group('measurement 1 — ckb in flutter_localizations', () {
    test('kMaterialSupportedLanguages lists 82 codes and ckb is not one', () {
      expect(kMaterialSupportedLanguages, hasLength(82));
      expect(
        kMaterialSupportedLanguages,
        containsAll(['en', 'de', 'fa', 'ar']),
      );
      expect(
        kMaterialSupportedLanguages.contains('ckb'),
        isFalse,
        reason:
            'if this ever becomes true, flutter_localizations now serves '
            'Sorani and E04 T04.4 vendored delegate trio should be deleted '
            'rather than maintained',
      );
    });

    test('all three Global delegates support en, de and fa but not ckb', () {
      const delegates = <String, LocalizationsDelegate<Object>>{
        'material': GlobalMaterialLocalizations.delegate,
        'cupertino': GlobalCupertinoLocalizations.delegate,
        'widgets': GlobalWidgetsLocalizations.delegate,
      };

      for (final entry in delegates.entries) {
        for (final code in <String>['en', 'de', 'fa', 'ar']) {
          expect(
            entry.value.isSupported(Locale(code)),
            isTrue,
            reason: '${entry.key} unexpectedly dropped $code',
          );
        }
        expect(
          entry.value.isSupported(const Locale('ckb')),
          isFalse,
          reason:
              'measured: ${entry.key} does not serve ckb, so switching to '
              'Sorani without a vendored delegate throws',
        );
      }
    });

    test(
      'DefaultWidgetsLocalizations claims every locale and is always LTR',
      () async {
        // This is the SILENT half, and it is worth naming precisely: it is
        // DefaultWidgetsLocalizations — WidgetsApp's built-in fallback — not
        // GlobalWidgetsLocalizations, that returns true for everything.
        // GlobalWidgetsLocalizations correctly reports ckb as unsupported.
        //
        // So fixing only the Material half leaves a Sorani build that runs fine
        // and reads backwards: the fallback accepts ckb and hands back a
        // hardcoded TextDirection.ltr. E04 must vendor a Widgets delegate too,
        // not only a Material one.
        for (final code in <String>['en', 'fa', 'ckb', 'zz']) {
          final locale = Locale(code);
          expect(
            DefaultWidgetsLocalizations.delegate.isSupported(locale),
            isTrue,
            reason:
                'the fallback accepts anything, including the nonsense code '
                'zz — so "it resolved" proves nothing about direction',
          );

          final loaded = await DefaultWidgetsLocalizations.delegate.load(
            locale,
          );
          expect(
            loaded.textDirection,
            TextDirection.ltr,
            reason: 'measured: hardcoded LTR even for fa, which is RTL',
          );
        }
      },
    );
  });

  group('measurement 2 — ckb in intl number symbols', () {
    test('intl 0.20.2 ships symbols for en, de, fa and ar but not ckb', () {
      for (final code in <String>['en', 'de', 'fa', 'ar']) {
        expect(numberFormatSymbols.containsKey(code), isTrue);
      }
      expect(
        numberFormatSymbols.containsKey('ckb'),
        isFalse,
        reason:
            'with no entry, a NumberFormat for ckb falls back to Latin '
            'digits SILENTLY. A Sorani UI full of 1480 reads as untranslated, '
            'not as a cosmetic slip. E04 pins ckb to fa symbol data',
      );
    });

    test("fa's symbols are the Eastern Arabic block CLAUDE.md mandates", () {
      final fa = numberFormatSymbols['fa']!;

      // U+06F0, NOT the Arabic-Indic block U+0660, whose 4, 5 and 6 are
      // different glyphs. This is what makes fa a safe donor for ckb.
      expect(fa.ZERO_DIGIT, '۰');
      expect(fa.DECIMAL_SEP, '٫');
      expect(fa.GROUP_SEP, '٬');
    });
  });
}
