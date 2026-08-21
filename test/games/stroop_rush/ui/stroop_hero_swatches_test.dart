import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/games/stroop_rush/ui/board/play_fill_painter.dart';
import 'package:mindforge/games/stroop_rush/ui/board/stroop_hero_swatches.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

import '../../../support/component_harness.dart';

/// The four chips under the tagline on the game detail screen.
///
/// **They are the legend for the second channel.** `app.html` draws them
/// carrying the ink fill pattern, not flat hue — which is the whole argument
/// for having a second channel at all, made where a player meets the game
/// rather than in the middle of a timed round.
void main() {
  group('the hero swatch row', () {
    testWidgets('is four chips, each painting its own pattern', (tester) async {
      await tester.pumpPopComponent(const StroopHeroSwatches());

      final painters = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(StroopHeroSwatches),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((paint) => paint.painter)
          .whereType<PlayFillPainter>()
          .toList();

      expect(painters, hasLength(4));
      expect(
        painters.map((p) => p.scene.fill).toSet(),
        PlayFill.values.toSet(),
        reason: 'all four patterns, so the row is a legend and not a palette',
      );
    });

    testWidgets('and it takes the design own size, not the field it is in', (
      tester,
    ) async {
      // THE DEFECT THIS EXISTS FOR. The hero used to embed the Home card's 2x2
      // quad, which sizes itself to whatever it is given — so inside a hero it
      // grew to the full column width and stood about seven hundred points
      // tall, with no patterns on it.
      // ALIGN, not a bare SizedBox: a SizedBox(width:) hands its child a
      // TIGHT width, which no widget can decline. The hero lays its children
      // out in a Column with a stretched cross axis, which is loose in the
      // other direction — Align reproduces that, and it is what lets a row
      // that wants to be small actually be small.
      await tester.pumpPopComponent(
        const SizedBox(
          width: 350,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: StroopHeroSwatches(),
          ),
        ),
      );

      const shape = SunburstShape.sunburstPop;
      // The ROW, not the wrapper: `ExcludeSemantics` passes the hero's own
      // constraints straight through, so measuring the outer widget measures
      // the hero. What must not grow is the drawing inside it.
      final size = tester.getSize(
        find
            .descendant(
              of: find.byType(StroopHeroSwatches),
              matching: find.byType(Row),
            )
            .first,
      );

      expect(size.height, shape.heroSwatchSize);
      expect(size.width, lessThan(350));
      expect(
        size.width,
        4 * shape.heroSwatchSize + 3 * SunburstShape.space2,
        reason: 'four chips and three gaps, and nothing else',
      );
    });
  });
}
