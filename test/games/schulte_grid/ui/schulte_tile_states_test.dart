@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_tile_state.dart';
import 'package:mindforge/games/schulte_grid/ui/board/next_ring_painter.dart';
import 'package:mindforge/games/schulte_grid/ui/board/schulte_tile.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

import '../../../support/component_harness.dart';
import '../../../support/golden_tolerance.dart';
import '../../../support/load_app_fonts.dart';
import '../../../support/locale_cases.dart';

/// The five tile states, with every hue removed.
///
/// **The acceptance question, and it is a human one: from this image alone, can
/// the five states be told apart?** If the answer is "only by colour", rule 4
/// is broken — and on this board the answer has to survive a Persian reader who
/// cannot use the numerals as a fallback either, because a found `۷` and an
/// idle `۷` are the same glyph.
///
/// The channels that carry it are depth and shape: `next` lifts and gains a
/// double ring, `found` sinks two points and loses its shadow, `wrong` sinks
/// the same way and shakes. Grey cannot erase any of those.
///
/// **What the image actually shows, read honestly.** `next` is unmistakable —
/// nothing else has a ring. `found` and `wrong` are both sunk and flat, and in
/// the still they differ by VALUE: mid-grey against near-black. That is a
/// legitimate second channel — luminance survives greyscale where hue does not
/// — and `wrong` also shakes, which a still cannot show. `idle` and `disabled`
/// are identical on purpose: `disabled` is only ever the whole board at once,
/// behind the countdown, so there is nothing for it to be confused with.
void main() {
  setUpAll(loadAppFonts);
  // The same tolerance every golden lane in this repo installs — see
  // `golden_tolerance.dart` for the measured noise it covers and the
  // regressions it still catches.
  setUp(installTolerantGoldenComparator);

  Widget row(SchulteTileState state) => SchulteTile(
    label: '7',
    semanticLabel: '7',
    state: state,
    wrongTapId: 0,
    onTap: () {},
  );

  for (final localeCase in LocaleCase.bothDirections) {
    testWidgets('the five states are distinct in grey — ${localeCase.tag}', (
      tester,
    ) async {
      await tester.pumpPopComponent(
        RepaintBoundary(
          child: Greyscale(
            child: Padding(
              // Room for the next tile's 5pt ring to draw outside its tile.
              padding: const EdgeInsets.all(SunburstShape.space3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final state in SchulteTileState.values) ...<Widget>[
                    if (state != SchulteTileState.values.first)
                      const SizedBox(width: SunburstShape.space3),
                    SizedBox.square(dimension: 52, child: row(state)),
                  ],
                ],
              ),
            ),
          ),
        ),
        localeCase: localeCase,
        resetFirst: true,
      );

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/greyscale/tiles_${localeCase.tag}.png'),
      );
    });
  }

  group('the channels that survive grey', () {
    testWidgets('are asserted on values, not left to the image', (
      tester,
    ) async {
      // A golden says "this looks like it did". These say WHY it is legible.
      const shape = SunburstShape.sunburstPop;

      for (final state in SchulteTileState.values) {
        await tester.pumpPopComponent(
          SizedBox.square(dimension: 60, child: row(state)),
          resetFirst: true,
        );

        final surface = tester.widget<PopSurface>(
          find.byType(PopSurface).first,
        );
        // SUMMED over the subtree. The tile's own translate sits inside
        // ShakeOnWrong's, which is the identity at rest — picking one by
        // position would be picking whichever nests deeper today.
        var dx = 0.0;
        var dy = 0.0;

        for (final transform in tester.widgetList<Transform>(
          find.descendant(
            of: find.byType(SchulteTile),
            matching: find.byType(Transform),
          ),
        )) {
          dx += transform.transform.getTranslation().x;
          dy += transform.transform.getTranslation().y;
        }

        switch (state) {
          case SchulteTileState.idle || SchulteTileState.disabled:
            expect(surface.elevation, PopElevation.e1);
            expect(dx, 0);
          case SchulteTileState.next:
            expect(surface.elevation, PopElevation.e2);
            expect(
              find
                  .byType(CustomPaint)
                  .evaluate()
                  .where(
                    (e) =>
                        (e.widget as CustomPaint).foregroundPainter
                            is NextRingPainter,
                  ),
              hasLength(1),
              reason: 'the ring is the channel that is not a hue',
            );
          case SchulteTileState.found || SchulteTileState.wrong:
            expect(surface.elevation, PopElevation.flat);
            expect(dx, shape.tileFoundSink.dx);
            expect(dy, shape.tileFoundSink.dy);
        }
      }
    });

    testWidgets('and only the NEXT tile carries a ring', (tester) async {
      // The cue has to be unique or it is not a cue.
      for (final state in SchulteTileState.values) {
        await tester.pumpPopComponent(
          SizedBox.square(dimension: 60, child: row(state)),
          resetFirst: true,
        );

        final rings = find
            .byType(CustomPaint)
            .evaluate()
            .where(
              (e) =>
                  (e.widget as CustomPaint).foregroundPainter
                      is NextRingPainter,
            );

        expect(
          rings,
          hasLength(state == SchulteTileState.next ? 1 : 0),
          reason: '$state',
        );
      }
    });
  });
}
