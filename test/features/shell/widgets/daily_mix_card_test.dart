import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/features/shell/widgets/daily_mix_card.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

import '../../../support/component_harness.dart';
import '../../../support/locale_cases.dart';

/// The card that starts a run without choosing a game.
///
/// It appears twice in the design in two skins, and it is a real destination in
/// both — an inert chevron is the dead affordance E11 forbids.
void main() {
  const colours = SunburstColors.sunburstPop;

  var taps = 0;

  Widget card({DailyMixVariant variant = DailyMixVariant.grape}) =>
      DailyMixCard(
        title: 'Daily Mix',
        summary: '3 games, 4 minutes',
        variant: variant,
        onTap: () => taps++,
      );

  PopSurface surfaceOf(WidgetTester tester) => tester.widget<PopSurface>(
    find
        .descendant(
          of: find.byType(DailyMixCard),
          matching: find.byType(PopSurface),
        )
        .first,
  );

  setUp(() => taps = 0);

  group('the two variants', () {
    testWidgets('grape on Home, paper on game detail', (tester) async {
      // One widget, two fills. Two widgets would be two places to fix the day
      // the summary string changes.
      await tester.pumpPopComponent(card());
      expect(surfaceOf(tester).fill, colours.accentAlt);

      await tester.pumpPopComponent(card(variant: DailyMixVariant.paper));
      expect(surfaceOf(tester).fill, colours.surfaceRaised);
    });

    testWidgets('and the text inverts with the fill', (tester) async {
      // Grape is a dark fill: ink on it is 2.2:1. The paper variant is the
      // opposite. A single colour for both is the defect this catches.
      await tester.pumpPopComponent(card());
      expect(
        tester.widget<Text>(find.text('Daily Mix')).style!.color,
        colours.textInvert,
      );

      await tester.pumpPopComponent(card(variant: DailyMixVariant.paper));
      expect(
        tester.widget<Text>(find.text('Daily Mix')).style!.color,
        colours.textPrimary,
      );
    });
  });

  group('it is one tap target', () {
    testWidgets('the whole card taps, labelled by its title', (tester) async {
      await tester.pumpPopComponent(card());

      final node = tester.getSemantics(find.byType(DailyMixCard));

      expect(node.label, contains('Daily Mix'));
      expect(node.flagsCollection.isButton, isTrue);

      await tester.tap(find.byType(DailyMixCard));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('and it is at least 48 points tall', (tester) async {
      await tester.pumpPopComponent(card());

      expect(
        tester.getSize(find.byType(DailyMixCard)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('the go badge announces nothing of its own', (tester) async {
      // It is decoration on a card that is already a button; a second stop
      // there is a second thing to swipe past.
      await tester.pumpPopComponent(card());

      expect(
        find.descendant(
          of: find.byType(DailyMixCard),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
    });
  });

  group('the row mirrors and the play triangle does not', () {
    testWidgets('the badge holds a MEDIA PLAY mark, which is fixed', (
      tester,
    ) async {
      // The epic called this a chevron; app.html draws a play triangle, and
      // E05's glyph table already decided that one does not flip — a media
      // play mark has the same meaning on both sides of the world, and a
      // Persian player who has ever used a music app expects it pointing the
      // same way. The mirroring here is the ROW's, not the glyph's.
      expect(SunburstGlyph.go.mirrorsInRtl, isFalse);
    });

    testWidgets('and the badge sits at the END edge in both directions', (
      tester,
    ) async {
      final trailing = <String, bool>{};

      for (final localeCase in LocaleCase.bothDirections) {
        await tester.pumpPopComponent(card(), localeCase: localeCase);

        final outer = tester.getRect(find.byType(DailyMixCard));
        final badge = tester.getRect(find.byType(SunburstGlyphIcon).first);

        trailing[localeCase.tag] = localeCase.direction == TextDirection.ltr
            ? badge.center.dx > outer.center.dx
            : badge.center.dx < outer.center.dx;
      }

      expect(trailing['en'], isTrue);
      expect(trailing['fa'], isTrue, reason: 'the card did not mirror');
    });
  });
}
