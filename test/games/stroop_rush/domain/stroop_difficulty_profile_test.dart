import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_difficulty_profile.dart';
import 'package:mindforge/theme/sunburst_colors.dart';

/// What each difficulty means, as numbers rather than as a feeling.
void main() {
  group('every difficulty has a profile', () {
    for (final difficulty in Difficulty.values) {
      test('${difficulty.name} resolves', () {
        // An exhaustive switch with no `default:`, so a fourth difficulty does
        // not compile until someone decides what it plays like.
        expect(profileFor(difficulty), isA<StroopDifficultyProfile>());
      });
    }
  });

  group('the three profiles get harder in one direction', () {
    final chill = profileFor(Difficulty.chill);
    final classic = profileFor(Difficulty.classic);
    final blitz = profileFor(Difficulty.blitz);

    test('more rounds each step', () {
      expect(chill.roundCount, lessThan(classic.roundCount));
      expect(classic.roundCount, lessThan(blitz.roundCount));
    });

    test('a larger share of them lie about their colour', () {
      // The incongruent share IS the difficulty of a Stroop task: a congruent
      // round asks you to read, and an incongruent one asks you not to.
      expect(chill.incongruentShare, lessThan(classic.incongruentShare));
      expect(classic.incongruentShare, lessThan(blitz.incongruentShare));
    });

    test('and the streak is worth more', () {
      expect(chill.multiplierCap, lessThan(classic.multiplierCap));
      expect(classic.multiplierCap, lessThan(blitz.multiplierCap));
    });

    test('every share is a ratio, and none of them is certain', () {
      // 1.0 would mean a game with no congruent rounds at all, which stops
      // being a Stroop task: the conflict only means something against a
      // baseline where word and ink agree.
      for (final profile in <StroopDifficultyProfile>[chill, classic, blitz]) {
        expect(profile.incongruentShare, greaterThan(0));
        expect(profile.incongruentShare, lessThan(1));
      }
    });
  });

  group('the answer pools', () {
    test('chill and classic draw from the four-answer set', () {
      for (final difficulty in <Difficulty>[
        Difficulty.chill,
        Difficulty.classic,
      ]) {
        expect(
          profileFor(difficulty).pool,
          <PlayAnswer>[
            PlayAnswer.red,
            PlayAnswer.blue,
            PlayAnswer.green,
            PlayAnswer.yellow,
          ],
          reason: difficulty.name,
        );
      }
    });

    test('and blitz adds the two extras', () {
      expect(profileFor(Difficulty.blitz).pool, hasLength(6));
      expect(
        profileFor(Difficulty.blitz).pool,
        containsAll(<PlayAnswer>[PlayAnswer.purple, PlayAnswer.orange]),
      );
    });

    test('but every pool can still yield four distinct fills', () {
      // THE CONSTRAINT THAT MAKES BLITZ POSSIBLE AT ALL. Four keys must carry
      // four different patterns, because hue is never the only channel. Blitz
      // draws four from six, and {blue, purple} are both solid while
      // {red, orange} are both stripe — so a pool that could not produce four
      // distinct fills would deadlock the generator rather than fail a test.
      for (final difficulty in Difficulty.values) {
        expect(
          profileFor(difficulty).pool.map((answer) => answer.fill).toSet(),
          hasLength(greaterThanOrEqualTo(4)),
          reason: '${difficulty.name} cannot fill four keys distinctly',
        );
      }
    });

    test('and no pool repeats an answer', () {
      for (final difficulty in Difficulty.values) {
        final pool = profileFor(difficulty).pool;

        expect(pool.toSet(), hasLength(pool.length), reason: difficulty.name);
      }
    });
  });
}
