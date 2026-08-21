import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/features/countdown/ui/countdown_screen.dart';
import 'package:mindforge/games/stroop_rush/ui/board/answer_key.dart';
import 'package:mindforge/games/stroop_rush/ui/stroop_board.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/ui/components/hud_pill.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

import '../../../support/locale_cases.dart';
import '../../../support/shell_harness.dart';

/// The two-tier boundary, at runtime, on the real play screen.
///
/// The source-level half is `test/policy/stroop_tier_policy_test.dart`. This is
/// the half a grep cannot make: what actually got PAINTED, and where.
///
/// Run in `en` and in `fa`. The boundary is not a direction property, but the
/// WALK is — an RTL run is what catches a fill that only appears in the
/// mirrored tree.
void main() {
  const colours = SunburstColors.sunburstPop;

  final run = RunConfig(
    gameId: GameId('stroop_rush'),
    difficulty: Difficulty.classic,
    seed: 42,
  );

  /// Every gameplay colour, by value.
  final gameplay = <Color>{
    colours.playRed,
    colours.playBlue,
    colours.playGreen,
    colours.playYellow,
    colours.playPurple,
    colours.playOrange,
  };

  /// Every chrome slot a board must never read.
  ///
  /// `danger` is deliberately ABSENT: it is bound to the same primitive as
  /// `playRed`, so asserting on its VALUE would fail every red answer key. The
  /// source-level test is what forbids a board from naming it, and that is the
  /// only place the distinction is visible — which is the whole reason both
  /// halves exist.
  final chrome = <Color>{
    colours.accent,
    colours.accentAlt,
    colours.accentDeep,
    colours.success,
    colours.successDeep,
    colours.warning,
    colours.gameStroop,
    colours.gameStroopDeep,
  };

  Future<void> pumpPlaying(WidgetTester tester, LocaleCase localeCase) async {
    await tester.pumpShellApp(
      const MindForgeApp(),
      localeCase: localeCase,
      useShippedRegistry: true,
      initialLocation: Routes.countdown(run),
    );

    for (var beat = 0; beat < CountdownScreen.beats; beat++) {
      await tester.pump(const Duration(seconds: 1));
    }

    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Every fill painted inside or outside the board, depending on [inBoard].
  Set<Color> fillsPainted(WidgetTester tester, {required bool inBoard}) {
    final boardFinder = find.byType(StroopBoard);
    final surfaces = inBoard
        ? find.descendant(of: boardFinder, matching: find.byType(PopSurface))
        : find.byType(PopSurface);

    final fills = <Color>{
      for (final surface in tester.widgetList<PopSurface>(surfaces))
        surface.fill,
    };

    if (inBoard) return fills;

    // Outside means "not descended from the board", which a Finder cannot say
    // directly: collect everything and subtract the board's own.
    return fills.difference(fillsPainted(tester, inBoard: true));
  }

  for (final localeCase in LocaleCase.bothDirections) {
    group('under ${localeCase.tag}', () {
      testWidgets('no gameplay colour is painted outside the board', (
        tester,
      ) async {
        // A gameplay colour in the chrome is a hint — and the colour-blind
        // swap re-points exactly those slots, so the hint would change colour
        // for the players who need it most.
        await pumpPlaying(tester, localeCase);

        expect(find.byType(StroopBoard), findsOneWidget);
        expect(
          fillsPainted(tester, inBoard: false).intersection(gameplay),
          isEmpty,
        );
      });

      testWidgets('and no chrome slot is painted inside it', (tester) async {
        await pumpPlaying(tester, localeCase);

        expect(
          fillsPainted(tester, inBoard: true).intersection(chrome),
          isEmpty,
        );
      });

      testWidgets('the board draws no HUD pill', (tester) async {
        await pumpPlaying(tester, localeCase);

        expect(
          find.descendant(
            of: find.byType(StroopBoard),
            matching: find.byType(HudPill),
          ),
          findsNothing,
        );
      });

      testWidgets('and the shell draws no answer key', (tester) async {
        await pumpPlaying(tester, localeCase);

        final keysOutside = find
            .byType(StroopAnswerKey)
            .evaluate()
            .where(
              (element) => find
                  .ancestor(
                    of: find.byWidget(element.widget),
                    matching: find.byType(StroopBoard),
                  )
                  .evaluate()
                  .isEmpty,
            );

        expect(keysOutside, isEmpty);
      });

      testWidgets('and the HUD still shows three pills above it', (
        tester,
      ) async {
        // The other half of the boundary: the shell keeps its chrome. A test
        // that only asserted absence would pass on an empty screen.
        await pumpPlaying(tester, localeCase);

        expect(find.byType(HudPill), findsNWidgets(3));
      });
    });
  }
}
