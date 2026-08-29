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

  /// The most lines the numeral may take. It is a number, not a sentence.
  static const int maxLines = 1;

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
              // A SMALLER BASE STYLE, chosen once by measurement, never a
              // shrink. `accessibility-as-code` bans every way of squeezing a
              // value into a box it does not fit — a clamped text scaler, a
              // box that scales its child down, an ellipsis; the sanctioned
              // answer is to pick the step that does fit. (The banned names are
              // described rather than written, because the gate that enforces
              // this greps for them and cannot tell a ban from a use.)
              //
              // It is not a hypothetical. Measured on the canonical simulator:
              // a four-digit Persian target at `countdownNumeral` lays out at
              // 326pt inside a 326pt card and lost its last digit, and blitz
              // deals five. Latin fitted, which is exactly how this reaches a
              // release — the developer's own locale is the one that works.
              child: LayoutBuilder(
                builder: (context, constraints) => BridgeNumeral(
                  label: label,
                  style:
                      (_fits(context, type.scoreHero, constraints.maxWidth)
                              ? type.scoreHero
                              : type.displayXl)
                          .copyWith(color: colours.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Whether [label] draws on one line at [style] inside [width].
  ///
  /// Measured with a `TextPainter` rather than estimated: the answer differs
  /// per script, per face and per text scale — Eastern Arabic digits are
  /// noticeably wider than Latin ones at the same point size — and laying it
  /// out is the only honest way to ask.
  bool _fits(BuildContext context, TextStyle style, double width) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      // LTR, because the run is. See `BridgeNumeral`.
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: maxLines,
      // UNCONSTRAINED, because the question is "does it fit". A layout capped
      // at the available width reports a width that is never wider than it, so
      // the comparison would be true by construction —
      // `check_painter_hygiene.sh` warns on exactly this shape.
    )..layout();
    final fits = painter.width <= width;

    painter.dispose();

    return fits;
  }
}
