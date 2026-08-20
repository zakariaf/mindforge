@Tags(['golden'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

import '../../support/component_harness.dart';
import '../../support/golden_tolerance.dart';
import '../../support/load_app_fonts.dart';
import '../../support/locale_cases.dart';

/// The glyph set, rendered — which is the only way to review artwork.
///
/// The `en` and `fa` sheets are the mirror table as a picture: put them side by
/// side and exactly three marks should have moved. That is a far faster review
/// than reading seventeen boolean assertions, and it is the check that catches
/// a glyph drawn asymmetrically by accident.
void main() {
  const colours = SunburstColors.sunburstPop;

  setUpAll(() async {
    await loadAppFonts();
    installTolerantGoldenComparator();
  });

  Widget sheet({required bool greyscale}) {
    final grid = ColoredBox(
      color: colours.surface,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(12),
        child: Wrap(
          spacing: 16,
          runSpacing: 14,
          children: [
            for (final glyph in SunburstGlyph.values)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Both weights, so the sheet shows the resolver's split as
                  // well as the artwork: 22 takes the lighter nav stroke, 18
                  // the heavier control stroke.
                  SunburstGlyphIcon(glyph),
                  const SizedBox(height: 4),
                  SunburstGlyphIcon(glyph, size: 18),
                ],
              ),
          ],
        ),
      ),
    );

    return greyscale ? Greyscale(child: grid) : grid;
  }

  for (final localeCase in <LocaleCase>[
    LocaleCase.all.first,
    LocaleCase.rightToLeft.first,
  ]) {
    testWidgets('the glyph sheet in ${localeCase.tag}', (tester) async {
      await tester.pumpPopComponent(
        RepaintBoundary(child: sheet(greyscale: false)),
        localeCase: localeCase,
      );

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile(popGolden('glyph_sheet', localeCase)),
      );
    });
  }

  testWidgets('and in greyscale', (tester) async {
    // Every mark is a stroke in one ink, so this sheet should be almost
    // unchanged. A glyph that only reads because of its colour shows up here.
    await tester.pumpPopComponent(
      RepaintBoundary(child: sheet(greyscale: true)),
    );

    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('goldens/greyscale/glyph_sheet.png'),
    );
  });
}
