import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/shared/motion/shake_on_wrong.dart';
import 'package:mindforge/theme/sunburst_motion.dart';

import '../../support/component_harness.dart';
import '../../support/locale_cases.dart';

/// The wrong-answer shake: two cycles, and the absence of a third.
void main() {
  const motion = SunburstMotion.sunburstPop;
  const key = Key('key');

  Widget shake({required bool isWrong}) => ShakeOnWrong(
    isWrong: isWrong,
    child: const SizedBox(key: key, width: 64, height: 64),
  );

  /// The horizontal offset the child is currently drawn at.
  double dxOf(WidgetTester tester) {
    final transforms = tester.widgetList<Transform>(
      find.descendant(
        of: find.byType(ShakeOnWrong),
        matching: find.byType(Transform),
      ),
    );

    return transforms
        .map((t) => t.transform.getTranslation().x)
        .fold(0, (a, b) => a + b);
  }

  /// Samples the offset every [step] for [frames] frames.
  Future<List<double>> sample(
    WidgetTester tester, {
    required int frames,
    required Duration step,
  }) async {
    final samples = <double>[];
    for (var i = 0; i < frames; i++) {
      samples.add(double.parse(dxOf(tester).toStringAsFixed(4)));
      await tester.pump(step);
    }
    return samples;
  }

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

    testWidgets('and the source has no third pass and no repeat', (
      tester,
    ) async {
      // The stop condition IS the absence of a third line. Asserted, because
      // "there is no loop" is invisible in a diff that adds one.
      final code = File('lib/shared/motion/shake_on_wrong.dart')
          .readAsStringSync()
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');

      expect(code, isNot(contains('.repeat(')));
      expect('forward('.allMatches(code), hasLength(2));
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

      expect(leftmost, closeTo(-motion.shakeAmplitude, 0.2));
      expect(rightmost, closeTo(motion.shakeAmplitude, 0.2));
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

    testWidgets('and the file reads no direction', (tester) async {
      final code = File('lib/shared/motion/shake_on_wrong.dart')
          .readAsStringSync()
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');

      expect(code, isNot(contains('Directionality')));
      expect(code, isNot(contains('TextDirection')));
    });
  });
}
