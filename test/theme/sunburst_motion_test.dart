import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/sunburst_motion.dart';

import '../support/design_source.dart';
import '../support/harness.dart';

void main() {
  const motion = SunburstMotion.sunburstPop;

  group('transcription from system.html', () {
    const durations = <String, Duration>{
      '--dur-tap': Duration(milliseconds: 120),
      '--dur-state': Duration(milliseconds: 160),
      '--dur-move': Duration(milliseconds: 180),
      '--dur-celebrate': Duration(milliseconds: 240),
    };

    for (final entry in durations.entries) {
      test('${entry.key} is ${entry.value.inMilliseconds}ms', () {
        expect(
          DesignSource.cssScalar(entry.key),
          '${entry.value.inMilliseconds}ms',
        );
      });
    }

    test('the four Dart durations match', () {
      expect(motion.durTap, const Duration(milliseconds: 120));
      expect(motion.durState, const Duration(milliseconds: 160));
      expect(motion.durMove, const Duration(milliseconds: 180));
      expect(motion.durCelebrate, const Duration(milliseconds: 240));
    });

    test('nothing runs past durCelebrate', () {
      for (final duration in <Duration>[
        motion.durTap,
        motion.durState,
        motion.durMove,
      ]) {
        expect(
          duration,
          lessThanOrEqualTo(motion.durCelebrate),
          reason: 'durCelebrate is the ceiling, not merely the longest',
        );
      }
    });

    test('there are exactly four durations and three curves', () {
      final fields = DesignSource.dartFieldNames(
        'lib/theme/sunburst_motion.dart',
        'SunburstMotion',
      );

      expect(
        fields,
        <String>[
          'durTap',
          'durState',
          'durMove',
          'durCelebrate',
          'easePop',
          'easeOut',
          'easeInOut',
        ],
        reason:
            'a fifth duration is a new moment nobody catalogued. This scale is '
            'a WHEN and nothing else: shakeAmplitude passed through here '
            'briefly and the list had to carry a sentence calling it "the one '
            'non-timing member", which is a test pinning an anomaly rather '
            'than resolving it. Magnitudes live on SunburstShape, beside '
            'e1..e4, focusGap and pressScale',
      );
    });

    test('the curves match the CSS cubic-beziers', () {
      expect(DesignSource.cssScalar('--ease-pop'), 'cubic-bezier(.2,1.5,.4,1)');
      expect(DesignSource.cssScalar('--ease-out'), 'cubic-bezier(.2,.8,.2,1)');
      expect(
        DesignSource.cssScalar('--ease-inout'),
        'cubic-bezier(.6,0,.3,1)',
      );

      expect(motion.easePop, const Cubic(0.2, 1.5, 0.4, 1));
      expect(motion.easeOut, const Cubic(0.2, 0.8, 0.2, 1));
      expect(motion.easeInOut, const Cubic(0.6, 0, 0.3, 1));
    });
  });

  group('easePop', () {
    test('overshoots past 1.0', () {
      // The whole reason it exists. If it stops overshooting it is easeOut
      // with extra steps, and every "pop" in the app goes flat.
      var maximum = 0.0;
      for (var i = 0; i <= 100; i++) {
        maximum = maximum > motion.easePop.transform(i / 100)
            ? maximum
            : motion.easePop.transform(i / 100);
      }

      expect(
        maximum,
        greaterThan(1.0),
        reason: 'a spring that never passes its target is not a spring',
      );
    });

    test('still lands exactly on its endpoints', () {
      expect(motion.easePop.transform(0), 0);
      expect(motion.easePop.transform(1), 1);
    });
  });

  group('resolve', () {
    testWidgets('returns the full duration by default', (tester) async {
      late Duration resolved;

      await tester.pumpApp(
        Builder(
          builder: (context) {
            resolved = SunburstMotion.of(context).resolve(
              context,
              motion.durState,
            );
            return const SizedBox.shrink();
          },
        ),
        theme: ThemeData(extensions: const <SunburstMotion>[motion]),
      );

      expect(resolved, motion.durState);
    });

    testWidgets('collapses to ZERO under reduced motion, never to shorter', (
      tester,
    ) async {
      final resolved = <Duration>[];

      await tester.pumpApp(
        Builder(
          builder: (context) {
            final scale = SunburstMotion.of(context);
            for (final full in <Duration>[
              motion.durTap,
              motion.durState,
              motion.durMove,
              motion.durCelebrate,
            ]) {
              resolved.add(scale.resolve(context, full));
            }
            return const SizedBox.shrink();
          },
        ),
        theme: ThemeData(extensions: const <SunburstMotion>[motion]),
        disableAnimations: true,
      );

      expect(
        resolved,
        everyElement(Duration.zero),
        reason:
            'reduced motion means STOP, not "gentler". A shorter duration '
            'is still motion, and every moment carries a non-motion residue '
            'that survives with zero duration',
      );
    });

    testWidgets('reads the flag from MediaQuery, not from app state', (
      tester,
    ) async {
      // accessibility-as-code: the OS setting lives in MediaQuery, and a
      // resolve() that took a bool would let app state disagree with it.
      late Duration withFlag;

      await tester.pumpApp(
        Builder(
          builder: (context) {
            withFlag = SunburstMotion.of(
              context,
            ).resolve(context, motion.durMove);
            return const SizedBox.shrink();
          },
        ),
        theme: ThemeData(extensions: const <SunburstMotion>[motion]),
        disableAnimations: true,
      );

      expect(withFlag, Duration.zero);
    });
  });

  group('the extension contract', () {
    testWidgets('of(context) asserts when the extension is missing', (
      tester,
    ) async {
      Object? error;

      await tester.pumpApp(
        Builder(
          builder: (context) {
            try {
              SunburstMotion.of(context);
            } on Object catch (caught) {
              error = caught;
            }
            return const SizedBox.shrink();
          },
        ),
        theme: ThemeData(),
      );

      expect(error, isA<AssertionError>());
    });

    test('lerp snaps at the midpoint, deliberately', () {
      // A DELIBERATE step, not an unfinished implementation. Durations and
      // curves are not meaningfully interpolable mid-transition, and MindForge
      // ships exactly one theme. Do not "fix" this into per-field lerping.
      final other = motion.copyWith(
        durTap: const Duration(milliseconds: 999),
      );

      expect(motion.lerp(other, 0.49), motion);
      expect(motion.lerp(other, 0.5), other);
      expect(motion.lerp(other, 0), motion);
      expect(motion.lerp(other, 1), other);
      expect(motion.lerp(null, 0.5), motion);
    });

    test('copyWith and equality cover every field', () {
      expect(
        motion.copyWith(durTap: const Duration(seconds: 1)),
        isNot(motion),
      );
      expect(motion.copyWith(easeOut: Curves.linear), isNot(motion));
      expect(motion.copyWith(), motion);
    });
  });
}
