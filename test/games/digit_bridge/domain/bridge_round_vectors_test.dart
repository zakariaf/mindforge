import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_round_generator.dart';

import 'bridge_round_vectors.dart';

void main() {
  group('the frozen table', () {
    test('still describes the runs production deals', () {
      // `==`, never a tolerance. These are integers; a run that is nearly the
      // frozen one is a different run.
      for (final vector in kBridgeRoundVectors) {
        final rounds = generateBridgeRounds(
          seed: vector.seed,
          difficulty: vector.difficulty,
        );

        expect(fingerprintOf(rounds), vector.fingerprint, reason: vector.note);
        expect(rounds, hasLength(vector.roundCount), reason: vector.note);
        expect(rounds.first.target, vector.firstTarget, reason: vector.note);
        expect(
          rounds.first.correctIndex,
          vector.firstCorrectIndex,
          reason: vector.note,
        );
      }
    });

    test('and covers all three difficulties and the extremes of the seed', () {
      // A table that pinned one difficulty would let the mode salt drift.
      expect(
        kBridgeRoundVectors.map((v) => v.difficulty).toSet(),
        Difficulty.values.toSet(),
      );
      expect(
        kBridgeRoundVectors.map((v) => v.seed),
        contains(0x7FFFFFFFFFFFFFFF),
      );
      expect(kBridgeRoundVectors.map((v) => v.seed), contains(0));
    });
  });
}
