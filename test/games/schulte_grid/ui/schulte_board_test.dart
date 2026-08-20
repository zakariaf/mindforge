import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/games/schulte_grid/application/schulte_board_notifier.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_tile_state.dart';
import 'package:mindforge/games/schulte_grid/ui/board/schulte_tile.dart';
import 'package:mindforge/games/schulte_grid/ui/schulte_board.dart';
import 'package:mindforge/ui/components/hud_pill.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

import '../../../support/component_harness.dart';
import '../../../support/harness.dart';
import '../../../support/load_app_fonts.dart';
import '../../../support/locale_cases.dart';

/// The board rectangle, at every size and in every language.
///
/// One `testWidgets` per tuple, never a loop inside one: Flutter reports an
/// overflow once per `RenderObject`, so a matrix written as one test reports
/// the first combination that broke and stays silent for the rest.
void main() {
  setUpAll(loadAppFonts);

  final run = RunConfig(
    gameId: GameId('schulte_grid'),
    difficulty: Difficulty.classic,
    seed: 42,
  );

  Future<void> pumpBoard(
    WidgetTester tester, {
    Device device = Device.reference390,
    LocaleCase? localeCase,
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    await tester.pumpPopComponent(
      SizedBox(
        // The board's own rectangle: the shell's 20pt gutter on each side.
        width: device.logicalSize.width - 40,
        height: device.logicalSize.width - 40,
        child: SchulteBoard(run: run),
      ),
      localeCase: localeCase,
      device: device,
      textScaler: textScaler,
      // The direction tests pump twice in one test, in two locales.
      resetFirst: true,
    );

    // The board opens on the first post-frame callback.
    await tester.pump();
  }

  group('the board draws no chrome', () {
    testWidgets('no HUD pill, no Scaffold, no SafeArea, no background', (
      tester,
    ) async {
      // The gutter and the turquoise behind it are the shell's, asked for by
      // the definition's `BoardBackground.gameAccent`. A board that painted
      // its own would be the second owner of a colour.
      await pumpBoard(tester);

      expect(
        find.descendant(
          of: find.byType(SchulteBoard),
          matching: find.byType(HudPill),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(SchulteBoard),
          matching: find.byType(SafeArea),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(SchulteBoard),
          matching: find.byType(ColoredBox),
        ),
        findsNothing,
      );
    });

    testWidgets('and the grid does not clip its own shadows', (tester) async {
      await pumpBoard(tester);

      expect(
        tester.widget<GridView>(find.byType(GridView)).clipBehavior,
        Clip.none,
      );
    });
  });

  for (final device in <Device>[
    Device.compact320,
    Device.small360,
    Device.reference390,
  ]) {
    for (final localeCase in LocaleCase.all) {
      testWidgets('${device.name} ${localeCase.tag} lays 25 square tiles out', (
        tester,
      ) async {
        await pumpBoard(tester, device: device, localeCase: localeCase);

        final tiles = find.byType(SchulteTile);

        expect(tiles, findsNWidgets(25));

        for (var i = 0; i < 25; i++) {
          final size = tester.getSize(tiles.at(i));

          expect(
            size.width,
            moreOrLessEquals(size.height, epsilon: 0.5),
            reason: 'tile $i is not square',
          );
          expect(
            size.shortestSide,
            greaterThanOrEqualTo(kPopMinTarget),
            reason: 'tile $i is under the tap floor',
          );
        }

        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final scale in <double>[1.3, 2]) {
    for (final localeCase in LocaleCase.all) {
      testWidgets('390 ${localeCase.tag} at ${scale}x does not overflow', (
        tester,
      ) async {
        await pumpBoard(
          tester,
          localeCase: localeCase,
          textScaler: TextScaler.linear(scale),
        );

        expect(tester.takeException(), isNull);
      });
    }
  }

  group('the grid does not mirror', () {
    testWidgets('the same value sits at the same offset in en and fa', (
      tester,
    ) async {
      // THE NAMED DIRECTION TEST. `cells[0]` must mean one screen position in
      // every locale, or every geometry assertion and the reference PNG fork.
      await pumpBoard(tester);

      final english = <Offset>[
        for (var i = 0; i < 25; i++)
          tester.getTopLeft(find.byType(SchulteTile).at(i)),
      ];
      final englishFirst = tester
          .widget<SchulteTile>(find.byType(SchulteTile).first)
          .label;

      await pumpBoard(tester, localeCase: LocaleCase.persian);

      for (var i = 0; i < 25; i++) {
        expect(
          tester.getTopLeft(find.byType(SchulteTile).at(i)),
          english[i],
          reason: 'tile $i moved between en and fa',
        );
      }

      // The VALUE at the visual top-left is the same board position, even
      // though the glyph that draws it is a different numeral.
      expect(
        tester.widget<SchulteTile>(find.byType(SchulteTile).first).label,
        isNot(englishFirst),
        reason: 'fa should render a different NUMERAL for the same value',
      );
    });

    testWidgets('and the hard offset shadow does not mirror either', (
      tester,
    ) async {
      // A light-source constant, not a reading-direction property. Asserted on
      // the value because it is the thing a reviewer queries and a golden
      // cannot answer.
      for (final localeCase in <LocaleCase>[
        LocaleCase.all.first,
        LocaleCase.persian,
      ]) {
        await pumpBoard(tester, localeCase: localeCase);

        final decorated = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(SchulteTile).first,
                matching: find.byType(DecoratedBox),
              ),
            )
            .map((box) => box.decoration)
            .whereType<BoxDecoration>()
            .where((d) => (d.boxShadow ?? const <BoxShadow>[]).isNotEmpty);

        for (final decoration in decorated) {
          expect(
            decoration.boxShadow!.single.offset.dx,
            greaterThan(0),
            reason: '${localeCase.tag} flipped the shadow',
          );
        }
      }
    });
  });

  group('a tap', () {
    testWidgets('reaches the tile it landed on, in both directions', (
      tester,
    ) async {
      // Proves the LTR-pinned island did not desynchronise pointer mapping
      // from paint: what the player touches is what resolves.
      for (final localeCase in <LocaleCase>[
        LocaleCase.all.first,
        LocaleCase.persian,
      ]) {
        await pumpBoard(tester, localeCase: localeCase);

        final container = ProviderScope.containerOf(
          tester.element(find.byType(SchulteBoard)),
        );
        final cells = container.read(schulteBoardNotifierProvider(run)).cells;
        final index = cells.indexOf(1);

        await tester.tap(find.byType(SchulteTile).at(index));
        await tester.pump();

        expect(
          container.read(schulteBoardNotifierProvider(run)).stateOf(index),
          SchulteTileState.found,
          reason: '${localeCase.tag} did not resolve the tapped tile',
        );
      }
    });
  });
}
