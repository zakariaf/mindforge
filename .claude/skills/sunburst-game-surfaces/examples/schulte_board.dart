// Schulte Grid board — the GameColourRole.decorative case.
//
// The counterpart to stroop_board.dart. Because hue is never Schulte's answer,
// this board MAY stand on its own accent and MAY use `danger` for a wrong tap.
// What it may not do is lean on hue: every tile state still differs in at least
// three of {shadow depth, transform, ring, border colour, glyph colour}.
//
// Owned elsewhere: SunburstColors/SunburstShape/SunburstType -> sunburst-tokens;
// PopSurface and the press physics -> sunburst-components; PlayScaffoldScreen,
// RunNotifier, GameHud and the progress track -> sunburst-shell-screens; the
// 240ms wrong-tap shake and the found haptic -> sunburst-motion-and-haptics.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/features/play/domain/board_snapshot.dart';
import 'package:mindforge/features/play/domain/run_config.dart';
import 'package:mindforge/games/schulte_grid/application/schulte_board_notifier.dart'
    show schulteBoardNotifierProvider;
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';

/// Five states, each carrying its own non-hue channels. Colour is derived from
/// this enum; it is never read back from a colour.
enum SchulteTileState { idle, next, found, wrong, disabled }

/// Precomputed by `SchulteBoardNotifier`; lives beside it in `application/`.
@immutable
class SchulteBoardView {
  const SchulteBoardView({
    required this.cells,
    required this.states,
    required this.foundCount,
    required this.nextValue,
  });

  /// The shuffled 1..25, in reading order. `cells.length` is the game's rule, not
  /// a layout constant — the board derives its column count from it.
  final List<int> cells;
  final List<SchulteTileState> states;
  final int foundCount, nextValue;

  int get columnCount => math.sqrt(cells.length).round();
}

/// RULES 10 and 11: the board's only upward channel besides intents. The shell
/// renders slotA from its own Clock, so the game leaves it empty; slotB is the
/// counter and slotC is the single highlighted pill. `HudTone.alarm` is the
/// shell's last-five-seconds rule and is never set here.
extension SchulteBoardSnapshot on SchulteBoardView {
  BoardSnapshot toSnapshot(AppLocalizations l) => BoardSnapshot(
        hud: GameHud(
          HudSlot(label: l.hudTimeLabel, value: ''),
          HudSlot(
            label: l.schulteFoundLabel,
            value: '$foundCount / ${cells.length}',
          ),
          HudSlot(
            label: l.schulteNextLabel,
            value: '$nextValue',
            tone: HudTone.highlight,
          ),
        ),
        progress: foundCount / cells.length,
        outcome: foundCount == cells.length
            ? RunOutcome.completed(score: foundCount)
            : null,
      );
}

/// The board region.
class SchulteBoard extends ConsumerWidget {
  const SchulteBoard({required this.config, super.key});

  /// Handed down by `GameDefinition.buildBoard`; it keys the notifier family.
  final RunConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view =
        ref.watch(schulteBoardNotifierProvider(config).select((s) => s.view));
    final colors = SunburstColors.of(context);

    // Legal here, illegal on Stroop: Schulte declares GameColourRole.decorative,
    // so the field may be the game accent. See references/accent-contract.md.
    return ColoredBox(
      color: GameAccent.schulteTurquoise.base(colors),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          SunburstShape.gutter,
          SunburstShape.gutter,
          SunburstShape.gutter,
          SunburstShape.space6,
        ),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // The board is square, sized to the SMALLER axis of the slot the
              // play scaffold handed it, so it can never overflow vertically.
              final maxHeight = constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : constraints.maxWidth;
              final side = math.min(constraints.maxWidth, maxHeight);
              return SizedBox.square(
                dimension: side,
                child: SchulteGrid(
                  config: config,
                  view: view,
                  gap: gridGap(side, view.columnCount),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The gap is derived from the tap-target floor, not from a device width: keep
/// the design's 12pt unless that would push the cell under 48pt, then step to
/// 8pt. On a 320pt screen (280pt board) 12pt gives 46.4pt and fails; 8pt gives
/// 49.6pt and clears. See references/board-states-and-layout.md for the table.
double gridGap(double side, int columns) {
  double cell(double gap) => (side - gap * (columns - 1)) / columns;
  return cell(SunburstShape.space3) >= kPopMinTarget
      ? SunburstShape.space3 // 12
      : SunburstShape.space2; // 8
}

/// n×n of computed square cells. Never a hardcoded tile size, never a floor.
class SchulteGrid extends ConsumerWidget {
  const SchulteGrid({
    required this.config,
    required this.view,
    required this.gap,
    super.key,
  });

  final RunConfig config;
  final SchulteBoardView view;
  final double gap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Non-negotiable: GridView clips to its own box by default, which would
      // shear off the e1 hard shadow AND the next-tile's 5pt double ring.
      clipBehavior: Clip.none,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: view.columnCount,
        crossAxisSpacing: gap, // COLUMN gap in a vertical grid
        mainAxisSpacing: gap, // ROW gap
      ),
      itemCount: view.cells.length,
      itemBuilder: (context, i) => SchulteTile(
        // Identity, not content: a re-tap after a reshuffle must not act on a
        // stale capture.
        key: ValueKey(view.cells[i]),
        value: view.cells[i],
        state: view.states[i],
        onTap: () =>
            ref.read(schulteBoardNotifierProvider(config).notifier).tapCell(i),
      ),
    );
  }
}

/// One cell. Read the state matrix in `references/board-states-and-layout.md`
/// before changing any of this.
class SchulteTile extends StatelessWidget {
  const SchulteTile({
    required this.value,
    required this.state,
    required this.onTap,
    super.key,
  });

  final int value;
  final SchulteTileState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    // Channel 1 — depth. Channel 2 — transform. Channel 3 — ring. Channel 4 —
    // glyph colour. Hue is the fifth, and it is derived last.
    final (PopElevation elevation, Offset shift, double scale) = switch (state) {
      SchulteTileState.idle => (PopElevation.e1, Offset.zero, 1.0),
      SchulteTileState.next => (PopElevation.e2, Offset.zero, 1.02),
      SchulteTileState.found => (PopElevation.flat, const Offset(2, 2), 1.0),
      SchulteTileState.wrong => (PopElevation.e1, Offset.zero, 1.0),
      // Disabled stays at e1: PopSurface repaints that shadow in borderDisabled
      // rather than removing it (`.btn[disabled]{box-shadow:3px 3px 0 ink-3}`).
      // `flat` here would silently disagree with every other disabled surface.
      SchulteTileState.disabled => (PopElevation.e1, Offset.zero, 1.0),
    };
    final fill = switch (state) {
      SchulteTileState.idle => colors.surface,
      SchulteTileState.next => colors.accent,
      SchulteTileState.found => colors.gameSchulteDeep, // ink 5.1:1
      // Legal ONLY because Schulte is decorative. On a mechanic board `danger`
      // IS playRed — the same value an answer key may be wearing.
      SchulteTileState.wrong => colors.danger,
      // PopSurface's own disabled shape overrides this to surfaceSunk and drops
      // the border to borderDisabled; passing surface keeps the call honest.
      SchulteTileState.disabled => colors.surface,
    };
    final glyph = switch (state) {
      SchulteTileState.wrong => colors.surfaceRaised,
      SchulteTileState.disabled => colors.textDisabled,
      _ => colors.textPrimary,
    };

    return Transform.translate(
      offset: shift,
      child: Transform.scale(
        scale: scale, // bleeds outside the box; layout geometry is untouched
        child: CustomPaint(
          // The ring is a STROKE painted outside the layout box, exactly like
          // PopSurface's focus ring — never a spread shadow, which the token
          // gate bans and which would reflow nothing but still lie about depth.
          painter: state == SchulteTileState.next
              ? NextRingPainter(
                  radius: shape.radiusMd,
                  gapColour: colors.surface,
                  ringColour: colors.border,
                )
              : null,
          child: PopSurface(
            fill: fill,
            radius: shape.radiusMd,
            elevation: elevation,
            // The sanctioned disabled shape change from system.html §11: fill to
            // surfaceSunk, border to ink-3, shadow dropped. Never an Opacity
            // fade — that would take the 3pt ink border down with the fill.
            enabled: state != SchulteTileState.disabled,
            // A found tile is not a control any more; idle and next are.
            onTap: state == SchulteTileState.found ? null : onTap,
            semanticLabel: '$value',
            child: Center(child: TileGlyph(value: value, color: glyph)),
          ),
        ),
      ),
    );
  }
}

/// The next-tile cue: 2pt cream immediately outside the edge, then 3pt ink, so
/// the ink band ends 5pt out — `system.html` §10 `.tile.next`. Same construction
/// as PopSurface's focus ring, which `sunburst-components` owns: strokes drawn
/// beyond the layout box, so the grid does not reflow when `next` moves.
class NextRingPainter extends CustomPainter {
  const NextRingPainter(
      {required this.radius, required this.gapColour, required this.ringColour});

  final Radius radius;
  final Color gapColour, ringColour;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    _stroke(canvas, box, 1, 2, gapColour); // cream, 0..2pt out
    _stroke(canvas, box, 3.5, 3, ringColour); // ink, 2..5pt out
  }

  void _stroke(Canvas canvas, Rect box, double out, double width, Color colour) =>
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              box.inflate(out), Radius.circular(radius.x + out)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..color = colour);

  @override
  bool shouldRepaint(NextRingPainter old) =>
      old.radius != radius ||
      old.gapColour != gapColour ||
      old.ringColour != ringColour;
}

/// A fixed-count grid cannot grow its cell, so text scale is absorbed by
/// choosing a smaller BASE style and letting the user's multiplier apply on top
/// — never by clamping the scaler, never by FittedBox, never by ellipsis.
///
/// DERIVED: `SunburstType` has no tile slot at all. system.html §10 draws the
/// tile at 24pt display/700/tabular, so sunburst-tokens owes `tileGlyph` (24)
/// and `tileGlyphCompact` (18). `numericHud` (22, tabular) and `button` (18) are
/// the nearest shipped slots; until the pair lands, the tile renders 2pt small
/// and the board is only verified to about 1.5x scale.
class TileGlyph extends StatelessWidget {
  const TileGlyph({required this.value, required this.color, super.key});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final type = SunburstType.of(context);
    final shape = SunburstShape.of(context);
    final scaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Cell minus the border on both edges and 2pt of breathing room.
        final inner = constraints.maxWidth - shape.borderWidth * 2 - 4;
        final style = scaler.scale(type.numericHud.fontSize!) <= inner
            ? type.numericHud
            : type.button;
        return Text('$value', style: style.copyWith(color: color));
      },
    );
  }
}
