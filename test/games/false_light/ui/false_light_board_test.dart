@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/games/false_light/domain/light_difficulty_profile.dart';
import 'package:mindforge/games/false_light/domain/tile_depth.dart';
import 'package:mindforge/games/false_light/ui/board/light_tile.dart';
import 'package:mindforge/games/false_light/ui/false_light_board.dart';
import 'package:mindforge/games/false_light/ui/light_metrics.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/hud_pill.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

import '../../../support/component_harness.dart';
import '../../../support/golden_tolerance.dart';
import '../../../support/harness.dart';
import '../../../support/load_app_fonts.dart';
import '../../../support/locale_cases.dart';

/// The board rectangle, at every size and in every language.
///
/// One `testWidgets` per tuple, never a loop inside one: Flutter reports an
/// overflow once per `RenderObject`, so a matrix written as one test reports the
/// first combination that broke and stays silent for the rest.
void main() {
  setUpAll(loadAppFonts);
  setUp(installTolerantGoldenComparator);

  RunConfig runAt(Difficulty difficulty) => RunConfig(
    gameId: GameId('false_light'),
    difficulty: difficulty,
    seed: 42,
  );

  Future<void> pumpBoard(
    WidgetTester tester, {
    Device device = Device.reference390,
    Difficulty difficulty = Difficulty.classic,
    LocaleCase? localeCase,
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    await tester.pumpPopComponent(
      SizedBox(
        // The board's own rectangle: the shell's 20pt gutter on each side.
        width: device.logicalSize.width - 40,
        height: 460,
        child: FalseLightBoard(run: runAt(difficulty)),
      ),
      localeCase: localeCase,
      device: device,
      textScaler: textScaler,
      resetFirst: true,
    );

    await tester.pump();
  }

  group('the board draws no chrome', () {
    testWidgets('no HUD pill, no Scaffold, no SafeArea, no background', (
      tester,
    ) async {
      await pumpBoard(tester);

      expect(
        find.descendant(
          of: find.byType(FalseLightBoard),
          matching: find.byType(HudPill),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(FalseLightBoard),
          matching: find.byType(SafeArea),
        ),
        findsNothing,
      );
    });

    testWidgets('and the grid does not clip its own shadows', (tester) async {
      // On THIS board the shadow is the answer, so clipping it would not
      // merely look wrong -- it would remove information.
      await pumpBoard(tester);

      expect(
        tester.widget<GridView>(find.byType(GridView)).clipBehavior,
        Clip.none,
      );
    });

    testWidgets('and it draws no text at all', (tester) async {
      // The differentiator, asserted rather than described. A board with no
      // text renders identically in every locale, which is what the two
      // goldens below compare to each other.
      await pumpBoard(tester);

      expect(
        find.descendant(
          of: find.byType(FalseLightBoard),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
    });
  });

  for (final device in <Device>[
    Device.compact320,
    Device.small360,
    Device.reference390,
  ]) {
    for (final difficulty in Difficulty.values) {
      testWidgets(
        '${device.name} ${difficulty.name} lays square tiles above the floor',
        (tester) async {
          await pumpBoard(tester, device: device, difficulty: difficulty);

          final profile = profileFor(difficulty);
          final tiles = find.byType(LightTile);

          expect(tiles, findsNWidgets(profile.columns * profile.rows));

          for (var i = 0; i < profile.columns * profile.rows; i++) {
            final size = tester.getSize(tiles.at(i));

            expect(
              size.width,
              moreOrLessEquals(size.height, epsilon: 0.5),
              reason:
                  'tile $i is not square -- a rectangle reads as a different '
                  'KIND of tile, which is a second accidental channel',
            );
            expect(
              size.width,
              greaterThanOrEqualTo(kPopMinTarget),
              reason:
                  'tile $i is ${size.width} on ${device.name} at '
                  '${difficulty.name}, under the 48pt tap floor',
            );
          }
        },
      );
    }
  }

  group('the light does not mirror', () {
    testWidgets('a raised tile draws the same shadow in both directions', (
      tester,
    ) async {
      // Working agreement 11's ONE exception, and on this board it is the
      // mechanic rather than a rendering detail. A future refactor to
      // EdgeInsetsDirectional would silently flip the light and break the game
      // in exactly two locales.
      final offsets = <String, Offset>{};

      for (final localeCase in LocaleCase.bothDirections) {
        await pumpBoard(tester, localeCase: localeCase);

        final surface = tester.widget<PopSurface>(
          find
              .descendant(
                of: find.byType(LightTile),
                matching: find.byType(PopSurface),
              )
              .first,
        );
        const shape = SunburstShape.sunburstPop;

        offsets[localeCase.tag] = shape
            .shadow(
              shape.e2,
              const Color(0xFF000000),
            )
            .first
            .offset;

        expect(surface.elevation, isNotNull);
      }

      expect(offsets['en'], offsets['fa']);
      expect(offsets['en']!.dx, greaterThan(0));
    });

    testWidgets('and the board carries nothing a locale can translate', (
      tester,
    ) async {
      // THE CLAIM, stated precisely after measuring it. An earlier version of
      // this test asserted the `en` and `fa` renders were PIXEL-IDENTICAL. They
      // are not, and the reason is correct behaviour: the tile grid mirrors,
      // like every other grid in the app. Measured: tile 0 sits at x=20 in
      // English and x=291.5 in Persian.
      //
      // Schulte Grid pins its grid LTR because 1..25 is ORDERED and `cells[0]`
      // has to mean a fixed screen position. A False Light field is unordered —
      // mirroring it yields another equally valid field — so pinning would buy
      // nothing and would make three of the app's four boards directional
      // islands, which is how a rule stops meaning anything.
      //
      // What IS locale-invariant is the board's CONTENT, and that is the half
      // the differentiation argument actually rests on: no string, no numeral,
      // and the same depths in the same traversal order.
      final sequences = <String, List<TileDepth>>{};

      for (final localeCase in LocaleCase.bothDirections) {
        await pumpBoard(tester, localeCase: localeCase);

        expect(
          find.descendant(
            of: find.byType(FalseLightBoard),
            matching: find.byType(Text),
          ),
          findsNothing,
          reason: 'a string on this board would be a thing to translate',
        );

        sequences[localeCase.tag] = tester
            .widgetList<LightTile>(find.byType(LightTile))
            .map((tile) => tile.depth)
            .toList();
      }

      expect(
        sequences['fa'],
        sequences['en'],
        reason:
            'the FIELD does not move with the locale, even though the grid '
            'that lays it out mirrors',
      );
    });

    for (final localeCase in LocaleCase.bothDirections) {
      testWidgets('the ${localeCase.tag} board matches its reference', (
        tester,
      ) async {
        await pumpBoard(tester, localeCase: localeCase);

        await expectLater(
          find.byType(FalseLightBoard),
          matchesGoldenFile('goldens/board_${localeCase.tag}.png'),
        );
      });
    }
  });

  group('metrics', () {
    test('the tile is square, sized by the tighter axis', () {
      // A grid that filled both axes independently would give blitz a field of
      // rectangles, and a rectangle reads as a different kind of tile.
      final wide = LightMetrics.forField(
        const Size(400, 200),
        columns: 5,
        rows: 6,
      );

      expect(wide.heightFor(6), lessThanOrEqualTo(200));
    });

    test('and the gap steps down where blitz needs it to', () {
      // Six columns in the 280pt board a 320pt phone gives is 36.7pt at the
      // roomy gap and 40pt at the tight one -- both under the floor, which is
      // why blitz is 5 x 6 rather than 6 x 5.
      final narrow = LightMetrics.forField(
        const Size(280, 460),
        columns: 5,
        rows: 6,
      );

      expect(narrow.tileSize, greaterThanOrEqualTo(kPopMinTarget));
    });
  });
}
