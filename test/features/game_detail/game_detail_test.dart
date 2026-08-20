import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/features/countdown/ui/countdown_screen.dart';
import 'package:mindforge/features/game_detail/ui/game_detail_screen.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/placeholder/placeholder_definitions.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/ui/components/difficulty_segmented.dart';
import 'package:mindforge/ui/components/pop_bottom_nav.dart';

import '../../support/locale_cases.dart';
import '../../support/shell_harness.dart';

void main() {
  final coral = Routes.gameDetail(GameId('placeholder_coral'));

  group('the detail screen', () {
    testWidgets('reads its game from the path, on a cold start', (
      tester,
    ) async {
      await tester.pumpShellApp(
        const MindForgeApp(),
        initialLocation: coral,
      );

      expect(find.byType(GameDetailScreen), findsOneWidget);
      expect(
        tester.widget<GameDetailScreen>(find.byType(GameDetailScreen)).gameId,
        GameId('placeholder_coral'),
      );
    });

    testWidgets('and carries NO bottom nav', (tester) async {
      // A player who has chosen a game has one way forward and one way back.
      // A tab bar here is a third.
      await tester.pumpShellApp(
        const MindForgeApp(),
        initialLocation: coral,
      );

      expect(find.byType(PopBottomNav), findsNothing);
    });

    testWidgets('and offers the GAME difficulties, not the enum', (
      tester,
    ) async {
      // Schulte Grid may ship without Blitz. A screen that offered all three
      // would start a run the definition refuses.
      final oneDifficulty = fixtureWithDifficulties(<Difficulty>[
        Difficulty.classic,
      ]);

      await tester.pumpShellApp(
        const MindForgeApp(),
        games: <GameDefinition>[oneDifficulty],
        initialLocation: Routes.gameDetail(oneDifficulty.id),
      );

      expect(
        tester
            .widget<DifficultySegmented>(find.byType(DifficultySegmented))
            .labels,
        hasLength(1),
      );
    });

    testWidgets('and exactly one thing is the header', (tester) async {
      await tester.pumpShellApp(
        const MindForgeApp(),
        initialLocation: coral,
      );

      expect(
        tester
            .widgetList<Semantics>(find.byType(Semantics))
            .where((node) => node.properties.header ?? false),
        hasLength(1),
      );
    });
  });

  group('in every locale', () {
    for (final localeCase in LocaleCase.all) {
      testWidgets('${localeCase.tag} renders the game own strings', (
        tester,
      ) async {
        await tester.pumpShellApp(
          const MindForgeApp(),
          initialLocation: coral,
          localeCase: localeCase,
        );

        final l10n = AppLocalizations.of(
          tester.element(find.byType(GameDetailScreen)),
        );

        expect(find.text(l10n.gamePlaceholderCoralName), findsOneWidget);
        expect(find.text(l10n.gamePlaceholderCoralKicker), findsOneWidget);
        expect(find.text(l10n.playButton), findsOneWidget);
      });
    }
  });

  group('Play', () {
    testWidgets('leads to the countdown, which carries no nav either', (
      tester,
    ) async {
      await tester.pumpShellApp(
        const MindForgeApp(),
        initialLocation: coral,
      );

      await tester.tap(find.text('Play'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CountdownScreen), findsOneWidget);
      expect(find.byType(PopBottomNav), findsNothing);
    });
  });

  group('a run route that cannot be read', () {
    testWidgets('renders the not-found screen, not a crash', (tester) async {
      // A stale deep link with a difficulty that no longer exists.
      await tester.pumpShellApp(
        const MindForgeApp(),
        initialLocation:
            '/game/placeholder_coral/countdown?difficulty=nope&seed=1',
      );

      expect(find.byType(CountdownScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

/// A definition offering only [difficulties].
GameDefinition fixtureWithDifficulties(List<Difficulty> difficulties) =>
    GameDefinition(
      id: placeholderCoralDefinition.id,
      accent: placeholderCoralDefinition.accent,
      colourRole: placeholderCoralDefinition.colourRole,
      scoreFormat: placeholderCoralDefinition.scoreFormat,
      scoreSource: placeholderCoralDefinition.scoreSource,
      strings: placeholderCoralDefinition.strings,
      difficulties: difficulties,
      boardBackground: placeholderCoralDefinition.boardBackground,
      buildBoard: placeholderCoralDefinition.buildBoard,
      buildArtwork: placeholderCoralDefinition.buildArtwork,
      bindBoard: placeholderCoralDefinition.bindBoard,
    );
