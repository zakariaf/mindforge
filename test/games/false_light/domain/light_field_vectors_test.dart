import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/games/false_light/domain/light_field_generator.dart';

import 'light_field_vectors.dart';

void main() {
  group('the frozen table', () {
    test('still describes the runs production deals', () {
      // `==`, never a tolerance. These are integers; a run that is nearly the
      // frozen one is a different run.
      for (final vector in kLightFieldVectors) {
        final fields = generateLightFields(
          seed: vector.seed,
          difficulty: vector.difficulty,
        );

        expect(fingerprintOf(fields), vector.fingerprint, reason: vector.note);
        expect(fields, hasLength(vector.fieldCount), reason: vector.note);
        expect(
          fields.first.pressedCount,
          vector.firstPressedCount,
          reason: vector.note,
        );
        expect(
          fields.fold<int>(0, (sum, field) => sum + field.pressedCount),
          vector.totalPressed,
          reason: vector.note,
        );
      }
    });

    test('and covers all three difficulties and the extremes of the seed', () {
      // A table that pinned one difficulty would let the mode salt drift.
      expect(
        kLightFieldVectors.map((v) => v.difficulty).toSet(),
        Difficulty.values.toSet(),
      );
      expect(
        kLightFieldVectors.map((v) => v.seed),
        contains(0x7FFFFFFFFFFFFFFF),
      );
      expect(kLightFieldVectors.map((v) => v.seed), contains(0));
    });
  });
}
