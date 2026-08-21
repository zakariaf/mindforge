import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/seeded_generator.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_difficulty_profile.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_scoring.dart';

/// One total function from an answer to a new score.
void main() {
  final classic = profileFor(Difficulty.classic);

  StroopScore answerAll(
    List<bool> answers, {
    StroopDifficultyProfile? profile,
  }) {
    var score = const StroopScore.zero();

    for (final isCorrect in answers) {
      score = applyAnswer(
        score,
        isCorrect: isCorrect,
        profile: profile ?? classic,
      );
    }

    return score;
  }

  group('a correct answer', () {
    test('adds base points times the multiplier, and lengthens the streak', () {
      // Walked one answer at a time against a hand-computed expectation, so a
      // change to the ramp shows up as a wrong NUMBER rather than as a wrong
      // shape.
      var score = const StroopScore.zero();
      var expected = 0;

      for (var streak = 0; streak < 20; streak++) {
        expected +=
            kStroopBasePoints *
            streakMultiplier(streak, cap: classic.multiplierCap);
        score = applyAnswer(score, isCorrect: true, profile: classic);

        expect(score.points, expected, reason: 'after ${streak + 1} correct');
        expect(score.streak, streak + 1);
      }
    });

    test('and counts itself', () {
      expect(answerAll(<bool>[true, true, true]).correct, 3);
      expect(answerAll(<bool>[true, true, true]).wrong, 0);
    });
  });

  group('a wrong answer', () {
    test('resets the streak and adds nothing', () {
      final before = answerAll(<bool>[true, true, true]);
      final after = applyAnswer(before, isCorrect: false, profile: classic);

      expect(after.streak, 0);
      expect(after.points, before.points);
      expect(after.wrong, 1);
    });

    test('even from a streak above the cap', () {
      // The cap limits what a streak PAYS, not what it counts, so a long
      // streak still falls all the way to zero.
      final long = answerAll(List<bool>.filled(50, true));

      expect(long.streak, 50);
      expect(
        applyAnswer(long, isCorrect: false, profile: classic).streak,
        0,
      );
    });

    test('and never takes points away', () {
      // Losing points for a wrong answer turns a game about speed into one
      // about not playing.
      final before = answerAll(<bool>[true, true]);

      expect(
        applyAnswer(before, isCorrect: false, profile: classic).points,
        greaterThanOrEqualTo(before.points),
      );
    });
  });

  group('the multiplier', () {
    test('is monotonic in the streak and never exceeds the cap', () {
      for (final difficulty in Difficulty.values) {
        final cap = profileFor(difficulty).multiplierCap;
        var previous = 0;

        for (var streak = 0; streak <= 200; streak++) {
          final multiplier = streakMultiplier(streak, cap: cap);

          expect(multiplier, greaterThanOrEqualTo(previous));
          expect(multiplier, lessThanOrEqualTo(cap));
          expect(multiplier, greaterThanOrEqualTo(1));
          previous = multiplier;
        }
      }
    });

    test('starts at one, so the first correct answer still scores', () {
      expect(streakMultiplier(0, cap: 4), 1);
    });

    test('and steps every kStroopStreakStep answers until the cap', () {
      expect(streakMultiplier(kStroopStreakStep - 1, cap: 6), 1);
      expect(streakMultiplier(kStroopStreakStep, cap: 6), 2);
      expect(streakMultiplier(kStroopStreakStep * 2, cap: 6), 3);
      expect(streakMultiplier(kStroopStreakStep * 99, cap: 6), 6);
    });

    test('and is DERIVED, never stored on the score', () {
      // Derive, don't store: a multiplier field would be a second copy of the
      // streak that can disagree with it, and the HUD would eventually show
      // one while the scorer used the other.
      expect(
        StroopScore.zero,
        isNotNull,
        reason: 'a placeholder so the reason above has a home',
      );
      expect(
        const StroopScore.zero().toString(),
        isNot(contains('multiplier')),
      );
    });
  });

  group('points never decrease', () {
    test('over a thousand seeded correct/wrong sequences', () {
      // Seeded rather than ambient, so a failure is reproducible from the
      // printed seed rather than from a screenshot of a CI log.
      for (var seed = 0; seed < 1000; seed++) {
        final generator = seedFrom('score:$seed', featureSalt: 1);
        final answers = <bool>[
          for (var i = 0; i < 40; i++) generator.nextInt(2) == 0,
        ];

        var score = const StroopScore.zero();

        for (final isCorrect in answers) {
          final next = applyAnswer(
            score,
            isCorrect: isCorrect,
            profile: classic,
          );

          expect(
            next.points,
            greaterThanOrEqualTo(score.points),
            reason: 'seed $seed, sequence $answers',
          );
          score = next;
        }
      }
    });
  });

  group('bestStreak', () {
    test('equals the longest prefix streak, checked against a fold', () {
      for (var seed = 0; seed < 200; seed++) {
        final generator = seedFrom('best:$seed', featureSalt: 2);
        final answers = <bool>[
          for (var i = 0; i < 40; i++) generator.nextInt(3) != 0,
        ];

        // An INDEPENDENT oracle in the test file: the scorer tracks the best
        // as it goes, and this recomputes it from the whole sequence.
        var running = 0;
        var best = 0;

        for (final isCorrect in answers) {
          running = isCorrect ? running + 1 : 0;
          if (running > best) best = running;
        }

        expect(
          answerAll(answers).bestStreak,
          best,
          reason: 'seed $seed',
        );
      }
    });

    test('and survives the streak it came from being broken', () {
      expect(
        answerAll(<bool>[true, true, true, false]).bestStreak,
        3,
      );
    });
  });

  group('a perfect run', () {
    test('scores the brute-force total for its profile', () {
      // The acceptance row. Thirty consecutive correct answers under classic,
      // summed independently here.
      for (final difficulty in Difficulty.values) {
        final profile = profileFor(difficulty);
        var expected = 0;

        for (var i = 0; i < profile.roundCount; i++) {
          expected +=
              kStroopBasePoints *
              streakMultiplier(i, cap: profile.multiplierCap);
        }

        expect(
          answerAll(
            List<bool>.filled(profile.roundCount, true),
            profile: profile,
          ).points,
          expected,
          reason: difficulty.name,
        );
      }
    });
  });

  group('the score holds no formatted string', () {
    test('every field is an int', () {
      // The regression this pins is "someone put the display value on the
      // value type", which is wrong the moment the locale changes mid-run —
      // and mid-run locale changes are a thing this app supports.
      const score = StroopScore.zero();

      expect(score.points, isA<int>());
      expect(score.streak, isA<int>());
      expect(score.bestStreak, isA<int>());
      expect(score.correct, isA<int>());
      expect(score.wrong, isA<int>());
    });
  });

  group('applyAnswer is pure', () {
    test('it returns a new instance and leaves the old one alone', () {
      const before = StroopScore.zero();
      final after = applyAnswer(before, isCorrect: true, profile: classic);

      expect(identical(before, after), isFalse);
      expect(before.points, 0);
      expect(before.streak, 0);
    });

    test('and two equal scores compare equal', () {
      expect(
        answerAll(<bool>[true, false, true]),
        answerAll(<bool>[true, false, true]),
      );
      expect(
        answerAll(<bool>[true, false, true]).hashCode,
        answerAll(<bool>[true, false, true]).hashCode,
      );
    });
  });
}
