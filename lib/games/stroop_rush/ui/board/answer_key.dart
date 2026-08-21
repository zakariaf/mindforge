import 'package:flutter/material.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_board_state.dart';
import 'package:mindforge/games/stroop_rush/ui/board/play_fill.dart';
import 'package:mindforge/games/stroop_rush/ui/board/play_fill_painter.dart';
import 'package:mindforge/shared/motion/shake_on_wrong.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

/// One answer key: a pattern panel, a colour word, and four states.
///
/// **Every state is separated by at least three non-hue channels**, because the
/// fill never changes: a key is its answer's colour in every state, and a wrong
/// key painted `danger` would erase the very thing the player is answering
/// about. What changes is elevation, translation and the ink strike bar.
///
/// | state | elevation | translate | strike bar |
/// |---|---|---|---|
/// | idle | e2 | none | no |
/// | accepted | e3 | none | no |
/// | rejected | flat | (2, 2) | yes |
/// | locked | flat | none | no |
///
/// A resolved key **drops its `onTap`** rather than passing `enabled: false`:
/// the disabled shape swaps the fill to `surfaceSunk`, which would erase the
/// answer (`sunburst-components` rule 6).
class StroopAnswerKey extends StatelessWidget {
  /// Creates a key.
  const StroopAnswerKey({
    required this.answer,
    required this.label,
    required this.state,
    required this.isColourBlindPalette,
    required this.wrongTapId,
    required this.onTap,
    super.key,
  });

  /// Which answer this key is.
  final PlayAnswer answer;

  /// The already-resolved colour word.
  final String label;

  /// What the key is showing.
  final AnswerKeyState state;

  /// Whether the run was dealt for the colour-blind palette.
  final bool isColourBlindPalette;

  /// A value that changes on every wrong tap.
  ///
  /// Keys the shake, so tapping the same wrong key twice shakes twice.
  final int wrongTapId;

  /// What a tap does, or `null` once the key is resolved.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    final (
      PopElevation elevation,
      Offset translate,
      bool isStruck,
    ) = switch (state) {
      AnswerKeyState.idle => (PopElevation.e2, Offset.zero, false),
      AnswerKeyState.accepted => (PopElevation.e3, Offset.zero, false),
      // SUNK, not greyed. The translate is toward the shadow — the same
      // travel a press makes — and it holds there.
      AnswerKeyState.rejected => (
        PopElevation.flat,
        SunburstShape.pressedShadow,
        true,
      ),
      AnswerKeyState.locked => (PopElevation.flat, Offset.zero, false),
    };

    final key = Transform.translate(
      offset: translate,
      child: PopSurface(
        // THE ANSWER'S OWN COLOUR, IN EVERY STATE. Painting a wrong key
        // `danger` would recolour the thing the question is about.
        fill: colours.answerColour(
          answer,
          colourBlind: isColourBlindPalette,
        ),
        radius: BorderRadiusDirectional.all(shape.radiusLg),
        elevation: elevation,
        onTap: onTap,
        semanticLabel: label,
        // NO HEIGHT OF ITS OWN. The grid sets `mainAxisExtent`, which is the
        // height the FIELD negotiated and can be as low as the 48pt tap floor
        // on a cramped screen. A SizedBox restating the token here was either
        // a no-op or silently clamped away, and a reader could not tell which
        // number won.
        // INSET BY THE EDGE AND CLIPPED TO IT. `PopSurface` paints its border
        // as a `BoxDecoration` behind its child and does not clip — so a child
        // that fills the surface paints straight over the ink edge and out to
        // the square corners. The pattern panel is exactly such a child: it
        // reached the start edge with no border and no shadow, while the label
        // half kept both, and the key looked cut in two.
        child: Padding(
          padding: EdgeInsetsDirectional.all(shape.borderWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.all(
              // The INNER curve: the outer radius less the edge it sits
              // inside, or the clip crosses the border on the diagonal.
              Radius.circular(shape.radiusLg.x - shape.borderWidth),
            ),
            child: Stack(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _PatternPanel(
                      answer: answer,
                      isColourBlindPalette: isColourBlindPalette,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: SunburstShape.space3,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) => Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            // THE STEP THAT FITS ON ONE LINE, chosen once, the
                            // same two-step rule the stimulus uses. `پرتەقاڵی`
                            // beside a 56pt panel does not fit at the full step
                            // on a 390pt phone; a smaller step reads better than
                            // a colour word broken across two lines.
                            style:
                                _fits(context, label, type.button, constraints)
                                ? type.button.copyWith(
                                    // FROM THE PALETTE, not the call site: ink
                                    // on yellow and paper on everything else,
                                    // and the palette is the only thing that
                                    // knows which.
                                    color: colours.answerLabel(answer),
                                  )
                                : type.buttonCompact.copyWith(
                                    color: colours.answerLabel(answer),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isStruck)
                  // FULL WIDTH IN BOTH DIRECTIONS. `start: 0, end: 0` rather
                  // than a width, so it never becomes a half-bar under RTL.
                  PositionedDirectional(
                    start: 0,
                    end: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: ColoredBox(
                        color: colours.border,
                        child: SizedBox(
                          height: shape.answerStrikeHeight,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    // E06'S WIDGET, WIRED — never a per-game copy. The two explicit forward
    // passes, the disposal and the reduce-motion collapse are all asserted in
    // its own test; what this file owns is the key that identifies one wrong
    // tap from the next.
    return ShakeOnWrong(
      key: ValueKey<int>(wrongTapId),
      isWrong: state == AnswerKeyState.rejected,
      child: key,
    );
  }

  /// Whether [label] draws on one line at [style] inside [constraints].
  ///
  /// Measured rather than estimated: the answer differs per script, per face
  /// and per text scale, and laying it out is the only honest way to ask.
  bool _fits(
    BuildContext context,
    String label,
    TextStyle style,
    BoxConstraints constraints,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final fits = painter.width <= constraints.maxWidth;

    painter.dispose();

    return fits;
  }
}

/// The 56pt pattern block at the key's START edge.
class _PatternPanel extends StatelessWidget {
  const _PatternPanel({
    required this.answer,
    required this.isColourBlindPalette,
  });

  final PlayAnswer answer;
  final bool isColourBlindPalette;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    return ExcludeSemantics(
      child: Container(
        width: shape.answerKeyPanelWidth,
        height: double.infinity,
        decoration: BoxDecoration(
          border: BorderDirectional(
            // CLOSED BY AN INK DIVIDER on its end side, which is what makes
            // the panel read as a swatch rather than as a stain on the key.
            end: BorderSide(color: colours.border, width: shape.borderWidth),
          ),
        ),
        // ITS OWN LAYER, so a key that presses or shakes does not re-rasterise
        // its pattern panel. The panel never changes; the transform above it
        // does. `check_painter_hygiene.sh` warns without this.
        child: RepaintBoundary(
          child: CustomPaint(
            painter: PlayFillPainter(
              PlayFillScene(
                fill: answer.fill,
                hue: colours.answerColour(
                  answer,
                  colourBlind: isColourBlindPalette,
                ),
                ink: colours.border,
                geometry: PlayFillGeometry.of(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
