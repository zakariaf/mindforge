import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/games/schulte_grid/ui/board/schulte_hero_art.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

import '../../../support/component_harness.dart';

/// The chips under the tagline on Schulte Grid's detail screen.
void main() {
  testWidgets('size themselves, and do not take the hero width', (
    tester,
  ) async {
    // THE DEFECT THIS EXISTS FOR. The hero reused the Home card's tile, whose
    // root is a bare AspectRatio — fine inside a 64pt frame, and inside the
    // hero it took the full column width and stood 310 points tall, so the
    // stat duo, the difficulty control and the Play button all went below the
    // fold. Stroop Rush hit exactly this and grew its own hero row; Schulte
    // inherited the bug by reusing one builder for two different drawings.
    await tester.pumpPopComponent(
      const SizedBox(
        width: 350,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: SchulteHeroArt(),
        ),
      ),
    );

    const shape = SunburstShape.sunburstPop;
    final size = tester.getSize(
      find
          .descendant(
            of: find.byType(SchulteHeroArt),
            matching: find.byType(Row),
          )
          .first,
    );

    expect(size.height, shape.heroSwatchSize);
    expect(size.width, lessThan(350));
  });
}
