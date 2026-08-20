@Tags(['golden'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/sunburst_motion.dart';
import 'package:mindforge/ui/components/pop_button.dart';

import '../support/component_harness.dart';
import '../support/golden_tolerance.dart';
import '../support/load_app_fonts.dart';
import '../support/locale_cases.dart';
import '../support/sample_strings.dart';

/// The press, at pinned phases, with the real bundled faces.
///
/// **A press has no reference PNG and cannot have one.** Every image under
/// `design/sunburst-pop/screens/` is an end state, and a held button is not a
/// state anyone screenshotted. So this lane is the only automated record of
/// what a press looks like, and the human pass over it is on device in E11.
///
/// The phase is pinned rather than settled: `pumpAndSettle` on a press either
/// runs forever or lands on the rest frame, and neither shows the thing being
/// goldened.
///
/// **Each image is the button, not the screen.** `find.byType(RepaintBoundary)`
/// matches the ones `MaterialApp` inserts above the stage as well, and `.first`
/// is the root — so a lane written that way goldens 390x844 of cream with a
/// button in the middle, and a press moving three pixels of ink is a fraction of
/// a percent of the frame. Keyed, the button IS the frame.
void main() {
  const motion = SunburstMotion.sunburstPop;
  const frame = ValueKey<String>('press-frame');

  setUpAll(() async {
    await loadAppFonts();
    installTolerantGoldenComparator();
  });

  Future<void> pumpButton(
    WidgetTester tester,
    LocaleCase localeCase, {
    bool disableAnimations = false,
  }) => tester.pumpPopComponent(
    RepaintBoundary(
      key: frame,
      child: PopButton(
        label: sampleStrings[localeCase.tag]!.button,
        onPressed: () {},
      ),
    ),
    localeCase: localeCase,
    disableAnimations: disableAnimations,
  );

  /// Pumps a button and returns a gesture already holding it down.
  ///
  /// [settle] pumps two full tap durations — the first carries the travel, the
  /// second lets easePop's overshoot come back down onto 1.0. One pump would
  /// golden a frame mid-spring, which is a golden that moves whenever the curve
  /// is retuned for any reason at all. Passing `false` goldens the
  /// **pointer-down frame**, which is where the reduce-motion branch is visible:
  /// with motion on it is still at rest, with motion off it is already there.
  Future<TestGesture> holdButton(
    WidgetTester tester,
    LocaleCase localeCase, {
    bool disableAnimations = false,
    bool settle = true,
  }) async {
    await pumpButton(tester, localeCase, disableAnimations: disableAnimations);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PopButton)),
    );
    await tester.pump();

    if (settle) {
      await tester.pump(motion.durTap);
      await tester.pump(motion.durTap);
    }

    return gesture;
  }

  testWidgets('at rest', (tester) async {
    // The frame the whole catalog is compared against. If this one moves, a
    // press change leaked into the resting chrome.
    await pumpButton(tester, LocaleCase.english);

    await expectLater(
      find.byKey(frame),
      matchesGoldenFile('press/pop_button_rest.png'),
    );
  });

  testWidgets('held', (tester) async {
    final gesture = await holdButton(tester, LocaleCase.english);
    addTearDown(gesture.up);

    await expectLater(
      find.byKey(frame),
      matchesGoldenFile('press/pop_button_pressed.png'),
    );
  });

  testWidgets('held under reduce motion, on the pointer-down frame', (
    tester,
  ) async {
    // Reduce motion collapses the DURATION to zero; it does not collapse the
    // press. Goldened on the pointer-down frame WITHOUT settling, because that
    // is the only frame where the branch is visible — settled, the two look
    // identical, which is correct and proves nothing. It catches the branch
    // being "simplified" into a no-op, which would leave a player with motion
    // off no acknowledgement at all that their finger landed.
    final gesture = await holdButton(
      tester,
      LocaleCase.english,
      disableAnimations: true,
      settle: false,
    );
    addTearDown(gesture.up);

    await expectLater(
      find.byKey(frame),
      matchesGoldenFile('press/pop_button_pressed_reduce_motion.png'),
    );
  });

  testWidgets('held in Persian', (tester) async {
    // The label mirrors and renders in Arabic script from the bundled face.
    // The shadow and the travel do not mirror, which is asserted numerically
    // below rather than left to a reader comparing two PNGs.
    final gesture = await holdButton(tester, LocaleCase.persian);
    addTearDown(gesture.up);

    await expectLater(
      find.byKey(frame),
      matchesGoldenFile('press/pop_button_pressed_fa.png'),
    );
  });

  testWidgets('held in German', (tester) async {
    // The longest label in the specimen set against the pressed chrome. The
    // button grows; nothing inside it shrinks to fit.
    final gesture = await holdButton(tester, LocaleCase.german);
    addTearDown(gesture.up);

    await expectLater(
      find.byKey(frame),
      matchesGoldenFile('press/pop_button_pressed_de.png'),
    );
  });

  group('what the images alone cannot say', () {
    testWidgets('reduce motion arrives on the frame the finger lands', (
      tester,
    ) async {
      // Two goldens that happened to be identical would both pass forever. The
      // difference has to be asserted, not eyeballed: under reduce motion the
      // surface arrives at the pressed geometry on the SAME FRAME instead of
      // travelling there.
      await pumpButton(tester, LocaleCase.english, disableAnimations: true);

      final rest = translationUnder(tester, find.byType(PopButton));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PopButton)),
      );
      addTearDown(gesture.up);
      await tester.pump();

      final onTouchDown = translationUnder(tester, find.byType(PopButton));
      await tester.pump(motion.durTap);
      await tester.pump(motion.durTap);

      expect(rest, Offset.zero);
      expect(onTouchDown, isNot(Offset.zero));
      expect(
        onTouchDown,
        translationUnder(tester, find.byType(PopButton)),
        reason:
            'reduce motion collapses the duration to zero, so the first frame '
            'IS the final one — which is also why pop_button_pressed.png and '
            'pop_button_pressed_reduce_motion.png are byte-identical, and why '
            'they are still two files: breaking the branch moves one of them',
      );
    });

    testWidgets('and the Persian frame travels exactly where English does', (
      tester,
    ) async {
      // So the pixel difference between those two goldens is TEXT, and nothing
      // else. Without this, a mirrored press would ship as "the RTL golden
      // looks different, as expected".
      final english = await holdButton(tester, LocaleCase.english);
      final englishTravel = translationUnder(tester, find.byType(PopButton));
      await english.up();

      final persian = await holdButton(tester, LocaleCase.persian);
      final persianTravel = translationUnder(tester, find.byType(PopButton));
      await persian.up();

      expect(persianTravel, englishTravel);
      expect(englishTravel.dx, greaterThan(0));
    });
  });
}
