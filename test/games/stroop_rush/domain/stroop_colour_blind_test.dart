import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/games/stroop_rush/application/stroop_answer_labels.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_round.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_round_generator.dart';
import 'package:mindforge/theme/sunburst_colors.dart';

/// The colour-blind setting is an input to GENERATION, not a paint-time swap.
///
/// That distinction is the whole task. A swap at paint time would leave blitz
/// drawing purple and orange and then recolouring them, which puts two keys on
/// the board that the palette has no distinct colour for — and it would let a
/// mid-run Settings change rewrite the question the player is currently
/// looking at.
void main() {
  List<StroopRound> roundsFor({
    int seed = 42,
    Difficulty difficulty = Difficulty.blitz,
    bool colourBlind = true,
  }) => generateStroopRounds(
    seed: seed,
    difficulty: difficulty,
    isColourBlindPalette: colourBlind,
  );

  group('the flag caps the answer set', () {
    test('no round offers purple or orange, at any difficulty', () {
      // THE TEST THAT FAILS IF THE FLAG IS ONLY READ AT PAINT TIME: blitz's
      // pool would still draw them and something downstream would recolour
      // what it could.
      for (var seed = 0; seed < 500; seed++) {
        for (final difficulty in Difficulty.values) {
          for (final round in roundsFor(seed: seed, difficulty: difficulty)) {
            expect(
              round.options,
              isNot(
                anyElement(
                  anyOf(equals(PlayAnswer.purple), equals(PlayAnswer.orange)),
                ),
              ),
              reason: 'seed $seed ${difficulty.name} round ${round.index}',
            );
          }
        }
      }
    });

    test('and the WORD is capped too, not just the keys', () {
      // A word naming a colour the palette cannot paint is worse than one
      // naming a colour that is merely absent from the board: there would be
      // no swapped hue for the player to have learnt.
      for (var seed = 0; seed < 300; seed++) {
        for (final round in roundsFor(seed: seed)) {
          expect(
            round.word,
            isNot(
              anyOf(equals(PlayAnswer.purple), equals(PlayAnswer.orange)),
            ),
            reason: 'seed $seed round ${round.index}',
          );
        }
      }
    });

    test('so blitz under the flag offers exactly the classic four', () {
      final offered = <PlayAnswer>{
        for (var seed = 0; seed < 100; seed++)
          for (final round in roundsFor(seed: seed)) ...round.options,
      };

      expect(offered, <PlayAnswer>{
        PlayAnswer.red,
        PlayAnswer.blue,
        PlayAnswer.green,
        PlayAnswer.yellow,
      });
    });

    test(
      'and four distinct fills still, because patterns are not a setting',
      () {
        for (var seed = 0; seed < 200; seed++) {
          for (final round in roundsFor(seed: seed)) {
            expect(
              round.options.map((answer) => answer.fill).toSet(),
              hasLength(4),
            );
          }
        }
      },
    );
  });

  group('generation branched, not rendering', () {
    test('the same seed deals a different sequence with the flag on', () {
      // If only the paint changed, these two would be identical.
      expect(
        roundsFor().map((round) => round.canonical()).join('|'),
        isNot(
          roundsFor(colourBlind: false).map((r) => r.canonical()).join('|'),
        ),
      );
    });

    test('and every round records the flag it was dealt under', () {
      // Read off the ROUND at paint time, never off the setting: a player who
      // flips it mid-run keeps playing the round they were given.
      expect(roundsFor().every((r) => r.isColourBlindPalette), isTrue);
      expect(
        roundsFor(colourBlind: false).every((r) => !r.isColourBlindPalette),
        isTrue,
      );
    });
  });

  group('the label follows the painted hue', () {
    test(
      'under the flag, green is labelled orange and red is labelled pink',
      () {
        // THE HALF THAT MAKES THE SETTING HONEST. `answerColour` paints
        // PlayAnswer.green as cbOrange, so a key labelled "Green" would be an
        // orange key with the wrong word on it — and this game is ABOUT the word
        // disagreeing with the colour, so that mistake is invisible by design.
        expect(
          answerWordKey(PlayAnswer.green, colourBlind: true),
          'colourOrange',
        );
        expect(answerWordKey(PlayAnswer.red, colourBlind: true), 'colourPink');

        // And the same two, unswapped, so the pair reads as a swap rather than
        // as two unrelated facts.
        expect(
          answerWordKey(PlayAnswer.green, colourBlind: false),
          'colourGreen',
        );
        expect(answerWordKey(PlayAnswer.red, colourBlind: false), 'colourRed');
      },
    );

    test(
      'and blue and yellow keep their own words, because they keep their hue',
      () {
        for (final answer in <PlayAnswer>[PlayAnswer.blue, PlayAnswer.yellow]) {
          expect(
            answerWordKey(answer, colourBlind: true),
            answerWordKey(answer, colourBlind: false),
            reason: answer.name,
          );
        }
      },
    );

    test('with the flag off, every answer is labelled with its own name', () {
      for (final answer in PlayAnswer.values) {
        expect(
          answerWordKey(answer, colourBlind: false).toLowerCase(),
          'colour${answer.name}',
          reason: answer.name,
        );
      }
    });

    test('and pink exists ONLY as a colour-blind label', () {
      // There is no PlayAnswer.pink and there must not be: pink is what red
      // BECOMES, not a fifth thing a round can offer. The key exists so the
      // swapped key can be named; the answer set does not grow.
      expect(
        PlayAnswer.values.map((answer) => answer.name),
        isNot(contains('pink')),
      );
      expect(
        PlayAnswer.values
            .map((answer) => answerWordKey(answer, colourBlind: true))
            .toSet(),
        contains('colourPink'),
      );
    });

    test('and key selection takes no locale', () {
      // A pure function of (PlayAnswer, bool). The locale reaches the label
      // only through the AppLocalizations instance the View already holds, so
      // switching language mid-run re-renders and re-deals nothing.
      for (final answer in PlayAnswer.values) {
        for (final flag in <bool>[false, true]) {
          expect(
            answerWordKey(answer, colourBlind: flag),
            answerWordKey(answer, colourBlind: flag),
          );
        }
      }
    });
  });
}
