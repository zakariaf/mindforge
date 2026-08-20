import 'package:flutter/widgets.dart';

/// The double ring around the tile the player is hunting.
///
/// `app.html`: `.tile.next{box-shadow:...,0 0 0 2px var(--cream),0 0 0 5px
/// var(--ink)}` — a cream band with an ink band outside it. Painted rather than
/// expressed as two spread shadows, because the house rule is that every
/// `BoxShadow` in the app has blur and spread at zero and comes from one
/// helper: a ring is not a shadow, and dressing it as one would put a second
/// meaning on the app's most load-bearing token.
///
/// **It reads no direction.** Two concentric rounded rects have no start and no
/// end edge, so this looks identical in `fa` as in `en` — which is what the
/// direction test asserts on values rather than on a golden.
@immutable
class NextRingPainter extends CustomPainter {
  /// Creates the ring painter.
  NextRingPainter({
    required this.inner,
    required this.outer,
    required this.innerColour,
    required this.outerColour,
    required this.radius,
  }) : _inner = Paint()
         ..color = innerColour
         ..style = PaintingStyle.stroke
         ..strokeWidth = inner,
       _outer = Paint()
         ..color = outerColour
         ..style = PaintingStyle.stroke
         ..strokeWidth = outer - inner;

  /// How wide the cream band is.
  final double inner;

  /// Where the ink band ends, measured from the tile's edge.
  final double outer;

  /// The cream band's colour.
  final Color innerColour;

  /// The ink band's colour.
  final Color outerColour;

  /// The tile's own corner, which the rings follow.
  final double radius;

  final Paint _inner;
  final Paint _outer;

  @override
  void paint(Canvas canvas, Size size) {
    final tile = Offset.zero & size;

    // Stroked rects are centred on their path, so each band is inflated by
    // half its own width to sit OUTSIDE the tile rather than over it.
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          tile.inflate(inner / 2),
          Radius.circular(radius + inner / 2),
        ),
        _inner,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          tile.inflate(inner + (outer - inner) / 2),
          Radius.circular(radius + inner + (outer - inner) / 2),
        ),
        _outer,
      );
  }

  @override
  bool shouldRepaint(NextRingPainter oldDelegate) =>
      oldDelegate.inner != inner ||
      oldDelegate.outer != outer ||
      oldDelegate.innerColour != innerColour ||
      oldDelegate.outerColour != outerColour ||
      oldDelegate.radius != radius;
}
