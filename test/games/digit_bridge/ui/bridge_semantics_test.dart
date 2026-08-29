import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/games/digit_bridge/ui/board/bridge_chip.dart';
import 'package:mindforge/games/digit_bridge/ui/board/bridge_target.dart';
import 'package:mindforge/games/digit_bridge/ui/digit_bridge_board.dart';
import 'package:mindforge/l10n/app_localizations.dart';

import '../../../support/component_harness.dart';
import '../../../support/load_app_fonts.dart';
import '../../../support/locale_cases.dart';

/// What a screen reader is told, in every language.
///
/// **The board says something a sighted player reads off the glyph shapes: which
/// of two writing systems this numeral is in.** A label of "four seven two"
/// alone is half the question, because on this board the other half is which
/// side of the bridge it sits on.
void main() {
  setUpAll(loadAppFonts);

  final run = RunConfig(
    gameId: GameId('digit_bridge'),
    difficulty: Difficulty.classic,
    seed: 42,
  );

  for (final localeCase in LocaleCase.all) {
    testWidgets('${localeCase.tag} announces every chip with its script', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpPopComponent(
        SizedBox(width: 350, height: 460, child: DigitBridgeBoard(run: run)),
        localeCase: localeCase,
        resetFirst: true,
      );
      await tester.pump();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(DigitBridgeBoard)),
      );
      final chips = tester.widgetList<BridgeChip>(find.byType(BridgeChip));

      // The chips are all in ONE script — the one the target is not in — so
      // exactly one of the two names appears, on all six.
      final names = <String>{
        for (final chip in chips)
          chip.semanticLabel.contains(l10n.bridgeScriptLatin)
              ? l10n.bridgeScriptLatin
              : l10n.bridgeScriptEasternArabic,
      };

      expect(
        names,
        hasLength(1),
        reason: 'the six chips are one side of the bridge, so one script name',
      );

      for (final chip in chips) {
        expect(
          chip.semanticLabel,
          contains(chip.label),
          reason: 'the announcement carries the numeral it draws',
        );
        expect(
          chip.semanticLabel,
          anyOf(
            contains(l10n.bridgeScriptLatin),
            contains(l10n.bridgeScriptEasternArabic),
          ),
          reason:
              'without the script name a reader is told half the question, '
              'because on this board the system it is written in IS the other '
              'half',
        );
      }

      handle.dispose();
    });

    testWidgets('${localeCase.tag} exposes a chip as a tappable button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpPopComponent(
        SizedBox(width: 350, height: 460, child: DigitBridgeBoard(run: run)),
        localeCase: localeCase,
        resetFirst: true,
      );
      await tester.pump();

      final chip = tester.widget<BridgeChip>(find.byType(BridgeChip).first);

      // matchesSemantics is EXACT, so every flag PopSurface declares has to be
      // listed. A chip that lost `isButton` would still be tappable and would
      // stop announcing itself as a control.
      expect(
        tester.getSemantics(find.bySemanticsLabel(chip.semanticLabel)),
        matchesSemantics(
          label: chip.semanticLabel,
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );

      handle.dispose();
    });

    testWidgets(
      '${localeCase.tag} announces the target, and it is not a chip',
      (
        tester,
      ) async {
        final handle = tester.ensureSemantics();

        await tester.pumpPopComponent(
          SizedBox(width: 350, height: 460, child: DigitBridgeBoard(run: run)),
          localeCase: localeCase,
          resetFirst: true,
        );
        await tester.pump();

        final target = tester.widget<BridgeTarget>(find.byType(BridgeTarget));

        // The target is the QUESTION. Exposing it as a button would offer a
        // seventh thing to tap and a reader would go looking for its effect.
        expect(
          tester.getSemantics(find.bySemanticsLabel(target.semanticLabel)),
          matchesSemantics(label: target.semanticLabel),
        );

        handle.dispose();
      },
    );
  }
}
