import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/source_text.dart';

/// One bundled font family: the `family:` name and the `asset:` paths declared
/// under it in `pubspec.yaml`.
typedef FontFamilyDeclaration = ({String family, List<String> assets});

/// The families MindForge bundles, and nothing else.
///
/// **E03 T03.7 appends the Arabic-script faces to this list and to nothing
/// else.** Fredoka and Nunito have no Arabic-script coverage, so after E01 the
/// app renders `en` and `de` and would tofu `fa` and `ckb`. That is a stated
/// incompleteness, not a finished font story.
const kExpectedFontFamilies = <FontFamilyDeclaration>[
  (family: 'Fredoka', assets: ['assets/fonts/Fredoka[wdth,wght].ttf']),
  (family: 'Nunito', assets: ['assets/fonts/Nunito[wght].ttf']),
];

/// The weights `sunburst-tokens/references/shape-and-type.md` names, which E03
/// will spend. Both families ship as **variable** fonts upstream, so these are
/// driven by `FontWeight` against the `wght` axis rather than by one static
/// `asset:` entry each — `design-system-structure` rule 10 forbids a redundant
/// `FontVariation('wght', ...)` on top of that.
const kIntendedWeights = <String, List<int>>{
  'Fredoka': [600, 700],
  'Nunito': [700, 800],
};

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  group('font declaration', () {
    test('pubspec declares exactly the expected families and assets', () {
      final block = RegExp(
        r'^  fonts:\s*\n((?:\s{4,}.*\n|\s*\n)*)',
        multiLine: true,
      ).firstMatch(pubspec);

      expect(block, isNotNull, reason: 'no `flutter: fonts:` block');

      final declared = <FontFamilyDeclaration>[];
      for (final line in block!.group(1)!.split('\n')) {
        final family = RegExp(r'^\s*- family:\s*(\S+)').firstMatch(line);
        if (family != null) {
          declared.add((family: family.group(1)!, assets: <String>[]));
          continue;
        }
        final asset = RegExp(r'^\s*- asset:\s*(\S+)').firstMatch(line);
        if (asset != null) declared.last.assets.add(asset.group(1)!);
      }

      expect(
        declared.map((d) => d.family).toList(),
        kExpectedFontFamilies.map((d) => d.family).toList(),
      );
      for (var i = 0; i < kExpectedFontFamilies.length; i++) {
        expect(declared[i].assets, kExpectedFontFamilies[i].assets);
      }
    });

    test('no per-weight asset entry duplicates a variable axis', () {
      expect(
        RegExp(r'^\s*weight:\s*\d+', multiLine: true).hasMatch(pubspec),
        isFalse,
        reason:
            'both families ship as variable fonts, so weight is driven by '
            'FontWeight against the wght axis. A `weight:` key here would pin '
            'one instance and silently discard the rest of the axis. The '
            'weights E03 spends are $kIntendedWeights',
      );
    });

    test('google_fonts appears nowhere in the declaration', () {
      // Comments are stripped first: the ban is on the declaration, and the
      // pubspec explains in prose why the package is refused.
      final declaration = withoutYamlComments(pubspec);

      expect(
        declaration.contains('google_fonts'),
        isFalse,
        reason:
            'CLAUDE.md: fonts are bundled, never fetched — google_fonts '
            'ships an HTTP code path into an app whose central promise is that '
            'it has none',
      );
    });
  });
}
