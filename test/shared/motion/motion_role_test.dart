import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/shared/motion/motion_role.dart';
import 'package:mindforge/theme/sunburst_motion.dart';

import '../../support/component_harness.dart';
import '../../support/locale_cases.dart';

void main() {
  const motion = SunburstMotion.sunburstPop;

  group('MotionRole', () {
    test('every role resolves to a duration on the motion scale', () {
      final expected = <MotionRole, Duration>{
        MotionRole.tap: motion.durTap,
        MotionRole.state: motion.durState,
        MotionRole.move: motion.durMove,
        MotionRole.celebrate: motion.durCelebrate,
        MotionRole.none: Duration.zero,
      };

      expect(expected.keys.toSet(), MotionRole.values.toSet());

      for (final entry in expected.entries) {
        expect(
          motion.durationFor(entry.key),
          entry.value,
          reason: '${entry.key}',
        );
      }
    });

    test('and none of them exceeds the celebrate ceiling', () {
      for (final role in MotionRole.values) {
        expect(
          motion.durationFor(role),
          lessThanOrEqualTo(motion.durCelebrate),
          reason: '$role is longer than the longest moment in the design',
        );
      }
    });
  });

  group('CurveRole', () {
    test('every role resolves to a curve on the motion scale', () {
      final expected = <CurveRole, Curve>{
        CurveRole.pop: motion.easePop,
        CurveRole.out: motion.easeOut,
        CurveRole.inOut: motion.easeInOut,
      };

      expect(expected.keys.toSet(), CurveRole.values.toSet());

      for (final entry in expected.entries) {
        expect(motion.curveFor(entry.key), entry.value, reason: '${entry.key}');
      }
    });
  });

  group('resolution', () {
    testWidgets('collapses every role to zero under reduce motion', (
      tester,
    ) async {
      // Reduce motion means STOP, not "gentler". Every moment carries a
      // non-motion residue, so the acknowledgement survives at zero duration.
      late BuildContext captured;

      await tester.pumpPopComponent(
        Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
        disableAnimations: true,
      );

      for (final role in MotionRole.values) {
        expect(
          SunburstMotion.of(captured).resolvedDurationFor(captured, role),
          Duration.zero,
          reason: '$role',
        );
      }
    });

    testWidgets('and is the same in every locale', (tester) async {
      // A duration is a duration in every language. The ckb case is also the
      // cheapest possible smoke test that E04's vendored delegate does not
      // throw when a motion widget builds.
      for (final localeCase in LocaleCase.all) {
        late BuildContext captured;

        await tester.pumpPopComponent(
          Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
          localeCase: localeCase,
        );

        expect(
          SunburstMotion.of(captured).resolvedDurationFor(
            captured,
            MotionRole.tap,
          ),
          motion.durTap,
          reason: localeCase.tag,
        );
      }
    });
  });
}
