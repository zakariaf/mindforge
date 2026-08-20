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

  /// The primitives that are a base colour at an opacity, not their own hex.
  ///
  /// `system.html` declares no alpha, so these cannot be compared to a custom
  /// property — but they are DERIVED rather than invented, and the derivation
  /// is what gets reviewed. Each row names its base and the `app.html` opacity
  /// it was composited at, and the test below checks both.
  const kCompositedPrimitives = <String, (String, int)>{
    // .hdr .rays{...var(--sunshine-deep)...;opacity:.5} -> 0.5 * 255 = 128.
    'sunshineDeepHalf': ('sunshineDeep', 0x80),
    // .hdr .dots{opacity:.16} over var(--ink) -> 0.16 * 255 = 41.
    'inkHalftone': ('ink', 0x29),
    // .hero .dots{opacity:.08} over var(--ink) -> 0.08 * 255 = 20.
    'inkHalftoneSoft': ('ink', 0x14),
    // .res-hdr .rays{opacity:.55} over var(--leaf-deep) -> 140.
    'leafDeepStrong': ('leafDeep', 0x8C),
    // .set-hdr .rays{opacity:.3} over var(--grape-pop) -> 77.
    'grapePopSoft': ('grapePop', 0x4D),
    // .count .rays{opacity:.55} over var(--grape-pop) -> 140.
    'grapePopStrong': ('grapePop', 0x8C),
    // .playband .rays{opacity:.45} over var(--coral-deep) -> 115.
    'coralDeepBand': ('coralDeep', 0x73),
    // .playband--schulte .rays{opacity:.45} over var(--turquoise-deep) -> 115.
    'turquoiseDeepBand': ('turquoiseDeep', 0x73),
  };

  group('token parity with system.html', () {
    test('the parser found the design source', () {
      // A guard on the parser: if system.html is reformatted into something
      // this cannot read, every assertion below would pass vacuously.
      expect(cssHexes, hasLength(30));
      expect(
        dartHexes,
        hasLength(kPrimitiveToCssVar.length + kCompositedPrimitives.length),
        reason:
            'the composited primitives have no CSS custom property to pair '
            'with, so they are counted separately and checked against their '
            'base below',
      );
    });

    for (final entry in kPrimitiveToCssVar.entries) {
      test('_P.${entry.key} matches ${entry.value}', () {
        expect(
          // The RGB half. dartPrimitiveHexes reports the full ARGB now, so a
          // composited primitive can be seen at all — and CSS custom
          // properties in system.html carry no alpha to compare against.
          dartHexes[entry.key]?.substring(2),
          cssHexes[entry.value],
          reason:
              'system.html is the authority for values. If the Dart is '
              'right and the design file is wrong, that is a deliberate design '
              'change: edit system.html, re-run capture-screens.sh, and commit '
              'the regenerated PNGs with the reason',
        );
      });
    }

    test('every composited primitive is its base at a stated opacity', () {
      // Not an exemption: a composited primitive still has to be traceable to
      // a reviewed value. Its RGB must equal its base's, and its alpha must be
      // the app.html opacity the row names.
      for (final entry in kCompositedPrimitives.entries) {
        final composited = dartHexes[entry.key];
        final base = dartHexes[entry.value.$1];

        expect(composited, isNotNull, reason: '_P.${entry.key} is missing');
        expect(base, isNotNull, reason: '_P.${entry.value.$1} is missing');

        expect(
          composited!.substring(2),
          base!.substring(2),
          reason: '${entry.key} should be ${entry.value.$1} at an opacity',
        );
        expect(
          int.parse(composited.substring(0, 2), radix: 16),
          entry.value.$2,
          reason: '${entry.key} alpha',
        );
      }
    });

    test('no primitive exists in Dart that system.html does not declare', () {
      expect(
        dartHexes.keys.toSet().difference(kCompositedPrimitives.keys.toSet()),
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
        reason:
            'a colour exists in the design system that no Dart slot can '
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
          reason:
              'the colour-blind palette RE-POINTS answers at existing '
              'hues rather than adding new ones. A fifth hue here would be a '
              'primitive with no chrome slot and no contrast declaration',
        );
      }
    });
  });
}
