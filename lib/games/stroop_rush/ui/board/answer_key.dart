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
        child: SizedBox(
          height: shape.answerKeyHeight,
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
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: type.button.copyWith(
                          // FROM THE PALETTE, not the call site: ink on
                          // yellow and paper on everything else, and the
                          // palette is the only thing that knows which.
                          color: colours.answerLabel(answer),
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
        child: CustomPaint(
          painter: PlayFillPainter(
            PlayFillScene(
              fill: answer.fill,
              hue: colours.answerColour(
                answer,
                colourBlind: isColourBlindPalette,
              ),
              ink: colours.border,
              geometry: PlayFillGeometry(
                stripePitch: shape.stripePitch,
                stripeAngle: shape.stripeAngle,
                dotPitch: shape.dotPitch,
                dotRadius: shape.dotRadius,
                ringPitch: shape.ringPitch,
                ringBandWidth: shape.ringBandWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
