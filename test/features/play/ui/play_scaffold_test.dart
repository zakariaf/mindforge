import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/app.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/features/countdown/ui/countdown_screen.dart';
import 'package:mindforge/features/play/ui/hud_row.dart';
import 'package:mindforge/features/play/ui/play_scaffold.dart';
import 'package:mindforge/features/shell/widgets/play_band.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/placeholder/placeholder_definitions.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/ui/components/hud_pill.dart';
import 'package:mindforge/ui/components/pop_bottom_nav.dart';
import 'package:mindforge/ui/components/pop_progress_bar.dart';
import 'package:mindforge/ui/components/pop_sheet.dart';

import '../../../support/fake_save_run.dart';
import '../../../support/fixture_game.dart';
import '../../../support/locale_cases.dart';
import '../../../support/shell_harness.dart';

/// The screen a run happens in.
void main() {
  RunConfig configFor(GameDefinition definition) => RunConfig(
    gameId: definition.id,
    difficulty: Difficulty.classic,
    seed: 5,
  );

  /// Arrives at the board the way a player does: through the countdown.
  ///
  /// A cold start straight at `/play` leaves the run IDLE — the countdown is
  /// what calls `beginPlaying()` — and a run that is not playing cannot be
  /// paused, so every pause assertion would have passed vacuously.
  Future<void> pumpPlay(
    WidgetTester tester, {
    GameDefinition? game,
    LocaleCase? localeCase,
    FakeSaveRun? saveRun,
  }) async {
    await tester.pumpShellApp(
      const MindForgeApp(),
      localeCase: localeCase,
      saveRun: saveRun,
      initialLocation: Routes.countdown(
        configFor(game ?? placeholderCoralDefinition),
      ),
    );

    for (var beat = 0; beat < CountdownScreen.beats; beat++) {
      await tester.pump(const Duration(seconds: 1));
    }

    await tester.pump(const Duration(milliseconds: 400));
  }

  group('the chrome is the shell own', () {
    testWidgets('two different games get identical geometry', (tester) async {
      // THE EPIC'S CENTRAL CLAIM. Only the board pane's colour differs between
      // two games; the band, the HUD row and the gutter do not.
      final rects = <String, (Rect, Rect)>{};

      for (final definition in <GameDefinition>[
        placeholderCoralDefinition,
        placeholderTurquoiseDefinition,
      ]) {
        await pumpPlay(tester, game: definition);

        rects[definition.id.value] = (
          tester.getRect(find.byType(PlayBand)),
          tester.getRect(find.byType(HudRow)),
        );
      }

      expect(
        rects['placeholder_turquoise'],
        rects['placeholder_coral'],
        reason: 'the chrome moved between two games',
      );
    });

    testWidgets('and it carries no bottom nav', (tester) async {
      await pumpPlay(tester);

      expect(find.byType(PopBottomNav), findsNothing);
    });

    testWidgets('the HUD pills share the row equally', (tester) async {
      // Equal flex, so a longer German caption cannot widen one pill and push
      // the other two out of line.
      for (final localeCase in <LocaleCase>[
        LocaleCase.english,
        LocaleCase.german,
      ]) {
        await pumpPlay(tester, localeCase: localeCase);

        final widths = tester
            .widgetList<HudPill>(find.byType(HudPill))
            .map((pill) => tester.getSize(find.byWidget(pill)).width)
            .toSet();

        expect(widths, hasLength(1), reason: localeCase.tag);
      }
    });
  });

  group('the pause sheet', () {
    Future<void> openPause(WidgetTester tester) async {
      final l10n = AppLocalizations.of(
        tester.element(find.byType(PlayScaffold)),
      );

      await tester.tap(find.bySemanticsLabel(l10n.pauseTitle));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('opens on the transition into paused, with two ways out', (
      tester,
    ) async {
      await pumpPlay(tester);
      await openPause(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(PlayScaffold)),
      );

      expect(find.byType(PopSheet), findsOneWidget);
      expect(find.text(l10n.pauseResume), findsOneWidget);
      expect(find.text(l10n.pauseQuit), findsOneWidget);
    });

    testWidgets('resuming goes back through the countdown, not the board', (
      tester,
    ) async {
      // A player put the phone down for a reason. Dropping them into a live
      // board with a running clock is how a run is lost to the pause rather
      // than to the game.
      await pumpPlay(tester);
      await openPause(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(PlayScaffold)),
      );

      await tester.tap(find.text(l10n.pauseResume));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CountdownScreen), findsOneWidget);
    });

    testWidgets('and quitting leaves for the game, writing nothing', (
      tester,
    ) async {
      final saves = FakeSaveRun();

      await pumpPlay(tester, saveRun: saves);
      await openPause(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(PlayScaffold)),
      );

      await tester.tap(find.text(l10n.pauseQuit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        saves.saved,
        isEmpty,
        reason:
            'an abandoned run does not go on the leaderboard and cannot beat '
            'a personal best',
      );
      expect(find.byType(PopSheet), findsNothing);
    });
  });

  group('the progress track', () {
    testWidgets('is ABSENT when a board reports no progress', (tester) async {
      // Not an empty well. A well at zero says "nothing done yet" about a game
      // that has no measurable progress at all — which is what a placeholder,
      // and Stroop Rush, actually report.
      await pumpPlay(tester);

      expect(find.byType(PopProgressBar), findsNothing);
    });

    testWidgets('and fills from the START edge in both directions', (
      tester,
    ) async {
      // A track that filled from the end edge in Persian would be counting
      // down while the English one counted up.
      // The coral placeholder's id, so gameStringsProvider resolves — the
      // registry's string table is keyed by id and refuses an unknown one
      // outright, which is the check that stops a blank card shipping.
      final game = fixtureGame(id: 'placeholder_coral');
      final config = RunConfig(
        gameId: game.id,
        difficulty: Difficulty.classic,
        seed: 5,
      );
      final leading = <String, bool>{};

      for (final localeCase in LocaleCase.bothDirections) {
        await tester.pumpShellApp(
          const MindForgeApp(),
          localeCase: localeCase,
          games: <GameDefinition>[game],
          initialLocation: Routes.countdown(config),
        );

        // PUBLISHED AFTER THE COUNTDOWN, not before it. The run notifier
        // subscribes when it builds and reads the board's current value then,
        // so a snapshot published on the way in is the one it starts from —
        // and a test that set it early would be asserting the initial state
        // rather than a board update.
        for (var beat = 0; beat < CountdownScreen.beats; beat++) {
          await tester.pump(const Duration(seconds: 1));
        }
        await tester.pump(const Duration(milliseconds: 400));

        ProviderScope.containerOf(tester.element(find.byType(PlayScaffold)))
            .read(fixtureBoardProvider.notifier)
            .publish(
              const BoardSnapshot(
                hud: GameHud(
                  leading: HudSlot(
                    labelKey: 'hudScore',
                    canonicalValue: 0,
                    format: StatFormat.points,
                  ),
                  middle: HudSlot(
                    labelKey: 'hudTime',
                    canonicalValue: 0,
                    format: StatFormat.duration,
                  ),
                ),
                progress: 0.3,
              ),
            );

        await tester.pump();

        expect(find.byType(PopProgressBar), findsOneWidget);

        final track = tester.getRect(find.byType(PopProgressBar));
        final fill = tester.getRect(
          find
              .descendant(
                of: find.byType(PopProgressBar),
                matching: find.byType(FractionallySizedBox),
              )
              .first,
        );

        leading[localeCase.tag] = localeCase.direction == TextDirection.ltr
            ? (fill.left - track.left).abs() < 1
            : (track.right - fill.right).abs() < 1;
      }

      expect(leading['en'], isTrue);
      expect(leading['fa'], isTrue, reason: 'the track filled from the end');
    });
  });
}
