import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/sunburst_type.dart';

import '../support/design_source.dart';
import '../support/harness.dart';

/// Every step, by name, in the order it is declared.
///
/// The count is DERIVED from the source file rather than hardcoded, so this
/// literal is the only place a new step is acknowledged — and adding one is a
/// one-line edit that a reviewer sees. E05 T05.1 took it from ten to twelve
/// with `buttonLarge` and `chip`; E08 T08.0 takes it further.
const kTypeSteps = <String>[
  'scoreHero',
  'displayXl',
  'displayL',
  'title',
  'numericHud',
  'button',
  'buttonLarge',
  'chip',
  'body',
  'caption',
  'label',
  'stimulus',
];

/// Reads every step off a scale, so a test can assert over all of them.
List<TextStyle> allSteps(SunburstType type) => <TextStyle>[
  type.scoreHero,
  type.displayXl,
  type.displayL,
  type.title,
  type.numericHud,
  type.button,
  type.buttonLarge,
  type.chip,
  type.body,
  type.caption,
  type.label,
  type.stimulus,
];

void main() {
  const latin = SunburstType.sunburstPop;
  final arabic = latin.forScript(SunburstScript.arabic);

  group('the scale', () {
    test('ships exactly the steps its source file declares', () {
      expect(
        DesignSource.dartFieldNames(
          'lib/theme/sunburst_type.dart',
          'SunburstType',
        ),
        kTypeSteps,
        reason: 'an unlisted step is a new role nobody designed',
      );
    });

    test('buttonLarge is Fredoka 21/24 and chip is Fredoka 600 14/18', () {
      expect(latin.buttonLarge.fontSize, 21);
      expect(latin.buttonLarge.height, 24 / 21);
      expect(latin.buttonLarge.fontWeight, FontWeight.w600);
      expect(latin.buttonLarge.fontFamily, SunburstType.display);

      expect(latin.chip.fontSize, 14);
      expect(latin.chip.height, 18 / 14);
      expect(latin.chip.fontWeight, FontWeight.w600);
      expect(latin.chip.fontFamily, SunburstType.display);
    });

    test('buttonLarge and chip carry the Arabic-script fallback', () {
      // Fredoka covers NO Arabic script at all, so a display step without a
      // fallback renders a chip label as tofu in half the shipped locales.
      // This asserts E03's cascade rather than redefining it: if it fails, the
      // fix lands in lib/theme/, not in the component that noticed.
      for (final style in <TextStyle>[latin.buttonLarge, latin.chip]) {
        expect(style.fontFamilyFallback, isNotEmpty);
        expect(style.fontFamilyFallback, contains(SunburstType.arabicFace));
      }
    });

    test('and both resolve to that face under the Arabic script', () {
      expect(arabic.buttonLarge.fontFamily, SunburstType.arabicFace);
      expect(arabic.chip.fontFamily, SunburstType.arabicFace);
    });

    test('every step declares an explicit size and family', () {
      for (final style in allSteps(latin)) {
        expect(style.fontSize, isNotNull);
        expect(style.fontFamily, isNotNull);
        expect(style.fontWeight, isNotNull);
      }
    });

    test('the two numeric steps are tabular', () {
      // An HUD value that reflows mid-run reads as a glitch, and the player is
      // watching it while doing something else.
      for (final style in <TextStyle>[latin.scoreHero, latin.numericHud]) {
        expect(
          style.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      }
    });

    test('every Latin cascade ends in a face that can draw Arabic', () {
      // design-system-structure rule 10. A glyph falling through to an OS font
      // is a defect, not a graceful fallback, and it is invisible on the
      // developer's device — the OS has a Persian font and the user's may not
      // have the same one.
      for (final style in allSteps(latin)) {
        expect(
          style.fontFamilyFallback,
          isNotNull,
          reason: 'a step with no cascade falls through to the OS',
        );
        expect(
          style.fontFamilyFallback!.last,
          SunburstType.arabicFace,
          reason: 'the cascade must END in the Arabic face',
        );
      }
    });
  });

  group('forScript(arabic)', () {
    test('re-points every step at the Arabic face', () {
      for (final style in allSteps(arabic)) {
        expect(style.fontFamily, SunburstType.arabicFace);
        expect(style.fontFamilyFallback, <String>[SunburstType.arabicFace]);
      }
    });

    test('zeroes letterSpacing on every step', () {
      // Not a stylistic preference. Arabic script is CURSIVE: adjacent letters
      // join, and tracking breaks those joins, turning a word into
      // disconnected shapes. Every negative value in the Latin scale exists to
      // tighten Fredoka's wide counters and means nothing here.
      for (final style in allSteps(arabic)) {
        expect(
          style.letterSpacing,
          0,
          reason: 'a non-zero tracking here would break cursive joins',
        );
      }
    });

    test('gives every step a taller line box than its Latin counterpart', () {
      // Arabic has deeper descenders and taller diacritics than Latin at the
      // same point size, so a height tuned for Fredoka shears them.
      final latinSteps = allSteps(latin);
      final arabicSteps = allSteps(arabic);

      for (var i = 0; i < latinSteps.length; i++) {
        expect(
          arabicSteps[i].height,
          greaterThan(latinSteps[i].height!),
          reason: '${kTypeSteps[i]} kept its Latin line box',
        );
      }
    });

    test('keeps the size of every step', () {
      // Only the family, weight, line box and tracking change. A different
      // size would be a different design, not the same design in another
      // script, and it would break the layout the reference PNGs were rendered
      // at.
      final latinSteps = allSteps(latin);
      final arabicSteps = allSteps(arabic);

      for (var i = 0; i < latinSteps.length; i++) {
        expect(
          arabicSteps[i].fontSize,
          latinSteps[i].fontSize,
          reason: kTypeSteps[i],
        );
      }
    });

    test('keeps the tabular figures on the numeric steps', () {
      // The Schulte tiles ARE the numbers, and in fa/ckb they are Eastern
      // Arabic digits with their own advance widths. Losing tabular here would
      // make the grid jitter as tiles are found.
      for (final style in <TextStyle>[arabic.scoreHero, arabic.numericHud]) {
        expect(
          style.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      }
    });

    test('latin returns the identical instance', () {
      expect(identical(latin.forScript(SunburstScript.latin), latin), isTrue);
    });
  });

  group('SunburstScript.forLocale', () {
    test('maps the four shipped locales', () {
      expect(
        SunburstScript.forLocale(const Locale('en')),
        SunburstScript.latin,
      );
      expect(
        SunburstScript.forLocale(const Locale('de')),
        SunburstScript.latin,
      );
      expect(
        SunburstScript.forLocale(const Locale('fa')),
        SunburstScript.arabic,
      );
      expect(
        SunburstScript.forLocale(const Locale('ckb')),
        SunburstScript.arabic,
      );
    });

    test('an unknown locale falls back to latin', () {
      expect(
        SunburstScript.forLocale(const Locale('zz')),
        SunburstScript.latin,
        reason: 'en is the fallback locale, so latin is the fallback script',
      );
    });
  });

  group('of(context) resolves from the ambient locale', () {
    testWidgets('and no call site ever names a font', (tester) async {
      const expected = <String, String>{
        'en': SunburstType.display,
        'de': SunburstType.display,
        'fa': SunburstType.arabicFace,
        'ckb': SunburstType.arabicFace,
      };

      for (final entry in expected.entries) {
        late SunburstType resolved;

        await tester.pumpApp(
          Builder(
            builder: (context) {
              resolved = SunburstType.of(context);
              return const SizedBox.shrink();
            },
          ),
          theme: ThemeData(extensions: const <SunburstType>[latin]),
          locale: Locale(entry.key),
        );
        if (entry.key != 'en') tester.takeException();

        expect(
          resolved.title.fontFamily,
          entry.value,
          reason: '${entry.key} resolved to the wrong family',
        );
      }
    });

    testWidgets('asserts when the extension is missing', (tester) async {
      Object? error;

      await tester.pumpApp(
        Builder(
          builder: (context) {
            try {
              SunburstType.of(context);
            } on Object catch (caught) {
              error = caught;
            }
            return const SizedBox.shrink();
          },
        ),
        theme: ThemeData(),
      );

      expect(error, isA<AssertionError>());
    });
  });

  group('no widget may name a font family', () {
    test('the family strings appear only in the type layer', () {
      final offenders = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.endsWith('sunburst_type.dart'))
          .where((f) => !f.path.endsWith('font_licences.dart'))
          .where((f) {
            final source = f.readAsStringSync();
            return source.contains("'Fredoka'") ||
                source.contains("'Nunito'") ||
                source.contains("'Vazirmatn'");
          })
          .map((f) => f.path)
          .toList();

      expect(
        offenders,
        isEmpty,
        reason:
            'a widget naming a family is a widget that will tofu in one of '
            'the four locales: $offenders',
      );
    });
  });
}
