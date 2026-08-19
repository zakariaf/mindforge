import 'package:meta/meta.dart';
import 'package:mindforge/core/calendar_day.dart';
import 'package:mindforge/core/run_metric.dart';
import 'package:mindforge/core/score_format.dart';

/// One completed run, as it is durably stored.
///
/// Every field is canonical: integers, a UTC epoch millisecond instant, a local
/// serial day and ASCII tokens. Nothing here is formatted and nothing here is
/// locale-dependent — `1,480`, `1.480` and `۱٬۴۸۰` are all render projections of
/// [metricValue].
///
/// Accuracy, average reaction, personal best and every aggregate are **derived**
/// rather than stored, so there is never a second authority to keep in sync.
@immutable
final class RunRecord {
  /// Creates a run record.
  const RunRecord({
    required this.id,
    required this.gameId,
    required this.difficultyId,
    required this.clientRunKey,
    required this.startedAtUtcMs,
    required this.playedOnDay,
    required this.durationMs,
    required this.format,
    required this.metricValue,
    required this.correctCount,
    required this.wrongCount,
    required this.longestCombo,
    required this.totalReactionMs,
    required this.createdAtUtcMs,
  });

  /// The row's stable identity, minted by the `IdGenerator` seam.
  final String id;

  /// Which game, as an ASCII token such as `stroop_rush` — never a display
  /// title, which would make every scoped query locale-dependent.
  final String gameId;

  /// Which difficulty, as an ASCII token such as `classic`. `Chill / Classic /
  /// Blitz` are ARB strings; `chill / classic / blitz` are what is stored.
  final String difficultyId;

  /// The idempotency key the engine minted for this run, so recording it twice
  /// is impossible rather than merely unlikely.
  final String clientRunKey;

  /// When the run started, as UTC epoch milliseconds. Always positive.
  final int startedAtUtcMs;

  /// The **local** civil day the run was played on.
  ///
  /// Deliberately distinct from [startedAtUtcMs]: this is the day boundary the
  /// streak and the "played today" check both read.
  final CalendarDay playedOnDay;

  /// How long the run lasted, in milliseconds. Never negative. The source of
  /// "Time trained".
  final int durationMs;

  /// How to read [metricValue], and which direction is better.
  final ScoreFormat format;

  /// The number the game scores by, in the unit [format] names. Never negative.
  ///
  /// Stamped per run, so a later scoring change leaves old rows interpretable.
  final int metricValue;

  /// How many answers were correct. Never negative.
  final int correctCount;

  /// How many answers were wrong. Never negative.
  final int wrongCount;

  /// The longest unbroken run of correct answers. Never negative, and never
  /// greater than [correctCount].
  final int longestCombo;

  /// The **sum** of every reaction time in milliseconds, not the average.
  ///
  /// The sum is stored and the average derived, so no rounded double ever
  /// reaches a column.
  final int totalReactionMs;

  /// When the row was written, as UTC epoch milliseconds, from the injected
  /// `Clock`.
  final int createdAtUtcMs;

  /// This run's score as a comparable metric.
  RunMetric get metric => RunMetric(format: format, value: metricValue);

  /// How many answers were given at all.
  int get answeredCount => correctCount + wrongCount;

  /// The share of answers that were correct, in `[0.0, 1.0]`, or `null` when
  /// nothing was answered.
  ///
  /// `null` rather than `0.0` or `NaN`: nothing answered is an absence, and a
  /// `NaN` renders as `NaN%` and compares false to itself.
  double? get accuracy =>
      answeredCount == 0 ? null : correctCount / answeredCount;

  /// The mean time to answer, or `null` when nothing was answered.
  Duration? get averageReaction => answeredCount == 0
      ? null
      : Duration(milliseconds: totalReactionMs ~/ answeredCount);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RunRecord && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'RunRecord($id, $gameId/$difficultyId, $metricValue)';
}
