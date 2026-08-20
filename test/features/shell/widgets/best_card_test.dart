import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/features/shell/widgets/best_card.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/components/tabular_text.dart';

import '../../../support/component_harness.dart';
import '../../../support/locale_cases.dart';

/// One game's personal best on the Stats screen.
void main() {
  const colours = SunburstColors.sunburstPop;
  const type = SunburstType.sunburstPop;

  Widget bestCard({
    GameAccent accent = GameAccent.stroop,
    String value = '1,480',
  }) => BestCard(
    label: 'BEST SCORE',
    gameName: 'Stroop Rush',
    value: value,
    accent: accent,
  );

  PopSurface outerOf(WidgetTester tester) => tester.widget<PopSurface>(
    find
        .descendant(
          of: find.byType(BestCard),
          matching: find.byType(PopSurface),
        )
        .first,
  );

  group('one card per accent', () {
    for (final accent in GameAccent.values) {
      testWidgets('${accent.name} fills with its own base colour', (
        tester,
      ) async {
        await tester.pumpPopComponent(bestCard(accent: accent));

        expect(
          outerOf(tester).fill,
          colours.accentFor(accent, GameColourRole.base),
        );
      });
    }
  });

  group('the value chip', () {
    testWidgets('is a nested cream surface, not a third elevation step', (
      tester,
    ) async {
      // app.html: the chip carries `2px 2px 0 var(--ink)` — the nested chip
      // step, the same one PopBadge uses, not e1 and not e2.
      await tester.pumpPopComponent(bestCard());

      final chip = tester
          .widgetList<PopSurface>(
            find.descendant(
              of: find.byType(BestCard),
              matching: find.byType(PopSurface),
            ),
          )
          .last;

      expect(chip.fill, colours.surface);
      expect(chip.elevation, PopElevation.chip);
      expect(chip.nested, isTrue);
    });

    testWidgets('prints at bestValue and is handed its digits', (
      tester,
    ) async {
      // The card formats nothing: ScoreFormat did that upstream, once, for
      // every screen. `points` 1480 is `1,480` in en, `1.480` in de and
      // `۱٬۴۸۰` in fa and ckb — and none of those decisions is made here.
      await tester.pumpPopComponent(bestCard(value: '۱٬۴۸۰'));

      final tabular = tester.widget<TabularText>(find.byType(TabularText));

      expect(tabular.value, '۱٬۴۸۰');
      expect(tabular.style.fontSize, type.bestValue.fontSize);
      expect(tabular.style.fontFeatures, type.bestValue.fontFeatures);
    });
  });

  group('the label is ink on every accent', () {
    testWidgets('never ink-2, which fails on coral', (tester) async {
      for (final accent in GameAccent.values) {
        await tester.pumpPopComponent(bestCard(accent: accent));

        expect(
          tester.widget<Text>(find.text('BEST SCORE')).style!.color,
          colours.textPrimary,
          reason: accent.name,
        );
      }
    });
  });

  group('the layout mirrors', () {
    testWidgets('the name leads and the chip trails, in both directions', (
      tester,
    ) async {
      final ordered = <String, bool>{};

      for (final localeCase in LocaleCase.bothDirections) {
        await tester.pumpPopComponent(bestCard(), localeCase: localeCase);

        final name = tester.getRect(find.text('Stroop Rush'));
        final chip = tester.getRect(find.byType(TabularText));

        ordered[localeCase.tag] = localeCase.direction == TextDirection.ltr
            ? name.left < chip.left
            : name.right > chip.right;
      }

      expect(ordered['en'], isTrue);
      expect(ordered['fa'], isTrue, reason: 'the best card did not mirror');
    });
  });

  group('semantics', () {
    testWidgets('reads label, game and value as one stop', (tester) async {
      await tester.pumpPopComponent(bestCard());

      final node = tester.getSemantics(find.byType(BestCard));

      expect(node.label, contains('BEST SCORE'));
      expect(node.label, contains('Stroop Rush'));
      expect(node.label, contains('1,480'));
    });
  });
}
