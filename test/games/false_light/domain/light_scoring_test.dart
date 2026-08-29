import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/seeded_generator.dart';
import 'package:mindforge/games/false_light/domain/light_difficulty_profile.dart';
import 'package:mindforge/games/false_light/domain/light_scoring.dart';

/// One total function from a sweep to a new score.
void main() {
  final classic = profileFor(Difficulty.classic);

  LightScore sweepAll(
    List<bool> sweeps, {
    LightDifficultyProfile? profile,
  }) {
    var score = const LightScore.zero();

    for (final isCorrect in sweeps) {
      score = applySweep(
        score,
        isCorrect: isCorrect,
        profile: profile ?? classic,
      );
    }

    return score;
  }

  group('a correct sweep', () {
    test('adds base points times the multiplier, and lengthens the streak', () {
      // Walked one sweep at a time against a hand-computed expectation, so a
      // change to the ramp shows up as a wrong NUMBER rather than as a wrong
      // shape.
      var score = const LightScore.zero();
      var expected = 0;

      for (var streak = 0; streak < 20; streak++) {
        expected +=
            kFalseLightBasePoints *
            streakMultiplier(streak, cap: classic.multiplierCap);
        score = applySweep(score, isCorrect: true, profile: classic);

        expect(score.points, expected, reason: 'after ${streak + 1} correct');
        expect(score.streak, streak + 1);
      }
    });

    test('and counts itself', () {
      expect(sweepAll(<bool>[true, true, true]).correct, 3);
      expect(sweepAll(<bool>[true, true, true]).wrong, 0);
    });
  });

  group('a wrong sweep', () {
    test('resets the streak and adds nothing', () {
      final before = sweepAll(<bool>[true, true, true]);
      final after = applySweep(before, isCorrect: false, profile: classic);

      expect(after.streak, 0);
      expect(after.points, before.points);
      expect(after.wrong, 1);
    });

    test('even from a streak above the cap', () {
      // The cap limits what a streak PAYS, not what it counts, so a long
      // streak still falls all the way to zero.
      final long = sweepAll(List<bool>.filled(50, true));

      expect(long.streak, 50);
      expect(applySweep(long, isCorrect: false, profile: classic).streak, 0);
    });

    test(
      'and never takes points away, because a negative score is dropped',
      () {
        // runs.dart:85 carries CHECK (metric_value >= 0). A negative score is
        // not persisted at all: the insert fails, the run leaves no row, never
        // reaches Stats and never becomes a BEST -- and nothing in the UI reads
        // a save failure, so the player sees an ordinary results screen for a
        // run that was already discarded.
        final before = sweepAll(<bool>[true, true]);

        expect(
          applySweep(before, isCorrect: false, profile: classic).points,
          greaterThanOrEqualTo(before.points),
        );
      },
    );
  });

  group('the score is never negative', () {
    test(
      'over a thousand seeded correct/wrong sequences, at every profile',
      () {
        // Seeded rather than ambient, so a failure is reproducible from the
        // printed seed rather than from a screenshot of a CI log.
        for (final difficulty in Difficulty.values) {
          final profile = profileFor(difficulty);

          for (var seed = 0; seed < 1000; seed++) {
            final generator = seedFrom('light_score:$seed', featureSalt: 1);
            final sweeps = <bool>[
              for (var i = 0; i < 40; i++) generator.nextInt(2) == 0,
            ];

            var score = const LightScore.zero();

            for (final isCorrect in sweeps) {
              final next = applySweep(
                score,
                isCorrect: isCorrect,
                profile: profile,
              );

              expect(next.points, greaterThanOrEqualTo(0));
              expect(
                next.points,
                greaterThanOrEqualTo(score.points),
                reason: '${difficulty.name}, seed $seed',
              );
              score = next;
            }
          }
        }
      },
    );

    test('and a run of nothing but wrong sweeps still scores zero', () {
      final score = sweepAll(List<bool>.filled(120, false));

      expect(score.points, 0);
      expect(score.correct, 0);
      expect(score.wrong, 120);
      expect(score.bestStreak, 0);
    });
  });

  group('bestStreak', () {
    test('never exceeds correct, which is what the runs CHECK requires', () {
      // runs.dart:88 carries CHECK (longest_combo <= correct_count). A best
      // streak that outran the correct count would fail the insert and take
      // the whole run down with it, silently.
      for (var seed = 0; seed < 500; seed++) {
        final generator = seedFrom('light_best:$seed', featureSalt: 2);
        final sweeps = <bool>[
          for (var i = 0; i < 60; i++) generator.nextInt(3) != 0,
        ];

        var score = const LightScore.zero();

        for (final isCorrect in sweeps) {
          score = applySweep(score, isCorrect: isCorrect, profile: classic);

          expect(
            score.bestStreak,
            lessThanOrEqualTo(score.correct),
            reason: 'seed $seed',
          );
          expect(score.streak, lessThanOrEqualTo(score.bestStreak));
        }
      }
    });

    test('equals the longest prefix streak, checked against a fold', () {
      for (var seed = 0; seed < 200; seed++) {
        final generator = seedFrom('light_fold:$seed', featureSalt: 3);
        final sweeps = <bool>[
          for (var i = 0; i < 40; i++) generator.nextInt(3) != 0,
        ];

        // An INDEPENDENT oracle in the test file: the scorer tracks the best
        // as it goes, and this recomputes it from the whole sequence.
        var running = 0;
        var best = 0;

        for (final isCorrect in sweeps) {
          running = isCorrect ? running + 1 : 0;
          if (running > best) best = running;
        }

        expect(sweepAll(sweeps).bestStreak, best, reason: 'seed $seed');
      }
    });

    test('and survives the streak it came from being broken', () {
      expect(sweepAll(<bool>[true, true, true, false]).bestStreak, 3);
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

    test('starts at one, so the first sweep of a run still scores', () {
      expect(streakMultiplier(0, cap: 4), 1);
    });

    test('and steps every kFalseLightStreakStep sweeps until the cap', () {
      expect(streakMultiplier(kFalseLightStreakStep - 1, cap: 6), 1);
      expect(streakMultiplier(kFalseLightStreakStep, cap: 6), 2);
      expect(streakMultiplier(kFalseLightStreakStep * 2, cap: 6), 3);
      expect(streakMultiplier(kFalseLightStreakStep * 99, cap: 6), 6);
    });

    test('and is DERIVED, never stored on the score', () {
      // Derive, don't store: a multiplier field would be a second copy of the
      // streak that can disagree with it, and the HUD would eventually show
      // one while the scorer used the other.
      expect(const LightScore.zero().toString(), isNot(contains('multiplier')));
    });

    test('and a chill cap is reachable inside a single field', () {
      // The step is four and a chill field hands out five or six sweeps, so
      // the reward lands while the player is still looking at the board that
      // earned it.
      expect(
        streakMultiplier(
          kFalseLightStreakStep,
          cap: profileFor(Difficulty.chill).multiplierCap,
        ),
        2,
      );
    });
  });

  group('the score holds no formatted string', () {
    test('every field is an int', () {
      // The regression this pins is "someone put the display value on the
      // value type", which is wrong the moment the locale changes mid-run --
      // and mid-run locale changes are a thing this app supports.
      const score = LightScore.zero();

      expect(score.points, isA<int>());
      expect(score.streak, isA<int>());
      expect(score.bestStreak, isA<int>());
      expect(score.correct, isA<int>());
      expect(score.wrong, isA<int>());
    });
  });

  group('applySweep is pure', () {
    test('it returns a new instance and leaves the old one alone', () {
      const before = LightScore.zero();
      final after = applySweep(before, isCorrect: true, profile: classic);

      expect(identical(before, after), isFalse);
      expect(before.points, 0);
      expect(before.streak, 0);
    });

    test('and two equal scores compare equal', () {
      expect(
        sweepAll(<bool>[true, false, true]),
        sweepAll(<bool>[true, false, true]),
      );
      expect(
        sweepAll(<bool>[true, false, true]).hashCode,
        sweepAll(<bool>[true, false, true]).hashCode,
      );
    });
  });

  group('a perfect run', () {
    test('scores the brute-force total for a full field-count sweep', () {
      // The acceptance row. Every pressed tile of every field, swept in order,
      // summed independently here.
      for (final difficulty in Difficulty.values) {
        final profile = profileFor(difficulty);
        // The lowest whole-tile count the band can yield, so the expectation
        // is a fixed number rather than a re-derivation of the generator.
        final sweeps =
            profile.fieldCount *
            (profile.tileCount * profile.pressedShareLow).round();
        var expected = 0;

        for (var i = 0; i < sweeps; i++) {
          expected +=
              kFalseLightBasePoints *
              streakMultiplier(i, cap: profile.multiplierCap);
        }

        expect(
          sweepAll(List<bool>.filled(sweeps, true), profile: profile).points,
          expected,
          reason: difficulty.name,
        );
      }
    });
  });
}
