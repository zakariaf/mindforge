import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/features/play/application/run_notifier.dart';
import 'package:mindforge/features/play/domain/run_phase.dart';
import 'package:mindforge/features/play/ui/play_band.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/game_registry.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/game_strings.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/ui/components/pop_icon_button.dart';
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

    // The results screen is the shell's decision, made when the run ends —
    // never the board's.
    ref.listen(runNotifierProvider(config), (previous, next) {
      if (previous?.phase == next.phase) return;
      if (next.phase != RunPhase.over) return;

      context.go(Routes.results(config));
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
            PlayBand(hud: run.hud, fill: accent),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  PopIconButton(
                    // The pause glyph does NOT mirror: it is two bars, not a
                    // direction.
                    glyph: SunburstGlyph.pause,
                    semanticLabel: l10n.pauseTitle,
                    onPressed: () =>
                        ref.read(runNotifierProvider(config).notifier).pause(),
                  ),
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
