import 'package:flutter/material.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

/// The 64pt tile on False Light's Home card.
///
/// A 3x3 of tiles, two of them pressed. The arrangement is the design's own and
/// is not generated: this is a picture of the game, not a board, and a tile that
/// redealt on every rebuild would be a moving target on a list the player is
/// scanning.
///
/// **Laid out rather than painted, which is the opposite of the other three
/// games' artwork — and it is the absence of text that earns it.** Schulte's
/// tile and Digit Bridge's are painted because a digit in an 18pt cell cannot
/// honour the OS text size. There is no digit here and no glyph of any kind, so
/// there is nothing to scale and nothing to clamp; a `Container` per cell says
/// exactly what the game is with no measurement question to answer.
class LightArtwork extends StatelessWidget {
  /// Creates the tile.
  const LightArtwork({super.key});

  /// Which of the nine cells are pressed, in reading order.
  ///
  /// Two of nine, which is inside the classic band (0.25-0.35) rounded to a
  /// grid this small — so the card is an honest sample of the game rather than
  /// a prettier arrangement.
  static const Set<int> pressed = <int>{1, 5};

  /// How many cells across.
  static const int columns = 3;

  @override
  Widget build(BuildContext context) {
    final shape = SunburstShape.of(context);

    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // Clip.none: the cells carry the same hard offset shadow the board
          // does, and clipping it at the frame is the one defect that reads as
          // a rendering glitch.
          clipBehavior: Clip.none,
          padding: EdgeInsets.zero,
          crossAxisSpacing: shape.miniTileGapValue,
          mainAxisSpacing: shape.miniTileGapValue,
          children: <Widget>[
            for (var i = 0; i < columns * columns; i++)
              _Cell(isPressed: pressed.contains(i)),
          ],
        ),
      ),
    );
  }
}

/// One cell of the picture: raised, or pressed.
class _Cell extends StatelessWidget {
  const _Cell({required this.isPressed});

  final bool isPressed;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    // THE SAME THREE CHANNELS THE BOARD USES, at a ninth of the size: fill,
    // shadow, position. A card that showed only the fill would be advertising a
    // colour game.
    return Transform.translate(
      offset: isPressed ? SunburstShape.pressedShadow : Offset.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isPressed
              ? colours.accentFor(GameAccent.falseLight, GameColourRole.deep)
              : colours.surfaceRaised,
          borderRadius: BorderRadius.all(shape.miniTileRadius),
          border: Border.all(
            color: colours.border,
            width: shape.miniTileBorderWidth,
          ),
          // THROUGH THE THEME'S ONE FACTORY. `shadow()` hardcodes zero blur
          // and zero spread, and `sunburst_shape_test` asserts it is the only
          // BoxShadow constructor in lib/ — which is how the blur stays out by
          // construction rather than by review.
          boxShadow: isPressed ? null : shape.shadow(shape.e1, colours.border),
        ),
      ),
    );
  }
}
