import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_difficulty_profile.dart';

/// What one correct answer is worth before the multiplier.
///
/// **DERIVED.** `app.html` shows 1,240 points at 17 of 30 rounds with a streak
/// of 7, which a ×1–×4 ramp over 40-point answers lands in the neighbourhood
/// of. The `score + 20` in `sunburst-motion-and-haptics`' example is
/// illustrative, not a token. It lives here rather than in `lib/theme/` because
/// it is a rule of this game, not an aesthetic of the app.
const int kStroopBasePoints = 40;

/// How many correct answers it takes to earn the next multiplier step.
///
/// **DERIVED**, and five for a reason a player can feel: at ×1 a run needs a
/// visible reward before the streak means anything, and a step every five
/// rounds reaches the classic cap of ×4 at fifteen — half of a thirty-round
/// run, so the second half is where a good run pulls away.
const int kStroopStreakStep = 5;

/// A run's score so far.
///
/// **Every field is an `int`.** No formatted string lives here: the display
/// form is a render projection that changes with the locale, and this app
/// changes locale mid-run.
@immutable
final class StroopScore {
  /// Creates a score.
  const StroopScore({
    required this.points,
    required this.streak,
    required this.bestStreak,
    required this.correct,
    required this.wrong,
  });

  /// The score a run starts from.
  const StroopScore.zero()
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
  final int bestStreak;

  /// How many answers were right.
  final int correct;

  /// How many were wrong.
  final int wrong;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StroopScore &&
          other.points == points &&
          other.streak == streak &&
          other.bestStreak == bestStreak &&
          other.correct == correct &&
          other.wrong == wrong;

  @override
  int get hashCode => Object.hash(points, streak, bestStreak, correct, wrong);

  @override
  String toString() =>
      'StroopScore(points: $points, streak: $streak, best: $bestStreak, '
      'correct: $correct, wrong: $wrong)';
}

/// What a streak of [streak] pays, capped at [cap].
///
/// **Derived, never stored.** A multiplier field on [StroopScore] would be a
/// second copy of the streak that can disagree with it — and the HUD would
/// eventually show one while the scorer used the other, which is the class of
/// bug nobody finds by reading.
///
/// Starts at 1, so the first correct answer of a run still scores.
int streakMultiplier(int streak, {required int cap}) =>
    math.min(1 + streak ~/ kStroopStreakStep, cap);

/// [score] after one answer.
///
/// A total function returning a NEW instance. Points never decrease: losing
/// them for a wrong answer turns a game about speed into one about not playing.
/// A wrong answer resets the streak to zero and adds nothing — the punishment
/// is the multiplier the player has to rebuild.
StroopScore applyAnswer(
  StroopScore score, {
  required bool isCorrect,
  required StroopDifficultyProfile profile,
}) {
  if (!isCorrect) {
    return StroopScore(
      points: score.points,
      streak: 0,
      bestStreak: score.bestStreak,
      correct: score.correct,
      wrong: score.wrong + 1,
    );
  }

  // The multiplier is read off the streak BEFORE this answer lengthens it, so
  // the first correct answer pays ×1 and the sixth pays ×2 — the step lands on
  // the answer that completes the run of five, not on the one after it.
  final earned =
      kStroopBasePoints *
      streakMultiplier(score.streak, cap: profile.multiplierCap);
  final streak = score.streak + 1;

  return StroopScore(
    points: score.points + earned,
    streak: streak,
    bestStreak: math.max(score.bestStreak, streak),
    correct: score.correct + 1,
    wrong: score.wrong,
  );
}
