import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/features/shell/widgets/score_slab.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/components/tabular_text.dart';

import '../../../support/component_harness.dart';
import '../../../support/locale_cases.dart';

/// The final score, set in white with a sunshine drop shadow.
void main() {
  const colours = SunburstColors.sunburstPop;
  const shape = SunburstShape.sunburstPop;
  const type = SunburstType.sunburstPop;

  Widget slab({String value = '1,240'}) =>
      ScoreSlab(label: 'FINAL SCORE', value: value);

  TextStyle valueStyle(WidgetTester tester) =>
      tester.widget<TabularText>(find.byType(TabularText)).style;

  group('the construction', () {
    testWidgets('is the raised surface at radiusXl on e3', (tester) async {
      await tester.pumpPopComponent(slab());

      final surface = tester.widget<PopSurface>(
        find
            .descendant(
              of: find.byType(ScoreSlab),
              matching: find.byType(PopSurface),
            )
            .first,
      );

      expect(surface.fill, colours.surfaceRaised);
      expect(surface.elevation, PopElevation.e3);
      expect(surface.radius, BorderRadiusDirectional.all(shape.radiusXl));
    });
  });

  group('the sunshine text shadow', () {
    testWidgets('is 5px, hard, and behind the numerals', (tester) async {
      // app.html: `text-shadow:5px 5px 0 var(--sunshine)`. Zero blur is the
      // whole look; a soft one reads as a print misregistration.
      await tester.pumpPopComponent(slab());

      final shadow = valueStyle(tester).shadows!.single;

      expect(shadow.color, colours.accent);
      expect(shadow.blurRadius, 0);
      expect(shadow.offset, const Offset(5, 5));
    });

    testWidgets('and it does NOT mirror, in either RTL locale', (tester) async {
      // The same light-source rule as the box shadow. A score whose shadow
      // fell to the start edge in Persian would be lit from the other side.
      for (final localeCase in LocaleCase.rightToLeft) {
        await tester.pumpPopComponent(slab(), localeCase: localeCase);

        expect(
          valueStyle(tester).shadows!.single.offset,
          const Offset(5, 5),
          reason: localeCase.tag,
        );
      }
    });
  });

  group('the value', () {
    testWidgets('prints at scoreHero with tabular figures', (tester) async {
      await tester.pumpPopComponent(slab());

      final style = valueStyle(tester);

      expect(style.fontSize, type.scoreHero.fontSize);
      expect(style.fontFeatures, type.scoreHero.fontFeatures);
    });

    testWidgets('does not shrink at text scale 2.0', (tester) async {
      // No FittedBox. A score that scales DOWN when the player asked for
      // larger text has inverted the setting they chose.
      await tester.pumpPopComponent(slab());
      final base = tester.getSize(find.byType(TabularText));

      await tester.pumpPopComponent(
        slab(),
        localeCase: LocaleCase.german,
        textScaler: const TextScaler.linear(2),
      );

      expect(
        tester.getSize(find.byType(TabularText)).height,
        greaterThan(base.height),
      );
      expect(
        find.descendant(
          of: find.byType(ScoreSlab),
          matching: find.byType(FittedBox),
        ),
        findsNothing,
      );
    });
  });

  group('semantics', () {
    testWidgets('reads as one stop', (tester) async {
      await tester.pumpPopComponent(slab());

      final node = tester.getSemantics(find.byType(ScoreSlab));

      expect(node.label, contains('FINAL SCORE'));
      expect(node.label, contains('1,240'));
    });
  });
}
