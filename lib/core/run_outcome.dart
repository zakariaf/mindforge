import 'package:meta/meta.dart';
import 'package:mindforge/core/result_stat.dart';

/// How a run ended.
///
/// Sealed, so the results screen switches it exhaustively and adding a third
/// ending breaks the build at the place that has to render it.
@immutable
sealed class RunOutcome {
  /// Creates an outcome.
  const RunOutcome();

  /// A run the player finished.
  ///
  /// It carries the three display stats and nothing else. **The run's numbers
  /// live on `BoardSnapshot`**, because a timed run can end without the board
  /// declaring anything at all and those numbers still have to reach the row.
  /// One authority for figures, one for how it ended.
  const factory RunOutcome.completed({
    required ResultStat first,
    required ResultStat second,
    required ResultStat third,
  }) = RunCompleted;

  /// A run the player left.
  const factory RunOutcome.abandoned() = RunAbandoned;
}

/// The player finished the run.
///
/// **Three stats as three fields, not a list.** The results screen is a fixed
/// three-column grid, so a fourth stat and a missing stat are both bugs — and
/// the type is what makes them unrepresentable. A `List` with
/// `assert(stats.length == 3)` was the first shape, and it cannot be `const`:
/// `List.length` is not a constant expression, so every board example in the
/// skills would have had to drop its `const`. Named fields give the invariant
/// AND the const, which is the same trade `GameHud` makes one file over.
@immutable
final class RunCompleted extends RunOutcome {
  /// Creates a completed outcome.
  const RunCompleted({
    required this.first,
    required this.second,
    required this.third,
  });

  /// The first cell of the results trio.
  final ResultStat first;

  /// The second cell.
  final ResultStat second;

  /// The third cell.
  final ResultStat third;

  /// The trio, in reading order, for a screen that lays them out.
  List<ResultStat> get stats => <ResultStat>[first, second, third];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunCompleted &&
          other.first == first &&
          other.second == second &&
          other.third == third;

  @override
  int get hashCode => Object.hash(first, second, third);
}

/// The player left before the run ended.
///
/// **It carries no score, and has no field to hold one.** An abandoned run does
/// not go on the leaderboard and does not beat a personal best; making that
/// unrepresentable is cheaper than remembering it at every call site.
@immutable
final class RunAbandoned extends RunOutcome {
  /// Creates an abandoned outcome.
  const RunAbandoned();

  @override
  bool operator ==(Object other) => other is RunAbandoned;

  @override
  int get hashCode => (RunAbandoned).hashCode;
}
