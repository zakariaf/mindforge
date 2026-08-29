import 'package:flutter/material.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

/// One tile of False Light, drawn small enough to be a picture of the game.
///
/// **The board's three channels at a fraction of the size**: fill value, hard
/// shadow, and position. A swatch that showed only the fill would be
/// advertising a colour game, which is the one thing this game is not.
///
/// Shared by the Home-card artwork and the detail screen's legend. They differ
/// only in scale and in which shape tokens they take, and both had a verbatim
/// copy of this construction — including the same four-line comment — before
/// this widget existed.
class LightSwatch extends StatelessWidget {
  /// Creates a swatch.
  const LightSwatch({
    required this.isPressed,
    required this.radius,
    required this.borderWidth,
    required this.shadow,
    this.size,
    super.key,
  });

  /// Whether this swatch shows a pressed tile.
  final bool isPressed;

  /// The corner radius at this scale.
  final Radius radius;

  /// The ink edge's width at this scale.
  final double borderWidth;

  /// The hard offset a raised swatch draws, and a pressed one moves into.
  ///
  /// Passed rather than read from a token here, because the two call sites are
  /// at genuinely different scales: a 64pt card tile and a 38pt hero chip take
  /// different offsets, and `SunburstShape` names both.
  final Offset shadow;

  /// A fixed side, or `null` to fill whatever the parent gives.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    return Transform.translate(
      offset: isPressed ? shadow : Offset.zero,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isPressed
              ? colours.accentFor(GameAccent.falseLight, GameColourRole.deep)
              : colours.surfaceRaised,
          borderRadius: BorderRadius.all(radius),
          border: Border.all(color: colours.border, width: borderWidth),
          // THROUGH THE THEME'S ONE FACTORY. `shadow()` hardcodes zero blur and
          // zero spread, and `sunburst_shape_test` asserts it is the only
          // `BoxShadow` constructor in `lib/` — which is how the blur stays out
          // by construction rather than by review.
          boxShadow: isPressed ? null : shape.shadow(shadow, colours.border),
        ),
      ),
    );
  }
}
