import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/features/shell/widgets/result_stat_cell.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/components/tabular_text.dart';

import '../../../support/component_harness.dart';
import '../../../support/locale_cases.dart';

/// One of the three cells under the results score.
///
/// A separate widget from `StatBox` and not a density flag on it: the two
/// differ in radius, padding, alignment, both type steps and their tone sets —
/// which is everything except "a caption over a value in a raised box".
void main() {
  const colours = SunburstColors.sunburstPop;
  const shape = SunburstShape.sunburstPop;
  const type = SunburstType.sunburstPop;

  Widget cell({ResultStatTone tone = ResultStatTone.paper}) =>
      ResultStatCell(label: 'ACCURACY', value: '92%', tone: tone);

  PopSurface surfaceOf(WidgetTester tester) => tester.widget<PopSurface>(
    find
        .descendant(
          of: find.byType(ResultStatCell),
          matching: find.byType(PopSurface),
        )
        .first,
  );

  group('the construction', () {
    testWidgets('is radiusMd on e1 — one step below the slab above it', (
      tester,
    ) async {
      await tester.pumpPopComponent(cell());

      final surface = surfaceOf(tester);

      expect(surface.elevation, PopElevation.e1);
      expect(surface.radius, BorderRadiusDirectional.all(shape.radiusMd));
    });

    testWidgets('the three tones are turquoise, paper and coral', (
      tester,
    ) async {
      // app.html: `.tri:nth-child(1){background:var(--turquoise)}` and
      // `.tri:nth-child(3){background:var(--coral)}`. The middle one is paper.
      final expected = <ResultStatTone, Color>{
        ResultStatTone.cool: colours.accentCool,
        ResultStatTone.paper: colours.surfaceRaised,
        ResultStatTone.warm: colours.accentWarm,
      };

      for (final entry in expected.entries) {
        await tester.pumpPopComponent(cell(tone: entry.key));

        expect(surfaceOf(tester).fill, entry.value, reason: entry.key.name);
      }
    });
  });

  group('the label colour follows the fill', () {
    testWidgets('ink on the saturated two, ink-2 on paper', (tester) async {
      // app.html says it on the rule: "on a saturated fill the label is ink —
      // ink-2 drops to 2.8:1 on coral".
      await tester.pumpPopComponent(cell());
      expect(
        tester.widget<Text>(find.text('ACCURACY')).style!.color,
        colours.textSecondary,
      );

      for (final tone in <ResultStatTone>[
        ResultStatTone.cool,
        ResultStatTone.warm,
      ]) {
        await tester.pumpPopComponent(cell(tone: tone));

        expect(
          tester.widget<Text>(find.text('ACCURACY')).style!.color,
          colours.textPrimary,
          reason: tone.name,
        );
      }
    });
  });

  group('the type roles', () {
    testWidgets('use the trio steps, not the stat-box ones', (tester) async {
      // 10/.09em and 23, not 10/.14em and 26. The trio is a third the width of
      // a stat box and the same numbers would not fit.
      await tester.pumpPopComponent(cell());

      expect(
        tester.widget<Text>(find.text('ACCURACY')).style!.letterSpacing,
        type.resultStatLabel.letterSpacing,
      );
      expect(
        tester.widget<TabularText>(find.byType(TabularText)).style.fontSize,
        type.resultStatValue.fontSize,
      );
    });
  });

  group('the content is centred, in every locale', () {
    testWidgets('so the trio reads as one row rather than three', (
      tester,
    ) async {
      for (final localeCase in LocaleCase.all) {
        await tester.pumpPopComponent(cell(), localeCase: localeCase);

        final outer = tester.getRect(find.byType(ResultStatCell));
        final value = tester.getRect(find.byType(TabularText));

        expect(
          value.center.dx,
          closeTo(outer.center.dx, 0.5),
          reason: localeCase.tag,
        );
      }
    });
  });
}
