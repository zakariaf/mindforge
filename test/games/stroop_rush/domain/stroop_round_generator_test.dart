import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_difficulty_profile.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_round.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_round_generator.dart';
import 'package:mindforge/theme/sunburst_colors.dart';

/// `(seed, difficulty, colour-blind)` in, a reproducible game out.
///
/// Every test here is a plain `test()`. There is no widget, no container and no
/// locale: generation is a total function over three inputs, and the moment it
/// needs any of those three things it has stopped being one.
void main() {
  List<StroopRound> roundsFor({
    int seed = 42,
    Difficulty difficulty = Difficulty.classic,
    bool isColourBlindPalette = false,
  }) => generateStroopRounds(
    seed: seed,
    difficulty: difficulty,
    isColourBlindPalette: isColourBlindPalette,
  );

  group('the shape of a run', () {
    for (final difficulty in Difficulty.values) {
      test('${difficulty.name} generates its profile round count', () {
        expect(
          roundsFor(difficulty: difficulty),
          hasLength(profileFor(difficulty).roundCount),
        );
      });
    }

    test('and the rounds are indexed from zero, in order', () {
      final rounds = roundsFor();

      expect(
        rounds.map((round) => round.index),
        List<int>.generate(rounds.length, (i) => i),
      );
    });
  });

  group('determinism', () {
    test('the same seed and difficulty produce byte-identical rounds twice', () {
      // Canonical strings rather than object equality: this is the assertion
      // that fails the moment ambient randomness comes back, and comparing the
      // serialized form is what makes the failure readable.
      expect(
        roundsFor().map((round) => round.canonical()).join('|'),
        roundsFor().map((round) => round.canonical()).join('|'),
      );
    });

    test('and a different seed produces a different sequence', () {
      // 64 consecutive seeds. Collisions on one (word, ink) pair are expected
      // — there are only sixteen of them — so the bar is that the FULL round
      // sequences differ, which is what a player would notice.
      final sequences = <String>{
        for (var seed = 1000; seed < 1064; seed++)
          roundsFor(seed: seed).map((r) => r.canonical()).join('|'),
      };

      expect(
        sequences,
        hasLength(64),
        reason: 'two seeds in 1000..1063 dealt the same 30 rounds',
      );
    });

    test('and the difficulty is part of the seed, not just the length', () {
      // Two difficulties sharing a seed must not deal the same opening rounds
      // — otherwise Blitz is Classic with extra innings.
      final classic = roundsFor(difficulty: Difficulty.classic).take(20);
      final chill = roundsFor(difficulty: Difficulty.chill).take(20);

      expect(
        classic.map((r) => r.canonical()).join('|'),
        isNot(chill.map((r) => r.canonical()).join('|')),
      );
    });
  });

  group('every round is playable', () {
    test('the ink is always among the offered options', () {
      // Seeded fuzz: 500 seeds across three difficulties. A round whose answer
      // is not on the board cannot be won.
      for (var seed = 0; seed < 500; seed++) {
        for (final difficulty in Difficulty.values) {
          for (final round in roundsFor(seed: seed, difficulty: difficulty)) {
            expect(
              round.options,
              contains(round.ink),
              reason: 'seed $seed, ${difficulty.name}, round ${round.index}',
            );
          }
        }
      }
    });

    test('and four options are offered, all distinct', () {
      for (var seed = 0; seed < 200; seed++) {
        for (final difficulty in Difficulty.values) {
          for (final round in roundsFor(seed: seed, difficulty: difficulty)) {
            expect(round.options, hasLength(4), reason: 'seed $seed');
            expect(round.options.toSet(), hasLength(4), reason: 'seed $seed');
          }
        }
      }
    });

    test('and the four carry four DISTINCT fills, not just four hues', () {
      // HUE IS NEVER THE ONLY CHANNEL. Blitz draws four from six and
      // {blue, purple} are both solid while {red, orange} are both stripe, so
      // an unfiltered draw offers two keys a colour-blind player cannot tell
      // apart. This is the invariant that makes the six-answer pool safe.
      for (var seed = 0; seed < 500; seed++) {
        for (final round in roundsFor(
          seed: seed,
          difficulty: Difficulty.blitz,
        )) {
          expect(
            round.options.map((answer) => answer.fill).toSet(),
            hasLength(4),
            reason: 'seed $seed round ${round.index}: ${round.options}',
          );
        }
      }
    });

    test('and the word is always drawable, offered or not', () {
      // The WORD may name a colour that is not on the board — that is a
      // legitimate Stroop trial — but it must still be a real answer.
      for (var seed = 0; seed < 200; seed++) {
        for (final round in roundsFor(seed: seed)) {
          expect(PlayAnswer.values, contains(round.word));
        }
      }
    });
  });

  group('congruency', () {
    test(
      'a congruent round names its own ink, an incongruent one never does',
      () {
        for (var seed = 0; seed < 200; seed++) {
          for (final round in roundsFor(seed: seed)) {
            expect(round.isCongruent, round.word == round.ink);
          }
        }
      },
    );

    for (final difficulty in Difficulty.values) {
      test(
        '${difficulty.name} hits its incongruent share within tolerance',
        () {
          // 2000 rounds, so the sampling error is small enough that a 0.05 band
          // is a real assertion rather than a formality.
          var incongruent = 0;
          var total = 0;

          for (var seed = 0; total < 2000; seed++) {
            for (final round in roundsFor(seed: seed, difficulty: difficulty)) {
              if (!round.isCongruent) incongruent++;
              total++;
            }
          }

          expect(
            incongruent / total,
            closeTo(profileFor(difficulty).incongruentShare, 0.05),
            reason: '${difficulty.name} over $total rounds',
          );
        },
      );
    }
  });

  group('the domain holds no language', () {
    test('a canonical round is ASCII digits and separators only', () {
      // THE TEST THAT FAILS IF A LOCALIZED LABEL IS EVER SMUGGLED IN. Enum
      // INDICES, never `name` or `toString()` — both are one refactor away
      // from a translated string, and a golden vector that moved with the
      // language would mean the generator had learnt to read.
      for (final round in roundsFor(difficulty: Difficulty.blitz)) {
        expect(
          round.canonical(),
          matches(RegExp(r'^[0-9:,]+$')),
          reason: round.canonical(),
        );
      }
    });

    test(
      'and the colour-blind flag is carried on the round, not read later',
      () {
        // The flag is an input to GENERATION and is captured into every round,
        // so a mid-run Settings change cannot alter what the running round is
        // asking. The board reads it off the round rather than off the setting.
        expect(
          roundsFor(
            isColourBlindPalette: true,
          ).every((r) => r.isColourBlindPalette),
          isTrue,
        );
        expect(
          roundsFor().every((r) => !r.isColourBlindPalette),
          isTrue,
        );
      },
    );
  });

  group('generation never throws', () {
    test('for any difficulty, either palette, across a seed sweep', () {
      // A total function. A rejection sampler that could not find four
      // distinct fills would hang or throw here rather than in a player's run.
      for (var seed = -50; seed < 50; seed++) {
        for (final difficulty in Difficulty.values) {
          for (final cvd in <bool>[false, true]) {
            expect(
              () => roundsFor(
                seed: seed,
                difficulty: difficulty,
                isColourBlindPalette: cvd,
              ),
              returnsNormally,
              reason: 'seed $seed ${difficulty.name} cvd=$cvd',
            );
          }
        }
      }
    });
  });
}
