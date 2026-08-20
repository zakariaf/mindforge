import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/features/play/application/run_notifier.dart';
import 'package:mindforge/features/play/domain/run_phase.dart';
import 'package:mindforge/features/play/ui/hud_row.dart';
import 'package:mindforge/features/shell/widgets/play_band.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/game_registry.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/game_strings.dart';
import 'package:mindforge/l10n/l10n_providers.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/ui/components/pop_button.dart';
import 'package:mindforge/ui/components/pop_icon_button.dart';
import 'package:mindforge/ui/components/pop_progress_bar.dart';
import 'package:mindforge/ui/components/pop_sheet.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

/// The screen a run happens in.
///
/// **It owns every pixel except the board rectangle.** The band, the pause
/// affordance, the safe areas and the gutter are the shell's; the game supplies
/// one widget and the background it sits on, and nothing else.
///
/// The board is handed a `RunConfig` and never the notifier: a board that could
/// reach the run could end it, pause it, or read a clock it is fenced from.
class PlayScaffold extends ConsumerWidget {
  /// Creates the scaffold for [config].
  const PlayScaffold({required this.config, super.key});

  /// The run being played.
  final RunConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colours = SunburstColors.of(context);
    final l10n = AppLocalizations.of(context);
    final definition = ref.watch(gameDefinitionProvider(config.gameId));
    final run = ref.watch(runNotifierProvider(config));
    final accent = colours.accentFor(definition.accent, GameColourRole.base);
    final progress = run.snapshot.progress;

    // The results screen is the shell's decision, made when the run ends —
    // never the board's. The pause SHEET is the same rule one step earlier:
    // the notifier owns the phase and this listener is what puts a surface in
    // front of the player when it changes.
    ref.listen(runNotifierProvider(config), (previous, next) {
      if (previous?.phase == next.phase) return;

      switch (next.phase) {
        case RunPhase.over:
          context.go(Routes.results(config));
        case RunPhase.paused:
          unawaited(_showPause(context, ref, config));
        case RunPhase.idle || RunPhase.countdown || RunPhase.playing:
          break;
      }
    });

    return PopScope(
      // A live run does not leave by a back gesture. It pauses, and the sheet
      // is where leaving is decided — which is the difference between quitting
      // and fat-fingering the edge of the screen mid-Blitz.
      canPop: run.phase != RunPhase.playing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        ref.read(runNotifierProvider(config).notifier).pause();
      },
      child: ColoredBox(
        color: switch (definition.boardBackground) {
          BoardBackground.surfaceSunk => colours.surfaceSunk,
          BoardBackground.gameAccent => accent,
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // The screen's one h1, announced and not drawn. The board IS the
            // screen visually, so there is no title to paint — but a screen
            // reader still needs to be told which game it just landed in.
            Semantics(
              header: true,
              label: ref.watch(gameStringsProvider)(definition).title,
              child: const SizedBox.shrink(),
            ),
            PlayBand(
              accent: definition.accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(child: HudRow(hud: run.hud)),
                      const SizedBox(width: 12),
                      // IN THE BAND, not on a row of its own below it. A
                      // separate row cost the board twelve points of height
                      // for one 48pt control; in the chrome it costs nothing,
                      // because the band is already as tall as its pills.
                      //
                      // The design draws NO pause control at all — its play
                      // band is three pills and a track — and this is a
                      // deliberate addition. iOS's edge-swipe does pause the
                      // run, and it is not a thing a player finds mid-Blitz.
                      // The pause glyph does not mirror: two bars, not a
                      // direction.
                      PopIconButton(
                        glyph: SunburstGlyph.pause,
                        semanticLabel: l10n.pauseTitle,
                        onPressed: () => ref
                            .read(runNotifierProvider(config).notifier)
                            .pause(),
                      ),
                    ],
                  ),
                  // THE TRACK IS ABSENT, not empty, when a board reports no
                  // progress. An empty well says "nothing done yet" about a
                  // game that has no measurable progress at all.
                  if (progress != null) ...<Widget>[
                    const SizedBox(height: 10),
                    PopProgressBar(
                      value: progress,
                      fill: colours.accentFor(
                        definition.accent,
                        GameColourRole.deep,
                      ),
                      semanticLabel: l10n.hudFound,
                      semanticValue: ref
                          .watch(localeNumbersProvider)
                          .percent(progress),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Padding(
                // THE GUTTER IS THE SHELL'S. A board that inset itself would
                // be deciding its own margins, and two games would disagree.
                padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 20),
                child: SafeArea(
                  top: false,
                  child: definition.buildBoard(context, config),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Puts the pause sheet in front of the player.
///
/// **It is not dismissible by tapping outside or by the back gesture.** A
/// paused run has exactly two ways forward and both are on the sheet; a sheet
/// that could be swiped away would leave the run paused behind it with no
/// affordance to resume, which is how a Blitz round is lost to a stray gesture
/// rather than to the game.
Future<void> _showPause(
  BuildContext context,
  WidgetRef ref,
  RunConfig config,
) async {
  final l10n = AppLocalizations.of(context);
  final notifier = ref.read(runNotifierProvider(config).notifier);

  await showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) => PopScope(
      canPop: false,
      child: PopSheet(
        title: l10n.pauseTitle,
        actions: <Widget>[
          PopButton(
            label: l10n.pauseResume,
            size: PopButtonSize.large,
            variant: PopButtonVariant.success,
            expand: true,
            onPressed: () {
              // KEEP PLAYING RE-ENTERS THE COUNTDOWN. Resuming does not drop
              // the player back into a live board with a running clock — they
              // put the phone down for a reason, and 3-2-1 is how they get
              // their attention back. The phase moves first and the sheet
              // closes second, so there is never a frame with a live board
              // under an open sheet.
              notifier.keepPlaying();
              Navigator.of(sheetContext).pop();
              context.go(Routes.countdown(config));
            },
          ),
          PopButton(
            label: l10n.pauseQuit,
            variant: PopButtonVariant.secondary,
            expand: true,
            onPressed: () {
              // ABANDON, WHICH WRITES NOTHING AND RESETS. A run the player
              // left does not go on the leaderboard and cannot beat a personal
              // best — the outcome type has no field to hold a score — and it
              // leaves no elapsed time behind for the next run to inherit.
              notifier.abandon();
              Navigator.of(sheetContext).pop();
              context.go(Routes.gameDetail(config.gameId));
            },
          ),
        ],
      ),
    ),
  );
}
