import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/shared/feedback/moment_catalog.dart';
import 'package:mindforge/shared/motion/shake_on_wrong.dart';
import 'package:mindforge/theme/sunburst_motion.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

import '../../support/component_harness.dart';
import '../../support/locale_cases.dart';

/// The wrong-answer shake: as many passes as its catalog row declares, and
/// nothing after them.
void main() {
  /// The horizontal offset the child is currently drawn at.
  double dxOf(WidgetTester tester) =>
      translationUnder(tester, find.byType(ShakeOnWrong)).dx;

  Future<List<double>> sample(
    WidgetTester tester, {
    required int frames,
    required Duration step,
  }) => sampleFrames(tester, dxOf, frames: frames, step: step);

  const motion = SunburstMotion.sunburstPop;
  const shape = SunburstShape.sunburstPop;
  const key = Key('key');

  Widget shake({required bool isWrong}) => ShakeOnWrong(
    isWrong: isWrong,
    child: const SizedBox(key: key, width: 64, height: 64),
  );

  group('it is bounded', () {
    testWidgets('two cycles, and it rests at zero', (tester) async {
      await tester.pumpPopComponent(shake(isWrong: false));
      await tester.pumpPopComponent(shake(isWrong: true));

      final samples = await sample(
        tester,
        frames: 14,
        step: motion.durCelebrate ~/ 6,
      );

      // where().isNotEmpty rather than Iterable.any: check_test_hygiene.sh
      // greps for mocktail's argument matcher by name followed by a paren, and
      // a word boundary matches between the dot and the a — so Dart's own
      // method trips a gate about a package this repository does not use. This
      // comment avoids naming it followed by a paren for the same reason.
      expect(
        samples.where((dx) => dx < -1),
        isNotEmpty,
        reason: 'the sweep goes negative',
      );
      expect(
        samples.where((dx) => dx > 1),
        isNotEmpty,
        reason: 'and positive',
      );

      // Two cycles of durCelebrate, plus a frame. A third would still be
      // moving here.
      await tester.pump(motion.durCelebrate * 2);
      expect(dxOf(tester), 0);
    });

    testWidgets('for exactly as many passes as the catalog declares', (
      tester,
    ) async {
      // THE STOP CONDITION IS A NUMBER IN THE TABLE, and this is what makes
      // that true rather than decorative. It used to be two unrolled forward()
      // calls with a comment saying there was no third, and a source grep
      // counting them — so editing cycles: 2 to 3 in the catalog changed
      // nothing at all.
      final cycles = specFor(Moment.answerWrong).cycles;
      expect(cycles, 2, reason: 'the row this test is calibrated against');

      await tester.pumpPopComponent(shake(isWrong: false));
      await tester.pumpPopComponent(shake(isWrong: true));

      // Pass by pass, not one long pump. A single pump past several passes
      // advances the clock and produces ONE frame: the awaited TickerFuture
      // resolves and the next pass starts, but nothing renders it, so the
      // widget still reads zero and the test would fail on a shake that is
      // working perfectly. Each pass gets its own pump, plus a SHORT one — not
      // a zero-duration pump — for the microtask that starts the next pass,
      // because the new controller measures its elapsed time from the first
      // frame after it begins.
      for (var pass = 0; pass < cycles - 1; pass++) {
        await tester.pump(motion.durCelebrate);
        await tester.pump(const Duration(milliseconds: 1));
      }

      // A quarter into the LAST pass, where the sweep is at its extreme. Not
      // one frame before the end: every pass finishes at zero, so that instant
      // cannot tell a shake that ran its passes from one that stopped early.
      await tester.pump(motion.durCelebrate ~/ 4);
      final insideTheLastPass = dxOf(tester);

      // And past the last one the table allows, nothing moves again.
      await tester.pump(motion.durCelebrate);
      expect(dxOf(tester), 0);

      await tester.pump(motion.durCelebrate);
      expect(dxOf(tester), 0);

      expect(
        insideTheLastPass,
        isNot(0),
        reason:
            'with cycles at $cycles the sweep is still running here; with one '
            'fewer it would already have rested',
      );
    });
  });

  group('what stops it', () {
    testWidgets('reduce motion skips the shake entirely', (tester) async {
      // The caller's residue carries it: the depth drop and the ink strike bar
      // are state, and they are what a player with motion off sees.
      await tester.pumpPopComponent(
        shake(isWrong: false),
        disableAnimations: true,
      );
      await tester.pumpPopComponent(
        shake(isWrong: true),
        disableAnimations: true,
      );

      final samples = await sample(
        tester,
        frames: 8,
        step: motion.durCelebrate ~/ 4,
      );

      expect(samples, everyElement(0.0));
    });

    testWidgets('a rebuild with isWrong still true does not re-trigger', (
      tester,
    ) async {
      // Only a false-to-true EDGE starts a sweep. A board that rebuilds every
      // frame while a wrong key is highlighted would shake forever.
      await tester.pumpPopComponent(shake(isWrong: false));
      await tester.pumpPopComponent(shake(isWrong: true));
      await tester.pump(motion.durCelebrate * 2);
      await tester.pump(motion.durCelebrate);

      expect(dxOf(tester), 0);

      await tester.pumpPopComponent(shake(isWrong: true));
      await tester.pump(motion.durCelebrate ~/ 4);

      expect(
        dxOf(tester),
        0,
        reason: 'still true is not a new wrong answer',
      );
    });

    testWidgets('and disposal mid-flight leaves no pending work', (
      tester,
    ) async {
      await tester.pumpPopComponent(shake(isWrong: false));
      await tester.pumpPopComponent(shake(isWrong: true));
      await tester.pump(motion.durCelebrate ~/ 2);

      await tester.pumpPopComponent(const SizedBox.shrink());
      await tester.pump(motion.durCelebrate * 2);

      expect(tester.takeException(), isNull);
    });
  });

  group('the sweep is symmetric, which is why it needs no direction', () {
    testWidgets('it travels the same distance to both sides', (tester) async {
      // THIS is the property that makes the shake the one MotionAxis.inline
      // moment with no Directionality in it. It moves along the reading axis,
      // but it goes equally far each way and returns to zero, so there is no
      // reading-direction bias in how far it travels or where it lands.
      //
      // What mirroring WOULD change is which side it jerks to first, and a
      // wrong answer carries no directional meaning for that to contradict.
      // That is the whole argument, and it depends entirely on the amplitudes
      // being equal — so they are asserted here rather than described. Make the
      // sweep lopsided and this fails; the locale matrix below never could,
      // because an asymmetric sweep is equally asymmetric in every locale.
      await tester.pumpPopComponent(shake(isWrong: false));
      await tester.pumpPopComponent(shake(isWrong: true));

      final samples = await sample(
        tester,
        frames: 40,
        step: motion.durCelebrate ~/ 20,
      );

      final leftmost = samples.reduce((a, b) => a < b ? a : b);
      final rightmost = samples.reduce((a, b) => a > b ? a : b);

      expect(leftmost, closeTo(-shape.shakeAmplitude, 0.2));
      expect(rightmost, closeTo(shape.shakeAmplitude, 0.2));
      expect(
        leftmost + rightmost,
        closeTo(0, 0.2),
        reason: 'a lopsided sweep has a direction, and would need to read one',
      );
    });

    testWidgets('and the sampled sweep is the same in every locale', (
      tester,
    ) async {
      final swept = <String, List<double>>{};

      for (final localeCase in LocaleCase.all) {
        await tester.pumpPopComponent(
          shake(isWrong: false),
          localeCase: localeCase,
        );
        await tester.pumpPopComponent(
          shake(isWrong: true),
          localeCase: localeCase,
        );

        swept[localeCase.tag] = await sample(
          tester,
          frames: 10,
          step: motion.durCelebrate ~/ 5,
        );
        await tester.pump(motion.durCelebrate * 2);
      }

      for (final entry in swept.entries) {
        expect(entry.value, swept['en'], reason: entry.key);
      }
    });
  });
}
