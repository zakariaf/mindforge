import 'package:flutter/material.dart';
import 'package:mindforge/games/false_light/ui/board/light_swatch.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

/// The four chips under the tagline on False Light's detail screen.
///
/// **A DIFFERENT DRAWING from the Home-card tile**, for the reason
/// `SchulteHeroArt` records: the tile sizes itself to whatever frame it is
/// given, and reusing it in a column with an unbounded height let it stand
/// three hundred points tall and push the Play button below the fold.
///
/// Where Stroop's row is the four answer patterns and Digit Bridge's is the two
/// numbering systems, this one is **the legend for the only channel the board
/// has**: raised, raised, pressed, raised. A player meets the difference here,
/// on a screen with no clock running, at chip size rather than at tile size —
/// which is the whole argument for the detail screen existing.
class LightHeroArt extends StatelessWidget {
  /// Creates the row.
  const LightHeroArt({super.key});

  /// Which chips are pressed, in order.
  static const List<bool> chips = <bool>[false, false, true, false];

  @override
  Widget build(BuildContext context) {
    final shape = SunburstShape.of(context);

    return ExcludeSemantics(
      child: Row(
        // MIN, so the row is four chips wide and not the hero wide.
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var i = 0; i < chips.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: SunburstShape.space2),
            LightSwatch(
              isPressed: chips[i],
              radius: shape.heroSwatchRadius,
              borderWidth: shape.borderWidth,
              shadow: shape.heroSwatchShadow,
              size: shape.heroSwatchSize,
            ),
          ],
        ],
      ),
    );
  }
}
