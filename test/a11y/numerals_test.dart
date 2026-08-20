import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_version.dart';
import 'package:mindforge/l10n/bidi_text.dart';

import '../support/load_app_fonts.dart';
import '../support/locale_cases.dart';
import '../support/sweep_surfaces.dart';

/// Every digit on every surface, in every language.
///
/// **The defect this catches is silent.** A Latin `4` in a Persian sentence is
/// not a crash and not an overflow — it reads as a screen somebody forgot to
/// translate, and it survives every test that asserts on a string the code
/// itself produced. The only way to catch it is to walk what is actually
/// rendered.
///
/// Three separate rules, because they fail separately:
///
/// 1. `en` and `de` render Latin digits and nothing else.
/// 2. `fa` and `ckb` render U+06F0–U+06F9 — the EXTENDED Arabic-Indic block —
///    and never U+0660–U+0669, which is the Arabic block. Both are "Eastern
///    Arabic"; only one has the right shapes for a Persian or Sorani reader,
///    and four and six differ outright between them.
/// 3. German groups with `.` where English groups with `,`.
void main() {
  setUpAll(loadAppFonts);

  /// Every string the surface actually draws.
  List<String> renderedText(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .where((value) => value.isNotEmpty)
      .toList();

  /// [text] with the bidi controls removed, which are invisible either way.
  String visible(String text) => BidiText.strip(text);

  for (final surface in SweepSurface.values) {
    for (final localeCase in LocaleCase.all) {
      testWidgets('${surface.name} draws ${localeCase.tag} digits only', (
        tester,
      ) async {
        await tester.pumpSurface(surface, localeCase: localeCase);

        final offenders = <String>[];

        for (final raw in renderedText(tester)) {
          final value = visible(raw);

          // TWO NAMED IDENTIFIERS keep their ASCII, and neither is a number a
          // reader counts with. A version is read back to a maintainer in a
          // bug report, so `۱.۰.۰` and `1.0.0` would look like two builds; an
          // SPDX id is a proper noun that matches nothing if its digits move.
          // Named rather than pattern-matched, so a third one has to come here
          // and argue for itself.
          if (value.contains(kAppVersion) || value.contains(kAppLicence)) {
            continue;
          }

          for (final rune in value.runes) {
            final isLatin = rune >= 0x30 && rune <= 0x39;
            final isArabicBlock = rune >= 0x0660 && rune <= 0x0669;
            final isPersianBlock = rune >= 0x06F0 && rune <= 0x06F9;

            if (!isLatin && !isArabicBlock && !isPersianBlock) continue;

            // THE ARABIC BLOCK IS ALWAYS WRONG HERE. This app ships no `ar`
            // locale, and mixing the two Eastern blocks is the anti-pattern
            // `i18n-rtl-l10n` names by hand.
            if (isArabicBlock) {
              offenders.add('U+0660 block in "$value"');
              continue;
            }

            if (localeCase.usesEasternArabicNumerals) {
              if (isLatin) offenders.add('Latin digit in "$value"');
            } else {
              if (isPersianBlock) offenders.add('Eastern digit in "$value"');
            }
          }
        }

        expect(
          offenders.toSet(),
          isEmpty,
          reason:
              '${surface.name} under ${localeCase.tag} — a digit from the '
              'wrong script reads as an untranslated screen',
        );
      });
    }
  }

  group('the grouping separator', () {
    testWidgets('is de own on a German surface, not English own', (
      tester,
    ) async {
      // The separator is the half of number formatting that survives having
      // the right DIGITS: `1,480` in German is as wrong as a Latin four in
      // Persian, and it looks deliberate.
      await tester.pumpSurface(
        SweepSurface.stats,
        localeCase: LocaleCase.german,
      );

      final grouped = renderedText(
        tester,
      ).map(visible).where((value) => RegExp(r'\d[.,]\d{3}').hasMatch(value));

      for (final value in grouped) {
        expect(
          value,
          isNot(contains(',')),
          reason: 'German groups with a full stop',
        );
      }
    });
  });

  group('the two ASCII identifiers', () {
    testWidgets('are still on the About screen, and still ASCII', (
      tester,
    ) async {
      // The exemption above is only honest if the things it exempts are still
      // there. A version that quietly became localized would pass the sweep by
      // disappearing from it.
      await tester.pumpSurface(
        SweepSurface.about,
        localeCase: LocaleCase.persian,
      );

      final drawn = renderedText(tester).map(visible).join(' ');

      expect(drawn, contains(kAppVersion));
      expect(drawn, contains(kAppLicence));
    });
  });
}
