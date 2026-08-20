import 'package:flutter/material.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

/// The 64pt tile on Stroop Rush's Home card.
///
/// Four quads in the four default answer hues. `app.html`: `.gart .quad i` —
/// a 2x2 grid, 5pt radius, a 2pt ink edge.
///
/// **It does not mirror**, and that is a decision rather than an oversight: the
/// quads are a fixed ornament with no reading order, so there is nothing in
/// them for a direction to be about. The FRAME around it is the card's and
/// mirrors with the card.
///
/// **It lives under `board/`, and that is E09's answer to the epic's Risk 1.**
/// The tile reads the gameplay palette while being painted outside the board
/// rectangle, and `check_game_palette.sh` refuses that anywhere else — rightly,
/// because a gameplay colour that becomes chrome is a hint the colour-blind
/// swap would then re-point.
///
/// The directory marks the files ALLOWED TO READ THE GAMEPLAY TIER, not the
/// files painted inside the rectangle, and this one qualifies on the substance:
/// it draws four ANSWERS, which is board vocabulary, and no accent, status or
/// state. Filing it here rather than widening the gate keeps the rule strict —
/// a file that wanted `danger` or `success` would still be refused, and
/// `stroop_artwork_test` asserts this one reads nothing but `answerColour`.
class StroopArtwork extends StatelessWidget {
  /// Creates the tile.
  const StroopArtwork({super.key});

  /// The four answers the tile shows, in reading order.
  ///
  /// The DEFAULT palette, never the colour-blind one: the Home card is not
  /// inside a run, so there is no round whose palette it could honour, and
  /// reading the live setting here would make the tile change under a player
  /// who has not started anything.
  static const List<PlayAnswer> quads = <PlayAnswer>[
    PlayAnswer.red,
    PlayAnswer.blue,
    PlayAnswer.green,
    PlayAnswer.yellow,
  ];

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    return ExcludeSemantics(
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: SunburstShape.space1,
        mainAxisSpacing: SunburstShape.space1,
        children: <Widget>[
          for (final answer in quads)
            DecoratedBox(
              decoration: BoxDecoration(
                color: colours.answerColour(answer),
                borderRadius: BorderRadius.all(shape.paletteSwatchRadius),
                border: Border.all(
                  color: colours.border,
                  width: shape.borderWidthNested,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
