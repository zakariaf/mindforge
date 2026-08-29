import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/games/false_light/domain/tile_depth.dart';
import 'package:mindforge/games/false_light/ui/board/light_tile.dart';
import 'package:mindforge/games/false_light/ui/false_light_board.dart';
import 'package:mindforge/l10n/app_localizations.dart';

import '../../../support/component_harness.dart';
import '../../../support/load_app_fonts.dart';
import '../../../support/locale_cases.dart';

/// What a screen reader is told, in every language.
///
/// **This board has exactly one visual channel and a screen-reader user cannot
/// use it.** Depth is a shadow, an offset and a fill value; none of the three
/// reaches a reader who cannot see them. So the label has to say "raised" or
/// "pressed" in words, or the game is not merely harder without sight — it is
/// unplayable.
///
/// It is also the reason the board carries ARB keys at all despite drawing no
/// text. `engine_locale_purity_test` asserts both halves: no `Text(` under the
/// tree, AND the three tile-state keys present.
void main() {
  setUpAll(loadAppFonts);

  final run = RunConfig(
    gameId: GameId('false_light'),
    difficulty: Difficulty.classic,
    seed: 42,
  );

  Future<void> pumpBoard(WidgetTester tester, LocaleCase localeCase) async {
    await tester.pumpPopComponent(
      SizedBox(width: 350, height: 460, child: FalseLightBoard(run: run)),
      localeCase: localeCase,
      resetFirst: true,
    );

    await tester.pump();
  }

  for (final localeCase in LocaleCase.all) {
    testWidgets('${localeCase.tag} says which depth every tile is', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pumpBoard(tester, localeCase);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(FalseLightBoard)),
      );
      final tiles = tester.widgetList<LightTile>(find.byType(LightTile));

      expect(tiles, isNotEmpty);

      for (final tile in tiles) {
        expect(
          tile.semanticLabel,
          tile.depth == TileDepth.pressed
              ? l10n.lightTilePressed
              : l10n.lightTileRaised,
          reason:
              'depth is the only visual channel here, so the label IS the '
              'board for a reader who cannot see a shadow',
        );
      }

      handle.dispose();
    });

    testWidgets('${localeCase.tag} and the two labels are distinguishable', (
      tester,
    ) async {
      // A translation that rendered "raised" and "pressed" as the same phrase
      // would pass the test above and leave the board unplayable. Checked per
      // locale rather than in English only, because that is where it would
      // happen.
      await pumpBoard(tester, localeCase);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(FalseLightBoard)),
      );

      expect(l10n.lightTilePressed, isNot(l10n.lightTileRaised));
      expect(l10n.lightTileSwept, isNot(l10n.lightTileRaised));
      expect(l10n.lightTileSwept, isNot(l10n.lightTilePressed));
    });

    testWidgets('${localeCase.tag} exposes a tile as a tappable button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pumpBoard(tester, localeCase);

      final tile = tester.widget<LightTile>(find.byType(LightTile).first);

      expect(
        tester.getSemantics(find.bySemanticsLabel(tile.semanticLabel).first),
        matchesSemantics(
          label: tile.semanticLabel,
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );

      handle.dispose();
    });
  }
}
