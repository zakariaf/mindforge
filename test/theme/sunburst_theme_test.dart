import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_motion.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_theme.dart';
import 'package:mindforge/theme/sunburst_type.dart';

import '../support/harness.dart';
import 'contrast_test.dart' show contrastRatio;

void main() {
  final theme = buildSunburstTheme();

  group('the theme carries all four extensions', () {
    testWidgets('every Sunburst accessor resolves under it', (tester) async {
      await tester.pumpApp(
        Builder(
          builder: (context) {
            // Each of these asserts if its extension is missing, so reaching
            // the expect below at all is the assertion.
            SunburstColors.of(context);
            SunburstShape.of(context);
            SunburstMotion.of(context);
            SunburstType.of(context);
            return const SizedBox.shrink();
          },
        ),
        theme: theme,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('the ColorScheme is hand-authored', () {
    test('and is never derived from a seed', () {
      // Comments stripped: the file explains in prose why a seed is refused,
      // and a gate that fires on its own rationale gets deleted rather than
      // obeyed.
      final source = File('lib/theme/sunburst_theme.dart')
          .readAsLinesSync()
          .map((line) => line.replaceFirst(RegExp('///?.*'), ''))
          .join('\n');

      expect(
        source.contains('ColorScheme.fromSeed'),
        isFalse,
        reason:
            'a seed derives ~40 roles from one hue, and every one of them '
            'would be a colour nobody in this system measured or declared a '
            'contrast floor for',
      );
    });

    test('its roles read the Sunburst slots', () {
      const colours = SunburstColors.sunburstPop;

      expect(theme.colorScheme.surface, colours.surface);
      expect(theme.colorScheme.onSurface, colours.textPrimary);
      expect(theme.colorScheme.primary, colours.accent);
      expect(theme.colorScheme.error, colours.danger);
      expect(theme.colorScheme.outline, colours.border);
    });

    test('the M3 elevation tint is nothing at all', () {
      expect(
        theme.colorScheme.surfaceTint,
        Colors.transparent,
        reason:
            'this system expresses elevation as an ink rectangle at zero '
            'blur; a translucent tint washed over cream would be a second, '
            'contradictory elevation language',
      );
    });
  });

  group('light theme only', () {
    test('the scheme is light and nothing names a dark one', () {
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('no file under lib/ names darkTheme, themeMode or Brightness.dark', () {
      final offenders = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) {
            // Comments are stripped: sunburst_theme.dart explains in prose why
            // there is no dark mode, and a gate that fires on its own
            // rationale gets deleted rather than obeyed.
            final source = f
                .readAsLinesSync()
                .map((line) => line.replaceFirst(RegExp('//.*'), ''))
                .join('\n');
            return source.contains('darkTheme') ||
                source.contains('themeMode') ||
                source.contains('Brightness.dark');
          })
          .map((f) => f.path)
          .toList();

      expect(
        offenders,
        isEmpty,
        reason:
            'CLAUDE.md working agreement 1. Adding a dark mode is a new '
            'design direction, not a token flip: $offenders',
      );
    });
  });

  group('Material feedback is turned off', () {
    test('so it cannot argue with the press-down', () {
      // Sunburst Pop acknowledges a press by translating the surface down onto
      // its shadow. A ripple layered on top of that reads as two systems
      // disagreeing about what just happened.
      expect(theme.splashFactory, NoSplash.splashFactory);
      expect(theme.highlightColor, Colors.transparent);
    });
  });

  group('GameAccent', () {
    const colours = SunburstColors.sunburstPop;

    test('resolves both halves of both accents', () {
      expect(
        colours.accentFor(GameAccent.stroop, GameColourRole.base),
        colours.gameStroop,
      );
      expect(
        colours.accentFor(GameAccent.stroop, GameColourRole.deep),
        colours.gameStroopDeep,
      );
      expect(
        colours.accentFor(GameAccent.schulte, GameColourRole.base),
        colours.gameSchulte,
      );
      expect(
        colours.accentFor(GameAccent.schulte, GameColourRole.deep),
        colours.gameSchulteDeep,
      );
    });

    test('every offered label actually clears 4.5:1 on its surface', () {
      // COMPUTED for every pair, not read off the @contrast declaration list.
      // That is the point: the previous version returned ink unconditionally
      // and its doc claimed a declaration that did not exist, so both the
      // shell gate and contrast_test passed over the one pair that fails —
      // ink on gameStroopDeep, measured 3.90:1.
      //
      // An omission from a declaration list is invisible. An omission here is
      // impossible: the loop is over the enums.
      for (final accent in GameAccent.values) {
        for (final role in GameColourRole.values) {
          final label = colours.accentLabelFor(accent, role);
          if (label == null) continue;

          expect(
            contrastRatio(label, colours.accentFor(accent, role)),
            greaterThanOrEqualTo(4.5),
            reason: '$accent/$role offers a label that fails the body floor',
          );
        }
      }
    });

    test('gameStroopDeep offers no label, because none clears the floor', () {
      // Both candidates fail: ink 3.90:1, paper 3.94:1. It is a pressed face, a
      // shadow edge and the dark half of a stripe — never a text surface — and
      // returning a colour anyway would be a WCAG AA failure with no gate
      // firing. A caller needing a label there should draw on the base.
      expect(
        colours.accentLabelFor(GameAccent.stroop, GameColourRole.deep),
        isNull,
      );

      for (final candidate in <Color>[
        colours.textPrimary,
        colours.surfaceRaised,
      ]) {
        expect(
          contrastRatio(candidate, colours.gameStroopDeep),
          lessThan(4.5),
          reason:
              'if this ever clears the floor, the null above should become '
              'that colour and this test should say so',
        );
      }
    });

    test('no accent resolves to a gameplay or colour-blind slot', () {
      // The tier rule, at the one place a game reaches into the palette.
      final gameplay = <Color>[
        SunburstColors.sunburstPop.playRed,
        SunburstColors.sunburstPop.playBlue,
        SunburstColors.sunburstPop.playGreen,
        SunburstColors.sunburstPop.playYellow,
        SunburstColors.sunburstPop.playPurple,
        SunburstColors.sunburstPop.playOrange,
        SunburstColors.sunburstPop.cbPink,
      ];

      for (final accent in GameAccent.values) {
        for (final role in GameColourRole.values) {
          expect(
            gameplay.contains(colours.accentFor(accent, role)),
            isFalse,
            reason:
                '$accent/$role paints chrome and must not move when a '
                'player flips the colour-blind setting',
          );
        }
      }
    });
  });
}
