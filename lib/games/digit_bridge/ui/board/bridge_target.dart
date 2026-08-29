import 'package:flutter/material.dart';
import 'package:mindforge/games/digit_bridge/ui/board/bridge_numeral.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/halftone_dots.dart';

/// The numeral the player is looking for.
///
/// A raised cream card carrying one glyph run, the same construction Stroop
/// Rush's stimulus card uses — because it is the same thing: the question,
/// presented once, above the answers.
class BridgeTarget extends StatelessWidget {
  /// Creates the target card.
  const BridgeTarget({
    required this.label,
    required this.semanticLabel,
    super.key,
  });

  /// The numeral, already rendered in this round's target script.
  final String label;

  /// What a screen reader announces.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    return PopSurface(
      fill: colours.surfaceRaised,
      radius: BorderRadiusDirectional.all(shape.radiusXl),
      elevation: PopElevation.e3,
      minTarget: 0,
      padding: const EdgeInsetsDirectional.all(SunburstShape.space3),
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          // The card carries the board lattice at the board strength.
          // `app.html`: `.stim .dots{opacity:.14}`.
          Positioned.fill(
            child: HalftoneLayer(
              scene: HalftoneScene(
                ink: colours.boardDots,
                ray: null,
                pitch: kBoardDotPitch,
              ),
            ),
          ),
          Semantics(
            label: semanticLabel,
            child: ExcludeSemantics(
              child: BridgeNumeral(
                label: label,
                style: type.countdownNumeral.copyWith(
                  color: colours.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
