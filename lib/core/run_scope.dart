import 'package:meta/meta.dart';

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
