import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/halftone_dots.dart';

/// The app's mark, at any size.
///
/// **A sunburst behind four chunky keys**, which is the app in one picture: the
/// ray sweep is the design direction's own signature — it is what every header
/// in the app is built on — and the 2x2 is the shape both games already speak
/// in, Stroop Rush's four answer keys and Schulte Grid's grid.
///
/// The first version of this was the wordmark's tile scaled up: a coral square
/// with a cream square inside it. At icon size that reads as a blank swatch
/// rather than as a mark, which is what it looked like on the home screen.
///
/// **The four colours are the app's ACCENTS, not its play palette.** Sunshine,
/// coral, turquoise and grape are the four surfaces a player already knows —
/// the primary, Stroop, Schulte and Settings — and they are chrome, so working
/// agreement 3 holds: the gameplay tier is what the colour-blind swap
/// re-points, and none of it appears here.
///
/// It lives in `lib/ui/` rather than in `tool/` so it reads the shipped tokens.
/// An icon exported by hand drifts from the palette the moment one moves, and
/// nothing notices until the icon on the home screen is a coral the app has
/// stopped using.
///
/// **Everything is a fraction of the side**, so one widget renders every size
/// iOS asks for, from 1024 down to 20.
class AppIconMark extends StatelessWidget {
  /// Creates the mark.
  const AppIconMark({super.key});

  /// The four accents, in reading order.
  static const List<GameAccent?> quadrants = <GameAccent?>[
    null, // sunshine, the app's own primary
    GameAccent.stroop,
    GameAccent.schulte,
    null, // grape, resolved below — Settings' colour
  ];

  /// How much of the side the quad spans.
  ///
  /// DERIVED. Large enough that four keys still read at 20pt, small enough to
  /// leave the burst a visible margin on all four sides.
  static const double quadShare = 0.62;

  /// The gap between keys, as a fraction of the side.
  static const double gapShare = 0.055;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final fills = <Color>[
          colours.accent,
          colours.accentFor(GameAccent.stroop, GameColourRole.base),
          colours.accentFor(GameAccent.schulte, GameColourRole.base),
          colours.accentAlt,
        ];

        return DecoratedBox(
          // OPAQUE, and painted rather than inherited. iOS rejects an app icon
          // with an alpha channel, and that rejection arrives at upload rather
          // than at build.
          decoration: BoxDecoration(color: colours.surface),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // THE SIGNATURE, from the centre — a burst, not a header's fan.
              //
              // The band's coral rather than the countdown's grape: the
              // countdown paints its sweep ON grape, where it is a tonal
              // shift, and the same colour over cream is a loud purple that
              // fights four saturated keys for the eye.
              //
              // WIDER AND FEWER SPOKES than a header's 5-in-12. At 20pt the
              // header's pitch is finer than a pixel and reads as noise; this
              // is the same motif at a size that survives the smallest asset
              // iOS asks for.
              HalftoneLayer(
                scene: HalftoneScene(
                  ink: null,
                  ray: colours.bandRayStroop,
                  origin: RayOrigin.centre,
                  // 24 DIVIDES 360, which 22 does not: the loop starts a new
                  // spoke every pitch until it passes 360, so a pitch that
                  // leaves a remainder draws its last wedge overlapping the
                  // first and the burst has one double-width ray in it. It
                  // was visible at three o'clock.
                  spokeDegrees: 12,
                  pitchDegrees: 24,
                  pitch: SunburstShape.space4,
                ),
              ),
              Center(
                child: SizedBox.square(
                  dimension: side * quadShare,
                  child: _Quad(fills: fills, side: side),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The 2x2 of keys.
class _Quad extends StatelessWidget {
  const _Quad({required this.fills, required this.side});

  final List<Color> fills;
  final double side;

  @override
  Widget build(BuildContext context) {
    final gap = side * AppIconMark.gapShare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var row = 0; row < 2; row++) ...<Widget>[
          if (row > 0) SizedBox(height: gap),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (var column = 0; column < 2; column++) ...<Widget>[
                  if (column > 0) SizedBox(width: gap),
                  Expanded(
                    child: _Key(fill: fills[row * 2 + column], side: side),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// One key: a fill, an ink edge and the hard offset.
class _Key extends StatelessWidget {
  const _Key({required this.fill, required this.side});

  final Color fill;
  final double side;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.all(
          // The card radius, at the mark's own scale rather than in points:
          // a fixed 16 would be a pill at 20pt and a hairline at 1024.
          Radius.circular(side * 0.085),
        ),
        border: Border.all(
          color: colours.border,
          // DERIVED, and thinner than it first was: at 0.028 the edge and the
          // shadow met around the corners and each key read as a dark blob
          // with a colour in the middle.
          width: side * 0.019,
        ),
        boxShadow: shape.shadow(
          // The hard offset, scaled. It does not mirror and it does not blur.
          Offset(side * 0.018, side * 0.018),
          colours.border,
        ),
      ),
    );
  }
}
