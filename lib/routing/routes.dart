import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';

/// Every location in the app, built in one place.
///
/// **A location is canonical data, not a rendered string.** It is ASCII in
/// every locale: the seed in a play URL is `42`, never `۴۲`, and the difficulty
/// is the enum name rather than a translated label. Localisation happens at
/// render; a URL that moved with the language could not be pasted into a bug
/// report, deep-linked, or compared.
///
/// Built here rather than concatenated at call sites so there is one spelling
/// of each path and one place a test can round-trip them.
abstract final class Routes {
  /// The home hub.
  static const String home = '/';

  /// The stats branch.
  static const String stats = '/stats';

  /// The settings branch.
  static const String settings = '/settings';

  /// What the app is and what it promises.
  static const String about = '/about';

  /// The path segment carrying a game id.
  static const String gameIdParam = 'gameId';

  /// The query parameter carrying a difficulty.
  static const String difficultyParam = 'difficulty';

  /// The query parameter carrying a run seed.
  static const String seedParam = 'seed';

  /// One game's detail screen.
  static String gameDetail(GameId id) => '/game/${id.value}';

  /// The countdown before a run.
  static String countdown(RunConfig config) =>
      '${gameDetail(config.gameId)}/countdown${_runQuery(config)}';

  /// A live run.
  static String play(RunConfig config) =>
      '${gameDetail(config.gameId)}/play${_runQuery(config)}';

  /// A finished run's results.
  static String results(RunConfig config) =>
      '${gameDetail(config.gameId)}/results${_runQuery(config)}';

  /// Rebuilds a config from a location's parameters.
  ///
  /// Returns `null` when either parameter is missing or unparseable, which is
  /// what a hand-edited or stale deep link looks like. The caller decides what
  /// to do about it; this only reports that it could not be read.
  static RunConfig? configFrom({
    required String? gameId,
    required String? difficulty,
    required String? seed,
  }) {
    if (gameId == null || difficulty == null || seed == null) return null;

    final parsedSeed = int.tryParse(seed);
    if (parsedSeed == null) return null;

    for (final candidate in Difficulty.values) {
      if (candidate.name != difficulty) continue;

      return RunConfig(
        gameId: GameId(gameId),
        difficulty: candidate,
        seed: parsedSeed,
      );
    }

    return null;
  }

  /// The query a run route carries.
  ///
  /// The difficulty is the enum NAME and the seed is ASCII digits, for the same
  /// reason `RunScope` persists the name: both are keys that must survive a
  /// translation edit and a language switch.
  static String _runQuery(RunConfig config) =>
      '?$difficultyParam=${config.difficulty.name}&$seedParam=${config.seed}';
}
