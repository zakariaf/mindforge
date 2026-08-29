import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/games/digit_bridge/ui/board/bridge_chip.dart';
import 'package:mindforge/games/digit_bridge/ui/board/bridge_target.dart';
import 'package:mindforge/games/digit_bridge/ui/digit_bridge_board.dart';

import '../../../support/component_harness.dart';
import '../../../support/harness.dart';
import '../../../support/load_app_fonts.dart';
import '../../../support/locale_cases.dart';

/// Does the numeral actually fit the box it is drawn in?
///
/// **The real-font lane, and this board is why the repo has one.** Ahem renders
/// no Persian digit — it draws an em-square, which fits everything and blesses
/// a layout that does not exist. Eastern Arabic digits are noticeably wider
/// than Latin ones at the same point size, so a fit measured in English is a
/// measurement of a different question.
///
/// **This test exists because the defect shipped to a simulator.** A four-digit
/// Persian target at the `countdownNumeral` step laid out at 326pt inside a
/// 326pt card and lost its last digit, while Latin fitted at 256pt — the exact
/// shape of a bug that reaches release, because the developer's own locale is
/// the one that works.
void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpBoard(
    WidgetTester tester, {
    required Difficulty difficulty,
    required LocaleCase localeCase,
    required Device device,
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    await tester.pumpPopComponent(
      SizedBox(
        // The board's own rectangle: the shell's 20pt gutter on each side.
        width: device.logicalSize.width - 40,
        height: 420,
        child: DigitBridgeBoard(
          run: RunConfig(
            gameId: GameId('digit_bridge'),
            difficulty: difficulty,
            seed: 42,
          ),
        ),
      ),
      localeCase: localeCase,
      device: device,
      textScaler: textScaler,
      resetFirst: true,
    );

    await tester.pump();
  }

  /// Whether [finder]'s single `Text` draws inside its own box.
  ///
  /// **The width is measured with a `TextPainter`, not read off the element,**
  /// and the difference is the whole test. `tester.getSize` on a `Text` returns
  /// the size the parent CONSTRAINED it to; a glyph run that overflows is
  /// clipped and reports the box width back, so the comparison is true by
  /// construction. Verified: an earlier version of this file read `getSize` and
  /// passed against the very build whose Persian target was losing its last
  /// digit on the simulator.
  void expectFits(WidgetTester tester, Finder finder, String what) {
    final text = tester.widget<Text>(
      find.descendant(of: finder, matching: find.byType(Text)).first,
    );
    final context = tester.element(finder.first);

    final painter = TextPainter(
      text: TextSpan(text: text.data, style: text.style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
      // UNCONSTRAINED. Capping at the available width is what made the earlier
      // version report a number that could never exceed the box.
    )..layout();
    final intrinsic = painter.width;

    painter.dispose();

    expect(
      intrinsic,
      lessThanOrEqualTo(tester.getSize(finder.first).width + 0.5),
      reason:
          '$what wants ${intrinsic}pt inside a '
          '${tester.getSize(finder.first).width}pt box',
    );
  }

  // BLITZ IS FIVE DIGITS, which is the widest run the game ever draws, and the
  // narrowest device is 320. Every tuple, because a fit is a per-script,
  // per-size question and one loop inside one test would report the first
  // failure and stay silent for the rest.
  for (final device in <Device>[Device.compact320, Device.reference390]) {
    for (final difficulty in Difficulty.values) {
      for (final localeCase in LocaleCase.all) {
        testWidgets(
          '${device.name} ${difficulty.name} ${localeCase.tag} fits the target',
          (tester) async {
            await pumpBoard(
              tester,
              difficulty: difficulty,
              localeCase: localeCase,
              device: device,
            );

            expectFits(tester, find.byType(BridgeTarget), 'the target numeral');
          },
        );
      }
    }
  }

  for (final localeCase in LocaleCase.all) {
    testWidgets('${localeCase.tag} fits blitz at text scale 1.3', (
      tester,
    ) async {
      // The compact step's whole reason for existing. Nothing shrinks to fit:
      // if this overflows, the answer is another step, never a clamped scaler.
      await pumpBoard(
        tester,
        difficulty: Difficulty.blitz,
        localeCase: localeCase,
        device: Device.compact320,
        textScaler: const TextScaler.linear(1.3),
      );

      expectFits(tester, find.byType(BridgeTarget), 'the target at 1.3');
      expect(tester.takeException(), isNull);
    });

    testWidgets('${localeCase.tag} fits five digits on every chip', (
      tester,
    ) async {
      await pumpBoard(
        tester,
        difficulty: Difficulty.blitz,
        localeCase: localeCase,
        device: Device.compact320,
      );

      final chips = find.byType(BridgeChip);

      for (var i = 0; i < tester.widgetList(chips).length; i++) {
        expectFits(tester, chips.at(i), 'chip $i');
      }
    });
  }
}
