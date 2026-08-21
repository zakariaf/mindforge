import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_scramble.dart';

/// The seeded scramble: a permutation, deterministic, and not too orderly.
void main() {
  group('every scramble', () {
    test('is a permutation of 1..n^2', () {
      // A repair pass that duplicated or dropped a value would still LOOK like
      // a board, and the player would hunt for a number that is not there.
      for (final size in <int>[4, 5]) {
        for (var seed = 0; seed < 2000; seed++) {
          final cells = schulteScramble(seed: seed, size: size);
          final sorted = List<int>.of(cells)..sort();

          expect(
            sorted,
            List<int>.generate(size * size, (i) => i + 1),
            reason: 'seed $seed at $size x $size',
          );
        }
      }
    });

    test('and is deterministic, and seeds do not collapse', () {
      // The same seed twice is the contract. 2000 seeds producing far fewer
      // than 2000 boards would mean the seed is barely reaching the shuffle.
      final fingerprints = <String>{};

      for (var seed = 0; seed < 2000; seed++) {
        final first = schulteScramble(seed: seed, size: 5);
        final again = schulteScramble(seed: seed, size: 5);

        expect(again, first, reason: 'seed $seed was not reproducible');
        fingerprints.add(first.join(','));
      }

      expect(fingerprints, hasLength(greaterThanOrEqualTo(1990)));
    });
  });

  group('natural positions', () {
    test('never exceed the threshold, at any seed', () {
      // THE NAMED THRESHOLD TEST. A Schulte board with 1 sitting in the top
      // left is not a search task, it is a freebie — and the player notices.
      for (final size in <int>[4, 5]) {
        for (var seed = 0; seed < 5000; seed++) {
          expect(
            naturalPositionCount(schulteScramble(seed: seed, size: size)),
            lessThanOrEqualTo(kMaxNaturalPositions),
            reason: 'seed $seed at $size x $size',
          );
        }
      }
    });

    test('but some scrambles DO leave one number in place', () {
      // The negative half. A full derangement is itself a pattern a regular
      // player learns — "1 is never top-left" is information — so the rule is
      // a ceiling, not a ban, and this proves we did not quietly ship the ban.
      var sawOne = false;

      for (var seed = 0; seed < 5000 && !sawOne; seed++) {
        sawOne =
            naturalPositionCount(schulteScramble(seed: seed, size: 5)) == 1;
      }

      expect(sawOne, isTrue);
    });
  });

  group('repairNaturalPositions', () {
    /// Every permutation of `1..n`, in lexicographic order.
    List<List<int>> permutationsOf(int n) {
      final result = <List<int>>[];

      void walk(List<int> chosen, List<int> rest) {
        if (rest.isEmpty) {
          result.add(chosen);

          return;
        }

        for (var i = 0; i < rest.length; i++) {
          walk(
            <int>[...chosen, rest[i]],
            <int>[...rest.sublist(0, i), ...rest.sublist(i + 1)],
          );
        }
      }

      walk(<int>[], List<int>.generate(n, (i) => i + 1));

      return result;
    }

    test('is total, sound and idempotent — exhaustively', () {
      // Exhaustive over 5! and 7!, because the repair is the one part of the
      // generator that can loop or run out of candidates, and a sampled test
      // would miss exactly the permutation that has nowhere left to swap.
      for (final n in <int>[5, 7]) {
        for (final permutation in permutationsOf(n)) {
          final repaired = repairNaturalPositions(permutation);
          final sorted = List<int>.of(repaired)..sort();

          expect(sorted, List<int>.generate(n, (i) => i + 1));
          expect(
            naturalPositionCount(repaired),
            lessThanOrEqualTo(kMaxNaturalPositions),
            reason: '$permutation repaired to $repaired',
          );
          expect(
            repairNaturalPositions(repaired),
            repaired,
            reason: 'repairing twice differed from repairing once',
          );
        }
      }
    });
  });
}
