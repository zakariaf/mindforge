import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/shared/feedback/haptic_verb.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/shared/feedback/testing/fake_haptic_gateway.dart';
import 'package:mindforge/shared/motion/press_physics.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_motion.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

import '../../support/component_harness.dart';
import '../../support/locale_cases.dart';

/// The press, from the outside: what `PopSurface` hands the one controller, and
/// what a finger on it costs.
void main() {
  const colours = SunburstColors.sunburstPop;
  const shape = SunburstShape.sunburstPop;
  const motion = SunburstMotion.sunburstPop;

  Widget surface({
    PopElevation elevation = PopElevation.e2,
    PopBorderStyle borderStyle = PopBorderStyle.solid,
    Moment commitMoment = Moment.buttonCommit,
    VoidCallback? onTap,
    bool enabled = true,
  }) => PopSurface(
    fill: colours.accent,
    elevation: elevation,
    borderStyle: borderStyle,
    commitMoment: commitMoment,
    enabled: enabled,
    onTap: onTap ?? () {},
    child: const SizedBox(width: 120, height: 56),
  );

  PressGeometry geometryIn(WidgetTester tester) =>
      tester.widget<PressPhysics>(find.byType(PressPhysics)).geometry;

  Offset translationIn(WidgetTester tester) {
    // The OUTER Transform is the travel; the inner one is the scale.
    final transform = tester.widget<Transform>(
      find
          .descendant(
            of: find.byType(PressPhysics),
            matching: find.byType(Transform),
          )
          .first,
    );

    return Offset(
      transform.transform.getTranslation().x,
      transform.transform.getTranslation().y,
    );
  }

  group('the geometry is derived, never a literal', () {
    testWidgets('e2 takes the e2 shadow and the full press scale', (
      tester,
    ) async {
      await tester.pumpPopComponent(surface());

      expect(geometryIn(tester).restOffset, shape.e2);
      expect(geometryIn(tester).pressScale, shape.pressScale);
      expect(
        geometryIn(tester).travel,
        Offset(shape.e2.dx - 1, shape.e2.dy - 1),
      );
    });

    testWidgets('and e1 takes the smaller scale, because the larger one is '
        'imperceptible on a surface that low', (tester) async {
      await tester.pumpPopComponent(surface(elevation: PopElevation.e1));

      expect(geometryIn(tester).restOffset, shape.e1);
      expect(geometryIn(tester).pressScale, shape.pressScaleSmall);
    });

    testWidgets('a flat surface travels nowhere and casts nothing', (
      tester,
    ) async {
      await tester.pumpPopComponent(
        surface(elevation: PopElevation.flat, borderStyle: PopBorderStyle.none),
      );

      expect(geometryIn(tester).restOffset, isNull);
      expect(geometryIn(tester).travel, Offset.zero);
    });

    testWidgets('and the derived geometry is identical in every locale', (
      tester,
    ) async {
      // A German label makes the surface wider and a Persian one makes it
      // taller. Neither changes the travel, the scale or the pressed shadow.
      for (final localeCase in LocaleCase.all) {
        await tester.pumpPopComponent(surface(), localeCase: localeCase);

        expect(
          geometryIn(tester).restOffset,
          shape.e2,
          reason: localeCase.tag,
        );
        expect(
          geometryIn(tester).pressScale,
          shape.pressScale,
          reason: localeCase.tag,
        );
      }
    });
  });

  group('what a press costs', () {
    testWidgets('pointer down fires no haptic', (tester) async {
      // The acknowledgement belongs to the COMMIT. A buzz on touch-down fires
      // for every scroll that started on a button.
      final gateway = FakeHapticGateway();
      await tester.pumpPopComponent(surface(), hapticGateway: gateway);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PopSurface)),
      );
      addTearDown(gesture.up);
      await tester.pump();

      expect(gateway.played, isEmpty);
    });

    testWidgets('a completed tap fires exactly one, and runs onTap once', (
      tester,
    ) async {
      final gateway = FakeHapticGateway();
      var taps = 0;
      await tester.pumpPopComponent(
        surface(onTap: () => taps++),
        hapticGateway: gateway,
      );

      await tester.tap(find.byType(PopSurface));
      await tester.pump();

      expect(taps, 1);
      expect(gateway.played, <HapticVerb>[HapticVerb.lightImpact]);
    });

    testWidgets('a cancelled gesture fires nothing and returns to rest', (
      tester,
    ) async {
      // Pressed, then dragged off. The surface must come back up and the tap
      // must not count — a player who changed their mind did not answer.
      final gateway = FakeHapticGateway();
      var taps = 0;
      await tester.pumpPopComponent(
        surface(onTap: () => taps++),
        hapticGateway: gateway,
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PopSurface)),
      );
      await tester.pump(motion.durTap);
      await gesture.moveTo(const Offset(5, 5));
      await gesture.up();
      await tester.pump(motion.durTap);

      expect(taps, 0);
      expect(gateway.played, isEmpty);
      expect(translationIn(tester), Offset.zero);
    });

    testWidgets('and a disabled surface never drives anything', (tester) async {
      // It KEEPS a live callback: the point is that `enabled` gates the press,
      // not that a null tap has nothing to call. A surface disabled only by
      // dropping its callback would pass this while still buzzing.
      final gateway = FakeHapticGateway();
      await tester.pumpPopComponent(
        surface(enabled: false),
        hapticGateway: gateway,
      );

      await tester.tap(find.byType(PopSurface), warnIfMissed: false);
      await tester.pump(motion.durTap);

      expect(gateway.played, isEmpty);
      expect(
        find.byType(PressPhysics),
        findsNothing,
        reason: 'a surface with nothing to do builds no press machinery',
      );
    });

    testWidgets('the commit moment is a parameter, not a hardcoded button', (
      tester,
    ) async {
      // A Schulte tile is not a button, and its acknowledgement is a selection
      // click rather than the button pop.
      final gateway = FakeHapticGateway();
      await tester.pumpPopComponent(
        surface(commitMoment: Moment.tileFound),
        hapticGateway: gateway,
      );

      await tester.tap(find.byType(PopSurface));
      await tester.pump();

      expect(gateway.played, <HapticVerb>[HapticVerb.selectionClick]);
    });
  });

  group('the press does not mirror', () {
    testWidgets('a held surface travels the same way in all four locales', (
      tester,
    ) async {
      // THE ARGUMENT: the surface travels down its OWN HARD OFFSET SHADOW, and
      // that shadow is a light-source constant — one imaginary light for the
      // whole app. Mirroring the travel would detach the object from its shadow
      // and light the Persian build from the other side. A build whose buttons
      // pressed up and to the start would be a bug, not a localization.
      final travelled = <String, Offset>{};

      for (final localeCase in LocaleCase.all) {
        await tester.pumpPopComponent(surface(), localeCase: localeCase);

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(PopSurface)),
        );
        await tester.pump(motion.durTap);
        await tester.pump(motion.durTap);

        travelled[localeCase.tag] = translationIn(tester);

        await gesture.up();
        await tester.pump(motion.durTap);
      }

      final english = travelled['en']!;

      expect(english.dx, greaterThan(0));
      expect(english.dy, greaterThan(0));

      for (final entry in travelled.entries) {
        expect(
          entry.value,
          english,
          reason:
              '${entry.key} pressed to ${entry.value} while en pressed to '
              '$english; the travel follows the light source, not the reading '
              'direction',
        );
      }
    });

    testWidgets('and the pressed shadow lands at (1,1) in both directions', (
      tester,
    ) async {
      for (final localeCase in LocaleCase.bothDirections) {
        await tester.pumpPopComponent(surface(), localeCase: localeCase);

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(PopSurface)),
        );
        await tester.pump(motion.durTap);
        await tester.pump(motion.durTap);

        expect(
          decorationsIn(tester)
              .where((d) => d.boxShadow != null)
              .map((d) => d.boxShadow!.single.offset),
          everyElement(SunburstShape.pressedShadow),
          reason: localeCase.tag,
        );

        await gesture.up();
        await tester.pump(motion.durTap);
      }
    });
  });
}
