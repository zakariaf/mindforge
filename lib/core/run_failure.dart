import 'package:meta/meta.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/failure.dart';
import 'package:mindforge/core/game_id.dart';

/// A run could not start or could not proceed.
///
/// **Never a sentence.** E08 renders one of these by switching on the sealed
/// variant and reading an ARB key; the [Failure.code] is what makes that switch
/// possible in four locales. Adding a `message` field would make the switch
/// unnecessary and the message untranslatable in the same stroke, so do not add
/// one — `run_failure_test.dart` fails if anyone does.
///
/// **Persistence failures are not mirrored here.** A run that failed to save is
/// a `DataFailure`, E02's family, surfaced through `RunState.saveFailure`.
/// Duplicating them would give the results screen two ways to say "the save did
/// not land", which is one way too many.
///
/// This family names only what the repository does not own: a run asked for
/// with a game or a difficulty the registry cannot serve.
@immutable
sealed class RunFailure extends Failure {
  /// Creates a run failure.
  const RunFailure();

  /// The identifier values this failure carries, for the tests that assert no
  /// prose reaches one.
  ///
  /// Declared on the base so a new variant has to answer the question rather
  /// than quietly opting out of it.
  List<String> get identifiers;
}

/// The registry has no game under this id.
///
/// A deep link to a game that was removed, or a saved row from a build that had
/// one. Recoverable: the shell sends the player home.
@immutable
final class UnknownGame extends RunFailure {
  /// Creates the failure for [gameId].
  const UnknownGame(this.gameId);

  /// The id nothing is registered under.
  final GameId gameId;

  @override
  String get code => 'run.unknown_game';

  @override
  List<String> get identifiers => <String>[gameId.value];

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UnknownGame && other.gameId == gameId;

  @override
  int get hashCode => Object.hash(code, gameId);

  @override
  String toString() => '$code($gameId)';
}

/// The game exists but does not offer this difficulty.
///
/// Schulte Grid may ship without Blitz; a saved row or a deep link naming it is
/// the case this exists for. Recoverable: the shell falls back to the game's
/// default difficulty.
@immutable
final class UnsupportedDifficulty extends RunFailure {
  /// Creates the failure for [difficulty] on [gameId].
  const UnsupportedDifficulty(this.gameId, this.difficulty);

  /// The game that was asked.
  final GameId gameId;

  /// The difficulty it does not offer.
  final Difficulty difficulty;

  @override
  String get code => 'run.unsupported_difficulty';

  @override
  List<String> get identifiers => <String>[gameId.value, difficulty.name];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnsupportedDifficulty &&
          other.gameId == gameId &&
          other.difficulty == difficulty;

  @override
  int get hashCode => Object.hash(code, gameId, difficulty);

  @override
  String toString() => '$code($gameId, ${difficulty.name})';
}
