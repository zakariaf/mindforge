@Tags(<String>['golden'])
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/games/false_light/domain/light_board_state.dart';
import 'package:mindforge/games/false_light/domain/tile_depth.dart';
import 'package:mindforge/games/false_light/ui/board/light_tile.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

import '../../../support/component_harness.dart';
import '../../../support/golden_tolerance.dart';
import '../../../support/load_app_fonts.dart';
import '../../../support/locale_cases.dart';

/// The tile states, with every hue removed.
///
/// **The acceptance question, and it is a human one: from this image alone, can
/// a raised tile be told from a pressed one?** On every other board in the app
/// that question has a fallback — a numeral, a word, an answer colour. This one
/// has none. Depth is the whole game, so if grey erases it the game does not
/// exist.
///
/// The channels that carry it are three, and none is hue:
///
/// - **shadow** — a raised tile draws a hard offset shadow, a pressed one draws
///   nothing at all;
/// - **position** — a pressed tile is translated into where its shadow was;
/// - **fill value** — paper against the accent's deep half, which is a
///   luminance difference and survives grey where a hue difference would not.
///
/// A swept tile takes the RAISED construction deliberately, so the board
/// visibly empties as it is cleared. That is why `lightTileSwept` is its own
/// screen-reader string rather than reusing "raised": the two look alike on
/// purpose, and a reader told "raised" could not tell what is left to do.
void main() {
  setUpAll(loadAppFonts);
  // The same tolerance every golden lane in this repo installs.
  setUp(installTolerantGoldenComparator);

  Widget tile(TileDepth depth, LightTileState state) => LightTile(
    depth: depth,
    state: state,
    wrongTapId: 0,
    semanticLabel: 'tile',
    onTap: () {},
  );

  const cases = <(TileDepth, LightTileState)>[
    (TileDepth.raised, LightTileState.idle),
    (TileDepth.pressed, LightTileState.idle),
    (TileDepth.pressed, LightTileState.swept),
    (TileDepth.raised, LightTileState.rejected),
    (TileDepth.raised, LightTileState.locked),
  ];

  for (final localeCase in LocaleCase.bothDirections) {
    testWidgets('raised and pressed are distinct in grey — ${localeCase.tag}', (
      tester,
    ) async {
      await tester.pumpPopComponent(
        RepaintBoundary(
          child: Greyscale(
            child: Padding(
              // Room for the hard shadow to draw outside its tile.
              padding: const EdgeInsets.all(SunburstShape.space3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final entry in cases) ...<Widget>[
                    if (entry != cases.first)
                      const SizedBox(width: SunburstShape.space3),
                    SizedBox.square(
                      dimension: 52,
                      child: tile(entry.$1, entry.$2),
                    ),
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
      final measured = <TileDepth, ({Color fill, bool hasShadow, double dy})>{};

      for (final depth in TileDepth.values) {
        await tester.pumpPopComponent(
          SizedBox.square(
            dimension: 60,
            child: tile(depth, LightTileState.idle),
          ),
          resetFirst: true,
        );

        final surface = tester.widget<PopSurface>(
          find.byType(PopSurface).first,
        );
        // SUMMED over the subtree. The tile's own translate sits inside
        // ShakeOnWrong's, which is the identity at rest -- picking one by
        // position would be picking whichever nests deeper today.
        var dy = 0.0;

        for (final transform in tester.widgetList<Transform>(
          find.descendant(
            of: find.byType(LightTile),
            matching: find.byType(Transform),
          ),
        )) {
          dy += transform.transform.getTranslation().y;
        }

        measured[depth] = (
          fill: surface.fill,
          hasShadow: surface.elevation != PopElevation.flat,
          dy: dy,
        );
      }

      final raised = measured[TileDepth.raised]!;
      final pressed = measured[TileDepth.pressed]!;

      expect(
        raised.hasShadow,
        isNot(pressed.hasShadow),
        reason: 'channel 1 of 3: only one of them draws a shadow',
      );
      expect(
        raised.dy,
        isNot(pressed.dy),
        reason: 'channel 2 of 3: a pressed tile sits where its shadow was',
      );
      expect(
        _luminance(raised.fill),
        isNot(closeTo(_luminance(pressed.fill), 0.2)),
        reason:
            'channel 3 of 3: the fills differ in VALUE, not only in hue -- '
            'which is what survives greyscale',
      );
    });
  });

  group('the colour-blind palette', () {
    testWidgets('changes nothing on this board, because nothing is an answer', (
      tester,
    ) async {
      // THE ASSERTION THE 4.3(a) RESPONSE RESTS ON. The setting re-points the
      // gameplay answer slots; this board has none, so there is nothing to
      // re-point. Measured on the rendered fills rather than argued.
      final fills = <bool, List<Color>>{};

      for (final colourBlind in <bool>[false, true]) {
        await tester.pumpPopComponent(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final entry in cases)
                SizedBox.square(
                  dimension: 52,
                  child: tile(entry.$1, entry.$2),
                ),
            ],
          ),
          settings: const AppSettings.defaults().copyWith(
            isColourBlindPalette: colourBlind,
          ),
          resetFirst: true,
        );

        fills[colourBlind] = tester
            .widgetList<PopSurface>(find.byType(PopSurface))
            .map((surface) => surface.fill)
            .toList();
      }

      expect(fills[true], fills[false]);
    });
  });
}

/// WCAG relative luminance, computed rather than eyeballed.
double _luminance(Color colour) {
  double channel(double component) => component <= 0.03928
      ? component / 12.92
      : math.pow((component + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * channel(colour.r) +
      0.7152 * channel(colour.g) +
      0.0722 * channel(colour.b);
}
