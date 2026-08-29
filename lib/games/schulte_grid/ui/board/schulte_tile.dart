import 'package:flutter/material.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_tile_state.dart';
import 'package:mindforge/games/schulte_grid/ui/board/next_ring_painter.dart';
import 'package:mindforge/shared/motion/shake_on_wrong.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

/// One numbered tile.
///
/// | state | fill | elevation | translate | ring |
/// |---|---|---|---|---|
/// | idle | cream | e1 | none | no |
/// | next | sunshine | e2 | none | **yes** |
/// | found | turquoise deep | flat | (2, 2) | no |
/// | wrong | danger | flat | (2, 2) | no |
/// | disabled | cream | e1 | none | no |
///
/// **No state is told apart by hue alone.** `next` carries a double ring,
/// `found` sinks and loses its shadow, `wrong` sinks and shakes — every row
/// survives a greyscale print, which `sunburst-game-surfaces` rule 4 requires
/// and the greyscale golden checks.
///
/// `wrong` is DERIVED: the design never drew one, because its screenshot is of
/// a run going well. It reuses `danger` — a UI slot, not a gameplay one, which
/// is legal here precisely because this board is `decorative`: no hue on it
/// carries meaning, so nothing the colour-blind swap re-points is nearby.
class SchulteTile extends StatelessWidget {
  /// Creates a tile.
  const SchulteTile({
    required this.label,
    required this.semanticLabel,
    required this.state,
    required this.wrongTapId,
    required this.onTap,
    super.key,
  });

  /// The already-localized numeral.
  final String label;

  /// What a screen reader says, already localized.
  final String semanticLabel;

  /// What this tile is doing.
  final SchulteTileState state;

  /// Changes on every wrong tap, so a repeat mistake shakes again.
  final int wrongTapId;

  /// What a completed tap does. Null once the tile is resolved.
  final VoidCallback? onTap;

  /// The key every tile that is not currently wrong carries.
  ///
  /// Any constant would do; -1 is chosen because `wrongTapId` counts up from
  /// zero and can never reach it.
  static const int _restingIdentity = -1;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    final (
      Color fill,
      Color ink,
      PopElevation elevation,
      Offset shift,
    ) = switch (state) {
      SchulteTileState.idle || SchulteTileState.disabled => (
        colours.surface,
        colours.textPrimary,
        PopElevation.e1,
        Offset.zero,
      ),
      SchulteTileState.next => (
        colours.accent,
        colours.textPrimary,
        PopElevation.e2,
        Offset.zero,
      ),
      // SUNK AND FLAT. The tile settles onto the board — the same travel a
      // press makes, held — so a found tile reads as done by its DEPTH
      // before its colour is considered.
      SchulteTileState.found => (
        colours.accentFor(GameAccent.schulte, GameColourRole.deep),
        colours.textPrimary,
        PopElevation.flat,
        shape.tileFoundSink,
      ),
      SchulteTileState.wrong => (
        colours.danger,
        colours.textInvert,
        PopElevation.flat,
        shape.tileFoundSink,
      ),
    };

    final tile = Transform.translate(
      // THE HIT AREA HOLDS STILL. Only the paint moves, which is what stops a
      // tile from sliding out from under a finger already on it.
      offset: shift,
      transformHitTests: false,
      child: PopSurface(
        fill: fill,
        radius: BorderRadiusDirectional.all(shape.radiusMd),
        elevation: elevation,
        onTap: onTap,
        semanticLabel: semanticLabel,
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            // TABULAR FIGURES, so a `11` and a `25` occupy the same width and
            // the grid does not shimmer as tiles resolve.
            style: type.numericHud.copyWith(
              color: ink,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );

    return ShakeOnWrong(
      // A NEW IDENTITY per wrong tap, so the same tile mistaken twice shakes
      // twice. E06's widget treats an arriving-wrong mount as an edge.
      //
      // **Only the WRONG tile takes it.** `wrongTapId` is a board-wide counter,
      // so keying every tile on it changed every key on one wrong tap and
      // remounted the whole grid: measured at 25 of 25 tiles for a single
      // shake, roughly fifty AnimationController and Ticker create-and-dispose
      // pairs on the frame that starts an animation and fires a haptic. Found
      // in E12, which had copied this line into two new boards — one of them a
      // thirty-tile grid whose designed failure mode is tapping the wrong tile.
      key: ValueKey<int>(
        state == SchulteTileState.wrong ? wrongTapId : _restingIdentity,
      ),
      isWrong: state == SchulteTileState.wrong,
      child: state == SchulteTileState.next
          ? Transform.scale(
              scale: shape.tileNextScale,
              child: CustomPaint(
                // FOREGROUND, so the rings sit over the neighbouring tiles
                // rather than under them — a ring half-hidden by the tile next
                // to it is a cue that only works in the middle of the board.
                foregroundPainter: NextRingPainter(
                  inner: shape.tileNextRingInner,
                  outer: shape.tileNextRingOuter,
                  innerColour: colours.surface,
                  outerColour: colours.border,
                  radius: shape.radiusMd.x,
                ),
                child: tile,
              ),
            )
          : tile,
    );
  }
}
