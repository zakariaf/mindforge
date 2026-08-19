// The shared play scaffold — the one screen every MindForge game inherits.
//
// The shell owns the top bar, the pause affordance, the play band (accent fill +
// ray/dot layers), the three HUD pills, the progress track, the run lifecycle and
// the hand-off to results. The game owns exactly one thing: the rectangle handed
// to `definition.buildBoard`. Dumb view over a session Notifier — no domain math,
// no clock read, no formatting; `RunState` arrives ready to render.
//
// Owned elsewhere: PopIconButton/PopChip/HudPill/PopProgressBar (`sunburst-components`),
// SunburstColors/SunburstShape/SunburstType (`sunburst-tokens`), RunNotifier
// (`references/run-lifecycle.md`), the feel (`sunburst-motion-and-haptics`).

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../games/game_definition.dart'; // BoardBackground
import '../../../games/game_registry.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/run_routes.dart';
import '../../../theme/game_accent.dart'; // GameAccent — sunburst-game-surfaces
import '../../../theme/sunburst_theme.dart';
import '../../../ui/components/hud_pill.dart';
import '../../../ui/components/pop_chip.dart';
import '../../../ui/components/pop_icon_button.dart';
import '../../../ui/components/pop_progress_bar.dart';
import '../../../ui/glyphs/sunburst_glyph.dart'; // shell-owned; README's 2.6/3 strokes
import '../../shell/widgets/halftone_dots.dart';
import '../../shell/widgets/play_band.dart';
import '../application/run_notifier.dart';
import '../domain/board_snapshot.dart';
import '../domain/run_config.dart';
import '../domain/run_phase.dart';
import '../domain/run_state.dart';
import 'pause_sheet.dart';

/// The play screen for ANY game. Route: `/play/:gameId`.
class PlayScaffoldScreen extends ConsumerWidget {
  const PlayScaffoldScreen({required this.config, super.key});

  final RunConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = SunburstColors.of(context);
    final run = ref.watch(runNotifierProvider(config));
    final definition = ref.watch(gameDefinitionProvider(config.gameId));

    // The game never navigates (rule 2). Exactly one listener owns the hand-off.
    ref.listen(runNotifierProvider(config).select((s) => s.phase), (previous, next) {
      switch (next) {
        case RunPhase.over:
          _announceOutcome(context, ref.read(runNotifierProvider(config)));
          RunRoutes.replaceWithResults(context, config);
        case RunPhase.paused:
          PauseSheet.show(context, config);
        case RunPhase.idle || RunPhase.countdown || RunPhase.playing:
          break;
      }
    });

    return PopScope(
      // Back never leaves a live run silently — it pauses it.
      canPop: run.phase == RunPhase.over,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(runNotifierProvider(config).notifier).pause();
      },
      child: Scaffold(
        // Cream behind the status-bar strip, exactly as app.html paints `.sb`.
        // Only CountdownScreen bleeds under it (rule 6).
        backgroundColor: colors.surface,
        body: SafeArea(
          bottom: false, // _BoardPane owns the bottom inset
          child: Column(
            children: [
              _PlayTopBar(config: config),
              PlayBand(
                accent: definition.accent,
                child: Column(
                  children: [
                    _HudRow(hud: run.hud),
                    // `progress == null` hides the track for that game — the shell
                    // drops the widget rather than drawing an empty well.
                    if (run.progress case final double progress)
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          SunburstShape.gutter, 0, SunburstShape.gutter, 14,
                        ),
                        child: PopProgressBar(
                          value: progress,
                          accent: definition.accent,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _BoardPane(
                  background: definition.boardBackground,
                  accent: definition.accent,
                  // THE SEAM. The only place a game-authored widget enters the tree.
                  child: RepaintBoundary(
                    child: definition.buildBoard(context, config),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One announcement for the whole outcome — never one per stat (rule 9).
  void _announceOutcome(BuildContext context, RunState run) {
    final l10n = AppLocalizations.of(context);
    final sentence = run.isPersonalBest
        ? l10n.runOverPersonalBest(run.scoreLabel)
        : l10n.runOver(run.scoreLabel);
    SemanticsService.announce(sentence, Directionality.of(context));
  }
}

/// Pause · title · difficulty chip. Padding 2/20/10, exactly as `.topbar` in app.html.
class _PlayTopBar extends ConsumerWidget {
  const _PlayTopBar({required this.config});

  final RunConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final type = SunburstType.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        SunburstShape.gutter, 2, SunburstShape.gutter, 10,
      ),
      child: Row(
        spacing: SunburstShape.space3,
        children: [
          PopIconButton(
            glyph: SunburstGlyph.pause,
            semanticLabel: l10n.pauseRun,
            onPressed: () => ref.read(runNotifierProvider(config).notifier).pause(),
          ),
          Expanded(
            // `titleBar` (17/600), not `title` (21/600). Reaching for a
            // `copyWith` with a literal size here fails check_raw_values.sh;
            // `titleBar` is one of the six steps SKILL.md requests from
            // `sunburst-tokens`.
            child: Text(l10n.gameTitle(config.gameId.value), style: type.titleBar),
          ),
          PopChip(label: l10n.difficultyLabel(config.difficulty.name)),
        ],
      ),
    );
  }
}

/// Three equal-flex pills, gap 8, padding 2/20/12. Reflows to 2+1 above 1.3×
/// text scale rather than letting a pill drop its label (DERIVED — app.html
/// renders one text scale only).
class _HudRow extends StatelessWidget {
  const _HudRow({required this.hud});

  final GameHud hud;

  static const double _reflowFactor = 1.3;

  @override
  Widget build(BuildContext context) {
    final type = SunburstType.of(context);
    final slots = <HudSlot>[hud.slotA, hud.slotB, hud.slotC];

    // Measure the real HUD value step, not a bare 1.0: a system TextScaler is
    // non-linear, so scaling the size the pill actually renders is the honest
    // test. No `!` — a malformed token falls back to the Row, never to a crash.
    final base = type.numericHud.fontSize;
    final reflow = base != null &&
        MediaQuery.textScalerOf(context).scale(base) > base * _reflowFactor;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        SunburstShape.gutter, 2, SunburstShape.gutter, SunburstShape.space3,
      ),
      // The HUD is not a live region: a polite region here re-reads the timer
      // every tick and the screen reader never stops talking (rule 9).
      child: Semantics(
        container: true,
        child: reflow
            ? Wrap(
                spacing: SunburstShape.space2,
                runSpacing: SunburstShape.space2,
                children: [for (final slot in slots) HudPill(slot: slot)],
              )
            : Row(
                spacing: SunburstShape.space2,
                children: [
                  for (final slot in slots) Expanded(child: HudPill(slot: slot)),
                ],
              ),
      ),
    );
  }
}

/// The board's pane: gutter 20, top 20, bottom 26, plus the halftone dot layer.
/// The board itself adds no SafeArea and no gutter — both are applied here.
class _BoardPane extends StatelessWidget {
  const _BoardPane({
    required this.background,
    required this.accent,
    required this.child,
  });

  final BoardBackground background;
  final GameAccent accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = SunburstColors.of(context);
    return ColoredBox(
      // Two values, both shell-resolved: a game names which, never a Color.
      color: switch (background) {
        BoardBackground.surfaceSunk => colors.surfaceSunk,
        BoardBackground.gameAccent => accent.base(colors),
      },
      child: HalftoneDots(
        opacity: 0.14, // `.playfill .wdots` in app.html
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              SunburstShape.gutter, SunburstShape.gutter, SunburstShape.gutter, 26,
            ),
            // Tight constraints, so the board centres its OWN content and every
            // game agrees where the rectangle is. Never scrolls: a scrolling
            // board moves the tile out from under the thumb aiming at it.
            child: SizedBox.expand(child: child),
          ),
        ),
      ),
    );
  }
}
