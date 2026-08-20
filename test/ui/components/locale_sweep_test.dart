import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/hud_tone.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
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
import 'package:mindforge/ui/components/pop_toggle.dart';
import 'package:mindforge/ui/components/timer_ring.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

import '../../support/component_harness.dart';
import '../../support/harness.dart';
import '../../support/load_app_fonts.dart';
import '../../support/locale_cases.dart';
import '../../support/sample_strings.dart';

/// The catalog through every locale, width, text scale and bold setting.
///
/// **One `testWidgets` per tuple.** A `RenderFlex` overflow is reported once
/// per `RenderObject` per frame, so a single test looping over the matrix would
/// report the first break and hide every one after it.
///
/// 4 locales x 4 widths x 3 scales x 2 bold settings is 96 cases. Nothing here
/// is allowed to shrink, ellipsise or clip to pass: a component that stops
/// fitting takes a smaller base type step or a different layout, and this
/// matrix is where that decision gets forced rather than deferred.
void main() {
  const colours = SunburstColors.sunburstPop;

  setUpAll(loadAppFonts);

  /// Every component the catalog ships, at one locale's specimen strings.
  Widget catalog(String tag) {
    final strings = sampleStrings[tag]!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PopButton(label: strings.button, onPressed: () {}),
          PopButton(
            label: strings.button,
            size: PopButtonSize.large,
            onPressed: () {},
          ),
          Row(
            children: [
              PopIconButton(
                glyph: SunburstGlyph.back,
                semanticLabel: strings.navPlay,
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              Flexible(child: PopChip(label: strings.chip)),
            ],
          ),
          PopCard(child: Text(strings.cardSubtitle)),
          GameCard(
            title: strings.cardTitle,
            subtitle: strings.cardSubtitle,
            accent: colours.gameStroop,
            semanticLabel: strings.cardTitle,
            bestLabel: strings.hudLabel,
            bestValue: strings.score,
            onTap: () {},
          ),
          DifficultySegmented(
            labels: <String>[
              strings.difficultyChill,
              strings.difficultyClassic,
              strings.difficultyBlitz,
            ],
            selectedIndex: 1,
            onSelected: (_) {},
          ),
          Row(
            children: [
              HudPill(label: strings.hudLabel, value: strings.score),
              const SizedBox(width: 8),
              HudPill(
                label: strings.hudLabel,
                value: strings.duration,
                tone: HudTone.alarm,
              ),
            ],
          ),
          TimerRing(
            progress: 0.4,
            label: strings.duration,
            semanticLabel: strings.hudLabel,
          ),
          PopProgressBar(value: 0.4, semanticLabel: strings.hudLabel),
          PopGridTile(
            label: strings.tile,
            state: PopGridTileState.next,
            semanticLabel: strings.tile,
          ),
          PopToggle(
            value: true,
            onLabel: strings.toggleOn,
            offLabel: strings.toggleOff,
            semanticLabel: strings.navSettings,
            onChanged: (_) {},
          ),
          PopBadge(label: strings.chip, variant: PopBadgeVariant.best),
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
    );
  }

  for (final localeCase in LocaleCase.all) {
    for (final device in Device.all) {
      for (final scale in <double>[1, 1.3, 2]) {
        for (final bold in <bool>[false, true]) {
          testWidgets(
            '${localeCase.tag} on ${device.name} at ${scale}x'
            '${bold ? ' bold' : ''}',
            (tester) async {
              await tester.pumpPopComponent(
                catalog(localeCase.tag),
                localeCase: localeCase,
                device: device,
                textScaler: TextScaler.linear(scale),
                boldText: bold,
              );

              expect(
                tester.takeException(),
                isNull,
                reason:
                    'the catalog overflowed under ${localeCase.tag} on '
                    '${device.name} at ${scale}x${bold ? ' bold' : ''}. The '
                    'fix is a smaller base type step or a different layout — '
                    'never a FittedBox, never an ellipsis, never a clamped '
                    'scaler',
              );
            },
          );
        }
      }
    }
  }

  group('the catalog never shrinks to fit', () {
    testWidgets('no FittedBox and no ellipsis anywhere in it', (tester) async {
      await tester.pumpPopComponent(
        catalog('de'),
        localeCase: LocaleCase.all[1],
        device: Device.compact320,
        textScaler: const TextScaler.linear(2),
      );

      expect(find.byType(FittedBox), findsNothing);

      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        expect(
          text.overflow,
          anyOf(isNull, TextOverflow.clip),
          reason: '"${text.data}" carries an overflow treatment',
        );
      }
    });
  });
}
