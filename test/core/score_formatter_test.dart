import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/core/score_formatter.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/l10n/locale_numbers.dart';

import '../policy/support/source_text.dart';

/// Reads [milliseconds] back out of its rendered form, in [locale].
num _secondsOf(SupportedLocale locale, int milliseconds) {
  final numbers = LocaleNumbers(locale);
  final rendered = ScoreFormatter(
    formatPoints: numbers.count,
    formatSeconds: numbers.seconds,
    durationLabel: (seconds) => '${seconds}s',
  ).format(ScoreFormat.duration, milliseconds);

  return numbers.parse(rendered.substring(0, rendered.length - 1));
}

/// One parameterised table over the four shipped locales.
///
/// Not four copied bodies: a copied body is a body someone updates three of.
void main() {
  /// A formatter wired the way `scoreFormatterProvider` wires it.
  ScoreFormatter formatterFor(SupportedLocale locale) {
    final numbers = LocaleNumbers(locale);

    return ScoreFormatter(
      formatPoints: numbers.count,
      formatSeconds: numbers.seconds,
      durationLabel: (seconds) => '${seconds}s',
    );
  }

  group('points render with each locale grouping separator', () {
    const expected = <String, (String, String)>{
      // The English pair is transcribed from design/sunburst-pop/app.html.
      'en': ('1,480', '1,240'),
      'de': ('1.480', '1.240'),
      'fa': ('۱٬۴۸۰', '۱٬۲۴۰'),
      'ckb': ('۱٬۴۸۰', '۱٬۲۴۰'),
    };

    for (final locale in SupportedLocale.values) {
      test(locale.tag, () {
        final formatter = formatterFor(locale);
        final pair = expected[locale.tag]!;

        expect(formatter.format(ScoreFormat.points, 1480), pair.$1);
        expect(formatter.format(ScoreFormat.points, 1240), pair.$2);
      });
    }
  });

  group('the digit block', () {
    test('fa and ckb emit EXTENDED Arabic-Indic digits', () {
      // U+06F0-06F9, not U+0660-0669. Those are different blocks with
      // different glyphs for 4, 5 and 6, and `intl` ships no ckb number
      // symbols at all — it falls back to Latin silently, which is what this
      // assertion exists to catch. Without it ckb ships an untranslated-looking
      // UI and no other gate notices.
      for (final locale in <SupportedLocale>[
        SupportedLocale.fa,
        SupportedLocale.ckb,
      ]) {
        final rendered = formatterFor(locale).format(ScoreFormat.points, 1480);

        for (final rune in rendered.runes) {
          if (rune == 0x66C) continue; // the thousands separator

          expect(
            rune >= 0x6F0 && rune <= 0x6F9,
            isTrue,
            reason:
                '${locale.tag} rendered U+${rune.toRadixString(16)} in '
                '"$rendered"',
          );
        }
      }
    });

    test('and en and de emit Latin digits', () {
      for (final locale in <SupportedLocale>[
        SupportedLocale.en,
        SupportedLocale.de,
      ]) {
        final rendered = formatterFor(locale).format(ScoreFormat.points, 1480);

        for (final rune in rendered.runes) {
          if (rune == 0x2C || rune == 0x2E) continue; // the separator

          expect(rune >= 0x30 && rune <= 0x39, isTrue, reason: locale.tag);
        }
      }
    });
  });

  group('a duration', () {
    test('renders one decimal in each locale separator', () {
      const expected = <String, String>{
        'en': '18.6s',
        'de': '18,6s',
        'fa': '۱۸٫۶s',
        'ckb': '۱۸٫۶s',
      };

      for (final locale in SupportedLocale.values) {
        expect(
          formatterFor(locale).format(ScoreFormat.duration, 18600),
          expected[locale.tag],
          reason: locale.tag,
        );
      }
    });

    test('TRUNCATES at the tenth rather than rounding', () {
      // E04's decision, and it is deliberate: LocaleNumbers.seconds and
      // LocaleNumbers.clock are the same duration shown two ways, and they used
      // to disagree — a Blitz round ending at 59,999ms read 0:59 on the HUD and
      // 60.0 on the results card, for one run. The epic's spec predates that
      // call and asked for rounding; the shipped behaviour is truncation and
      // the two views agreeing is worth more.
      for (final locale in SupportedLocale.values) {
        expect(
          _secondsOf(locale, 18650),
          closeTo(18.6, 1e-9),
          reason: locale.tag,
        );
        expect(
          _secondsOf(locale, 18699),
          closeTo(18.6, 1e-9),
          reason: locale.tag,
        );
      }
    });

    test('and zero and a sub-second value render without a gap', () {
      for (final locale in SupportedLocale.values) {
        expect(_secondsOf(locale, 0), 0, reason: locale.tag);
        expect(_secondsOf(locale, 900), closeTo(0.9, 1e-9), reason: locale.tag);
      }
    });

    test('every formatted duration round-trips through its own parser', () {
      // Through LocaleNumbers.parse, NOT through AsciiNumerals.normalize.
      // normalize folds DIGITS and says so: its own doc states the output is
      // not parseable, because a German decimal comma and a Persian U+066B are
      // separators rather than digits and pass straight through. Parsing a
      // normalised string works for three locales and silently reads `18,6` as
      // eighteen in the fourth.
      for (final locale in SupportedLocale.values) {
        for (var tenths = 0; tenths < 2000; tenths++) {
          expect(
            _secondsOf(locale, tenths * 100),
            closeTo(tenths / 10, 1e-9),
            reason: '${locale.tag} at $tenths tenths',
          );
        }
      }
    });
  });

  group('formatting reads no ambient state', () {
    test('it is a pure function of its injected closures', () {
      // Intl.defaultLocale set to fa, formatting through an English formatter:
      // still Latin digits. The formatter cannot reach the ambient locale
      // because it holds no formatter to reach it with.
      final previous = Intl.defaultLocale;
      addTearDown(() => Intl.defaultLocale = previous);

      Intl.defaultLocale = 'fa';

      expect(
        formatterFor(SupportedLocale.en).format(ScoreFormat.points, 1480),
        '1,480',
      );
    });

    test('and the file imports nothing that could', () {
      final code = withoutDartComments(
        File('lib/core/score_formatter.dart').readAsStringSync(),
      );

      for (final banned in <String>[
        'package:intl',
        'NumberFormat',
        'DateFormat',
        'toStringAsFixed',
        'AppLocalizations',
        'package:flutter',
      ]) {
        expect(code, isNot(contains(banned)), reason: banned);
      }
    });

    test('and it cannot know the word for seconds', () {
      // The unit arrives as a pattern. A literal 's' here would be an English
      // word in four locales.
      final code = withoutDartComments(
        File('lib/core/score_formatter.dart').readAsStringSync(),
      );

      expect(code, isNot(contains("'s'")));
    });
  });
}
