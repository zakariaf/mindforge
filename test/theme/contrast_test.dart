import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import '../support/wcag.dart';

/// One `// @contrast <fg> <bg> <min>` declaration.
typedef ContrastPair = ({String foreground, String background, double minimum});

/// Every `// @contrast` declaration in the colours file.
List<ContrastPair> declaredPairs() =>
    RegExp(
      r'//\s*@contrast\s+(\w+)\s+(\w+)\s+([0-9.]+)',
    ).allMatches(File('lib/theme/sunburst_colors.dart').readAsStringSync()).map(
      (
        match,
      ) {
        return (
          foreground: match.group(1)!,
          background: match.group(2)!,
          minimum: double.parse(match.group(3)!),
        );
      },
    ).toList();

const SunburstColors _palette = SunburstColors.sunburstPop;

final Map<String, Color> _slots = <String, Color>{
  'surface': _palette.surface,
  'surfaceSunk': _palette.surfaceSunk,
  'surfaceRaised': _palette.surfaceRaised,
  'surfaceInvert': _palette.surfaceInvert,
  'textPrimary': _palette.textPrimary,
  'textSecondary': _palette.textSecondary,
  'textDisabled': _palette.textDisabled,
  'textInvert': _palette.textInvert,
  'border': _palette.border,
  'borderDisabled': _palette.borderDisabled,
  'divider': _palette.divider,
  'dotPattern': _palette.dotPattern,
  'accent': _palette.accent,
  'accentDeep': _palette.accentDeep,
  'accentAlt': _palette.accentAlt,
  'success': _palette.success,
  'successDeep': _palette.successDeep,
  'warning': _palette.warning,
  'danger': _palette.danger,
  'focusRing': _palette.focusRing,
  'gameStroop': _palette.gameStroop,
  'gameStroopDeep': _palette.gameStroopDeep,
  'gameSchulte': _palette.gameSchulte,
  'gameSchulteDeep': _palette.gameSchulteDeep,
  'gameDigitBridge': _palette.gameDigitBridge,
  'gameDigitBridgeDeep': _palette.gameDigitBridgeDeep,
  'gameFalseLight': _palette.gameFalseLight,
  'gameFalseLightDeep': _palette.gameFalseLightDeep,
  'playRed': _palette.playRed,
  'playBlue': _palette.playBlue,
  'playGreen': _palette.playGreen,
  'playYellow': _palette.playYellow,
  'playPurple': _palette.playPurple,
  'playOrange': _palette.playOrange,
  'cbBlue': _palette.cbBlue,
  'cbYellow': _palette.cbYellow,
  'cbOrange': _palette.cbOrange,
  'cbPink': _palette.cbPink,
};

void main() {
  final pairs = declaredPairs();

  group('WCAG contrast', () {
    test('the declarations were found', () {
      // A guard on the parser: if the block is reformatted into something this
      // cannot read, every assertion below would pass over an empty list.
      expect(pairs, hasLength(30));
    });

    test('every declared name resolves to a slot', () {
      for (final pair in pairs) {
        expect(
          _slots.keys,
          containsAll(<String>[pair.foreground, pair.background]),
          reason: 'an unresolvable name is a declaration that checks nothing',
        );
      }
    });

    for (final pair in pairs) {
      test('${pair.foreground} on ${pair.background}', () {
        final ratio = contrastRatio(
          _slots[pair.foreground]!,
          _slots[pair.background]!,
        );

        expect(
          ratio,
          greaterThanOrEqualTo(pair.minimum),
          reason:
              'measured ${ratio.toStringAsFixed(2)}:1, floor '
              '${pair.minimum}:1. Fix the hex or restate the pair — never '
              'lower the floor',
        );
      });
    }

    test('playYellow is illegal as bare text on cream', () {
      // Documented as an expectation, not left implicit: an INVERTED assertion
      // here would be a silent accessibility regression. The Stroop stimulus is
      // three paint passes — fill, ink border, ink label — precisely because
      // the answer hues are not legible as bare text on the page.
      expect(
        contrastRatio(_palette.playYellow, _palette.surface),
        lessThan(4.5),
        reason:
            'if this ever clears 4.5:1 the palette moved, and the reason '
            'the stimulus is layered no longer holds',
      );
    });

    test('the colour-blind palette keeps its label contrast', () {
      // The swap re-points answers; it must not quietly break the label rule
      // that answerLabel encodes.
      for (final answer in PlayAnswer.values) {
        final fill = _palette.answerColour(answer, colourBlind: true);
        final label = _palette.answerLabel(answer);

        expect(
          contrastRatio(label, fill),
          greaterThanOrEqualTo(4.5),
          reason: '$answer under the colour-blind palette',
        );
      }
    });
  });
}
