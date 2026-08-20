import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/l10n/locale_numbers.dart';
import 'package:mindforge/l10n/supported_locales.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_motion.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';

import 'component_harness.dart';
import 'harness.dart';
import 'load_app_fonts.dart';
import 'locale_cases.dart';
import 'sample_strings.dart';

/// Meta-tests for the harness every component test in E05 imports.
///
/// Written before the harness, because a harness that is quietly wrong makes
/// every test above it agree with itself forever: a golden rendered in Ahem
/// matches its own Ahem baseline, and an RTL test wrapped in a hardcoded
/// `Directionality` over English text passes while proving nothing.
void main() {
  setUpAll(loadAppFonts);

  group("E04's l10n surface is still under the names this harness imports", () {
    // THE INTEGRATION CANARY. A rename in lib/l10n/ fails here, once and
    // loudly, instead of surfacing as fourteen mystery compile errors later in
    // the epic.
    test('the shipped locale list is en, de, fa, ckb in that order', () {
      expect(
        supportedLocales.map((locale) => locale.languageCode).toList(),
        <String>['en', 'de', 'fa', 'ckb'],
      );
      expect(
        SupportedLocale.values.map((locale) => locale.tag).toList(),
        <String>['en', 'de', 'fa', 'ckb'],
        reason: 'supportedLocales is a projection of the enum, not a copy',
      );
    });

    test('LocaleNumbers still formats, and still per locale', () {
      expect(const LocaleNumbers(SupportedLocale.fa).count(1480), '۱٬۴۸۰');
      expect(const LocaleNumbers(SupportedLocale.de).count(1480), '1.480');
    });
  });

  group('pumpPopComponent', () {
    testWidgets('installs all four Sunburst extensions', (tester) async {
      // Every of() asserts when its extension is missing, so a theme that lost
      // one throws here rather than falling back to Material's defaults and
      // rendering something that merely looks wrong.
      late SunburstColors colours;
      late SunburstShape shape;
      late SunburstMotion motion;
      late SunburstType type;

      await tester.pumpPopComponent(
        Builder(
          builder: (context) {
            colours = SunburstColors.of(context);
            shape = SunburstShape.of(context);
            motion = SunburstMotion.of(context);
            type = SunburstType.of(context);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(colours.surface, SunburstColors.sunburstPop.surface);
      expect(shape.borderWidth, 3);
      expect(motion.durTap, isNotNull);
      expect(type.chip.fontSize, 14);
    });

    testWidgets('pumps every supported locale without throwing', (
      tester,
    ) async {
      // The E05-side canary for E04's vendored ckb delegates. Discovering a
      // missing one here, once, beats discovering it in T05.11 with 96 red
      // tuples.
      for (final localeCase in LocaleCase.all) {
        await tester.pumpPopComponent(
          const SizedBox.shrink(),
          localeCase: localeCase,
        );
        expect(tester.takeException(), isNull, reason: localeCase.tag);
      }
    });

    testWidgets('resolves direction from the locale, never from a parameter', (
      tester,
    ) async {
      for (final localeCase in LocaleCase.all) {
        late TextDirection resolved;

        await tester.pumpPopComponent(
          Builder(
            builder: (context) {
              resolved = Directionality.of(context);
              return const SizedBox.shrink();
            },
          ),
          localeCase: localeCase,
        );

        expect(resolved, localeCase.direction, reason: localeCase.tag);
      }
    });

    test('and exposes no textDirection parameter at all', () {
      // Direction is a CONSEQUENCE of the locale. A harness that accepts one
      // lets a test claim RTL while the locale, the fonts and the numerals stay
      // English — which looks right and proves nothing.
      final source = File('test/support/component_harness.dart')
          .readAsStringSync()
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');

      expect(source, isNot(contains('textDirection')));
    });

    testWidgets('MediaQuery sits above MaterialApp and keeps the view size', (
      tester,
    ) async {
      // A bare MediaQueryData() would report Size.zero and let a broken layout
      // pass, so the harness must build from .copyWith.
      late Size reported;

      await tester.pumpPopComponent(
        Builder(
          builder: (context) {
            reported = MediaQuery.sizeOf(context);
            return const SizedBox.shrink();
          },
        ),
        textScaler: const TextScaler.linear(2),
      );

      expect(reported, Device.reference390.logicalSize);
    });

    testWidgets('boldText reaches the subtree', (tester) async {
      late bool bold;

      await tester.pumpPopComponent(
        Builder(
          builder: (context) {
            bold = MediaQuery.boldTextOf(context);
            return const SizedBox.shrink();
          },
        ),
        boldText: true,
      );

      expect(bold, isTrue);
    });
  });

  group('useDevice', () {
    testWidgets('pins the logical size and restores it afterwards', (
      tester,
    ) async {
      final original = tester.view.physicalSize;

      for (final device in Device.all) {
        useDevice(tester, device);

        expect(
          tester.view.physicalSize,
          device.logicalSize * device.dpr,
          reason: '$device',
        );
        expect(tester.view.devicePixelRatio, device.dpr);
      }

      tester.view.reset();
      expect(tester.view.physicalSize, original);
    });
  });

  group('loadAppFonts', () {
    double widthOf(String text, TextStyle style) {
      // TextPainter REQUIRES a direction and this one measures a single
      // glyph's advance, which is the same either way. It is not a layout
      // claim, and it is the only textDirection under test/support/ outside
      // harness.dart.
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    test('registers the bundled Latin faces', () {
      // Under Ahem every glyph is one em wide, so a proportional face measures
      // NARROWER for the same string. If E01's .ttf files went missing this is
      // the test that says so, instead of every golden below quietly rendering
      // boxes and matching its own baseline forever.
      const style = TextStyle(fontFamily: SunburstType.display, fontSize: 40);
      const ahem = TextStyle(fontSize: 40);

      expect(
        widthOf('iiiii', style),
        isNot(closeTo(widthOf('iiiii', ahem), 1)),
      );
    });

    test('registers a face that covers Arabic and Sorani script', () {
      // Measured against U+FFFF, a permanently unassigned codepoint that always
      // renders as the last-resort box. Equal widths mean the glyph is MISSING
      // and the Persian golden is a field of notdef boxes that will match
      // itself forever.
      //
      // Heuristic, not proof. The proof is the eye check on the ckb contact
      // sheet in T05.11.
      final style = SunburstType.sunburstPop
          .forScript(SunburstScript.arabic)
          .body;
      final notdef = widthOf('￿', style);

      for (final letter in <String>[
        'ا', 'ب', 'ژ', // Arabic and Persian
        'ڕ', 'ڵ', 'ۆ', 'ێ', 'ھ', // the five Sorani-specific letters
      ]) {
        expect(
          widthOf(letter, style),
          isNot(closeTo(notdef, 0.01)),
          reason: '"$letter" measures as the notdef box, so the face lacks it',
        );
      }
    });
  });

  group('Greyscale', () {
    /// Applies the filter's own matrix, so this proves the shipped constant
    /// rather than a second idea of what greyscale means.
    (double, double, double) filtered(Color colour) {
      const m = Greyscale.saturationZero;
      double channel(int row) =>
          m[row * 5] * colour.r +
          m[row * 5 + 1] * colour.g +
          m[row * 5 + 2] * colour.b +
          m[row * 5 + 4];

      return (channel(0), channel(1), channel(2));
    }

    test('maps every colour to a neutral grey', () {
      for (final colour in <Color>[
        const Color(0xFFFF0000),
        const Color(0xFF00FF00),
        const Color(0xFF0000FF),
        const Color(0xFFFFC53D),
      ]) {
        final (r, g, b) = filtered(colour);

        expect(r, closeTo(g, 1e-9), reason: '$colour');
        expect(g, closeTo(b, 1e-9), reason: '$colour');
      }
    });

    test('and collapses two hues of equal luminance onto the same grey', () {
      // THE POINT OF THE LANE. If `selected` and `rest` differ only in hue,
      // they become one row here, and a player with a colour vision deficiency
      // sees what this golden shows.
      const olive = Color(0xFF808000);
      const teal = Color(0xFF008080);

      final (oliveGrey, _, _) = filtered(olive);
      final (tealGrey, _, _) = filtered(teal);

      expect(
        oliveGrey,
        isNot(closeTo(tealGrey, 1e-9)),
        reason:
            'these two differ in LUMINANCE as well as hue, so the filter must '
            'keep them apart — it desaturates, it does not flatten',
      );

      // And two that differ ONLY in hue DO collapse, which is the failure the
      // lane is built to make visible. These two have identical luminance by
      // construction: 0.2126r + 0.7152g + 0.0722b is the same for both.
      final (redGrey, _, _) = filtered(const Color(0xFFFF0000));
      final (blueGrey, _, _) = filtered(
        Color.fromARGB(255, 0, 0, (0.2126 * 255 / 0.0722).round()),
      );

      expect(redGrey, closeTo(blueGrey, 1));
    });
  });

  group('the specimen strings', () {
    test('cover every shipped locale', () {
      expect(
        sampleStrings.keys.toList(),
        SupportedLocale.values.map((locale) => locale.tag).toList(),
      );
    });

    test('the de specimen is at least 1.25x the en specimen', () {
      // By construction: German is the expansion stress case, and a specimen
      // set that quietly held English text would make every locale golden a
      // duplicate of the en one.
      final en = sampleStrings['en']!;
      final de = sampleStrings['de']!;

      expect(
        de.totalLength / en.totalLength,
        greaterThanOrEqualTo(1.25),
        reason: 'en=${en.totalLength} de=${de.totalLength}',
      );
    });

    test('the fa and ckb specimens are Arabic script throughout', () {
      bool isArabicScript(int rune) =>
          (rune >= 0x0600 && rune <= 0x06FF) ||
          (rune >= 0x0750 && rune <= 0x077F);

      for (final tag in <String>['fa', 'ckb']) {
        for (final entry in sampleStrings[tag]!.byField.entries) {
          // ZWNJ and ZWJ are legitimate Persian and Sorani orthography — the
          // Persian for "blitz" is برق‌آسا, with a zero-width non-joiner
          // between the two words — so they are format characters here, not
          // stray Latin. Measured: without this the specimen set looked wrong
          // when it was the test that was.
          final letters = entry.value.runes.where(
            (rune) =>
                rune > 0x20 &&
                rune != 0x00A0 &&
                rune != 0x200C &&
                rune != 0x200D,
          );

          expect(
            letters.where((rune) => !isArabicScript(rune)),
            isEmpty,
            reason: '$tag.${entry.key} = "${entry.value}" is not Arabic script',
          );
        }
      }
    });

    test('and the ckb specimen uses at least one Sorani-only letter', () {
      const sorani = <int>[0x0695, 0x06B5, 0x06C6, 0x06CE, 0x06BE];
      final all = sampleStrings['ckb']!.byField.values.join();

      expect(
        all.runes.where(sorani.contains),
        isNotEmpty,
        reason:
            'without one, the ckb contact sheet cannot show a Sorani-specific '
            'glyph failing',
      );
    });

    test('the numeral fields carry the digits their locale renders', () {
      expect(sampleStrings['en']!.score, '1,480');
      expect(sampleStrings['de']!.score, '1.480');
      expect(sampleStrings['fa']!.score, '۱٬۴۸۰');
      expect(sampleStrings['ckb']!.score, '۱٬۴۸۰');
    });
  });

  group('popGolden', () {
    test('puts every locale in its own directory, spelled once', () {
      expect(
        popGolden('pop_button', LocaleCase.all.first),
        'goldens/en/pop_button.png',
      );
      expect(
        popGolden('pop_button', LocaleCase.rightToLeft.first),
        'goldens/fa/pop_button.png',
      );
    });
  });
}
