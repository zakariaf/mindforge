import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/game_stats.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/core/run_metric.dart';
import 'package:mindforge/core/run_scope.dart';
import 'package:mindforge/core/streak_status.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/features/countdown/ui/countdown_screen.dart';
import 'package:mindforge/features/settings/ui/language_sheet.dart';
import 'package:mindforge/features/settings/widgets/settings_row.dart';
import 'package:mindforge/games/schulte_grid/application/schulte_board_notifier.dart';
import 'package:mindforge/games/schulte_grid/ui/board/schulte_tile.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/ui/components/pop_icon_button.dart';

import 'harness.dart';
import 'locale_cases.dart';
import 'shell_harness.dart';

/// Every surface a player can reach.
///
/// **One list, consumed by every sweep.** Two lists drift, and a screen missing
/// from one of them is a screen nobody checked — which is exactly how a
/// hardcoded label or a Latin digit survives to a release build.
///
/// The two SHEETS are surfaces too. They carry text, targets and a direction
/// like any screen, and the language sheet in particular is the one surface a
/// Sorani reader has to use before the app is readable at all.
enum SweepSurface {
  home,
  gameDetail,
  countdown,
  stroopRush,
  schulteGrid,
  pauseSheet,
  results,
  stats,
  settings,
  language,
  about;

  /// Whether reaching this surface means finishing a run.
  bool get needsCompletedRun => this == SweepSurface.results;
}

/// Data every sweep seeds, so the numbers on screen are worth looking at.
///
/// **An empty app renders zeros and em-dashes**, and a sweep of zeros cannot
/// see the digit classes most likely to regress: a grouped thousand, a
/// percentage, a chart label, a personal best. The first version of this file
/// seeded nothing, so every value it ever inspected was `0`, `—`, `0:00` or
/// `100%` — and the grouping-separator assertion built on it could never
/// match anything.
///
/// The figures are the design's own, from `app.html`: a 1,480 best and a
/// seven-run series peaking there.
final Map<String, Result<RunMetric?, DataFailure>> kSweepBests =
    <String, Result<RunMetric?, DataFailure>>{
      'stroop_rush': const Ok<RunMetric?, DataFailure>(
        RunMetric.points(1480),
      ),
      'schulte_grid': const Ok<RunMetric?, DataFailure>(
        RunMetric.duration(18600),
      ),
    };

/// Aggregates with four-digit values in them, for both shipped games.
final Map<RunScope, GameStats> kSweepStats = <RunScope, GameStats>{
  for (final id in <String>['stroop_rush', 'schulte_grid'])
    for (final difficulty in Difficulty.values)
      RunScope.of(GameId(id), difficulty): const GameStats(
        gamesPlayed: 128,
        // 3h 12m, which is what `app.html` prints.
        timeTrainedMs: 11520000,
        correctCount: 1204,
        wrongCount: 96,
        totalReactionMs: 770560,
        longestCombo: 11,
      ),
};

/// The Stroop run every sweep drives.
final RunConfig kSweepStroop = RunConfig(
  gameId: GameId('stroop_rush'),
  difficulty: Difficulty.classic,
  seed: 42,
);

/// The Schulte run every sweep drives.
final RunConfig kSweepSchulte = RunConfig(
  gameId: GameId('schulte_grid'),
  difficulty: Difficulty.classic,
  seed: 42,
);

/// Pumps one sweep surface with the shipped registry, in a given locale.
///
/// **The shipped registry, not fixtures.** A sweep exists to look at what
/// ships; a fixture game would hide a real board's real strings.
extension SweepPump on WidgetTester {
  Future<void> pumpSurface(
    SweepSurface surface, {
    LocaleCase? localeCase,
    Device device = Device.reference390,
    TextScaler textScaler = TextScaler.noScaling,
    bool boldText = false,
  }) async {
    Future<void> open(String location) => pumpShellApp(
      const MindForgeApp(),
      useShippedRegistry: true,
      localeCase: localeCase,
      device: device,
      textScaler: textScaler,
      boldText: boldText,
      initialLocation: location,
      bests: kSweepBests,
      stats: kSweepStats,
      streak: const StreakStatus(
        currentDays: 4,
        longestDays: 12,
        isActiveToday: true,
      ),
    );

    /// Runs the 3-2-1 out, so the board is live rather than disabled.
    Future<void> beginPlaying() async {
      for (var beat = 0; beat <= CountdownScreen.beats; beat++) {
        await pump(const Duration(seconds: 1));
      }

      await pump();
    }

    switch (surface) {
      case SweepSurface.home:
        await open(Routes.home);
      case SweepSurface.stats:
        await open(Routes.stats);
      case SweepSurface.settings:
        await open(Routes.settings);
      case SweepSurface.about:
        await open(Routes.about);
      case SweepSurface.gameDetail:
        await open(Routes.gameDetail(kSweepStroop.gameId));
      case SweepSurface.countdown:
        await open(Routes.countdown(kSweepStroop));
      case SweepSurface.stroopRush:
        await open(Routes.countdown(kSweepStroop));
        await beginPlaying();
      case SweepSurface.schulteGrid:
        await open(Routes.countdown(kSweepSchulte));
        await beginPlaying();
      case SweepSurface.pauseSheet:
        await open(Routes.countdown(kSweepStroop));
        await beginPlaying();
        // Through the pause control, not by calling the notifier: the sheet is
        // reached the way a player reaches it.
        await tap(find.byType(PopIconButton).first);
        await pump();
        await pump(const Duration(milliseconds: 400));
      case SweepSurface.language:
        await open(Routes.settings);

        final context = element(find.byType(SettingsRow).first);

        unawaited(LanguageSheet.show(context));
        await pump();
        await pump(const Duration(milliseconds: 400));
      case SweepSurface.results:
        // A REAL FINISHED RUN. Schulte ends when its last tile is found, which
        // is the only way to reach Results without faking an outcome — and a
        // faked one would sweep a screen no player ever sees.
        await open(Routes.countdown(kSweepSchulte));
        await beginPlaying();

        final container = ProviderScope.containerOf(
          element(find.byType(MaterialApp)),
        );
        final cells = container
            .read(schulteBoardNotifierProvider(kSweepSchulte))
            .cells;

        for (var value = 1; value <= cells.length; value++) {
          await tap(find.byType(SchulteTile).at(cells.indexOf(value)));
          await pump();
        }

        await pump(const Duration(milliseconds: 500));
        await pump(const Duration(milliseconds: 500));
    }
  }
}
