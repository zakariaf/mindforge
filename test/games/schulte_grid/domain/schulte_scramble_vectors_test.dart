import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_scramble.dart';

import 'schulte_oracle.dart';
import 'schulte_scramble_vectors.dart';

/// The frozen boards, and the second implementation that argues they are right.
void main() {
  group('the frozen table', () {
    test('still describes the boards production makes', () {
      // `==`, never a tolerance. These are integers; a board that is nearly the
      // frozen one is a different board.
      for (final vector in kSchulteScrambleVectors) {
        final cells = schulteScramble(seed: vector.seed, size: vector.size);

        expect(fingerprintOf(cells), vector.fingerprint, reason: vector.note);
        expect(cells.first, vector.firstCell, reason: vector.note);
        expect(
          naturalPositionCount(cells),
          vector.naturalPositions,
          reason: vector.note,
        );
      }
    });

    test('and covers both shipping sizes and the extremes of the seed', () {
      // A table that pinned one size would let the size salt drift.
      expect(kSchulteScrambleVectors.map((v) => v.size).toSet(), <int>{
        3,
        4,
        5,
      });
      expect(
        kSchulteScrambleVectors.map((v) => v.seed),
        contains(0x7FFFFFFFFFFFFFFF),
      );
    });
  });

  group('production and the independent oracle', () {
    test('agree over 500 seeds at three sizes', () {
      // THE PART THAT ARGUES FOR CORRECTNESS. The table above proves stability;
      // this proves two people implementing the same written definition — one
      // in native ints with in-place swaps, one in BigInt with an explicit
      // 64-bit mask — reach the same boards. The arithmetic they must agree on
      // is exactly where Dart and a naive transcription part company: `%` on a
      // negative dividend and `>>>` on a set sign bit.
      for (final size in <int>[3, 4, 5]) {
        for (var seed = 0; seed < 500; seed++) {
          expect(
            schulteScramble(seed: seed, size: size),
            oracleScramble(seed: seed, size: size),
            reason: 'seed $seed at $size x $size',
          );
        }
      }
    });

    test('and on the extreme seeds the table pins', () {
      for (final vector in kSchulteScrambleVectors) {
        expect(
          schulteScramble(seed: vector.seed, size: vector.size),
          oracleScramble(seed: vector.seed, size: vector.size),
          reason: vector.note,
        );
      }
    });
  });
}
