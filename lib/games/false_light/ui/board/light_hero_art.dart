import 'package:flutter/material.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
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
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      // MIN, so the row is four chips wide and not the hero wide.
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < chips.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: SunburstShape.space2),
          _Chip(isPressed: chips[i]),
        ],
      ],
    ),
  );
}

/// One chip: a tile at rest, or a tile pressed.
class _Chip extends StatelessWidget {
  const _Chip({required this.isPressed});

  final bool isPressed;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    return Transform.translate(
      offset: isPressed ? SunburstShape.pressedShadow : Offset.zero,
      child: Container(
        width: shape.heroSwatchSize,
        height: shape.heroSwatchSize,
        decoration: BoxDecoration(
          color: isPressed
              ? colours.accentFor(GameAccent.falseLight, GameColourRole.deep)
              : colours.surfaceRaised,
          borderRadius: BorderRadius.all(shape.radiusSm),
          border: Border.all(color: colours.border, width: shape.borderWidth),
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
