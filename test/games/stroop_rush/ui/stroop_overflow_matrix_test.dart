import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/games/stroop_rush/ui/board/answer_key.dart';
import 'package:mindforge/games/stroop_rush/ui/stroop_board.dart';

import '../../../support/component_harness.dart';
import '../../../support/harness.dart';
import '../../../support/load_app_fonts.dart';
import '../../../support/locale_cases.dart';

/// The board at every width, in every locale, at five text scales.
///
/// One `testWidgets` per tuple, never a loop inside one: Flutter reports an
/// overflow once per `RenderObject`, so a matrix written as one test reports
/// the first combination that broke and stays silent for the rest.
///
/// German is the LENGTH stress case; `fa` and `ckb` are the LINE-BOX HEIGHT
/// case — Arabic-script ascenders and descenders are taller, so a card that
/// fits `de` at 2.0 is not evidence for `ckb` at 2.0.
///
/// **Real fonts.** The test font draws every glyph as an identical em square,
/// which makes every locale the same width and every one of these cases
/// meaningless.
///
/// The bold lane is crossed only with the LARGEST scale rather than with the
/// whole axis: bold is a weight change whose worst case is the largest text,
/// and 60 more cases for the middle of that range would buy nothing. That
/// trade is stated here rather than left implicit.
void main() {
  setUpAll(loadAppFonts);

  final run = RunConfig(
    gameId: GameId('stroop_rush'),
    difficulty: Difficulty.blitz,
    seed: 7,
  );

  const scales = <double>[1, 1.3, 1.5, 2, 3];

  Future<void> pumpBoard(
    WidgetTester tester, {
    required Device device,
    required LocaleCase localeCase,
    required double scale,
    bool boldText = false,
    bool colourBlind = false,
  }) => tester.pumpPopComponent(
    // `settings:` rather than a nested ProviderScope — see the note in
    // stroop_greyscale_golden_test.dart. A nested scope leaves
    // `appSettingsProvider` resolving in the root container, which made the
    // colour-blind lane of this matrix identical to the default one.
    SizedBox(
      // The board's own rectangle: the shell's 20pt gutter on each side, and
      // what is left under the play band on the shortest shipped device.
      width: device.logicalSize.width - 40,
      height: 520,
      child: StroopBoard(run: run),
    ),
    localeCase: localeCase,
    device: device,
    textScaler: TextScaler.linear(scale),
    boldText: boldText,
    settings: const AppSettings.defaults().copyWith(
      isColourBlindPalette: colourBlind,
    ),
  );

  /// Every answer label sits inside its own key.
  void expectLabelsFit(WidgetTester tester, String context) {
    for (final key in tester.widgetList<StroopAnswerKey>(
      find.byType(StroopAnswerKey),
    )) {
      final keyRect = tester.getRect(find.byWidget(key));
      final label = find.descendant(
        of: find.byWidget(key),
        matching: find.text(key.label),
      );

      if (label.evaluate().isEmpty) continue;

      final labelRect = tester.getRect(label);

      expect(
        labelRect.width,
        lessThanOrEqualTo(keyRect.width + 0.5),
        reason: '$context: "${key.label}" is wider than its key',
      );
    }
  }

  group('the scale lane', () {
    for (final device in Device.all) {
      for (final localeCase in LocaleCase.all) {
        for (final scale in scales) {
          testWidgets(
            '${device.name} ${localeCase.tag} x$scale',
            (tester) async {
              await pumpBoard(
                tester,
                device: device,
                localeCase: localeCase,
                scale: scale,
              );

              expect(
                tester.takeException(),
                isNull,
                reason:
                    'the board overflowed at ${device.name} '
                    '${localeCase.tag} x$scale',
              );
              expectLabelsFit(
                tester,
                '${device.name} ${localeCase.tag} x$scale',
              );
            },
          );
        }
      }
    }
  });

  group('the bold lane', () {
    for (final device in Device.all) {
      for (final localeCase in LocaleCase.all) {
        testWidgets('${device.name} ${localeCase.tag} bold x2.0', (
          tester,
        ) async {
          // The Arabic-script bold is a DIFFERENT FONT FILE, so it is the one
          // that can actually change metrics — which is why this lane exists
          // at all rather than being assumed to follow from the scale lane.
          await pumpBoard(
            tester,
            device: device,
            localeCase: localeCase,
            scale: 2,
            boldText: true,
          );

          expect(tester.takeException(), isNull);
          expectLabelsFit(tester, '${device.name} ${localeCase.tag} bold');
        });
      }
    }
  });

  group('the colour-blind lane', () {
    for (final localeCase in LocaleCase.all) {
      testWidgets('${localeCase.tag} at the reference width', (tester) async {
        // The swapped labels are DIFFERENT WORDS — "Pink" for red and
        // "Orange" for green — so the longest label under the flag is not the
        // longest label without it.
        await pumpBoard(
          tester,
          device: Device.reference390,
          localeCase: localeCase,
          scale: 1.3,
          colourBlind: true,
        );

        expect(tester.takeException(), isNull);
        expectLabelsFit(tester, '${localeCase.tag} colour-blind');
      });
    }
  });
}
