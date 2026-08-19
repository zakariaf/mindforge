import 'package:meta/meta.dart';

/// The aggregate numbers behind a game's detail, results and stats surfaces.
///
/// Every member is a **number**, permanently. `128`, `92%`, `640ms` and
/// `3h 12m` are render projections E04's `LocaleNumbers` and the ARB own; this
/// type declares no `String` member and no formatting method, because a
/// formatted value crossing this boundary is a value that would read `1,480` in
/// English and `1.480` in German inside a layer that must not know the
/// difference.
///
/// Nothing here is stored. Every field is a fold over `runs`, recomputed on
/// read, so there is never a cached total to desynchronise.
@immutable
final class GameStats {
  /// Creates an aggregate.
  const GameStats({
    required this.gamesPlayed,
    required this.timeTrainedMs,
    required this.correctCount,
    required this.wrongCount,
    required this.totalReactionMs,
    required this.longestCombo,
  });

  /// The empty aggregate, for a scope with no runs.
  ///
  /// Counts are `0` and the derived ratios are `null` — never `0.0`, which
  /// would render as a real "0% accuracy" for someone who has never played.
  const GameStats.empty()
    : gamesPlayed = 0,
      timeTrainedMs = 0,
      correctCount = 0,
      wrongCount = 0,
      totalReactionMs = 0,
      longestCombo = 0;

  /// How many runs are in scope.
  final int gamesPlayed;

  /// Total wall-clock time across those runs, in milliseconds.
  final int timeTrainedMs;

  /// Total correct answers across those runs.
  final int correctCount;

  /// Total wrong answers across those runs.
  final int wrongCount;

  /// Total of every reaction time across those runs, in milliseconds.
  final int totalReactionMs;

  /// The best single-run combo in scope.
  final int longestCombo;

  /// How many answers were given at all.
  int get answeredCount => correctCount + wrongCount;

  /// The share of answers that were correct, in `[0.0, 1.0]`, or `null` when
  /// nothing was answered.
  double? get accuracy =>
      answeredCount == 0 ? null : correctCount / answeredCount;

  /// The mean time to answer, or `null` when nothing was answered.
  Duration? get averageReaction => answeredCount == 0
      ? null
      : Duration(milliseconds: totalReactionMs ~/ answeredCount);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStats &&
          other.gamesPlayed == gamesPlayed &&
          other.timeTrainedMs == timeTrainedMs &&
          other.correctCount == correctCount &&
          other.wrongCount == wrongCount &&
          other.totalReactionMs == totalReactionMs &&
          other.longestCombo == longestCombo;

  @override
  int get hashCode => Object.hash(
    gamesPlayed,
    timeTrainedMs,
    correctCount,
    wrongCount,
    totalReactionMs,
    longestCombo,
  );

  @override
  String toString() =>
      'GameStats(played: $gamesPlayed, '
      'trainedMs: $timeTrainedMs, accuracy: $accuracy)';
}
