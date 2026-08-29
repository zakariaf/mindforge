import 'package:flutter/material.dart';
import 'package:mindforge/games/false_light/domain/light_board_state.dart';
import 'package:mindforge/games/false_light/domain/tile_depth.dart';
import 'package:mindforge/shared/motion/shake_on_wrong.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

/// One tile: a depth, and what has happened to it.
///
/// **THE WHOLE GAME IS IN THIS WIDGET, and it contains no text and no answer
/// colour.** A raised tile and a pressed one are told apart by three channels
/// at once, none of them hue:
///
/// | | fill | elevation | position |
/// |---|---|---|---|
/// | raised | `surfaceRaised` | `e2` | at rest |
/// | pressed | accent deep | `flat` | translated into the shadow |
///
/// The fills differ in **luminance**, not only in hue — paper against the
/// accent's deep half — which is what makes the board playable with every
/// colour removed. `light_greyscale_test` computes that separation rather than
/// asserting it, and `light_palette_independence_test` proves the colour-blind
/// setting changes nothing here, because there is no answer colour to re-point.
///
/// The shadow does **not** mirror in RTL. That is working agreement 11's one
/// exception — one imaginary light for the whole app — and on this board it
/// stops being a rendering detail and becomes the mechanic, which is why
/// `light_direction_test` asserts the offset is identical in both directions.
class LightTile extends StatelessWidget {
  /// Creates a tile.
  const LightTile({
    required this.depth,
    required this.state,
    required this.wrongTapId,
    required this.onTap,
    required this.semanticLabel,
    super.key,
  });

  /// Whether this tile is raised or pressed. A property of the FIELD, and it
  /// never changes for the life of the field.
  final TileDepth depth;

  /// What has happened to it since.
  final LightTileState state;

  /// A value that changes on every wrong tap. Keys the shake.
  final int wrongTapId;

  /// What a tap does, or `null` once the tile is resolved.
  final VoidCallback? onTap;

  /// What a screen reader announces.
  ///
  /// **"Raised" or "pressed", in words.** Depth is the only visual channel on
  /// this board, and a screen-reader user cannot see a shadow — so the thing a
  /// sighted player reads off the geometry has to be said out loud, or the game
  /// is unplayable rather than merely harder.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    final isPressed = depth == TileDepth.pressed;
    final isSwept = state == LightTileState.swept;

    final (Color fill, PopElevation elevation, Offset translate) = switch ((
      isPressed,
      isSwept,
    )) {
      // A SWEPT TILE JOINS THE FIELD. It takes the raised construction, so the
      // board visibly empties as it is cleared and a player can see at a glance
      // what is left — which is the difference between a search and a memory
      // test.
      (_, true) => (colours.surfaceRaised, PopElevation.e2, Offset.zero),
      (true, false) => (
        colours.accentFor(GameAccent.falseLight, GameColourRole.deep),
        PopElevation.flat,
        SunburstShape.pressedShadow,
      ),
      (false, false) => (
        colours.surfaceRaised,
        PopElevation.e2,
        Offset.zero,
      ),
    };

    final tile = Transform.translate(
      offset: translate,
      child: PopSurface(
        fill: fill,
        radius: BorderRadiusDirectional.all(shape.radiusLg),
        elevation: elevation,
        onTap: onTap,
        semanticLabel: semanticLabel,
        child: state == LightTileState.rejected
            ? Padding(
                padding: EdgeInsetsDirectional.all(shape.borderWidth),
                child: Center(
                  child: Container(
                    height: shape.borderWidth,
                    margin: const EdgeInsetsDirectional.symmetric(
                      horizontal: SunburstShape.space2,
                    ),
                    color: colours.border,
                  ),
                ),
              )
            : const SizedBox.expand(),
      ),
    );

    return ShakeOnWrong(
      // KEYED ON THE TAP, not on the state: ShakeOnWrong plays the
      // false-to-true EDGE, so a second tap on the same raised tile would look
      // to it like a rebuild of the first and play nothing.
      key: ValueKey<int>(wrongTapId),
      isWrong: state == LightTileState.rejected,
      child: tile,
    );
  }
}
