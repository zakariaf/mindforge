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

        // A representative slice across every message shape: plain, select,
        // plural, two-plural, and one with typed placeholders.
        final rendered = <String, String>{
          'appTitle': l10n.appTitle,
          'playButton': l10n.playButton,
          'homeGreeting': l10n.homeGreeting('evening'),
          'streakDays': l10n.streakDays(4),
          'dailyMixSummary': l10n.dailyMixSummary(4, 3),
          'foundOfTotal': l10n.foundOfTotal(25, 6),
          'durationHoursMinutes': l10n.durationHoursMinutes(12, 3),
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
