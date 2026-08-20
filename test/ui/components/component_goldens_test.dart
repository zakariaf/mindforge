@Tags(['golden'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/hud_tone.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/difficulty_segmented.dart';
import 'package:mindforge/ui/components/game_card.dart';
import 'package:mindforge/ui/components/hud_pill.dart';
import 'package:mindforge/ui/components/pop_badge.dart';
import 'package:mindforge/ui/components/pop_bottom_nav.dart';
import 'package:mindforge/ui/components/pop_button.dart';
import 'package:mindforge/ui/components/pop_card.dart';
import 'package:mindforge/ui/components/pop_chip.dart';
import 'package:mindforge/ui/components/pop_grid_tile.dart';
import 'package:mindforge/ui/components/pop_icon_button.dart';
import 'package:mindforge/ui/components/pop_progress_bar.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/components/pop_toggle.dart';
import 'package:mindforge/ui/components/timer_ring.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

import '../../support/component_harness.dart';
import '../../support/golden_tolerance.dart';
import '../../support/load_app_fonts.dart';
import '../../support/locale_cases.dart';
import '../../support/sample_strings.dart';

/// The catalog's golden lane: construction and mirroring, per component.
///
/// **One file, not one per component.** Every golden here loads the real
/// bundled faces and installs the same tolerant comparator, and doing that
/// setup fourteen times is fourteen chances for one lane to quietly differ from
/// the others.
///
/// The lanes, stated once:
///
/// * the per-component **state matrix** in `en` and `fa` — construction in both
///   directions;
/// * a **greyscale** matrix in `en` only — state collision is hue-dependent,
///   not locale-dependent, so running it four times proves nothing new.
///
/// What a golden proves: that the rendering CHANGED. It does not prove the
/// rendering is right. That comparison is a human putting the image beside
/// `design/sunburst-pop/system.html`, which is why every visual task carries a
/// screenshot step and the PR body has to name what was compared.
void main() {
  const colours = SunburstColors.sunburstPop;
  const shape = SunburstShape.sunburstPop;

  setUpAll(() async {
    await loadAppFonts();
    installTolerantGoldenComparator();
  });

  Widget surfaceAt(PopComponentState state, PopElevation elevation) =>
      PopSurface(
        fill: state == PopComponentState.selected
            ? colours.accent
            : colours.surfaceRaised,
        elevation: elevation,
        enabled: state != PopComponentState.disabled,
        selected: state == PopComponentState.selected,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        onTap: () {},
        child: Text('$elevation'.split('.').last),
      );

  group('PopSurface', () {
    for (final localeCase in <LocaleCase>[
      LocaleCase.all.first,
      LocaleCase.rightToLeft.first,
    ]) {
      testWidgets('the state matrix in ${localeCase.tag}', (tester) async {
        await tester.pumpPopComponent(
          RepaintBoundary(
            child: popStateMatrix(
              states: const <PopComponentState>[
                PopComponentState.rest,
                PopComponentState.disabled,
                PopComponentState.selected,
              ],
              // Wrap, not Row: five elevation steps side by side overflow a
              // 390pt canvas, and a matrix sheet that clips is a matrix sheet
              // nobody can read the last column of.
              buildState: (state) => Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  for (final elevation in PopElevation.values)
                    surfaceAt(state, elevation),
                ],
              ),
            ),
          ),
          localeCase: localeCase,
        );

        await expectLater(
          find.byType(RepaintBoundary).first,
          matchesGoldenFile(popGolden('pop_surface_states', localeCase)),
        );
      });
    }

    testWidgets('the greyscale matrix', (tester) async {
      // If two rows are indistinguishable here they are indistinguishable to a
      // player with a colour vision deficiency, whatever the palette says.
      await tester.pumpPopComponent(
        RepaintBoundary(
          child: Greyscale(
            child: popStateMatrix(
              states: const <PopComponentState>[
                PopComponentState.rest,
                PopComponentState.disabled,
                PopComponentState.selected,
              ],
              buildState: (state) => surfaceAt(state, PopElevation.e2),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/greyscale/pop_surface_states.png'),
      );
    });
  });

  group('the button family', () {
    Widget buttonAt(PopComponentState state, PopButtonVariant variant) =>
        PopButton(
          label: 'Play',
          variant: variant,
          onPressed: state == PopComponentState.disabled ? null : () {},
        );

    for (final localeCase in <LocaleCase>[
      LocaleCase.all.first,
      LocaleCase.rightToLeft.first,
    ]) {
      testWidgets('PopButton in ${localeCase.tag}', (tester) async {
        await tester.pumpPopComponent(
          RepaintBoundary(
            child: popStateMatrix(
              states: const <PopComponentState>[
                PopComponentState.rest,
                PopComponentState.disabled,
              ],
              buildState: (state) => Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  for (final variant in PopButtonVariant.values)
                    buttonAt(state, variant),
                ],
              ),
            ),
          ),
          localeCase: localeCase,
        );

        await expectLater(
          find.byType(RepaintBoundary).first,
          matchesGoldenFile(popGolden('pop_button_states', localeCase)),
        );
      });
    }

    testWidgets('PopButton at rest in de, the expansion case', (tester) async {
      // German only needs the REST state: the expansion axis is about length,
      // and a pressed German button is the same length as a resting one.
      await tester.pumpPopComponent(
        RepaintBoundary(
          child: SizedBox(
            width: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PopButton(
                  label: sampleStrings['de']!.navSettings,
                  size: PopButtonSize.large,
                  onPressed: () {},
                ),
                const SizedBox(height: 10),
                PopChip(label: sampleStrings['de']!.chip),
              ],
            ),
          ),
        ),
        localeCase: LocaleCase.all[1],
      );

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile(popGolden('pop_button_de', LocaleCase.all[1])),
      );
    });

    for (final localeCase in <LocaleCase>[
      LocaleCase.all.first,
      LocaleCase.rightToLeft.first,
    ]) {
      testWidgets('the small catalog in ${localeCase.tag}', (tester) async {
        final strings = sampleStrings[localeCase.tag]!;

        await tester.pumpPopComponent(
          RepaintBoundary(
            child: ColoredBox(
              color: colours.surface,
              child: Padding(
                padding: const EdgeInsetsDirectional.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopIconButton(
                          glyph: SunburstGlyph.back,
                          semanticLabel: 'back',
                          onPressed: () {},
                        ),
                        const SizedBox(width: 10),
                        PopChip(
                          label: strings.chip,
                          glyph: SunburstGlyph.flame,
                        ),
                        const SizedBox(width: 10),
                        PopChip(label: strings.score),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final density in PopCardDensity.values) ...[
                      PopCard(
                        density: density,
                        child: Text(strings.cardTitle),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
          ),
          localeCase: localeCase,
        );

        await expectLater(
          find.byType(RepaintBoundary).first,
          matchesGoldenFile(popGolden('small_catalog', localeCase)),
        );
      });
    }
  });

  group('DashedInkBorder', () {
    testWidgets('renders identically in en and fa', (tester) async {
      // A dashed edge is decoration, not a directional affordance: a closed
      // path walked from a fixed origin has no "start" for a reader to find.
      // Both directions are pointed at ONE golden, which is how byte-identity
      // is stated rather than described.
      for (final localeCase in <LocaleCase>[
        LocaleCase.all.first,
        LocaleCase.rightToLeft.first,
      ]) {
        await tester.pumpPopComponent(
          RepaintBoundary(
            child: PopSurface(
              fill: colours.surface,
              borderStyle: PopBorderStyle.dashed,
              radius: BorderRadiusDirectional.all(shape.radiusLg),
              child: const SizedBox(width: 140, height: 70),
            ),
          ),
          localeCase: localeCase,
        );

        await expectLater(
          find.byType(RepaintBoundary).first,
          matchesGoldenFile('goldens/shared/dashed_edge.png'),
        );
      }
    });
  });

  group('the catalog contact sheet', () {
    // FOUR IMAGES, ONE PER LOCALE, and the ones a human actually looks at. The
    // ckb sheet is the only automated place a Sorani-specific glyph is drawn
    // at all, which is what makes a font-fallback failure visible rather than
    // inferred.
    for (final localeCase in LocaleCase.all) {
      testWidgets('in ${localeCase.tag}', (tester) async {
        final strings = sampleStrings[localeCase.tag]!;

        await tester.pumpPopComponent(
          RepaintBoundary(
            child: ColoredBox(
              color: colours.surface,
              child: Padding(
                padding: const EdgeInsetsDirectional.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PopButton(label: strings.button, onPressed: () {}),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        PopIconButton(
                          glyph: SunburstGlyph.back,
                          semanticLabel: strings.navPlay,
                          onPressed: () {},
                        ),
                        const SizedBox(width: 8),
                        PopChip(
                          label: strings.chip,
                          glyph: SunburstGlyph.flame,
                        ),
                        const SizedBox(width: 8),
                        PopBadge(
                          label: strings.hudLabel,
                          variant: PopBadgeVariant.best,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GameCard(
                      title: strings.cardTitle,
                      subtitle: strings.cardSubtitle,
                      accent: colours.gameStroop,
                      semanticLabel: strings.cardTitle,
                      bestLabel: strings.hudLabel,
                      bestValue: strings.score,
                      onTap: () {},
                    ),
                    const SizedBox(height: 8),
                    DifficultySegmented(
                      labels: <String>[
                        strings.difficultyChill,
                        strings.difficultyClassic,
                        strings.difficultyBlitz,
                      ],
                      selectedIndex: 1,
                      onSelected: (_) {},
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        HudPill(
                          label: strings.hudLabel,
                          value: strings.score,
                        ),
                        const SizedBox(width: 8),
                        HudPill(
                          label: strings.hudLabel,
                          value: strings.duration,
                          tone: HudTone.alarm,
                        ),
                        const SizedBox(width: 8),
                        PopGridTile(
                          label: strings.tile,
                          state: PopGridTileState.next,
                          semanticLabel: strings.tile,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    PopProgressBar(
                      value: 0.45,
                      semanticLabel: strings.hudLabel,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        PopToggle(
                          value: true,
                          onLabel: strings.toggleOn,
                          offLabel: strings.toggleOff,
                          semanticLabel: strings.navSettings,
                          onChanged: (_) {},
                        ),
                        const SizedBox(width: 8),
                        TimerRing(
                          progress: 0.4,
                          label: strings.duration,
                          semanticLabel: strings.hudLabel,
                          size: 72,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    PopBottomNav(
                      items: <PopNavItem>[
                        PopNavItem(
                          glyph: SunburstGlyph.navPlay,
                          label: strings.navPlay,
                        ),
                        PopNavItem(
                          glyph: SunburstGlyph.navStats,
                          label: strings.navStats,
                        ),
                        PopNavItem(
                          glyph: SunburstGlyph.navSettings,
                          label: strings.navSettings,
                        ),
                      ],
                      selectedIndex: 0,
                      onSelected: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
          localeCase: localeCase,
        );

        await expectLater(
          find.byType(RepaintBoundary).first,
          matchesGoldenFile(popGolden('catalog_contact_sheet', localeCase)),
        );
      });
    }
  });
}
