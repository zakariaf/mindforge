import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/shared/feedback/haptic_verb.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/shared/feedback/testing/fake_haptic_gateway.dart';
import 'package:mindforge/shared/motion/pop_celebration.dart';
import 'package:mindforge/theme/sunburst_motion.dart';

import '../../support/component_harness.dart';
import '../../support/locale_cases.dart';

/// The celebration: one pass, no loop, and nothing in the player's way.
void main() {
  /// The scale the badge is drawn at right now.
  double scaleOf(WidgetTester tester) =>
      scaleUnder(tester, find.byType(PopCelebration));

  const motion = SunburstMotion.sunburstPop;

  const badge = Key('badge');

  Widget celebration({
    Moment moment = Moment.personalBest,
    String? freshMount,
  }) => PopCelebration(
    // A key only where a test needs a FRESH State. Re-pumping the same widget
    // type at the same position reuses the element, so the latch is already
    // set and the celebration correctly declines to replay — which is the
    // behaviour one test asserts and the reason another needs a new key.
    key: freshMount == null ? null : ValueKey<String>(freshMount),
    moment: moment,
    child: const SizedBox(key: badge, width: 80, height: 40),
  );

  /// Every transform between the celebration and the badge.
  ///
  /// SCOPED TO THE CELEBRATION. MaterialApp's page transition wraps the whole
  /// route in a scale of its own, and an unscoped ancestor walk multiplies the
  /// route's entry animation into the reading — which looks exactly like a
  /// celebration that starts 90ms late.
  Iterable<Transform> transformsOver(WidgetTester tester) =>
      tester.widgetList<Transform>(
        find.descendant(
          of: find.byType(PopCelebration),
          matching: find.byType(Transform),
        ),
      );

  /// The rotation applied above the badge, in radians.
  double rotationOf(WidgetTester tester) {
    final transforms = transformsOver(tester);

    return transforms
        .map(
          (t) => math.atan2(t.transform.getRow(1)[0], t.transform.getRow(0)[0]),
        )
        .reduce((a, b) => a + b);
  }

  group('it plays once', () {
    testWidgets('and a rebuild does not play it again', (tester) async {
      // A celebration that replays on every rebuild fires a heavy impact every
      // time the theme, the locale or the parent's state moves.
      final gateway = FakeHapticGateway();
      await tester.pumpPopComponent(celebration(), hapticGateway: gateway);
      await tester.pump(motion.durCelebrate);

      // A locale change forces didChangeDependencies without remounting.
      await tester.pumpPopComponent(
        celebration(),
        hapticGateway: gateway,
        localeCase: LocaleCase.german,
      );
      await tester.pump(motion.durCelebrate);

      expect(gateway.played, <HapticVerb>[HapticVerb.heavyImpact]);
    });
  });

  group('the haptic fires above every stop condition', () {
    testWidgets('reduce motion silences the animation, not the moment', (
      tester,
    ) async {
      // THE ORDERING BUG THIS TEST EXISTS FOR: an early return for reduced
      // motion placed ABOVE fire(). A player with animation off still earned
      // the personal best and still gets told.
      final gateway = FakeHapticGateway();
      await tester.pumpPopComponent(
        celebration(),
        hapticGateway: gateway,
        disableAnimations: true,
      );
      await tester.pump();

      expect(gateway.played, <HapticVerb>[HapticVerb.heavyImpact]);
      expect(
        scaleOf(tester),
        1.0,
        reason: 'no pop under reduce motion; it rests at its end state',
      );
    });

    testWidgets('and haptics off silences the moment, not the animation', (
      tester,
    ) async {
      // The mirror case. Two independent switches, and the celebration is not
      // allowed to conflate them.
      final gateway = FakeHapticGateway();
      await tester.pumpPopComponent(
        celebration(),
        hapticGateway: gateway,
        settings: const AppSettings.defaults().copyWith(
          isHapticsEnabled: false,
        ),
      );
      await tester.pump(motion.durCelebrate ~/ 2);

      expect(gateway.played, isEmpty);
      expect(scaleOf(tester), isNot(1.0));
    });
  });

  group('and when the route becomes current again', () {
    testWidgets('the celebration it declined to draw finally plays', (
      tester,
    ) async {
      // THE BUG: one latch covering two different questions. _hasPlayed was set
      // above the off-route return, so a badge INSERTED WHILE A SHEET WAS ON
      // TOP never popped — not then, and not after the sheet closed, because
      // the latch had already swallowed the retry.
      //
      // Setting this up needs the celebration to MOUNT while its route is not
      // current, which is the part the first version of this test got wrong: it
      // mounted the badge on a current route and pushed over it half a second
      // later, by which time the pop had long finished. A results screen that
      // inserts the badge under an open pause sheet is the real shape.
      final showBadge = ValueNotifier<bool>(false);
      addTearDown(showBadge.dispose);
      final gateway = FakeHapticGateway();

      await tester.pumpPopComponent(
        Navigator(
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            builder: (context) => ValueListenableBuilder<bool>(
              valueListenable: showBadge,
              builder: (context, show, _) =>
                  show ? celebration() : const SizedBox.shrink(),
            ),
          ),
        ),
        hapticGateway: gateway,
      );
      await tester.pump(const Duration(milliseconds: 500));

      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).last,
      );

      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (context) => const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // The badge arrives with the sheet already on top.
      showBadge.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        gateway.played,
        <HapticVerb>[HapticVerb.heavyImpact],
        reason: 'the moment happened whether or not anyone was looking',
      );

      navigator.pop();
      await tester.pump();

      // Sampled across the window rather than probed at one instant: the route
      // does not become current until its pop TRANSITION finishes, so the
      // celebration starts somewhere inside these frames and is over by the end
      // of them. A single reading lands on 1.0 either way.
      final scales = await sampleFrames(
        tester,
        scaleOf,
        frames: 40,
        step: const Duration(milliseconds: 20),
      );

      expect(
        scales.where((scale) => scale != 1.0),
        isNotEmpty,
        reason:
            'the pop runs once the badge is visible again, rather than having '
            'been swallowed by the same latch that guards the haptic',
      );
    });

    testWidgets('and the moment still fires exactly once', (tester) async {
      // The half of the latch that must NOT relax: a heavy impact per route
      // change would be worse than no celebration at all.
      final gateway = FakeHapticGateway();

      await tester.pumpPopComponent(celebration(), hapticGateway: gateway);
      await tester.pump(motion.durCelebrate);
      await tester.pumpPopComponent(
        celebration(),
        hapticGateway: gateway,
        localeCase: LocaleCase.persian,
      );
      await tester.pump(motion.durCelebrate);

      expect(gateway.played, <HapticVerb>[HapticVerb.heavyImpact]);
    });
  });

  group('what it rests at', () {
    testWidgets('the scale is 1.0 once the pass completes', (tester) async {
      await tester.pumpPopComponent(celebration());
      await tester.pump(motion.durCelebrate);
      await tester.pump(motion.durCelebrate);

      expect(scaleOf(tester), closeTo(1, 0.0001));
    });

    testWidgets('and it applies no rotation of its own', (tester) async {
      // The -2.5deg of .badge.new is the BADGE's resting geometry and PopBadge
      // applies it from the token. A restingTiltDegrees inlet here was a raw
      // degrees number any call site could pass a literal to, which is exactly
      // what the token exists to prevent — and it left the token with no
      // production consumer at all.
      await tester.pumpPopComponent(celebration());
      await tester.pump(motion.durCelebrate);

      expect(rotationOf(tester), 0);
    });
  });

  group('it blocks nothing', () {
    testWidgets('a tap behind it lands mid-celebration', (tester) async {
      // A celebration that swallowed input would eat the "play again" tap for
      // the duration of its own pop.
      var taps = 0;

      await tester.pumpPopComponent(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: celebration(),
        ),
      );
      await tester.pump(motion.durCelebrate ~/ 2);
      await tester.tap(find.byKey(badge));

      expect(taps, 1);

      // Scoped to the celebration's own subtree: MaterialApp's route machinery
      // carries pointer gates of its own, and an unscoped search finds those
      // and says nothing about this widget.
      for (final type in <Type>[AbsorbPointer, IgnorePointer, ModalBarrier]) {
        expect(
          find.descendant(
            of: find.byType(PopCelebration),
            matching: find.byType(type),
          ),
          findsNothing,
          reason: '$type',
        );
      }
    });
  });

  group('it does not mirror', () {
    testWidgets('the pop and the tilt are identical in all four locales', (
      tester,
    ) async {
      // A scale pop is MotionAxis.none — it has no reading direction to have.
      // The tilt is a shape constant of the badge, the same class of decision
      // as the hard offset shadow.
      final sampled = <String, List<double>>{};
      final tilts = <String, double>{};

      for (final localeCase in LocaleCase.all) {
        await tester.pumpPopComponent(
          celebration(freshMount: localeCase.tag),
          localeCase: localeCase,
        );

        final frames = <double>[];
        for (var i = 0; i < 6; i++) {
          frames.add(scaleOf(tester));
          await tester.pump(motion.durCelebrate ~/ 6);
        }

        sampled[localeCase.tag] = frames;
        tilts[localeCase.tag] = rotationOf(tester);
        await tester.pump(motion.durCelebrate);
      }

      expect(
        sampled['en']!.reduce((a, b) => a > b ? a : b),
        closeTo(1.0735, 0.001),
        reason:
            'the measured peak across these six samples; the true peak is '
            '1.0753 between two of them. Nominally 1.06 in system.html — '
            'easePop overshoots INSIDE the rising segment, which is the pop, '
            'and the settle dips to 0.995 before landing on 1.0 the way a '
            'spring does. Recorded here because a curve chained onto a tween '
            'sequence does not produce the numbers either one names alone',
      );

      for (final entry in sampled.entries) {
        expect(entry.value, sampled['en'], reason: entry.key);
        expect(
          tilts[entry.key],
          tilts['en'],
          reason:
              '${entry.key} tilted the other way; the badge tilt is a '
              'shape constant, not a reading-direction property',
        );
      }
    });
  });
}
