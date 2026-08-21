import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/game_stats.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_metric.dart';
import 'package:mindforge/core/run_scope.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/features/countdown/ui/countdown_screen.dart';
import 'package:mindforge/features/game_detail/ui/game_detail_screen.dart';
import 'package:mindforge/features/home/application/home_notifier.dart';
import 'package:mindforge/features/shell/widgets/daily_mix_card.dart';
import 'package:mindforge/features/shell/widgets/game_hero_panel.dart';
import 'package:mindforge/features/shell/widgets/ray_header.dart';
import 'package:mindforge/features/shell/widgets/stat_box.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/ui/components/difficulty_segmented.dart';
import 'package:mindforge/ui/components/pop_bottom_nav.dart';

import '../../support/fixture_registry.dart';
import '../../support/locale_cases.dart';
import '../../support/shell_harness.dart';

void main() {
  final coral = Routes.gameDetail(GameId('fixture_alpha'));
  const coralScope = RunScope('fixture_alpha');

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
        GameId('fixture_alpha'),
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

  group('the composition', () {
    testWidgets('is a title bar and a hero, NOT a ray header', (tester) async {
      // app.html gives this screen a plain top bar over the pane: the colour
      // arrives with the hero panel, which is the game's, rather than with a
      // header strip, which is the shell's. A RayHeader here would paint the
      // game's accent edge to edge and leave the hero with nothing to say.
      await tester.pumpShellApp(const MindForgeApp(), initialLocation: coral);

      expect(find.byType(RayHeader), findsNothing);
      expect(find.byType(GameHeroPanel), findsOneWidget);
    });

    testWidgets('the stat duo shows the formatted best and the run count', (
      tester,
    ) async {
      await tester.pumpShellApp(
        const MindForgeApp(),
        initialLocation: coral,
        bests: <String, Result<RunMetric?, DataFailure>>{
          'fixture_alpha': const Ok<RunMetric?, DataFailure>(
            RunMetric.points(1480),
          ),
        },
        stats: <RunScope, GameStats>{
          coralScope: const GameStats(
            gamesPlayed: 128,
            timeTrainedMs: 0,
            correctCount: 0,
            wrongCount: 0,
            totalReactionMs: 0,
            longestCombo: 0,
          ),
        },
      );

      final values = tester
          .widgetList<StatBox>(find.byType(StatBox))
          .map((box) => box.value)
          .toList();

      expect(values, <String>['1,480', '128']);
    });

    testWidgets('and a game with no runs shows a dash, never a zero', (
      tester,
    ) async {
      // A zero states a score that was never achieved. The RUN COUNT is
      // legitimately zero and prints as one; the BEST is absent and prints as
      // an em dash. The two are different facts and the screen says so.
      await tester.pumpShellApp(const MindForgeApp(), initialLocation: coral);

      final values = tester
          .widgetList<StatBox>(find.byType(StatBox))
          .map((box) => box.value)
          .toList();

      expect(values, <String>['—', '0']);
    });

    testWidgets('the Daily Mix card is here in its paper skin', (tester) async {
      await tester.pumpShellApp(const MindForgeApp(), initialLocation: coral);

      expect(
        tester.widget<DailyMixCard>(find.byType(DailyMixCard)).variant,
        DailyMixVariant.paper,
      );
    });

    testWidgets('Classic is selected by default, not the first entry', (
      tester,
    ) async {
      // app.html shows Classic selected, and it is right for a reason a list
      // index cannot express: Chill is for someone who wants no pressure and
      // Blitz is for someone chasing a number, while Classic is what the game
      // IS.
      await tester.pumpShellApp(const MindForgeApp(), initialLocation: coral);

      final segmented = tester.widget<DifficultySegmented>(
        find.byType(DifficultySegmented),
      );

      expect(
        segmented.labels[segmented.selectedIndex],
        AppLocalizations.of(
          tester.element(find.byType(GameDetailScreen)),
        ).difficultyClassic,
      );
    });

    testWidgets('a difficulty chosen for ANOTHER game does not survive', (
      tester,
    ) async {
      // Going from one game's detail to another's replaces the widget and
      // Flutter KEEPS THE STATE — same screen, different game. A selection the
      // new game does not offer leaves indexOf at -1, and the segmented
      // control renders with nothing selected.
      final threeWay = fixtureWithDifficulties(Difficulty.values);
      final chillOnly = GameDefinition(
        id: GameId('fixture_beta'),
        accent: fixtureBeta.accent,
        colourRole: fixtureBeta.colourRole,
        scoreFormat: fixtureBeta.scoreFormat,
        scoreSource: fixtureBeta.scoreSource,
        strings: fixtureBeta.strings,
        difficulties: const <Difficulty>[Difficulty.chill],
        boardBackground: fixtureBeta.boardBackground,
        buildBoard: fixtureBeta.buildBoard,
        buildArtwork: fixtureBeta.buildArtwork,
        buildHeroArt: (context) => const SizedBox.shrink(),
        bindBoard: fixtureBeta.bindBoard,
      );

      await tester.pumpShellApp(
        const MindForgeApp(),
        games: <GameDefinition>[threeWay, chillOnly],
        initialLocation: Routes.gameDetail(threeWay.id),
      );

      // Pick Blitz on the three-way game.
      await tester.tap(
        find.text(
          AppLocalizations.of(
            tester.element(find.byType(GameDetailScreen)),
          ).difficultyBlitz,
        ),
      );
      await tester.pump();

      // Then walk to the game that offers only Chill.
      GoRouter.of(
        tester.element(find.byType(GameDetailScreen)),
      ).go(Routes.gameDetail(chillOnly.id));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        tester
            .widget<DifficultySegmented>(find.byType(DifficultySegmented))
            .selectedIndex,
        0,
        reason: 'Blitz is not on the menu of the game now on screen',
      );
    });

    testWidgets('and a game without Classic falls back to its first', (
      tester,
    ) async {
      final chillOnly = fixtureWithDifficulties(<Difficulty>[Difficulty.chill]);

      await tester.pumpShellApp(
        const MindForgeApp(),
        games: <GameDefinition>[chillOnly],
        initialLocation: Routes.gameDetail(chillOnly.id),
      );

      final segmented = tester.widget<DifficultySegmented>(
        find.byType(DifficultySegmented),
      );

      expect(segmented.selectedIndex, 0);
    });

    testWidgets('and Play is the LAST thing on the screen', (tester) async {
      // It is pinned to the bottom by a spacer, under the Daily Mix card. A
      // Play button that floated up under the segmented control would put the
      // two ways to start a run beside each other.
      await tester.pumpShellApp(const MindForgeApp(), initialLocation: coral);

      expect(
        tester.getRect(find.text('Play')).top,
        greaterThan(tester.getRect(find.byType(DailyMixCard)).bottom),
      );
    });
  });

  group('the segmented control fits its labels', () {
    for (final localeCase in LocaleCase.all) {
      testWidgets('at ${localeCase.tag}, with no overflow', (tester) async {
        // German is the length stress case and this control has the least
        // slack on the screen.
        await tester.pumpShellApp(
          const MindForgeApp(),
          initialLocation: coral,
          localeCase: localeCase,
        );

        expect(tester.takeException(), isNull, reason: localeCase.tag);

        final track = tester.getRect(find.byType(DifficultySegmented));

        expect(track.width, lessThanOrEqualTo(390), reason: localeCase.tag);
      });
    }
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
        final strings = fixtureGameStrings(fixtureAlpha);

        // THE GAME'S strings come through the resolver and the CHROME's come
        // through the ARB. Both halves are asserted, because the screen's job
        // is to keep them apart: it must not invent a game name, and it must
        // not leave a button untranslated.
        //
        // The name appears twice — once in the title bar and once as the
        // hero's h1, exactly as app.html draws it. Only one of the two
        // announces itself.
        expect(find.text(strings.title), findsNWidgets(2));
        expect(find.text(strings.kicker), findsOneWidget);
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
        initialLocation: '/game/fixture_alpha/countdown?difficulty=nope&seed=1',
      );

      expect(find.byType(CountdownScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('the Daily Mix card on a game detail screen', () {
    testWidgets('is ABSENT on the page it would send you to', (tester) async {
      // A CARD THAT NAVIGATES TO ITSELF. On the detail screen of whichever
      // game today's pick chose, the card read "Today's pick: Stroop Rush" and
      // led to the screen already on display. app.html draws a Daily Mix card
      // here, but its card summarises a multi-game mix; ours names one game,
      // and on that game's own page it is the dead affordance E11 forbids.
      await tester.pumpShellApp(
        const MindForgeApp(),
        initialLocation: Routes.gameDetail(fixtureBeta.id),
      );

      final pick = ProviderScope.containerOf(
        tester.element(find.byType(GameDetailScreen)),
      ).read(homeHubProvider).dailyPick;

      expect(pick, fixtureBeta.id, reason: 'the fixture pick is this game');
      expect(find.byType(DailyMixCard), findsNothing);
    });

    testWidgets('and PRESENT on a game it does not point at', (tester) async {
      // The other half, so the row is hidden for the right reason rather than
      // hidden always.
      await tester.pumpShellApp(
        const MindForgeApp(),
        initialLocation: Routes.gameDetail(fixtureAlpha.id),
      );

      expect(find.byType(DailyMixCard), findsOneWidget);
    });
  });
}

/// A definition offering only [difficulties].
GameDefinition fixtureWithDifficulties(List<Difficulty> difficulties) =>
    GameDefinition(
      id: fixtureAlpha.id,
      accent: fixtureAlpha.accent,
      colourRole: fixtureAlpha.colourRole,
      scoreFormat: fixtureAlpha.scoreFormat,
      scoreSource: fixtureAlpha.scoreSource,
      strings: fixtureAlpha.strings,
      difficulties: difficulties,
      boardBackground: fixtureAlpha.boardBackground,
      buildBoard: fixtureAlpha.buildBoard,
      buildArtwork: fixtureAlpha.buildArtwork,
      buildHeroArt: (context) => const SizedBox.shrink(),
      bindBoard: fixtureAlpha.bindBoard,
    );
