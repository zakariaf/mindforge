import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/placeholder/placeholder_definitions.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/ui/components/game_card.dart';

import '../../support/locale_cases.dart';
import '../../support/shell_harness.dart';

void main() {
  group('the hub renders the registry as data', () {
    testWidgets('one card per definition, locked slot included', (
      tester,
    ) async {
      await tester.pumpShellApp(const MindForgeApp());

      expect(find.byType(GameCard), findsNWidgets(3));
    });

    testWidgets('and a FOURTH definition adds a fourth card with no edit here', (
      tester,
    ) async {
      // THE ENGINE CLAIM, asserted. If this needed a change to home_screen.dart
      // then Schulte Grid would need one too, and the seam is gone.
      await tester.pumpShellApp(
        const MindForgeApp(),
        games: <GameDefinition>[
          ...placeholderDefinitions(),
          placeholderCoralDefinition,
        ],
      );

      expect(find.byType(GameCard), findsNWidgets(4));
    });

    testWidgets('and the locked slot carries no tap', (tester) async {
      await tester.pumpShellApp(const MindForgeApp());

      final locked = tester
          .widgetList<GameCard>(find.byType(GameCard))
          .where((card) => card.locked)
          .toList();

      expect(locked, hasLength(1));
      expect(locked.single.onTap, isNull);
    });

    testWidgets('and a locked card does not print its tagline twice', (
      tester,
    ) async {
      // E05 fixed exactly this and it must not come back: the badge is its own
      // string, not the subtitle reused.
      await tester.pumpShellApp(const MindForgeApp());

      final locked = tester
          .widgetList<GameCard>(find.byType(GameCard))
          .firstWhere((card) => card.locked);

      expect(locked.lockedLabel, isNotNull);
      expect(locked.lockedLabel, isNot(locked.subtitle));
    });
  });

  group('a game nobody has played', () {
    testWidgets('shows no BEST pill rather than a zero', (tester) async {
      // A zero states a score that was never achieved — and it would state it
      // in whichever digits the locale uses, which makes it look deliberate.
      await tester.pumpShellApp(const MindForgeApp());

      for (final card in tester.widgetList<GameCard>(find.byType(GameCard))) {
        expect(card.bestValue, isNull, reason: card.title);
      }
    });
  });

  group('in every locale', () {
    for (final localeCase in LocaleCase.all) {
      testWidgets('${localeCase.tag} renders translated card titles', (
        tester,
      ) async {
        // Resolved through the ARB, never a literal in the screen. Asserted by
        // resolving the same key the screen resolves, so the test survives a
        // translation edit.
        await tester.pumpShellApp(
          const MindForgeApp(),
          localeCase: localeCase,
        );

        final l10n = AppLocalizations.of(
          tester.element(find.byType(GameCard).first),
        );

        expect(find.text(l10n.gamePlaceholderCoralName), findsOneWidget);
        expect(find.text(l10n.gamePlaceholderLockedName), findsOneWidget);

        // The badge, asserted through the card rather than by finding text: a
        // locked GAME still has a name, and a status word that happened to
        // match one would make a text finder ambiguous rather than wrong.
        final locked = tester
            .widgetList<GameCard>(find.byType(GameCard))
            .firstWhere((card) => card.locked);

        expect(locked.lockedLabel, l10n.comingSoon);
      });
    }

    testWidgets('and exactly one thing on the screen is a header', (
      tester,
    ) async {
      // A screen reader's heading list is only useful if one thing claims it.
      await tester.pumpShellApp(const MindForgeApp());

      // Counted over the widget tree rather than the semantics tree: a
      // Semantics(header: true) is the thing being asserted, and the widget
      // finder says exactly how many there are.
      final headers = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((node) => node.properties.header ?? false);

      expect(headers, hasLength(1));
    });
  });
}
