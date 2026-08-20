import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/features/shell/widgets/play_band.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

import '../../../support/component_harness.dart';
import '../../../support/locale_cases.dart';

/// The strip above a board.
///
/// It is the shell's, not a game's: two games hand it two accents and get the
/// same geometry, which is the engine claim this epic exists to make.
void main() {
  const colours = SunburstColors.sunburstPop;
  const shape = SunburstShape.sunburstPop;
  const contentKey = Key('band-content');

  Widget band(GameAccent accent) => PlayBand(
    accent: accent,
    child: const SizedBox(key: contentKey, height: 40, width: 100),
  );

  BoxDecoration decorationOf(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(PlayBand),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((box) => box.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((d) => d.border != null);

  group('the construction', () {
    for (final accent in GameAccent.values) {
      testWidgets('fills with ${accent.name} base and carries only a bottom '
          'border', (tester) async {
        await tester.pumpPopComponent(band(accent));

        final decoration = decorationOf(tester);
        final border = decoration.border! as Border;

        expect(
          decoration.color,
          colours.accentFor(accent, GameColourRole.base),
          reason: "the band is the GAME's colour, not the app accent",
        );
        expect(border.bottom.width, shape.borderWidth);
        expect(border.bottom.color, colours.border);
        expect(border.top, BorderSide.none);
        expect(border.left, BorderSide.none);
        expect(border.right, BorderSide.none);
      });
    }

    testWidgets('and it draws no shadow of its own', (tester) async {
      // A band is a region, not a raised surface. The 3px ink line IS its
      // separation from the board.
      await tester.pumpPopComponent(band(GameAccent.stroop));

      expect(decorationOf(tester).boxShadow, anyOf(isNull, isEmpty));
    });
  });

  group('the gutter', () {
    testWidgets('is 20 on both sides in en and in ckb', (tester) async {
      // EdgeInsetsDirectional: the same numbers, the other physical side.
      final gaps = <String, (double, double)>{};

      for (final localeCase in <LocaleCase>[
        LocaleCase.english,
        LocaleCase.sorani,
      ]) {
        await tester.pumpPopComponent(
          band(GameAccent.schulte),
          localeCase: localeCase,
        );

        final outer = tester.getRect(find.byType(PlayBand));
        final inner = tester.getRect(find.byKey(contentKey));

        gaps[localeCase.tag] = (
          inner.left - outer.left,
          outer.right - inner.right,
        );
      }

      expect(gaps['en'], (20.0, 20.0));
      expect(gaps['ckb'], (20.0, 20.0));
    });
  });

  group('the safe area', () {
    testWidgets('takes the top inset and leaves the bottom to the board', (
      tester,
    ) async {
      await tester.pumpPopComponent(band(GameAccent.stroop));

      final safeArea = tester
          .widgetList<SafeArea>(
            find.descendant(
              of: find.byType(PlayBand),
              matching: find.byType(SafeArea),
            ),
          )
          .single;

      expect(safeArea.top, isTrue);
      expect(safeArea.bottom, isFalse);
    });
  });

  group("the chrome is the shell's", () {
    testWidgets('two different accents produce identical geometry', (
      tester,
    ) async {
      // THE ENGINE CLAIM, at the smallest scale it can be asserted: only the
      // fill differs between two games.
      final rects = <GameAccent, (Rect, Rect)>{};

      for (final accent in GameAccent.values) {
        await tester.pumpPopComponent(band(accent));

        rects[accent] = (
          tester.getRect(find.byType(PlayBand)),
          tester.getRect(find.byKey(contentKey)),
        );
      }

      expect(rects[GameAccent.stroop], rects[GameAccent.schulte]);
    });
  });
}
