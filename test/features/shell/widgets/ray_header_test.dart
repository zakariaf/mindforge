import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/features/shell/widgets/ray_header.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/halftone_dots.dart';

import '../../../support/component_harness.dart';
import '../../../support/locale_cases.dart';

void main() {
  const colours = SunburstColors.sunburstPop;
  const shape = SunburstShape.sunburstPop;
  const contentKey = Key('header-content');

  Widget header() => RayHeader(
    fill: colours.accent,
    rays: colours.headerRay,
    child: const SizedBox(key: contentKey, height: 40),
  );

  group('the construction', () {
    testWidgets('is a fill and a 3px ink BOTTOM border, and nothing else', (
      tester,
    ) async {
      await tester.pumpPopComponent(header());

      final decoration = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(RayHeader),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.border != null);

      final border = decoration.border! as Border;

      expect(border.bottom.width, shape.borderWidth);
      expect(border.bottom.color, colours.border);
      expect(border.top, BorderSide.none);
      expect(border.left, BorderSide.none);
      expect(border.right, BorderSide.none);
    });

    testWidgets('and the decoration announces nothing', (tester) async {
      // A screen reader walks the content and never meets a texture.
      await tester.pumpPopComponent(header());

      expect(
        find.descendant(
          of: find.byType(RayHeader),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
    });
  });

  group('the content inset mirrors, and the texture does not', () {
    testWidgets('the inset values are identical and the sides swap', (
      tester,
    ) async {
      // EdgeInsetsDirectional: the NUMBERS are the same in both directions and
      // the physical side they land on is not. That is the whole reason the
      // type is used, and it is only visible with a rect comparison.
      final gaps = <String, (double, double)>{};

      for (final localeCase in LocaleCase.bothDirections) {
        await tester.pumpPopComponent(header(), localeCase: localeCase);

        final outer = tester.getRect(find.byType(RayHeader));
        final inner = tester.getRect(find.byKey(contentKey));

        gaps[localeCase.tag] = (
          inner.left - outer.left,
          outer.right - inner.right,
        );
      }

      expect(gaps['en'], (20.0, 20.0));
      expect(gaps['fa'], (20.0, 20.0));
    });

    testWidgets('and the ray sweep is the same scene in both', (tester) async {
      // Rays and dots are a LIGHT SOURCE and a TEXTURE — one imaginary light
      // for the whole app, exactly like the hard offset shadow. Mirroring them
      // would light the Persian build from the other side for no reason a
      // reader could name.
      final scenes = <String, HalftoneScene>{};

      for (final localeCase in LocaleCase.bothDirections) {
        await tester.pumpPopComponent(header(), localeCase: localeCase);

        scenes[localeCase.tag] = tester
            .widgetList<CustomPaint>(
              find.descendant(
                of: find.byType(RayHeader),
                matching: find.byType(CustomPaint),
              ),
            )
            .map((paint) => paint.painter)
            .whereType<HalftonePainter>()
            .single
            .scene;
      }

      expect(scenes['fa'], scenes['en']);
    });
  });

  group('the safe area', () {
    testWidgets('the header starts below the top inset', (tester) async {
      // A header is the thing under the status bar. Its bottom is the nav
      // bar's problem, not its own.
      await tester.pumpPopComponent(header());

      final safeAreas = tester.widgetList<SafeArea>(
        find.descendant(
          of: find.byType(RayHeader),
          matching: find.byType(SafeArea),
        ),
      );

      expect(safeAreas.single.top, isTrue);
      expect(safeAreas.single.bottom, isFalse);
    });
  });
}
