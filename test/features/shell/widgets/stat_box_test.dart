import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/features/shell/widgets/stat_box.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/components/tabular_text.dart';

import '../../../support/component_harness.dart';
import '../../../support/locale_cases.dart';

/// A caption over a number, in a raised box.
///
/// It appears on game detail and on Stats, in two tones, and it formats
/// nothing: the value arrives already localized.
void main() {
  const colours = SunburstColors.sunburstPop;
  const shape = SunburstShape.sunburstPop;
  const type = SunburstType.sunburstPop;

  Widget box({
    StatBoxTone tone = StatBoxTone.paper,
    String value = '1,480',
  }) => StatBox(label: 'YOUR BEST', value: value, tone: tone);

  PopSurface surfaceOf(WidgetTester tester) => tester.widget<PopSurface>(
    find
        .descendant(of: find.byType(StatBox), matching: find.byType(PopSurface))
        .first,
  );

  group('the construction', () {
    testWidgets('is radiusLg on e1', (tester) async {
      // e1, not e2. app.html: `.statbox{box-shadow:var(--sh-1)}` — a stat box
      // is the quietest raised thing on its screen.
      await tester.pumpPopComponent(box());

      final surface = surfaceOf(tester);

      expect(surface.elevation, PopElevation.e1);
      expect(surface.radius, BorderRadiusDirectional.all(shape.radiusLg));
    });

    testWidgets('paper is the raised surface and accent is sunshine', (
      tester,
    ) async {
      await tester.pumpPopComponent(box());
      expect(surfaceOf(tester).fill, colours.surfaceRaised);

      await tester.pumpPopComponent(box(tone: StatBoxTone.accent));
      expect(surfaceOf(tester).fill, colours.accent);
    });
  });

  group('the label colour is a function of the fill', () {
    testWidgets('ink-2 on paper, ink on the saturated fill', (tester) async {
      // app.html says it on the rule: "ink-2 is for paper and cream only — on
      // a saturated fill the label goes ink". textSecondary on sunshine is
      // 3.1:1, and this is the caption a transcription reuses without looking.
      await tester.pumpPopComponent(box());
      expect(
        tester.widget<Text>(find.text('YOUR BEST')).style!.color,
        colours.textSecondary,
      );

      await tester.pumpPopComponent(box(tone: StatBoxTone.accent));
      expect(
        tester.widget<Text>(find.text('YOUR BEST')).style!.color,
        colours.textPrimary,
      );
    });
  });

  group('the value', () {
    testWidgets('prints at statValue with tabular figures', (tester) async {
      await tester.pumpPopComponent(box());

      // TabularText, not Text: Fredoka ignores the tnum feature the step
      // declares, and a column of numbers has to line up anyway.
      final style = tester.widget<TabularText>(find.byType(TabularText)).style;

      expect(style.fontSize, type.statValue.fontSize);
      expect(style.fontFeatures, type.statValue.fontFeatures);
    });

    testWidgets('is rendered exactly as handed over, in every locale', (
      tester,
    ) async {
      // THE WIDGET FORMATS NOTHING. Handed Eastern Arabic digits it renders
      // them; it contains no NumberFormat, no toString on a num and no digit
      // literal. That is what keeps the numeral system one decision instead of
      // five.
      for (final localeCase in LocaleCase.all) {
        await tester.pumpPopComponent(
          box(value: '۱٬۴۸۰'),
          localeCase: localeCase,
        );

        expect(
          tester.widget<TabularText>(find.byType(TabularText)).value,
          '۱٬۴۸۰',
          reason: localeCase.tag,
        );
      }
    });
  });

  group('the geometry', () {
    testWidgets('starts at the start edge in both directions', (tester) async {
      final leads = <String, bool>{};

      for (final localeCase in LocaleCase.bothDirections) {
        await tester.pumpPopComponent(box(), localeCase: localeCase);

        final outer = tester.getRect(find.byType(StatBox));
        final label = tester.getRect(find.text('YOUR BEST'));

        leads[localeCase.tag] = localeCase.direction == TextDirection.ltr
            ? (label.left - outer.left) < (outer.right - label.right)
            : (outer.right - label.right) < (label.left - outer.left);
      }

      expect(leads['en'], isTrue);
      expect(leads['fa'], isTrue);
    });
  });

  group('semantics', () {
    testWidgets('reads as one thing, and is not a control', (tester) async {
      // "Your best, 1,480" as one stop. Two stops for a caption and a number
      // is how a stats screen becomes twelve unrelated announcements.
      await tester.pumpPopComponent(box());

      final node = tester.getSemantics(find.byType(StatBox));

      expect(node.label, contains('YOUR BEST'));
      expect(node.label, contains('1,480'));
      expect(node.flagsCollection.isButton, isFalse);
    });
  });
}
