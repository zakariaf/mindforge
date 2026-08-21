@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/games/stroop_rush/ui/stroop_board.dart';

import '../../../support/component_harness.dart';
import '../../../support/golden_tolerance.dart';
import '../../../support/load_app_fonts.dart';
import '../../../support/locale_cases.dart';

/// The board with every hue removed.
///
/// **The acceptance question, and it is a human one: from this image alone, can
/// each key be matched to the word?** If the answer is "only by reading the
/// labels", the pattern pass is broken — and under `fa` that answer is also
/// unavailable to anyone who cannot read Persian, which is exactly the point of
/// having a second channel.
///
/// Red and green collapse to the same olive under deuteranopia and to the same
/// grey here. Stripe, dot, ring and solid never do.
///
/// Both palettes, because the colour-blind one is not exempt: it re-points four
/// hues and changes none of the patterns, so if the patterns were doing no work
/// the swap would be the only thing standing between two answers.
void main() {
  setUpAll(loadAppFonts);
  // THE SAME TOLERANCE EVERY OTHER GOLDEN LANE IN THIS REPO INSTALLS. A golden
  // blessed on a developer's Mac and compared on a GitHub runner differs by a
  // few pixels of anti-aliasing even with identical Flutter, identical fonts
  // and identical DPR — and this file paints through two `saveLayer`s and a
  // `BlendMode.srcIn`, which is where that noise is largest. Omitting it made
  // these four the only golden tests in the suite that failed on CI while
  // passing locally.
  setUp(installTolerantGoldenComparator);

  final run = RunConfig(
    gameId: GameId('stroop_rush'),
    difficulty: Difficulty.classic,
    seed: 42,
  );

  Future<void> pumpGreyBoard(
    WidgetTester tester, {
    required LocaleCase localeCase,
    required bool colourBlind,
  }) => tester.pumpPopComponent(
    // THE HARNESS'S OWN `settings:`, not a nested ProviderScope. A nested
    // scope overriding `settingsProvider` moves nothing: `appSettingsProvider`
    // is not itself scoped there, so it resolves in the ROOT container and
    // reads the root's settings. Both colour-blind goldens were byte-identical
    // to their default siblings for exactly that reason, and the cvd lane was
    // proving nothing while looking like coverage.
    RepaintBoundary(
      child: Greyscale(
        child: SizedBox(width: 350, height: 520, child: StroopBoard(run: run)),
      ),
    ),
    localeCase: localeCase,
    settings: const AppSettings.defaults().copyWith(
      isColourBlindPalette: colourBlind,
    ),
  );

  for (final localeCase in LocaleCase.bothDirections) {
    for (final colourBlind in <bool>[false, true]) {
      final palette = colourBlind ? 'cvd' : 'default';

      testWidgets('${localeCase.tag} $palette', (tester) async {
        await pumpGreyBoard(
          tester,
          localeCase: localeCase,
          colourBlind: colourBlind,
        );

        await expectLater(
          find.byType(RepaintBoundary).first,
          matchesGoldenFile(
            'goldens/greyscale/board_${localeCase.tag}_$palette.png',
          ),
        );
      });
    }
  }
}
