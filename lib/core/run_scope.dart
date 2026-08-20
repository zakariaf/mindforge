import 'package:meta/meta.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';

/// Which runs a read is about: one game, optionally narrowed to one difficulty.
///
/// The family key for every scoped stream. Value equality is what makes
/// `runStatsProvider(RunScope('stroop_rush', 'classic'))` return the same
/// provider instance from two different widgets rather than opening two
/// database subscriptions over the same query.
@immutable
final class RunScope {
  /// Creates a scope over [gameId], optionally narrowed to [difficultyId].
  const RunScope(this.gameId, [this.difficultyId]);

  /// The one conversion from typed engine values to the persisted strings.
  ///
  /// Screens hold a [GameId] and a [Difficulty]; E02's providers are keyed by a
  /// `RunScope`. Without one factory in the middle, every screen hand-builds
  /// the key and one of them eventually spells it differently — at which point
  /// two widgets open two database subscriptions over the same query and a
  /// personal best appears in one and not the other.
  ///
  /// A null [difficulty] is the all-difficulties scope.
  factory RunScope.of(GameId gameId, Difficulty? difficulty) => RunScope(
    gameId.value,
    // THE ENUM NAME, never labelKey and never a translated label. This column
    // is a join key: it has to survive an ARB rename and a translation edit
    // alike, and `difficultyClassic` or `Klassisch` in a WHERE clause is a row
    // nobody can find again.
    difficulty?.name,
  );

  /// The game, as an ASCII token such as `stroop_rush`.
  final String gameId;

  /// The difficulty, as an ASCII token such as `classic`, or `null` to span
  /// every difficulty of [gameId].
  final String? difficultyId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunScope &&
          other.gameId == gameId &&
          other.difficultyId == difficultyId;

  @override
  int get hashCode => Object.hash(gameId, difficultyId);

  @override
  String toString() => 'RunScope($gameId, ${difficultyId ?? '*'})';
}
