import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/shared/motion/press_physics.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

import '../../support/component_harness.dart';
import '../../support/locale_cases.dart';

void main() {
  const shape = SunburstShape.sunburstPop;
  const colours = SunburstColors.sunburstPop;
  final en = LocaleCase.all.first;
  final fa = LocaleCase.rightToLeft.first;

  group('PopElevation, as arithmetic', () {
    test('restOffset resolves each step, and flat draws nothing', () {
      expect(PopElevation.flat.restOffset(shape), isNull);
      expect(PopElevation.e1.restOffset(shape), const Offset(3, 3));
      expect(PopElevation.e2.restOffset(shape), const Offset(5, 5));
      expect(PopElevation.e3.restOffset(shape), const Offset(8, 8));
      expect(PopElevation.e4.restOffset(shape), const Offset(10, 10));
    });

    test(
      'pressScale is the small one at e1 and below, the large one above',
      () {
        expect(PopElevation.flat.pressScale(shape), shape.pressScaleSmall);
        expect(PopElevation.e1.pressScale(shape), shape.pressScaleSmall);
        expect(PopElevation.e2.pressScale(shape), shape.pressScale);
        expect(PopElevation.e4.pressScale(shape), shape.pressScale);
      },
    );

    test('travel is the resting offset minus one on both axes', () {
      for (final elevation in PopElevation.values) {
        final rest = elevation.restOffset(shape);
        final geometry = PressGeometry(
          restOffset: rest,
          pressScale: elevation.pressScale(shape),
        );

        expect(
          geometry.travel,
          rest == null ? Offset.zero : Offset(rest.dx - 1, rest.dy - 1),
          reason: '$elevation',
        );
      }
    });

    test('and the travel has no direction component to mirror', () {
      // The press moves the object TOWARD ITS SHADOW, and the shadow is a
      // light-source constant. Both axes are positive at every step, in every
      // locale, because PressGeometry holds no TextDirection at all.
      for (final elevation in PopElevation.values.where(
        (e) => e != PopElevation.flat,
      )) {
        final geometry = PressGeometry(
          restOffset: elevation.restOffset(shape),
          pressScale: 1,
        );

        expect(geometry.travel.dx, greaterThan(0), reason: '$elevation');
        expect(geometry.travel.dy, greaterThan(0), reason: '$elevation');
      }
    });
  });

  group('the painted surface', () {
    Future<BoxDecoration> decorationOf(
      WidgetTester tester, {
      required LocaleCase localeCase,
      PopElevation elevation = PopElevation.e2,
    }) async {
      await tester.pumpPopComponent(
        PopSurface(
          fill: colours.accent,
          elevation: elevation,
          onTap: () {},
          child: const SizedBox(width: 60, height: 40),
        ),
        localeCase: localeCase,
      );

      return tester
              .widget<DecoratedBox>(find.byType(DecoratedBox).first)
              .decoration
          as BoxDecoration;
    }

    testWidgets('every shadow it paints has blur and spread 0', (tester) async {
      for (final elevation in PopElevation.values) {
        final decoration = await decorationOf(
          tester,
          localeCase: en,
          elevation: elevation,
        );

        for (final shadow in decoration.boxShadow ?? const <BoxShadow>[]) {
          expect(shadow.blurRadius, 0, reason: '$elevation');
          expect(shadow.spreadRadius, 0, reason: '$elevation');
        }
      }
    });

    testWidgets('flat draws no shadow at all, not a shadow at zero', (
      tester,
    ) async {
      // A zero-offset hard shadow still paints a ring of ink around the
      // surface, so "flat" has to mean nothing is drawn.
      final decoration = await decorationOf(
        tester,
        localeCase: en,
        elevation: PopElevation.flat,
      );

      expect(decoration.boxShadow, anyOf(isNull, isEmpty));
    });

    testWidgets('the hard shadow is identical in fa and in en', (tester) async {
      // THE REVIEWER'S QUESTION, ANSWERED BY A TEST. The shadow is a light
      // source fixed at the top-start of the PAGE, not a reading-direction
      // property. Mirroring it would put the light behind the reader in half
      // the shipped locales, and make every RTL screenshot disagree with
      // system.html §07 for no reason anyone could name.
      for (final elevation in PopElevation.values.where(
        (e) => e != PopElevation.flat,
      )) {
        final ltr = await decorationOf(
          tester,
          localeCase: en,
          elevation: elevation,
        );
        final rtl = await decorationOf(
          tester,
          localeCase: fa,
          elevation: elevation,
        );

        final ltrOffset = ltr.boxShadow!.single.offset;
        final rtlOffset = rtl.boxShadow!.single.offset;

        expect(rtlOffset, ltrOffset, reason: '$elevation');
        expect(rtlOffset.dx, greaterThan(0), reason: '$elevation');
        expect(rtlOffset.dy, greaterThan(0), reason: '$elevation');
      }
    });

    testWidgets('directional padding DOES mirror', (tester) async {
      // The positive control for the negative controls above. If this fails,
      // mirroring is not happening at all and the shadow tests are green for
      // the wrong reason.
      Future<double> startInsetOf(LocaleCase localeCase) async {
        await tester.pumpPopComponent(
          PopSurface(
            fill: colours.accent,
            padding: const EdgeInsetsDirectional.only(start: 20, end: 8),
            onTap: () {},
            child: const SizedBox(
              key: ValueKey<String>('inner'),
              width: 40,
              height: 40,
            ),
          ),
          localeCase: localeCase,
        );

        final outer = tester.getRect(find.byType(DecoratedBox).first);
        final inner = tester.getRect(
          find.byKey(const ValueKey<String>('inner')),
        );

        return localeCase.direction == TextDirection.ltr
            ? inner.left - outer.left
            : outer.right - inner.right;
      }

      // 20 from the START edge in both, which is the LEFT in en and the RIGHT
      // in fa. Measured: the 3px ink edge paints INSIDE the decoration's box
      // and overlaps the padding rather than adding to it, so the inset is the
      // padding alone.
      expect(await startInsetOf(en), closeTo(20, 0.5));
      expect(await startInsetOf(fa), closeTo(20, 0.5));
    });
  });

  group('the press', () {
    testWidgets('does not move the hit area, in either direction', (
      tester,
    ) async {
      // THE REGRESSION TEST FOR THE WHOLE DESIGN. A Transform wrapped around
      // the gesture detector moves the target out from under the finger and
      // eats the tap.
      for (final localeCase in <LocaleCase>[en, fa]) {
        var taps = 0;

        await tester.pumpPopComponent(
          PopSurface(
            fill: colours.accent,
            onTap: () => taps++,
            child: const SizedBox(width: 80, height: 60),
          ),
          localeCase: localeCase,
        );

        final target = find.byType(PopSurface);
        final atRest = tester.getRect(target);

        final gesture = await tester.startGesture(
          atRest.centerLeft + const Offset(2, 0),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(
          tester.getRect(target),
          atRest,
          reason: 'the hit area moved during the press under ${localeCase.tag}',
        );

        await gesture.up();
        await tester.pump();

        expect(
          taps,
          1,
          reason:
              'a finger that pressed the edge must still be on the target '
              'when it lifts, under ${localeCase.tag}',
        );
      }
    });

    testWidgets('reduced motion drops the transform and keeps the shadow', (
      tester,
    ) async {
      // Reduce motion means STOP, not "gentler". The travel is dropped
      // entirely; the pressed shadow still applies, on the same frame.
      await tester.pumpPopComponent(
        PopSurface(
          fill: colours.accent,
          onTap: () {},
          child: const SizedBox(width: 80, height: 60),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PopSurface)),
      );
      await tester.pump();

      // Without a frame budget the controller jumped straight to the end, so
      // the shadow is already at the pressed offset.
      final decoration =
          tester
                  .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                  .decoration
              as BoxDecoration;

      expect(decoration.boxShadow, isNotNull);
      await gesture.up();
      await tester.pump();
    });

    testWidgets('fires its commit moment exactly once per tap', (tester) async {
      var taps = 0;

      await tester.pumpPopComponent(
        PopSurface(
          fill: colours.accent,
          // A non-default moment, so this asserts the wiring rather than the
          // default value.
          commitMoment: Moment.difficultySelect,
          onTap: () => taps++,
          child: const SizedBox(width: 80, height: 60),
        ),
      );

      await tester.tap(find.byType(PopSurface));
      await tester.pump();

      expect(taps, 1);
    });
  });

  group('the target floor', () {
    testWidgets('is 48 on both axes around a small child', (tester) async {
      await tester.pumpPopComponent(
        PopSurface(
          fill: colours.accent,
          onTap: () {},
          child: const SizedBox(width: 12, height: 12),
        ),
      );

      final size = tester.getSize(find.byType(PopSurface));

      expect(size.width, greaterThanOrEqualTo(kPopMinTarget));
      expect(size.height, greaterThanOrEqualTo(kPopMinTarget));
    });

    testWidgets('and minTarget 0 lets an ancestor own the gesture', (
      tester,
    ) async {
      await tester.pumpPopComponent(
        PopSurface(
          fill: colours.accent,
          minTarget: 0,
          onTap: () {},
          child: const SizedBox(width: 12, height: 12),
        ),
      );

      expect(
        tester.getSize(find.byType(PopSurface)).height,
        lessThan(kPopMinTarget),
      );
    });
  });

  group('disabled', () {
    testWidgets('resolves inside the palette, with no Opacity anywhere', (
      tester,
    ) async {
      // Never an Opacity over the enabled colour: a translucent surface picks
      // up whatever is behind it, so the same disabled button reads
      // differently on cream than on a coloured card, and its ink edge goes
      // grey-blue rather than grey.
      await tester.pumpPopComponent(
        PopSurface(
          fill: colours.accent,
          enabled: false,
          onTap: () {},
          child: const SizedBox(width: 60, height: 40),
        ),
      );

      final decoration =
          tester
                  .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                  .decoration
              as BoxDecoration;

      expect(decoration.color, colours.surfaceSunk);
      expect(decoration.border!.top.color, colours.borderDisabled);
      expect(decoration.boxShadow!.single.color, colours.borderDisabled);
      expect(find.byType(Opacity), findsNothing);
    });

    testWidgets('but a borderless surface keeps its fill', (tester) async {
      // The answer-key carve-out: a key whose fill IS the affordance stays its
      // own colour when it is not tappable, or the player cannot tell which
      // key they missed.
      await tester.pumpPopComponent(
        PopSurface(
          fill: colours.playBlue,
          borderStyle: PopBorderStyle.none,
          enabled: false,
          onTap: () {},
          child: const SizedBox(width: 60, height: 40),
        ),
      );

      final decoration =
          tester
                  .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                  .decoration
              as BoxDecoration;

      expect(decoration.color, colours.playBlue);
    });
  });

  group('semantics', () {
    testWidgets('declare button, enabled and selected', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpPopComponent(
        PopSurface(
          fill: colours.accent,
          selected: true,
          enabled: false,
          semanticLabel: 'Play',
          onTap: () {},
          child: const SizedBox(width: 60, height: 40),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Play')),
        matchesSemantics(
          label: 'Play',
          hasEnabledState: true,
          hasSelectedState: true,
          isSelected: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('and a null onTap is not a button at all', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpPopComponent(
        PopSurface(
          fill: colours.accent,
          semanticLabel: 'Card',
          child: const SizedBox(width: 60, height: 40),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Card')),
        matchesSemantics(label: 'Card'),
        reason:
            'no button flag, no enabled state and no tap action: a surface '
            'with nothing to do is not a control',
      );

      handle.dispose();
    });
  });
}
