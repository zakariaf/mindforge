import 'package:flutter/widgets.dart';

/// Strokes a rounded rectangle as a dashed ink edge.
///
/// The edge of a surface that is not yet real — a locked game, a slot waiting
/// to be filled. The dash pitch comes from the shape scale, not from here.
///
/// **The dash phase does not mirror.** The path is closed and is walked from a
/// fixed origin, so an `en` and an `fa` rendering are byte-identical. A dashed
/// edge is decoration, not a directional affordance: there is no "start" of a
/// rectangle for a reader to find, and rotating the phase per locale would
/// change the picture without changing what it says.
class DashedInkBorder extends CustomPainter {
  /// Creates a dashed border painter.
  DashedInkBorder({
    required this.radius,
    required this.colour,
    required this.strokeWidth,
    required this.dashOn,
    required this.dashOff,
  }) : _paint = Paint()
         ..color = colour
         ..style = PaintingStyle.stroke
         ..strokeWidth = strokeWidth;

  /// The corner radius to trace.
  final BorderRadius radius;

  /// The ink the dashes are drawn in.
  final Color colour;

  /// How thick each dash is.
  final double strokeWidth;

  /// The painted length of one dash.
  final double dashOn;

  /// The gap between dashes.
  final double dashOff;

  /// Built once in the constructor, never inside [paint].
  ///
  /// `paint()` runs on every frame of every press; allocating there is how a
  /// list of these turns into jank on a scroll.
  final Paint _paint;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..addRRect(radius.toRRect(Offset.zero & size).deflate(strokeWidth / 2));

    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;

      while (distance < metric.length) {
        final end = (distance + dashOn).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), _paint);
        distance = end + dashOff;
      }
    }
  }

  @override
  bool shouldRepaint(DashedInkBorder old) =>
      old.radius != radius ||
      old.colour != colour ||
      old.strokeWidth != strokeWidth ||
      old.dashOn != dashOn ||
      old.dashOff != dashOff;
}
