import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/shared/feedback/moment_catalog.dart';
import 'package:mindforge/shared/motion/directional_slide.dart';
import 'package:mindforge/shared/motion/motion_axis.dart';
import 'package:mindforge/theme/sunburst_motion.dart';

import '../../support/component_harness.dart';
import '../../support/locale_cases.dart';

/// The one place a start-edge offset becomes a physical one.
void main() {
  const motion = SunburstMotion.sunburstPop;
  const child = Key('sliding');

  /// A controller a test drives by hand, so no frame timing is involved.
  late AnimationController controller;

  setUp(() {
    controller = AnimationController(
      vsync: const TestVSync(),
      duration: motion.durMove,
    );
  });

  tearDown(() => controller.dispose());

  /// A slide for [moment], whose AXIS comes from the catalog row.
  ///
  /// There is no axis parameter to pass. It used to be one, beside the moment,
  /// which meant a caller could hand a route transition a vertical axis and
  /// silently stop it mirroring under Persian — a combination the catalog
  /// already answers and no widget should let a caller contradict.
  Widget slide({
    required Offset beginStart,
    Moment moment = Moment.routeTransition,
  }) => DirectionalSlide(
    t: controller,
    beginStart: beginStart,
    moment: moment,
    child: const SizedBox(key: child, width: 100, height: 100),
  );

  Rect rectOf(WidgetTester tester) => tester.getRect(find.byKey(child));

  /// How far the child is displaced at `t == 0`, in physical pixels.
  ///
  /// Measured against where it LANDS rather than against the screen edge: the
  /// child is 100pt inside a 390pt stage, so a one-width offset never puts it
  /// off-screen and "is it off the edge" would be a test of the stage size.
  /// The displacement is the thing the widget decides.
  Future<double> displacementOf(
    WidgetTester tester,
    LocaleCase localeCase, {
    required Offset beginStart,
    Moment moment = Moment.routeTransition,
  }) async {
    await tester.pumpPopComponent(
      slide(beginStart: beginStart, moment: moment),
      localeCase: localeCase,
    );

    controller.value = 1;
    await tester.pump();
    final landed = rectOf(tester).left;

    controller.value = 0;
    await tester.pump();

    return rectOf(tester).left - landed;
  }

  group('an inline slide mirrors', () {
    testWidgets('it enters from the physical end edge under LTR', (
      tester,
    ) async {
      expect(
        await displacementOf(
          tester,
          LocaleCase.english,
          beginStart: const Offset(1, 0),
        ),
        100,
        reason: 'one child width toward the physical RIGHT in English',
      );
    });

    testWidgets('and from the other edge under both RTL locales', (
      tester,
    ) async {
      for (final localeCase in LocaleCase.rightToLeft) {
        expect(
          await displacementOf(
            tester,
            localeCase,
            beginStart: const Offset(1, 0),
          ),
          -100,
          reason:
              '${localeCase.tag}: the SAME start-edge offset of +1 is one child '
              'width toward the physical LEFT when the page reads right to '
              'left. Same declaration, opposite physics, no sign written down',
        );
      }
    });

    testWidgets('and it lands in the same place in both directions', (
      tester,
    ) async {
      // Mirroring is about where it comes FROM, never where it ends.
      final landed = <String, Rect>{};

      for (final localeCase in LocaleCase.bothDirections) {
        await tester.pumpPopComponent(
          slide(beginStart: const Offset(1, 0)),
          localeCase: localeCase,
        );
        controller.value = 1;
        await tester.pump();

        landed[localeCase.tag] = rectOf(tester);
      }

      expect(landed['fa'], landed['en']);
    });
  });

  group('a vertical slide does not', () {
    testWidgets('it is pixel-identical in all four locales', (tester) async {
      // The pause sheet rises from the bottom edge in every language. Up is up.
      final atRest = <String, Rect>{};
      final halfway = <String, Rect>{};

      for (final localeCase in LocaleCase.all) {
        await tester.pumpPopComponent(
          slide(
            beginStart: const Offset(0, 1),
            moment: Moment.sheetTransition,
          ),
          localeCase: localeCase,
        );

        controller.value = 0;
        await tester.pump();
        atRest[localeCase.tag] = rectOf(tester);

        controller.value = 0.5;
        await tester.pump();
        halfway[localeCase.tag] = rectOf(tester);
      }

      for (final tag in atRest.keys) {
        expect(atRest[tag], atRest['en'], reason: tag);
        expect(halfway[tag], halfway['en'], reason: tag);
      }
    });

    testWidgets('even when it carries a sideways component', (tester) async {
      // THE TEST THAT MAKES THE BRANCH OBSERVABLE. A pure-vertical offset has
      // dx == 0, so applying reading order to it is a no-op and a widget that
      // mirrored EVERYTHING would pass the test above. Given a drift, a
      // vertical slide must still put it in canvas coordinates: the axis says
      // this motion does not mirror, and that has to be true of the whole
      // offset rather than of the component that happens to be zero.
      final drifted = <String, double>{};

      for (final localeCase in LocaleCase.all) {
        drifted[localeCase.tag] = await displacementOf(
          tester,
          localeCase,
          beginStart: const Offset(0.3, 1),
          moment: Moment.sheetTransition,
        );
      }

      for (final entry in drifted.entries) {
        expect(
          entry.value,
          30,
          reason:
              '${entry.key} drifted to ${entry.value}; a vertical motion is '
              'the same motion in every language, including the part of it '
              'that happens to be horizontal',
        );
      }
    });
  });

  group('what it refuses to be', () {
    /// Pumps a slide and returns whatever it threw.
    ///
    /// The asserts moved from the constructor to `build()` when the axis
    /// stopped being a parameter: there is nothing to check until the moment's
    /// row can be read, and the row is the same on every build.
    Future<Object?> pumpAndCatch(
      WidgetTester tester, {
      required Offset beginStart,
      required Moment moment,
    }) async {
      await tester.pumpPopComponent(
        slide(beginStart: beginStart, moment: moment),
      );

      return tester.takeException();
    }

    testWidgets('a fixed-axis moment: the press does not belong here', (
      tester,
    ) async {
      expect(
        await pumpAndCatch(
          tester,
          beginStart: const Offset(1, 1),
          moment: Moment.buttonPress,
        ),
        isAssertionError,
      );
    });

    testWidgets('a none-axis moment: there is nothing to slide', (
      tester,
    ) async {
      expect(
        await pumpAndCatch(
          tester,
          beginStart: const Offset(0, 1),
          moment: Moment.runStart,
        ),
        isAssertionError,
      );
    });

    testWidgets('and an inline moment handed an offset with no dx', (
      tester,
    ) async {
      // The mis-declaration is now in the OFFSET rather than in the axis: the
      // moment says inline and the offset does not move along that axis.
      expect(
        await pumpAndCatch(
          tester,
          beginStart: const Offset(0, 1),
          moment: Moment.routeTransition,
        ),
        isAssertionError,
      );
    });

    testWidgets('and the axis cannot be contradicted at all', (tester) async {
      // There is no axis parameter. This is the assertion that the whole
      // change exists for: the only way to say which axis a slide travels on
      // is to name a moment, and the catalog answers for it.
      const slide = DirectionalSlide(
        t: kAlwaysCompleteAnimation,
        beginStart: Offset(1, 0),
        moment: Moment.sheetTransition,
        child: SizedBox.shrink(),
      );

      expect(slide.axis, specFor(Moment.sheetTransition).axis);
      expect(slide.axis, MotionAxis.vertical);
    });
  });

  group('a live locale switch', () {
    testWidgets('re-mirrors with no restart and no exception', (tester) async {
      // The test that exercises E04's ckb delegate under a motion widget. If
      // the delegate is missing this is where it throws, loudly, in CI —
      // GlobalMaterialLocalizations ships no ckb, and a switch to Sorani
      // without the vendored trio both throws and silently renders LTR.
      final walked = <double>[];

      for (final tag in <String>['en', 'fa', 'ckb', 'en']) {
        walked.add(
          await displacementOf(
            tester,
            LocaleCase.all.firstWhere((c) => c.tag == tag),
            beginStart: const Offset(1, 0),
          ),
        );
      }

      expect(tester.takeException(), isNull);
      expect(
        walked,
        <double>[100, -100, -100, 100],
        reason:
            'en, fa, ckb, en - the entry edge follows every switch, including '
            'the switch BACK, which is where a direction cached at first build '
            'would stick',
      );
    });
  });

  group('the timing comes from the catalog', () {
    testWidgets('a route transition runs at durMove on easeInOut', (
      tester,
    ) async {
      final built = slide(beginStart: const Offset(1, 0)) as DirectionalSlide;

      await tester.pumpPopComponent(built);

      final context = tester.element(find.byType(DirectionalSlide));

      expect(built.durationIn(context), motion.durMove);
      expect(built.curveIn(context), motion.easeInOut);
    });

    testWidgets('and collapses to zero under reduce motion', (tester) async {
      final built = slide(beginStart: const Offset(1, 0)) as DirectionalSlide;

      await tester.pumpPopComponent(built, disableAnimations: true);

      expect(
        built.durationIn(tester.element(find.byType(DirectionalSlide))),
        Duration.zero,
        reason: 'reduce motion collapses to STILLNESS, never to faster',
      );
    });
  });

  group('it is the only slide in the app', () {
    test('and it negates no dx by hand', () {
      // SlideTransition's own textDirection applies the x offset in reading
      // order when set and in canvas coordinates when null. Negating a dx by
      // hand is the thing that seam exists to make unnecessary.
      final code = File('lib/shared/motion/directional_slide.dart')
          .readAsStringSync()
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');

      expect(code, isNot(contains('-beginStart')));
      expect(code, isNot(contains('dx * -1')));
      expect(code, isNot(contains('-offset.dx')));
    });

    test('nothing else in lib builds a SlideTransition', () {
      final offenders = <String>[];

      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path == 'lib/shared/motion/directional_slide.dart') continue;

        final code = entity
            .readAsStringSync()
            .split('\n')
            .where((line) => !line.trimLeft().startsWith('//'))
            .join('\n');

        if (code.contains('SlideTransition(')) offenders.add(entity.path);
      }

      expect(offenders, isEmpty);
    });
  });
}
