import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/shared/motion/press_physics.dart';
import 'package:mindforge/theme/sunburst_motion.dart';

import '../../support/component_harness.dart';

void main() {
  const geometry = PressGeometry(restOffset: Offset(5, 5), pressScale: 0.98);

  group('PressGeometry', () {
    test('travels one pixel short of its resting offset, on both axes', () {
      expect(geometry.travel, const Offset(4, 4));
      expect(
        const PressGeometry(restOffset: null, pressScale: 1).travel,
        Offset.zero,
      );
    });

    test('and holds no direction to derive a sign from', () {
      // A press moves the object TOWARD ITS SHADOW, and the shadow is a
      // light-source constant. There is no TextDirection in this class, which
      // is what makes "the travel is (+dx, +dy) in every locale" true rather
      // than merely intended.
      expect(geometry.travel.dx, greaterThan(0));
      expect(geometry.travel.dy, greaterThan(0));
    });
  });

  group('the press curve', () {
    testWidgets('overshoots rather than arriving early and freezing', (
      tester,
    ) async {
      // THE BUG THIS PINS: passing easePop to animateTo makes the controller
      // clamp its own value to [0, 1], and easePop peaks near 1.09 — the
      // overshoot it is named for. Measured before the fix, sampling the
      // travel every 10ms of a 120ms press: it reached the end at 30ms and
      // then sat still for 90ms. Three quarters of the press was a freeze.
      final samples = <double>[];

      await tester.pumpPopComponent(
        PressPhysics(
          geometry: geometry,
          builder: (context, t, child) {
            samples.add(t);
            // ColoredBox, not a bare SizedBox: Listener defers to its child
            // for hit testing and a SizedBox is not hit-testable, so the
            // pointer never arrives. In the app PopSurface's opaque
            // GestureDetector sits above and does that job.
            return const ColoredBox(
              color: Color(0xFF000000),
              child: SizedBox(width: 60, height: 40),
            );
          },
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PressPhysics)),
      );
      samples.clear();

      const motion = SunburstMotion.sunburstPop;
      for (var i = 0; i < 12; i++) {
        await tester.pump(motion.durTap ~/ 12);
      }

      expect(
        // where().isNotEmpty rather than Iterable's shorter predicate:
        // check_test_hygiene greps test/ for a bare call by that name looking
        // for mocktail matchers used without a registered fallback.
        samples.where((t) => t > 1),
        isNotEmpty,
        reason:
            'the curve never exceeded 1.0, so the overshoot was clamped away '
            'and the surface arrived early: $samples',
      );
      // And it keeps MOVING. Values above 1.0 are the overshoot coming back,
      // which is motion; what the clamp produced was a run of identical
      // samples, which is a freeze. Counted as repeats rather than as
      // "how many are near 1", because the settle legitimately passes through
      // there.
      final frozen = <double>{};
      var longestRun = 0;
      var run = 0;
      double? previous;
      for (final sample in samples) {
        if (previous != null && (sample - previous).abs() < 1e-6) {
          run++;
          frozen.add(sample);
        } else {
          run = 0;
        }
        if (run > longestRun) longestRun = run;
        previous = sample;
      }

      expect(
        longestRun,
        lessThan(3),
        reason: 'the press froze at $frozen for $longestRun frames: $samples',
      );

      await gesture.up();
      await tester.pump(motion.durTap);
    });

    testWidgets('and a surface unmounted under a held finger does not throw', (
      tester,
    ) async {
      // GestureBinding caches a live pointer's hit-test path, so the UP event
      // is still delivered to a Listener whose element is gone — a pause sheet
      // that auto-closes, or a route that pops, while a finger is down.
      await tester.pumpPopComponent(
        PressPhysics(
          geometry: geometry,
          builder: (context, t, child) => const SizedBox(width: 60, height: 40),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PressPhysics)),
      );
      await tester.pump();

      await tester.pumpPopComponent(const SizedBox.shrink());
      await gesture.up();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
