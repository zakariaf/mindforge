import 'package:flutter/material.dart';
import 'package:mindforge/games/stroop_rush/ui/board/play_fill.dart';
import 'package:mindforge/games/stroop_rush/ui/board/play_fill_painter.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

/// The four chips under the tagline on Stroop Rush's detail screen.
///
/// `app.html`: `.swatchrow i` — four 38pt chips in a row, each with the full
/// 3pt ink edge and a 2pt hard offset.
///
/// **They carry the PATTERN, not just the hue, and that is the whole point.**
/// This row is the legend for the second channel: a player meets stripe, solid,
/// dot and ring here, on a screen with no clock running, rather than having to
/// work them out mid-round. The Home card's tile is a different drawing — a 2x2
/// of plain quads inside a cream frame — and the two are not interchangeable,
/// which is why a definition builds each of them separately.
///
/// **It sizes itself.** The hero hands its child whatever width the column has;
/// a widget that expanded into that grew to seven hundred points tall and lost
/// its patterns, which is what shipped before the reference comparison.
///
/// It lives under `board/` for the same reason the Home tile does — it reads
/// the gameplay tier, and `check_game_palette.sh` allows that here.
class StroopHeroSwatches extends StatelessWidget {
  /// Creates the row.
  const StroopHeroSwatches({super.key});

  /// The four answers, in the order `app.html` lays them out.
  ///
  /// The DEFAULT palette. The detail screen is not a run, so there is no round
  /// whose palette it could honour — and the colour-blind swap re-points hues
  /// while leaving every pattern where it is, which is exactly what the row is
  /// here to show.
  static const List<PlayAnswer> swatches = <PlayAnswer>[
    PlayAnswer.red,
    PlayAnswer.blue,
    PlayAnswer.green,
    PlayAnswer.yellow,
  ];

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        // MIN, so the row is four chips wide and not the hero wide.
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final answer in swatches) ...<Widget>[
            if (answer != swatches.first)
              const SizedBox(width: SunburstShape.space2),
            _Swatch(answer: answer),
          ],
        ],
      ),
    );
  }
}

/// One chip.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.answer});

  final PlayAnswer answer;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final radius = BorderRadius.all(shape.heroSwatchRadius);

    return Container(
      width: shape.heroSwatchSize,
      height: shape.heroSwatchSize,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: colours.border, width: shape.borderWidth),
        // THROUGH THE THEME'S OWN HELPER, which is the one place a BoxShadow
        // is constructed in lib/: no blur, no spread, and it does not mirror.
        boxShadow: shape.shadow(shape.heroSwatchShadow, colours.border),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: CustomPaint(
          painter: PlayFillPainter(
            PlayFillScene(
              fill: answer.fill,
              hue: colours.answerColour(answer),
              ink: colours.border,
              geometry: PlayFillGeometry.of(context),
            ),
          ),
        ),
      ),
    );
  }
}
