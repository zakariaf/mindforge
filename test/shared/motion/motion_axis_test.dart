import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/shared/motion/motion_axis.dart';

void main() {
  group('MotionAxis', () {
    test('has exactly four values', () {
      expect(MotionAxis.values, hasLength(4));
      expect(MotionAxis.values.map((axis) => axis.name).toSet(), <String>{
        'none',
        'inline',
        'vertical',
        'fixed',
      });
    });

    test('only inline is direction-dependent', () {
      // One getter, switched exhaustively, so "mirrors" is defined once and
      // every later test reads it rather than restating it.
      const expected = <MotionAxis, bool>{
        MotionAxis.inline: true,
        MotionAxis.none: false,
        MotionAxis.vertical: false,
        MotionAxis.fixed: false,
      };

      expect(expected.keys.toSet(), MotionAxis.values.toSet());

      for (final entry in expected.entries) {
        expect(entry.key.mirrorsUnderRtl, entry.value, reason: '${entry.key}');
      }
    });

    test('and fixed is the one whose reason is the light source', () {
      // Stated as its own assertion because it is the value a reviewer will
      // question: a pressed surface travels down its own hard offset shadow,
      // and that shadow is a property of the design's lighting rather than of
      // reading direction.
      expect(MotionAxis.fixed.mirrorsUnderRtl, isFalse);
    });
  });
}
