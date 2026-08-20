import 'package:meta/meta.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';

/// Everything the shell hands down to start a run.
///
/// Value-equal, because it is the family key for the run notifier: two widgets
/// asking for the same `(game, difficulty, seed)` must get the same run, and a
/// new seed must get a new one — which is exactly what "Play again" is.
///
/// **It carries no locale.** A locale on the family key would make switching
/// language mid-run start a different run, which is precisely backwards: the
/// run is the same run, rendered in another language.
@immutable
final class RunConfig {
  /// Creates a config.
  const RunConfig({
    required this.gameId,
    required this.difficulty,
    required this.seed,
  });

  /// Which game.
  final GameId gameId;

  /// Which difficulty.
  final Difficulty difficulty;

  /// The seed the round is generated from, so it can be replayed.
  final int seed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunConfig &&
          other.gameId == gameId &&
          other.difficulty == difficulty &&
          other.seed == seed;

  @override
  int get hashCode => Object.hash(gameId, difficulty, seed);

  @override
  String toString() => 'RunConfig($gameId, ${difficulty.name}, $seed)';
}
