import 'package:flutter_test/flutter_test.dart';

import '../support/design_source.dart';

/// Every `_P` constant, mapped to the `system.html` custom property it
/// transcribes.
///
/// This table is the transcription itself. A hex invented in Dart, or a custom
/// property left untranscribed, fails one of the tests below.
const kPrimitiveToCssVar = <String, String>{
  'cream': '--cream',
  'creamSunk': '--cream-2',
  'creamEdge': '--cream-3',
  'paper': '--paper',
  'ink': '--ink',
  'inkSoft': '--ink-2',
  'inkMuted': '--ink-3',
  'sunshine': '--sunshine',
  'sunshineDeep': '--sunshine-deep',
  'coral': '--coral',
  'coralDeep': '--coral-deep',
  'turquoise': '--turquoise',
  'turquoiseDeep': '--turquoise-deep',
  'grape': '--grape',
  'grapePop': '--grape-pop',
  'leaf': '--leaf',
  'leafDeep': '--leaf-deep',
  'tangerine': '--tangerine',
  'dot': '--dot',
  'playRed': '--play-red',
  'playBlue': '--play-blue',
  'playGreen': '--play-green',
  'playYellow': '--play-yellow',
  'playPurple': '--play-purple',
  'playOrange': '--play-orange',
  'playPink': '--play-pink',
};

void main() {
  final cssHexes = DesignSource.cssRootHexes();
  final dartHexes = DesignSource.dartPrimitiveHexes();

  group('token parity with system.html', () {
    test('the parser found the design source', () {
      // A guard on the parser: if system.html is reformatted into something
      // this cannot read, every assertion below would pass vacuously.
      expect(cssHexes, hasLength(30));
      expect(dartHexes, hasLength(kPrimitiveToCssVar.length));
    });

    for (final entry in kPrimitiveToCssVar.entries) {
      test('_P.${entry.key} matches ${entry.value}', () {
        expect(
          dartHexes[entry.key],
          cssHexes[entry.value],
          reason: 'system.html is the authority for values. If the Dart is '
              'right and the design file is wrong, that is a deliberate design '
              'change: edit system.html, re-run capture-screens.sh, and commit '
              'the regenerated PNGs with the reason',
        );
      });
    }

    test('no primitive exists in Dart that system.html does not declare', () {
      expect(
        dartHexes.keys.toSet(),
        kPrimitiveToCssVar.keys.toSet(),
        reason: 'a hex invented in Dart has escaped design review',
      );
    });

    test('no hex custom property is left untranscribed', () {
      // The four --cb-* vars are excluded because they duplicate a gameplay
      // hex rather than introducing one; the next test proves that.
      final transcribable = cssHexes.keys
          .where((name) => !name.startsWith('--cb-'))
          .toSet();

      expect(
        transcribable,
        kPrimitiveToCssVar.values.toSet(),
        reason: 'a colour exists in the design system that no Dart slot can '
            'reach',
      );
    });

    test('the colour-blind vars reuse gameplay primitives', () {
      const reuse = <String, String>{
        '--cb-blue': '--play-blue',
        '--cb-yellow': '--play-yellow',
        '--cb-orange': '--play-orange',
        '--cb-pink': '--play-pink',
      };

      for (final entry in reuse.entries) {
        expect(
          cssHexes[entry.key],
          cssHexes[entry.value],
          reason: 'the colour-blind palette RE-POINTS answers at existing '
              'hues rather than adding new ones. A fifth hue here would be a '
              'primitive with no chrome slot and no contrast declaration',
        );
      }
    });
  });
}
