import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_metric.dart';
import 'package:mindforge/core/run_record.dart';
import 'package:mindforge/core/run_scope.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/game_registry.dart';

/// One game's headline number.
@immutable
final class GameBest {
  /// Creates the pair.
  const GameBest({required this.definition, required this.metric});

  /// Which game.
  final GameDefinition definition;

  /// Its best run, or `null` when it has none.
  ///
  /// **Nullable rather than a zero.** A game nobody has played has no best,
  /// and a zero in any locale states a score that was never achieved.
  final RunMetric? metric;
}

/// Everything the Stats screen renders, with no rendered string in it.
@immutable
final class StatsState {
  /// Creates the state.
  const StatsState({
    required this.bests,
    required this.gamesPlayed,
    required this.timeTrainedMs,
    required this.chartGame,
    required this.series,
  });

  /// One entry per **unlocked** game, in registry order.
  ///
  /// A locked game has no history to show and listing it would promise one.
  final List<GameBest> bests;

  /// Runs across every game.
  final int gamesPlayed;

  /// Time spent playing, across every game.
  final int timeTrainedMs;

  /// Which game the chart is about, or `null` when nothing has been played.
  final GameDefinition? chartGame;

  /// That game's recent runs, **oldest first**.
  ///
  /// Oldest first whatever the reading direction. A chart is a time axis, and
  /// a Persian build that reversed it would say the player got worse.
  final List<RunRecord> series;

  /// Whether there is any history to chart.
  bool get isEmpty => series.isEmpty;
}

/// The Stats screen's state.
///
/// **It reads E02's seams and owns no repository of its own.** There is no
/// `StatsRepository`: every number here is a fold over `runs`, recomputed on
/// read, so there is never a cached total to desynchronise.
final Provider<StatsState> statsHubProvider = Provider<StatsState>((ref) {
  final unlocked = ref
      .watch(gameRegistryProvider)
      .where((game) => !game.isLocked)
      .toList();
  final bests = ref.watch(allBestsProvider).value;

  var gamesPlayed = 0;
  var timeTrainedMs = 0;
  GameDefinition? chartGame;

  final entries = <GameBest>[];

  for (final game in unlocked) {
    final stats = ref.watch(runStatsProvider(RunScope.of(game.id, null))).value;

    gamesPlayed += stats?.gamesPlayed ?? 0;
    timeTrainedMs += stats?.timeTrainedMs ?? 0;

    entries.add(
      GameBest(
        definition: game,
        metric: switch (bests?[game.id.value]) {
          Ok(:final value) => value,
          // A read that failed is not a zero: the card says "no best yet"
          // until the store answers, which is what it says for a game nobody
          // has played too.
          Err() || null => null,
        },
      ),
    );

    // THE FIRST UNLOCKED GAME WITH ANY RUNS, in registry order. Not "the most
    // recently played", which would need every row of every game loaded to
    // decide, and not something the player picks — the chart is a glance, and
    // a chooser on it is a feature nobody asked for. A game with no runs is
    // skipped rather than charted as a flat line at zero.
    if (chartGame == null && (stats?.gamesPlayed ?? 0) > 0) chartGame = game;
  }

  final game = chartGame;

  return StatsState(
    bests: entries,
    gamesPlayed: gamesPlayed,
    timeTrainedMs: timeTrainedMs,
    chartGame: game,
    // REVERSED, because the DAO orders newest first for paging and a chart
    // reads oldest to latest. Done here rather than in the painter: a painter
    // that reordered its input would be making a product decision on a canvas.
    series: game == null
        ? const <RunRecord>[]
        : (ref.watch(chartSeriesProvider(RunScope.of(game.id, null))).value ??
                  const <RunRecord>[])
              .reversed
              .toList(),
  );
});
