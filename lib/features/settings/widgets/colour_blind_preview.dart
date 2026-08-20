import 'package:flutter/material.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

/// The four colours the colour-blind setting swaps **in**.
///
/// **It shows the destination, not the current palette.** The row is an offer:
/// "these are the colours you would get". Previewing what is already on screen
/// would tell the player nothing about the choice.
///
/// It announces nothing — the row's label says what the setting does, and four
/// unnamed colour chips read as four unnamed colour chips.
class ColourBlindPreview extends StatelessWidget {
  /// Creates the preview.
  const ColourBlindPreview({super.key});

  /// One swatch's size. `app.html`: `.cbprev i{width:24px;height:16px}`.
  static const Size swatchSize = Size(24, 16);

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    return ExcludeSemantics(
      // A WRAP, not a Row. Four swatches at 24pt plus their gaps are 116 wide,
      // and on a 320pt screen the label column they sit under is 95 — measured
      // by the overflow matrix, at scale 1.0, in English. They wrap to a second
      // line rather than running off the card.
      child: Wrap(
        children: <Widget>[
          for (final colour in <Color>[
            colours.cbBlue,
            colours.cbYellow,
            colours.cbOrange,
            colours.cbPink,
          ])
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 5, bottom: 5),
              child: Container(
                width: swatchSize.width,
                height: swatchSize.height,
                decoration: BoxDecoration(
                  color: colour,
                  borderRadius: BorderRadius.all(shape.paletteSwatchRadius),
                  border: Border.all(
                    color: colours.border,
                    width: shape.borderWidthNested,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
