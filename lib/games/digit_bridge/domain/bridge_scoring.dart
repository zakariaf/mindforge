import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_difficulty_profile.dart';

/// What one matched numeral is worth before the multiplier.
///
/// **DERIVED.** Fifty rather than Stroop Rush's forty, because a Digit Bridge
/// round is a longer read: a Stroop trial resolves on one glyph and this one
/// resolves on three to five, scanned against six candidates. A run of
/// eighteen classic rounds at a ×1–×4 ramp lands in the same thousands the
/// results card and the BEST pill were laid out for, so the two games' scores
/// stay comparable at a glance on the home hub.
///
/// It lives here rather than in `lib/theme/` because it is a rule of this game,
/// not an aesthetic of the app.
const int kBridgeBasePoints = 50;

/// How many correct answers it takes to earn the next multiplier step.
///
/// **DERIVED**, and four rather than five because a Digit Bridge run is
/// shorter than a Stroop one at every difficulty — twelve to twenty-four rounds
/// against twenty to forty. A step every five would let a chill run end before
/// the multiplier moved once, which makes the streak pill decoration.
const int kBridgeStreakStep = 4;

/// A run's score so far.
///
/// **Every field is an `int`.** No formatted string lives here: the display
/// form is a render projection that changes with the locale, and this app
/// changes locale mid-run — which for this game it is especially likely to,
/// because switching language is how a player finds the script they read best.
@immutable
final class BridgeScore {
  /// Creates a score.
  const BridgeScore({
    required this.points,
    required this.streak,
    required this.bestStreak,
    required this.correct,
    required this.wrong,
  });

  /// The score a run starts from.
  const BridgeScore.zero()
    : points = 0,
      streak = 0,
      bestStreak = 0,
      correct = 0,
      wrong = 0;

  /// Points earned.
  final int points;

  /// How many correct answers in a row, right now.
  final int streak;

  /// The longest streak this run has reached.
  ///
  /// It survives the streak that produced it being broken — that is the whole
  /// point of it — and the results screen reports it rather than the current
  /// streak, which is almost always zero by the time a run ends.
  ///
  /// **It can never exceed [correct]**, and that is a persistence constraint
  /// rather than a stylistic one: `runs` carries
  /// `CHECK (longest_combo <= correct_count)`, so a state that broke it would
  /// produce a run the repository silently refuses to save.
  final int bestStreak;

  /// How many answers were right.
  final int correct;

  /// How many were wrong.
  final int wrong;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BridgeScore &&
          other.points == points &&
          other.streak == streak &&
          other.bestStreak == bestStreak &&
          other.correct == correct &&
          other.wrong == wrong;

  @override
  int get hashCode => Object.hash(points, streak, bestStreak, correct, wrong);

  @override
  String toString() =>
      'BridgeScore(points: $points, streak: $streak, best: $bestStreak, '
      'correct: $correct, wrong: $wrong)';
}

/// What a streak of [streak] pays, capped at [cap].
///
/// **Derived, never stored.** A multiplier field on [BridgeScore] would be a
/// second copy of the streak that can disagree with it — and the HUD would
/// eventually show one while the scorer used the other.
///
/// Starts at 1, so the first correct answer of a run still scores.
int streakMultiplier(int streak, {required int cap}) =>
    math.min(1 + streak ~/ kBridgeStreakStep, cap);

/// [score] after one answer.
///
/// A total function returning a NEW instance.
///
/// **Points never decrease.** That is a persistence fact before it is a design
/// one: `lib/data/db/tables/runs.dart` carries `CHECK (metric_value >= 0)`, so
/// a negative total is a row the database refuses, a repository that returns
/// `ConstraintViolated`, and — because nothing in the UI reads `saveFailure` —
/// a player who sees an ordinary results screen for a run that left no trace.
/// A wrong answer resets the streak and adds nothing; the punishment is the
/// multiplier the player has to rebuild.
BridgeScore applyAnswer(
  BridgeScore score, {
  required bool isCorrect,
  required BridgeDifficultyProfile profile,
}) {
  if (!isCorrect) {
    return BridgeScore(
      points: score.points,
      streak: 0,
      bestStreak: score.bestStreak,
      correct: score.correct,
      wrong: score.wrong + 1,
    );
  }

  // The multiplier is read off the streak BEFORE this answer lengthens it, so
  // the first correct answer pays ×1 and the fifth pays ×2 — the step lands on
  // the answer that completes the run of four, not on the one after it.
  final earned =
      kBridgeBasePoints *
      streakMultiplier(score.streak, cap: profile.multiplierCap);
  final streak = score.streak + 1;

  return BridgeScore(
    points: score.points + earned,
    streak: streak,
    bestStreak: math.max(score.bestStreak, streak),
    correct: score.correct + 1,
    wrong: score.wrong,
  );
}
