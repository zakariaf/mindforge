import 'package:flutter/material.dart';
import 'package:mindforge/games/false_light/ui/board/light_swatch.dart';
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
              LightSwatch(
                isPressed: pressed.contains(i),
                radius: shape.miniTileRadius,
                borderWidth: shape.miniTileBorderWidth,
                shadow: shape.heroSwatchShadow,
              ),
          ],
        ),
      ),
    );
  }
}
