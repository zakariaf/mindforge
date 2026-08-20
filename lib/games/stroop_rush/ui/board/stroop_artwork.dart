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
    return ExcludeSemantics(
      // NOT A GRIDVIEW, and not for tidiness. A scroll viewport resolves its
      // own constraints, and on the canonical simulator this one laid the
      // quads out below the 48pt frame and clipped them — the tile drew as an
      // empty cream square with two dark slivers at its bottom edge, while
      // every widget test of it passed. Four fixed boxes need no viewport, no
      // delegate and no physics; two rows of two fill whatever they are given.
      // SQUARE ON ITS OWN TERMS. The frame centres its child, which hands
      // this one LOOSE constraints — and a Column of Expanded rows under a
      // loose height resolves to nothing. AspectRatio takes the width it is
      // offered and states the height, which is true of the tile anyway.
      child: AspectRatio(
        aspectRatio: 1,
        child: Column(
          // STRETCH, or the rows take their minimum width — which for a Row of
          // Expanded children is zero, and the tile draws nothing at all.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(child: _QuadRow(answers: quads.sublist(0, 2))),
            const SizedBox(height: SunburstShape.space1),
            Expanded(child: _QuadRow(answers: quads.sublist(2))),
          ],
        ),
      ),
    );
  }
}

/// One row of the 2x2.
class _QuadRow extends StatelessWidget {
  const _QuadRow({required this.answers});

  final List<PlayAnswer> answers;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    return Row(
      // STRETCH on this axis too. Expanded bounds the WIDTH; the height stays
      // loose, and a DecoratedBox with no child collapses to nothing under a
      // loose constraint — which draws two hairlines instead of two swatches.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final answer in answers) ...<Widget>[
          if (answer != answers.first)
            const SizedBox(width: SunburstShape.space1),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colours.answerColour(answer),
                borderRadius: BorderRadius.all(shape.paletteSwatchRadius),
                border: Border.all(
                  color: colours.border,
                  width: shape.borderWidthNested,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
