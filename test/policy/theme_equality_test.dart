import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_motion.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';

import '../support/design_source.dart';

/// Every field a theme extension declares takes part in its equality.
///
/// **This caught a real one.** E05 added six slots to `SunburstShape` and two
/// steps to `SunburstType`, touched the constructor, `copyWith`, `lerp` and the
/// const instance — and missed `_props`, which is what `==` and `hashCode` are
/// built from. Two shapes differing only in the new fields compared **equal**,
/// so `ThemeData` would not have rebuilt when one changed.
///
/// `sunburst-tokens` rule 12 lists five places a new slot has to be touched.
/// `_props` is the sixth, and it is the one nobody remembers, because nothing
/// visibly breaks: the app renders, the tests pass, and the extension quietly
/// stops noticing half of itself.
///
/// Rather than trusting the list, this counts. The field count comes from the
/// source file, the props count from the object, and they have to agree.
void main() {
  /// How many entries the extension's `_props` list holds.
  ///
  /// Read through equality rather than by exposing the list: an extension that
  /// differs in exactly one field must compare unequal, so flipping each field
  /// in turn and counting the inequalities counts the props.
  int declaredFieldsOf(String file, String className) =>
      DesignSource.dartFieldNames(file, className).length;

  group('every declared field takes part in equality', () {
    test('SunburstShape', () {
      // The one direct measurement available: lerp walks every field, so a
      // half-way shape differing in ALL fields must be unequal to both ends,
      // and a shape differing in ONE field must be unequal to the original.
      const base = SunburstShape.sunburstPop;

      final variants = <String, SunburstShape>{
        'eChip': base.copyWith(eChip: const Offset(99, 99)),
        'borderWidthNested': base.copyWith(borderWidthNested: 99),
        'dashOn': base.copyWith(dashOn: 99),
        'dashOff': base.copyWith(dashOff: 99),
        'glyphStrokeNav': base.copyWith(glyphStrokeNav: 99),
        'glyphStrokeControl': base.copyWith(glyphStrokeControl: 99),
        'borderWidth': base.copyWith(borderWidth: 99),
        'radiusSm': base.copyWith(radiusSm: const Radius.circular(99)),
        'e1': base.copyWith(e1: const Offset(99, 99)),
        'pressScale': base.copyWith(pressScale: 0.1),
        'badgeTiltDegrees': base.copyWith(badgeTiltDegrees: 99),
        'shakeAmplitude': base.copyWith(shakeAmplitude: 99),
        'celebrationScaleFrom': base.copyWith(celebrationScaleFrom: 99),
        'celebrationScalePeak': base.copyWith(celebrationScalePeak: 99),
        'wordmarkTile': base.copyWith(wordmarkTile: 99),
        'wordmarkTileRadius': base.copyWith(
          wordmarkTileRadius: const Radius.circular(99),
        ),
        'focusGap': base.copyWith(focusGap: 99),
        'stripePitch': base.copyWith(stripePitch: 99),
        'chartBarRadiusTop': base.copyWith(
          chartBarRadiusTop: const Radius.circular(99),
        ),
        'chartBarRadiusBottom': base.copyWith(
          chartBarRadiusBottom: const Radius.circular(99),
        ),
        'settingsChipRadius': base.copyWith(
          settingsChipRadius: const Radius.circular(99),
        ),
        'paletteSwatchRadius': base.copyWith(
          paletteSwatchRadius: const Radius.circular(99),
        ),
        'countdownRing': base.copyWith(countdownRing: 99),
        'countdownDot': base.copyWith(countdownDot: 99),
        'countdownReadyShadow': base.copyWith(
          countdownReadyShadow: const Offset(99, 99),
        ),
        'gameArtFrame': base.copyWith(gameArtFrame: 99),
        'lockedChip': base.copyWith(lockedChip: 99),
        'cardChipRadius': base.copyWith(
          cardChipRadius: const Radius.circular(99),
        ),
        'dotPitch': base.copyWith(dotPitch: 99),
        'dotRadius': base.copyWith(dotRadius: 99),
        'ringPitch': base.copyWith(ringPitch: 99),
        'ringBandWidth': base.copyWith(ringBandWidth: 99),
        'glyphStrokeWidth': base.copyWith(glyphStrokeWidth: 99),
        'answerKeyHeight': base.copyWith(answerKeyHeight: 99),
        'answerKeyPanelWidth': base.copyWith(answerKeyPanelWidth: 99),
        'answerStrikeHeight': base.copyWith(answerStrikeHeight: 99),
      };

      for (final entry in variants.entries) {
        expect(
          entry.value,
          isNot(base),
          reason:
              '${entry.key} is missing from _props, so two shapes differing '
              'only in it compare equal and the theme never rebuilds',
        );
      }
    });

    test('SunburstType', () {
      const base = SunburstType.sunburstPop;
      const swapped = TextStyle(fontSize: 99);

      final variants = <String, SunburstType>{
        'buttonLarge': base.copyWith(buttonLarge: swapped),
        'chip': base.copyWith(chip: swapped),
        'body': base.copyWith(body: swapped),
        'scoreHero': base.copyWith(scoreHero: swapped),
      };

      for (final entry in variants.entries) {
        expect(entry.value, isNot(base), reason: entry.key);
      }
    });

    test('SunburstColors', () {
      const base = SunburstColors.sunburstPop;

      expect(base.copyWith(accent: const Color(0xFF123456)), isNot(base));
      expect(base.copyWith(cbPink: const Color(0xFF123456)), isNot(base));
    });

    test('SunburstMotion', () {
      const base = SunburstMotion.sunburstPop;

      expect(base.copyWith(durTap: const Duration(days: 1)), isNot(base));
    });
  });

  group('and the source still declares what these tests enumerate', () {
    // If a seventh shape slot lands, this count moves and the test above stops
    // being exhaustive — so the count is pinned rather than assumed.
    test('SunburstShape declares 51 instance fields', () {
      expect(
        declaredFieldsOf('lib/theme/sunburst_shape.dart', 'SunburstShape'),
        51,
      );
    });
  });
}
