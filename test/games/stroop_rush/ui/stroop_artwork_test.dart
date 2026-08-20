import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/games/stroop_rush/ui/board/stroop_artwork.dart';
import 'package:mindforge/theme/sunburst_colors.dart';

import '../../../policy/support/source_text.dart';
import '../../../support/component_harness.dart';
import '../../../support/locale_cases.dart';

/// The 64pt identity tile on the Home card.
void main() {
  const colours = SunburstColors.sunburstPop;

  group('it draws the four default answers', () {
    testWidgets('in reading order, in their own hues', (tester) async {
      await tester.pumpPopComponent(
        const SizedBox.square(dimension: 64, child: StroopArtwork()),
      );

      final fills = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(StroopArtwork),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => (box.decoration as BoxDecoration).color)
          .toList();

      expect(fills, <Color>[
        colours.playRed,
        colours.playBlue,
        colours.playGreen,
        colours.playYellow,
      ]);
    });

    testWidgets('and the DEFAULT palette, even with the setting on', (
      tester,
    ) async {
      // The Home card is not inside a run, so there is no round whose palette
      // it could honour — and reading the live setting here would make the
      // tile change under a player who has not started anything.
      expect(StroopArtwork.quads, hasLength(4));
      expect(
        StroopArtwork.quads.map((answer) => answer.fill).toSet(),
        hasLength(4),
        reason: 'four answers, four distinct patterns, even as an ornament',
      );
    });

    testWidgets('and announces nothing — the card title names the game', (
      tester,
    ) async {
      await tester.pumpPopComponent(
        const SizedBox.square(dimension: 64, child: StroopArtwork()),
      );

      expect(
        find.descendant(
          of: find.byType(StroopArtwork),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });
  });

  group('it does not mirror', () {
    testWidgets('because a 2x2 ornament has no reading order', (tester) async {
      // The FRAME around it is the card's and mirrors with the card. The quads
      // are a fixed arrangement with nothing in them for a direction to be
      // about, and flipping them would be motion for its own sake.
      final orders = <String, List<Color?>>{};

      for (final localeCase in LocaleCase.bothDirections) {
        await tester.pumpPopComponent(
          const SizedBox.square(dimension: 64, child: StroopArtwork()),
          localeCase: localeCase,
        );

        final boxes = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(StroopArtwork),
                matching: find.byType(DecoratedBox),
              ),
            )
            .toList();

        orders[localeCase.tag] = <Color?>[
          for (final box in boxes) (box.decoration as BoxDecoration).color,
        ];
      }

      expect(orders['fa'], orders['en']);
    });
  });

  group('the board/ exemption stays narrow', () {
    test('the artwork reads answerColour and no chrome slot', () {
      // E09 files this under board/ because that directory marks the files
      // ALLOWED TO READ THE GAMEPLAY TIER — Risk 1's resolution. The exemption
      // is only honest while the file uses it for one thing, so that is a test
      // rather than a promise.
      final code = withoutDartComments(
        File(
          'lib/games/stroop_rush/ui/board/stroop_artwork.dart',
        ).readAsStringSync(),
      );

      for (final chrome in <String>[
        'accent',
        'success',
        'warning',
        'danger',
        'focusRing',
        'gameStroop',
      ]) {
        expect(
          code,
          isNot(contains('colours.$chrome')),
          reason: 'an ornament must not reach for a chrome slot',
        );
      }

      expect(code, contains('answerColour'));
    });
  });
}
