import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

/// The measured geometry a [PlayFill] is drawn with.
///
/// A value type carried into the painter rather than read from a `BuildContext`
/// inside `paint()`: a painter that reached for a theme would be reading it on
/// every frame, and `shouldRepaint` could not compare what it read.
@immutable
final class PlayFillGeometry {
  /// Creates the geometry.
  const PlayFillGeometry({
    required this.stripePitch,
    required this.stripeAngle,
    required this.dotPitch,
    required this.dotRadius,
    required this.ringPitch,
    required this.ringBandWidth,
  });

  /// The geometry the theme declares.
  ///
  /// ONE ADAPTER, not one per call site. The stimulus glyph and the answer
  /// key's panel draw the same four patterns and must draw them identically —
  /// a key whose stripes ran at a different pitch from the word's would break
  /// the match the second channel exists to make. Both used to assemble these
  /// six fields by hand, which is two places for a seventh pattern to be
  /// forgotten.
  factory PlayFillGeometry.of(BuildContext context) {
    final shape = SunburstShape.of(context);

    return PlayFillGeometry(
      stripePitch: shape.stripePitch,
      stripeAngle: shape.stripeAngle,
      dotPitch: shape.dotPitch,
      dotRadius: shape.dotRadius,
      ringPitch: shape.ringPitch,
      ringBandWidth: shape.ringBandWidth,
    );
  }

  /// Distance between stripe centres.
  final double stripePitch;

  /// Stripe angle, in degrees.
  final double stripeAngle;

  /// Distance between dot centres.
  final double dotPitch;

  /// One dot's radius.
  final double dotRadius;

  /// Distance between ring centres.
  final double ringPitch;

  /// One ring's painted width.
  final double ringBandWidth;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayFillGeometry &&
          other.stripePitch == stripePitch &&
          other.stripeAngle == stripeAngle &&
          other.dotPitch == dotPitch &&
          other.dotRadius == dotRadius &&
          other.ringPitch == ringPitch &&
          other.ringBandWidth == ringBandWidth;

  @override
  int get hashCode => Object.hash(
    stripePitch,
    stripeAngle,
    dotPitch,
    dotRadius,
    ringPitch,
    ringBandWidth,
  );
}

/// Paints [fill]'s ink pattern over [bounds].
///
/// **The INK half only.** `system.html` §03 states each pattern as a gradient
/// between the play colour and ink; the play colour is already on the surface
/// by the time this runs, so this draws what ink adds. [PlayFill.solid] adds
/// nothing, and that is the whole of its implementation.
///
/// The pattern is the SECOND CHANNEL, not decoration. Red and green collapse to
/// the same olive under deuteranopia and to the same grey in a screenshot;
/// stripe and dot never do.
///
/// **Two paints, because the three patterns need two styles.** Stripes and
/// rings are strokes and dots are fills; one paint would draw hollow dots or
/// solid stripes, and switching a paint's style inside `paint()` is a mutation
/// of a shared object that the next frame inherits.
///
/// Every `Paint` is passed in. Nothing here allocates, because this runs inside
/// a `paint()` that runs on every frame of a shake.
void paintPlayFill(
  Canvas canvas,
  Rect bounds,
  PlayFill fill, {
  required Paint inkStroke,
  required Paint inkFill,
  required PlayFillGeometry geometry,
}) {
  switch (fill) {
    case PlayFill.solid:
      // Nothing. A solid answer's second channel is the ABSENCE of a pattern,
      // which is as distinguishable as any of the other three.
      return;
    case PlayFill.stripe:
      _paintStripes(canvas, bounds, inkStroke, geometry);
    case PlayFill.dot:
      _paintDots(canvas, bounds, inkFill, geometry);
    case PlayFill.ring:
      _paintRings(canvas, bounds, inkStroke, geometry);
  }
}

void _paintStripes(
  Canvas canvas,
  Rect bounds,
  Paint ink,
  PlayFillGeometry geometry,
) {
  final radians = geometry.stripeAngle * math.pi / 180;
  final step = geometry.stripePitch / math.cos(radians);
  // Hoisted out of the loop: a transcendental per stripe per frame is real
  // work on a glyph that shakes twice per wrong answer.
  final lean = bounds.height * math.tan(radians);

  for (
    var x = bounds.left - bounds.height;
    x < bounds.right + bounds.height;
    x += step
  ) {
    canvas.drawLine(
      Offset(x, bounds.bottom),
      Offset(x + lean, bounds.top),
      ink,
    );
  }
}

void _paintDots(
  Canvas canvas,
  Rect bounds,
  Paint ink,
  PlayFillGeometry geometry,
) {
  for (var y = bounds.top; y < bounds.bottom; y += geometry.dotPitch) {
    for (var x = bounds.left; x < bounds.right; x += geometry.dotPitch) {
      canvas.drawCircle(Offset(x, y), geometry.dotRadius, ink);
    }
  }
}

void _paintRings(
  Canvas canvas,
  Rect bounds,
  Paint ink,
  PlayFillGeometry geometry,
) {
  final centre = bounds.center;
  final reach = bounds.longestSide;

  for (
    var radius = geometry.ringPitch;
    radius < reach;
    radius += geometry.ringPitch
  ) {
    canvas.drawCircle(centre, radius, ink);
  }
}
