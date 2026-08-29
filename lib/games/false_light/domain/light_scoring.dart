import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:mindforge/games/false_light/domain/light_difficulty_profile.dart';

/// What one correctly swept tile is worth before the multiplier.
///
/// **DERIVED.** No reference screen fixes it. Twenty-five rather than Stroop
/// Rush's forty because a sweep is cheaper than a trial — one tap, no reading,
/// and a classic run holds roughly seventy of them against Stroop's thirty — so
/// the same base would put False Light's totals in a different order of
/// magnitude from every other game on the same Stats screen. It lives here
/// rather than in `lib/theme/` because it is a rule of this game, not an
/// aesthetic of the app.
const int kFalseLightBasePoints = 25;

/// How many correct sweeps it takes to earn the next multiplier step.
///
/// **DERIVED**, and four rather than Stroop's five because a False Light field
/// hands out five to nine sweeps: at a step of four the ramp is something that
/// happens WITHIN a field, so the reward lands while the player is still
/// looking at the board that earned it. Blitz reaches its cap of 6 at twenty
/// consecutive sweeps, which is two or three clean fields out of sixteen — early
/// enough to be worth chasing, far enough that one careless field costs it.
const int kFalseLightStreakStep = 4;

/// A run's score so far.
///
/// **Every field is an `int`.** No formatted string lives here: the display
/// form is a render projection that changes with the locale, and this app
/// changes locale mid-run.
@immutable
final class LightScore {
  /// Creates a score.
  const LightScore({
    required this.points,
    required this.streak,
    required this.bestStreak,
    required this.correct,
    required this.wrong,
  });

  /// The score a run starts from.
  const LightScore.zero()
    : points = 0,
      streak = 0,
      bestStreak = 0,
      correct = 0,
      wrong = 0;

  /// Points earned.
  final int points;

  /// How many correct sweeps in a row, right now.
  final int streak;

  /// The longest streak this run has reached.
  ///
  /// It survives the streak that produced it being broken — that is the whole
  /// point of it — and the results screen reports it rather than the current
  /// streak, which is almost always zero by the time a run ends.
  ///
  /// **It can never exceed [correct].** `runs` persists it as `longest_combo`
  /// under `CHECK (longest_combo <= correct_count)` (lib/data/db/tables/runs.dart:88),
  /// so a best streak that outran the correct count would fail the insert and
  /// discard the whole run. [applySweep] holds it by construction — the best is
  /// the max over streaks, and a streak only ever grows alongside [correct] —
  /// and `light_scoring_test` asserts it over a sweep of sequences.
  final int bestStreak;

  /// How many sweeps landed on a pressed tile.
  final int correct;

  /// How many landed on a raised one.
  final int wrong;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LightScore &&
          other.points == points &&
          other.streak == streak &&
          other.bestStreak == bestStreak &&
          other.correct == correct &&
          other.wrong == wrong;

  @override
  int get hashCode => Object.hash(points, streak, bestStreak, correct, wrong);

  @override
  String toString() =>
      'LightScore(points: $points, streak: $streak, best: $bestStreak, '
      'correct: $correct, wrong: $wrong)';
}

/// What a streak of [streak] pays, capped at [cap].
///
/// **Derived, never stored.** A multiplier field on [LightScore] would be a
/// second copy of the streak that can disagree with it — and the HUD would
/// eventually show one while the scorer used the other, which is the class of
/// bug nobody finds by reading.
///
/// Starts at 1, so the first sweep of a run still scores.
int streakMultiplier(int streak, {required int cap}) =>
    math.min(1 + streak ~/ kFalseLightStreakStep, cap);

/// [score] after one sweep.
///
/// A total function returning a NEW instance.
///
/// **The score is never negative, and that is a persistence contract rather
/// than a kindness.** `runs` stores it under `CHECK (metric_value >= 0)`
/// (lib/data/db/tables/runs.dart:85), so a negative score cannot be written at
/// all: the insert would fail, the run would leave no row, it would never reach
/// Stats and could never become a BEST — and because nothing in the UI reads a
/// save failure, the player would be shown an ordinary results screen for a run
/// that had already been thrown away. A wrong sweep therefore resets the streak
/// to zero and adds nothing; it does not subtract. The punishment is the
/// multiplier the player has to rebuild.
LightScore applySweep(
  LightScore score, {
  required bool isCorrect,
  required LightDifficultyProfile profile,
}) {
  if (!isCorrect) {
    return LightScore(
      points: score.points,
      streak: 0,
      bestStreak: score.bestStreak,
      correct: score.correct,
      wrong: score.wrong + 1,
    );
  }

  // The multiplier is read off the streak BEFORE this sweep lengthens it, so
  // the first correct sweep pays x1 and the fifth pays x2 — the step lands on
  // the sweep that completes the run of four, not on the one after it.
  final earned =
      kFalseLightBasePoints *
      streakMultiplier(score.streak, cap: profile.multiplierCap);
  final streak = score.streak + 1;

  return LightScore(
    points: score.points + earned,
    streak: streak,
    bestStreak: math.max(score.bestStreak, streak),
    correct: score.correct + 1,
    wrong: score.wrong,
  );
}
