import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/features/shell/widgets/game_hero_panel.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/halftone_dots.dart';

import '../../../support/component_harness.dart';
import '../../../support/locale_cases.dart';

/// The panel a game's identity lives in on its detail screen.
void main() {
  const colours = SunburstColors.sunburstPop;
  const shape = SunburstShape.sunburstPop;
  const type = SunburstType.sunburstPop;
  const artworkKey = Key('hero-artwork');

  // A pane-width box. The harness centres a component at its intrinsic width,
  // and a panel exactly as wide as its own text has no start edge to test.
  // The strings are short on purpose: a widget test renders in the test font,
  // where every glyph is an em square, so real copy would overflow 350 and pin
  // every rect to the same edge.
  Widget hero({GameAccent accent = GameAccent.stroop}) => SizedBox(
    width: 350,
    child: GameHeroPanel(
      accent: accent,
      kicker: 'TAGS',
      title: 'Alpha',
      tagline: 'Do the thing',
      artwork: const SizedBox(key: artworkKey, height: 38, width: 170),
    ),
  );

  PopSurface surfaceOf(WidgetTester tester) => tester.widget<PopSurface>(
    find
        .descendant(
          of: find.byType(GameHeroPanel),
          matching: find.byType(PopSurface),
        )
        .first,
  );

  group('the construction', () {
    testWidgets('is the accent fill at radiusXl on e3', (tester) async {
      // e3, not e2. A uniform elevation across hero, cards and stat boxes is
      // the common transcription defect, and it flattens the whole screen.
      await tester.pumpPopComponent(hero());

      final surface = surfaceOf(tester);

      expect(
        surface.fill,
        colours.accentFor(GameAccent.stroop, GameColourRole.base),
      );
      expect(surface.elevation, PopElevation.e3);
      expect(
        surface.radius,
        BorderRadiusDirectional.all(shape.radiusXl),
      );
    });

    testWidgets('and it is not a control', (tester) async {
      // The hero is the screen's subject, not its Play button. A tappable one
      // would put a second way to start a run beside the real one.
      await tester.pumpPopComponent(hero());

      expect(surfaceOf(tester).onTap, isNull);
    });

    testWidgets('takes the accent, so a second game is a second fill only', (
      tester,
    ) async {
      await tester.pumpPopComponent(hero(accent: GameAccent.schulte));

      expect(
        surfaceOf(tester).fill,
        colours.accentFor(GameAccent.schulte, GameColourRole.base),
      );
    });
  });

  group('the title is the heading', () {
    testWidgets('and it is the only thing in the panel that claims to be', (
      tester,
    ) async {
      // A detail screen's h1 is the game's name. A heading list is only worth
      // having if exactly one thing is in it.
      await tester.pumpPopComponent(hero());

      final headers = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((node) => node.properties.header ?? false);

      expect(headers, hasLength(1));
    });
  });

  group('the dot layer', () {
    testWidgets('runs at the panel opacity, not the header one', (
      tester,
    ) async {
      // .08, NOT .16. app.html says so in a comment on the rule itself: ink
      // text on the coral-plus-dots composite needs 4.5:1, and the header's
      // stronger lattice takes it below the floor.
      await tester.pumpPopComponent(hero());

      final painter = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(GameHeroPanel),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((paint) => paint.painter)
          .whereType<HalftonePainter>()
          .single;

      expect(painter.scene.ink, colours.heroDots);
      expect(painter.scene.ray, isNull, reason: 'the hero has no ray sweep');
    });
  });

  group('the type roles', () {
    testWidgets('kicker, title and tagline each print in their own step', (
      tester,
    ) async {
      await tester.pumpPopComponent(hero());

      TextStyle styleOf(String data) =>
          tester.widget<Text>(find.text(data)).style!;

      expect(styleOf('TAGS').fontSize, type.sectionLabel.fontSize);
      expect(styleOf('Alpha').fontSize, type.heroTitle.fontSize);
      expect(
        styleOf('Do the thing').fontSize,
        type.body.fontSize,
      );
    });

    testWidgets('and every one of them is ink, never ink-2', (tester) async {
      // On a saturated fill textSecondary drops below 4.5:1. The kicker is the
      // one most likely to be written as a muted caption out of habit.
      await tester.pumpPopComponent(hero());

      for (final data in <String>[
        'TAGS',
        'Alpha',
        'Do the thing',
      ]) {
        expect(
          tester.widget<Text>(find.text(data)).style!.color,
          colours.textPrimary,
          reason: data,
        );
      }
    });
  });

  group('the geometry does not move with the locale', () {
    testWidgets('the artwork keeps its size in en and fa', (tester) async {
      // Swatches are geometry. A locale that resized them would be resizing
      // the game's own palette preview.
      final sizes = <String, Size>{};

      for (final localeCase in LocaleCase.bothDirections) {
        await tester.pumpPopComponent(hero(), localeCase: localeCase);

        sizes[localeCase.tag] = tester.getSize(find.byKey(artworkKey));
      }

      expect(sizes['fa'], sizes['en']);
    });

    testWidgets('and the content starts at the start edge in both', (
      tester,
    ) async {
      final leads = <String, bool>{};

      for (final localeCase in LocaleCase.bothDirections) {
        await tester.pumpPopComponent(hero(), localeCase: localeCase);

        final panel = tester.getRect(find.byType(GameHeroPanel));
        final title = tester.getRect(find.text('Alpha'));

        leads[localeCase.tag] = localeCase.direction == TextDirection.ltr
            ? (title.left - panel.left) < (panel.right - title.right)
            : (panel.right - title.right) < (title.left - panel.left);
      }

      expect(leads['en'], isTrue);
      expect(leads['fa'], isTrue, reason: 'the hero content did not mirror');
    });
  });
}
