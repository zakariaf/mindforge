import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/locale_numbers.dart';
import 'package:mindforge/theme/sunburst_type.dart';

import '../support/harness.dart';
import '../support/locale_cases.dart';

/// The matrix E05 and every later epic run their components through.
///
/// It is exercised here, on the smallest possible widget, so that a regression
/// in the harness itself surfaces before a component is blamed for it.
void main() {
  for (final localeCase in LocaleCase.all) {
    group('under ${localeCase.tag}', () {
      testWidgets('direction follows the locale', (tester) async {
        // pumpLocalized asserts this internally; asserting it again here is
        // deliberate, so the matrix reads as a statement rather than relying on
        // a side effect of the helper.
        late TextDirection resolved;

        await tester.pumpLocalized(
          Builder(
            builder: (context) {
              resolved = Directionality.of(context);
              return const SizedBox.shrink();
            },
          ),
          localeCase,
        );

        expect(resolved, localeCase.direction);
      });

      testWidgets('a plural in an RTL locale prints LOCALISED digits', (
        tester,
      ) async {
        // The bug this shape exists to prevent: gen-l10n interpolates an int
        // placeholder with Dart toString(), so "زنجیره‌ی 4 روزه" — a Persian
        // sentence with a Latin digit in it — is what shipped before the
        // placeholders became pre-formatted Strings.
        late AppLocalizations l10n;

        await tester.pumpLocalized(
          Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
          localeCase,
        );

        final formatted = LocaleNumbers.count(4, localeCase.locale);
        final rendered = l10n.streakDays(4, formatted);

        expect(rendered, contains(formatted));
        if (localeCase.usesEasternArabicNumerals) {
          expect(
            RegExp('[0-9]').hasMatch(rendered),
            isFalse,
            reason:
                'an ASCII digit in a Persian or Sorani sentence reads as '
                'untranslated: "\$rendered"',
          );
        }
      });

      testWidgets('every string resolves and none is empty', (tester) async {
        late AppLocalizations l10n;

        await tester.pumpLocalized(
          Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
          localeCase,
        );

        // Numbers arrive PRE-FORMATTED, through LocaleNumbers. See the
        // NUMERALS note on those keys in the ARB.
        String f(int v) => LocaleNumbers.count(v, localeCase.locale);
        final three = f(3);
        final four = f(4);
        final six = f(6);
        final twelve = f(12);
        final twentyFive = f(25);

        // A representative slice across every message shape: plain, select,
        // plural, two-plural, and one with typed placeholders.
        final rendered = <String, String>{
          'appTitle': l10n.appTitle,
          'playButton': l10n.playButton,
          'homeGreeting': l10n.homeGreeting('evening'),
          'streakDays': l10n.streakDays(4, four),
          'dailyMixSummary': l10n.dailyMixSummary(4, 3, four, three),
          'foundOfTotal': l10n.foundOfTotal(twentyFive, six),
          'durationHoursMinutes': l10n.durationHoursMinutes(twelve, three),
          'toggleOn': l10n.toggleOn,
          'settingsLanguageSystem': l10n.settingsLanguageSystem,
        };

        for (final entry in rendered.entries) {
          expect(
            entry.value,
            isNotEmpty,
            reason: '${entry.key} is empty under $localeCase',
          );
        }
      });

      testWidgets('the type scale resolves to a face that can draw it', (
        tester,
      ) async {
        late SunburstType type;

        await tester.pumpLocalized(
          Builder(
            builder: (context) {
              type = SunburstType.of(context);
              return const SizedBox.shrink();
            },
          ),
          localeCase,
        );

        expect(
          type.body.fontFamily,
          localeCase.locale.isRightToLeft
              ? SunburstType.arabicFace
              : SunburstType.bodyFace,
          reason:
              'Fredoka and Nunito have no Arabic-script coverage at all, '
              'so an RTL locale resolving to one of them renders tofu',
        );
      });

      test('numbers render in the right digit system', () {
        final rendered = LocaleNumbers.count(1480, localeCase.locale);

        if (localeCase.usesEasternArabicNumerals) {
          expect(rendered, '۱٬۴۸۰');
        } else {
          expect(
            rendered.runes.every((r) => r < 0x0600),
            isTrue,
            reason: '$localeCase must render Latin digits',
          );
        }
      });
    });
  }

  group('the matrix itself', () {
    test('is a projection of SupportedLocale, not a second list', () {
      expect(LocaleCase.all.map((c) => c.tag).toList(), [
        'en',
        'de',
        'fa',
        'ckb',
      ]);
      expect(LocaleCase.rightToLeft.map((c) => c.tag).toList(), ['fa', 'ckb']);
    });
  });
}
