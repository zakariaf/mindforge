import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/hud_tone.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/difficulty_segmented.dart';
import 'package:mindforge/ui/components/game_card.dart';
import 'package:mindforge/ui/components/hud_pill.dart';
import 'package:mindforge/ui/components/pop_badge.dart';
import 'package:mindforge/ui/components/pop_bottom_nav.dart';
import 'package:mindforge/ui/components/pop_grid_tile.dart';
import 'package:mindforge/ui/components/pop_progress_bar.dart';
import 'package:mindforge/ui/components/pop_sheet.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/components/pop_toggle.dart';
import 'package:mindforge/ui/components/tabular_text.dart';
import 'package:mindforge/ui/components/timer_ring.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

import '../../support/component_harness.dart';
import '../../support/harness.dart';
import '../../support/load_app_fonts.dart';
import '../../support/locale_cases.dart';
import '../../support/sample_strings.dart';

void main() {
  const colours = SunburstColors.sunburstPop;
  const shape = SunburstShape.sunburstPop;
  final en = LocaleCase.all.first;
  final de = LocaleCase.all[1];
  final fa = LocaleCase.rightToLeft.first;
  final ckb = LocaleCase.rightToLeft[1];

  setUpAll(loadAppFonts);

  BoxDecoration decorationOf(WidgetTester tester, [int index = 0]) =>
      tester
              .widget<DecoratedBox>(find.byType(DecoratedBox).at(index))
              .decoration
          as BoxDecoration;

  group('HudPill', () {
    testWidgets('each tone resolves its fill and both text slots', (
      tester,
    ) async {
      final expected = <HudTone, (Color fill, Color label, Color value)>{
        HudTone.neutral: (
          colours.surfaceRaised,
          colours.textSecondary,
          colours.textPrimary,
        ),
        HudTone.highlight: (
          colours.accent,
          colours.textPrimary,
          colours.textPrimary,
        ),
        HudTone.alarm: (
          colours.danger,
          colours.surfaceRaised,
          colours.surfaceRaised,
        ),
      };

      expect(expected.keys.toSet(), HudTone.values.toSet());

      for (final entry in expected.entries) {
        await tester.pumpPopComponent(
          HudPill(label: 'Time', value: '0:23', tone: entry.key),
        );

        final (fill, label, value) = entry.value;

        expect(decorationOf(tester).color, fill, reason: '${entry.key}');
        expect(
          tester.widget<Text>(find.text('Time')).style!.color,
          label,
          reason: '${entry.key}',
        );
        // The value is rendered through TabularText, which splits it into
        // per-digit boxes, so the style is read off the widget rather than off
        // a Text that no longer exists as one node.
        expect(
          tester.widget<TabularText>(find.byType(TabularText)).style.color,
          value,
          reason: '${entry.key}',
        );
      }
    });

    testWidgets('the alarm is danger, never a gameplay slot', (tester) async {
      // The colour-blind setting re-points gameplay colours. An alarm aliased
      // to one would change hue for exactly the players who need it most.
      await tester.pumpPopComponent(
        const HudPill(label: 'Time', value: '0:04', tone: HudTone.alarm),
      );

      final fill = decorationOf(tester).color;

      expect(fill, colours.danger);
      for (final gameplay in <Color>[
        colours.gameStroop,
        colours.gameStroopDeep,
        colours.gameSchulte,
        colours.gameSchulteDeep,
      ]) {
        expect(fill, isNot(gameplay));
      }
    });

    testWidgets('is neither pressable nor focusable', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpPopComponent(
        const HudPill(label: 'Score', value: '1,480'),
      );

      // MergeSemantics folds the caption and the value into one announcement,
      // so a screen reader says "Score 1,480" rather than stopping twice — and
      // matchesSemantics with neither a button flag nor a tap action is how
      // "reports, does not respond" is stated.
      expect(
        tester.getSemantics(find.byType(HudPill)),
        matchesSemantics(label: 'Score\n1,480'),
        reason:
            'one node, and the value announced whole — TabularText splits the '
            'digits for LAYOUT and hides that split from semantics, or a '
            'screen reader would read "one, comma, four, eight, zero"',
      );

      handle.dispose();
    });

    testWidgets('its value does not reflow when a digit changes, per locale', (
      tester,
    ) async {
      // Tabular figures are a property of the FONT. That Fredoka honours them
      // is known; that Vazirmatn honours them for U+06F0-U+06F9 is not
      // something to assume, which is why every shipped locale is measured.
      final cases = <LocaleCase, (String, String)>{
        en: ('0:23', '0:11'),
        de: ('1.480', '9.999'),
        fa: ('۰:۲۳', '۰:۱۱'),
        ckb: ('۰:۲۳', '۰:۱۱'),
      };

      for (final entry in cases.entries) {
        final (before, after) = entry.value;

        await tester.pumpPopComponent(
          HudPill(label: 'Time', value: before),
          localeCase: entry.key,
        );
        final firstWidth = tester.getSize(find.byType(HudPill)).width;

        await tester.pumpPopComponent(
          HudPill(label: 'Time', value: after),
          localeCase: entry.key,
        );

        expect(
          tester.getSize(find.byType(HudPill)).width,
          firstWidth,
          reason:
              'the pill resized between "$before" and "$after" under '
              '${entry.key.tag}, so a running clock would jitter',
        );
      }
    });
  });

  group('PopGridTile', () {
    testWidgets('every state is distinguishable without colour', (
      tester,
    ) async {
      // Fill, depth and ink all move together, so no state is carried by hue
      // alone. The greyscale golden is what proves the result; this asserts
      // the intent per state.
      final seen = <(Color, PopElevation)>{};

      for (final state in PopGridTileState.values) {
        await tester.pumpPopComponent(
          PopGridTile(label: '25', state: state, semanticLabel: 'tile 25'),
        );

        seen.add((decorationOf(tester).color!, state.elevation));
      }

      expect(
        seen,
        hasLength(PopGridTileState.values.length),
        reason: 'two states render identically',
      );
    });

    testWidgets('found draws no shadow and no Opacity', (tester) async {
      await tester.pumpPopComponent(
        const PopGridTile(
          label: '7',
          state: PopGridTileState.found,
          semanticLabel: 'tile 7',
        ),
      );

      expect(decorationOf(tester).boxShadow, anyOf(isNull, isEmpty));
      expect(find.byType(Opacity), findsNothing);
    });

    testWidgets('a two-digit Eastern Arabic label fits at every text scale', (
      tester,
    ) async {
      // The number the Schulte board is MADE of. A tile that clips its own
      // label is the game rendered wrong, not a cosmetic slip.
      for (final localeCase in <LocaleCase>[fa, ckb]) {
        for (final scale in <double>[1, 1.3, 2]) {
          for (final device in <Device>[
            Device.compact320,
            Device.reference390,
          ]) {
            await tester.pumpPopComponent(
              PopGridTile(
                label: sampleStrings[localeCase.tag]!.tile,
                state: PopGridTileState.idle,
                semanticLabel: 'tile',
              ),
              localeCase: localeCase,
              device: device,
              textScaler: TextScaler.linear(scale),
            );

            final tile = tester.getRect(find.byType(PopGridTile));
            final label = tester.getRect(
              find.text(sampleStrings[localeCase.tag]!.tile),
            );

            expect(tester.takeException(), isNull);
            expect(
              tile.contains(label.topLeft) && tile.contains(label.bottomRight),
              isTrue,
              reason:
                  '${localeCase.tag} at ${scale}x on ${device.name}: the label '
                  'is not inside the tile',
            );
          }
        }
      }
    });
  });

  group('PopToggle', () {
    testWidgets('says its state as well as showing it', (tester) async {
      // The printed word is the non-colour channel. Without it the control is
      // green-versus-cream, which is exactly one channel.
      for (final value in <bool>[true, false]) {
        await tester.pumpPopComponent(
          PopToggle(
            value: value,
            onLabel: 'ON',
            offLabel: 'OFF',
            semanticLabel: 'Sound',
            onChanged: (_) {},
          ),
        );

        expect(find.text(value ? 'ON' : 'OFF'), findsOneWidget);
        expect(
          decorationOf(tester).color,
          value ? colours.success : colours.surfaceSunk,
        );
      }
    });

    testWidgets('and its track fits the Persian state word', (tester) async {
      // 66 points fits ON and OFF. It does not fit روشن and خاموش, which is
      // why the track sizes to its own label instead of to a transcribed
      // number.
      await tester.pumpPopComponent(
        PopToggle(
          value: false,
          onLabel: sampleStrings['fa']!.toggleOn,
          offLabel: sampleStrings['fa']!.toggleOff,
          semanticLabel: 'صدا',
          onChanged: (_) {},
        ),
        localeCase: fa,
      );

      final track = tester.getRect(find.byType(PopToggle));
      final word = tester.getRect(find.text(sampleStrings['fa']!.toggleOff));

      expect(tester.takeException(), isNull);
      expect(track.contains(word.topLeft), isTrue);
      expect(track.contains(word.bottomRight), isTrue);
    });
  });

  group('DifficultySegmented', () {
    testWidgets('the chosen item lifts while the others stay flat', (
      tester,
    ) async {
      // The inversion IS the affordance: everything else goes down when
      // touched, so an item that comes up reads as chosen rather than pressed.
      await tester.pumpPopComponent(
        DifficultySegmented(
          labels: const <String>['Chill', 'Classic', 'Blitz'],
          selectedIndex: 1,
          onSelected: (_) {},
        ),
      );

      final decorations = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((box) => box.decoration as BoxDecoration)
          .toList();

      expect(
        decorations.where((d) => d.boxShadow?.isNotEmpty ?? false),
        hasLength(1),
        reason: 'exactly one segment is raised',
      );
    });

    testWidgets('and its order follows reading direction', (tester) async {
      Future<double> firstItemLeft(LocaleCase localeCase) async {
        await tester.pumpPopComponent(
          DifficultySegmented(
            labels: const <String>['Chill', 'Classic', 'Blitz'],
            selectedIndex: 0,
            onSelected: (_) {},
          ),
          localeCase: localeCase,
        );

        return tester.getRect(find.text('Chill')).left;
      }

      expect(
        await firstItemLeft(en),
        lessThan(await firstItemLeft(fa)),
        reason: 'the easiest option leads in both directions',
      );
    });
  });

  group('GameCard', () {
    testWidgets('takes its accent as an argument and branches on nothing', (
      tester,
    ) async {
      await tester.pumpPopComponent(
        GameCard(
          title: 'Stroop Rush',
          subtitle: 'Tap the colour',
          accent: colours.gameStroop,
          semanticLabel: 'Stroop Rush',
          onTap: () {},
        ),
      );

      expect(decorationOf(tester).color, colours.gameStroop);
    });

    testWidgets('title and subtitle are both textPrimary', (tester) async {
      // On a coral fill the secondary ink lands at 2.8:1. This is asserted on
      // the resolved colour rather than checked by eye.
      await tester.pumpPopComponent(
        GameCard(
          title: 'Stroop Rush',
          subtitle: 'Tap the colour',
          accent: colours.gameStroop,
          semanticLabel: 'Stroop Rush',
          onTap: () {},
        ),
      );

      expect(
        tester.widget<Text>(find.text('Stroop Rush')).style!.color,
        colours.textPrimary,
      );
      expect(
        tester.widget<Text>(find.text('Tap the colour')).style!.color,
        colours.textPrimary,
      );
    });

    testWidgets('locked is dashed, unraised and untappable', (tester) async {
      var taps = 0;

      await tester.pumpPopComponent(
        GameCard(
          title: 'N-Back',
          subtitle: 'Coming soon',
          accent: colours.accentAlt,
          semanticLabel: 'N-Back',
          locked: true,
          onTap: () => taps++,
        ),
      );

      expect(decorationOf(tester).boxShadow, anyOf(isNull, isEmpty));
      expect(decorationOf(tester).border, isNull, reason: 'the edge is dashed');

      await tester.tap(find.byType(GameCard), warnIfMissed: false);
      await tester.pump();

      expect(taps, 0);
    });

    testWidgets('and its best pill uses the nested edge width', (tester) async {
      await tester.pumpPopComponent(
        GameCard(
          title: 'Stroop Rush',
          subtitle: 'Tap the colour',
          accent: colours.gameStroop,
          semanticLabel: 'Stroop Rush',
          bestLabel: 'BEST',
          bestValue: '1,480',
          onTap: () {},
        ),
      );

      final pill = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((box) => box.decoration as BoxDecoration)
          .firstWhere((d) => d.color == colours.surface);

      expect(pill.border!.top.width, shape.borderWidthNested);
      expect(
        tester.widget<Text>(find.text('BEST')).style!.color,
        colours.textSecondary,
        reason: 'legal because the pill sits on cream, not on the coral card',
      );
    });
  });

  group('PopBottomNav', () {
    testWidgets('has a top ink rule and no other edge', (tester) async {
      // A top border has no handedness, so it is not a directional property
      // and does not mirror.
      await tester.pumpPopComponent(
        PopBottomNav(
          items: const <PopNavItem>[
            PopNavItem(glyph: SunburstGlyph.navPlay, label: 'Play'),
            PopNavItem(glyph: SunburstGlyph.navStats, label: 'Stats'),
          ],
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      );

      final border = decorationOf(tester).border!;

      expect(border.top.width, shape.borderWidth);
      expect(border.bottom, BorderSide.none);
      expect(border.isUniform, isFalse);
    });

    testWidgets('and the German label does not clip the active chip', (
      tester,
    ) async {
      // 88 points fits "Play" and "Stats". It does not fit "Einstellungen",
      // which is why the chip sizes to its own label.
      await tester.pumpPopComponent(
        PopBottomNav(
          items: <PopNavItem>[
            PopNavItem(
              glyph: SunburstGlyph.navSettings,
              label: sampleStrings['de']!.navSettings,
            ),
          ],
          selectedIndex: 0,
          onSelected: (_) {},
        ),
        localeCase: de,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(sampleStrings['de']!.navSettings), findsOneWidget);
    });
  });

  group('PopSheet', () {
    testWidgets('its action order is vertical, so it does not mirror', (
      tester,
    ) async {
      // Asserted in BOTH directions on purpose, so nobody later "fixes" a
      // stacking order that was never handed.
      for (final localeCase in <LocaleCase>[en, fa]) {
        await tester.pumpPopComponent(
          const PopSheet(
            title: 'Paused',
            actions: <Widget>[
              Text('Resume'),
              Text('Quit'),
            ],
          ),
          localeCase: localeCase,
        );

        expect(
          tester.getRect(find.text('Resume')).top,
          lessThan(tester.getRect(find.text('Quit')).top),
          reason: 'primary first, in ${localeCase.tag}',
        );
      }
    });
  });

  group('PopProgressBar and TimerRing', () {
    testWidgets('the bar fills from the start edge in both directions', (
      tester,
    ) async {
      Future<Rect> fillRect(LocaleCase localeCase) async {
        await tester.pumpPopComponent(
          const SizedBox(
            width: 200,
            child: PopProgressBar(value: 0.25, semanticLabel: 'Progress'),
          ),
          localeCase: localeCase,
        );

        return tester.getRect(find.byType(FractionallySizedBox));
      }

      final ltr = await fillRect(en);
      final rtl = await fillRect(fa);

      expect(ltr.width, closeTo(rtl.width, 1), reason: 'same amount filled');
      expect(
        ltr.left,
        lessThan(rtl.left),
        reason: 'the fill grows from the start edge, which swaps sides',
      );
    });

    testWidgets('the bar actually paints its fill', (tester) async {
      // The contact sheet caught this and no unit test would have: a
      // CustomPaint with no child and no size measures ZERO, so the bar
      // rendered as an empty track at every value.
      await tester.pumpPopComponent(
        const SizedBox(
          width: 200,
          child: PopProgressBar(value: 0.5, semanticLabel: 'Progress'),
        ),
      );

      expect(
        tester.getSize(find.byType(CustomPaint).last).width,
        greaterThan(0),
      );
      expect(
        tester.getSize(find.byType(CustomPaint).last).height,
        greaterThan(0),
      );
    });

    testWidgets('the ring reads no direction at all', (tester) async {
      // A clock. It runs from twelve, clockwise, in every locale — the same
      // reasoning that keeps the motion glyph unflipped.
      for (final localeCase in <LocaleCase>[en, fa]) {
        await tester.pumpPopComponent(
          const TimerRing(
            progress: 0.4,
            label: '0:23',
            semanticLabel: 'Time',
          ),
          localeCase: localeCase,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(TimerRing), findsOneWidget);
      }
    });
  });

  group('PopBadge', () {
    testWidgets('each variant carries its own mark', (tester) async {
      const expected = <PopBadgeVariant, SunburstGlyph?>{
        PopBadgeVariant.best: SunburstGlyph.star,
        PopBadgeVariant.locked: SunburstGlyph.lock,
        PopBadgeVariant.neutral: null,
      };

      expect(expected.keys.toSet(), PopBadgeVariant.values.toSet());

      for (final entry in expected.entries) {
        await tester.pumpPopComponent(
          PopBadge(label: 'New', variant: entry.key),
        );

        expect(
          find.byType(SunburstGlyphIcon),
          entry.value == null ? findsNothing : findsOneWidget,
          reason: '${entry.key}',
        );
      }
    });
  });

  group('the findings the correctness review turned up', () {
    testWidgets('a locked card does not print its tagline twice', (
      tester,
    ) async {
      // The badge reused `subtitle`, so every locked card on the home hub said
      // "Coming soon" as both its tagline and its badge.
      await tester.pumpPopComponent(
        GameCard(
          title: 'N-Back',
          subtitle: 'Coming soon',
          accent: colours.accentAlt,
          semanticLabel: 'N-Back',
          lockedLabel: 'Locked',
          locked: true,
        ),
      );

      expect(find.text('Coming soon'), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);
    });

    testWidgets('the progress bar announces the value it is given', (
      tester,
    ) async {
      // It was the ONE component that formatted a number, and it emitted ASCII
      // digits and an ASCII percent sign under fa, where the rest of the
      // screen renders ۴۵٪.
      final handle = tester.ensureSemantics();

      await tester.pumpPopComponent(
        const SizedBox(
          width: 200,
          child: PopProgressBar(
            value: 0.45,
            semanticLabel: 'پیشرفت',
            semanticValue: '۴۵٪',
          ),
        ),
        localeCase: fa,
      );

      expect(
        tester.getSemantics(find.byType(PopProgressBar)).value,
        '۴۵٪',
      );

      handle.dispose();
    });

    testWidgets('a sheet keeps its gap when one action instance repeats', (
      tester,
    ) async {
      // `action != actions.last` compares by IDENTITY, so a const action used
      // twice silently lost the separator before the repeat.
      const shared = SizedBox(width: 40, height: 20);

      await tester.pumpPopComponent(
        const PopSheet(
          title: 'Paused',
          actions: <Widget>[shared, SizedBox(width: 40, height: 30), shared],
        ),
      );

      final gaps = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((box) => box.height == SunburstShape.space3)
          .length;

      expect(gaps, 2, reason: 'two gaps between three actions');
    });

    testWidgets('a bidi-isolated Latin number keeps its Latin pitch', (
      tester,
    ) async {
      // TabularText chose its digit script with a bare codepoint comparison,
      // so the FSI mark the bidi helper inserts — which sits above U+06F0 —
      // made it measure against Eastern Arabic digits Fredoka cannot draw. The
      // pitch then came from the fallback face and the glyph from Fredoka.
      const isolated =
          '\u2068'
          '12:34'
          '\u2069';

      await tester.pumpPopComponent(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TabularText(isolated, style: TextStyle(fontSize: 22)),
            TabularText('12:34', style: TextStyle(fontSize: 22)),
          ],
        ),
      );

      final widths = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .map((box) => box.width)
          .whereType<double>()
          .toSet();

      expect(tester.takeException(), isNull);
      expect(
        widths,
        hasLength(1),
        reason:
            'the isolated and the bare number were measured against different '
            'digit scripts: $widths',
      );
    });
  });
}
