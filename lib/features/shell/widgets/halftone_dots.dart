import 'package:flutter/widgets.dart';

/// Where a ray sweep radiates from.
///
/// Two origins, because the design uses two: a header's burst is centred on a
/// point well ABOVE the strip so only its lower fan shows, and the countdown's
/// fills the screen from the middle. Neither follows the reading direction.
enum RayOrigin {
  /// `app.html`: `.hdr .rays{left:50%;top:-330px;width:720px;height:720px}`.
  aboveTop,

  /// `app.html`: `.count .rays{left:50%;top:50%;width:1000px;height:1000px}`.
  centre,
}

/// The dot lattice and ray sweep behind a header, as one value.
///
/// A value type so the painter's `shouldRepaint` is one comparison rather than
/// seven, and so a scene can be compared in a test without reaching into the
/// painter.
///
/// **Both layers are optional and neither has a "draw it at zero alpha" path.**
/// Stats has dots and no rays; the countdown has a burst and no dots. Leaving
/// the colour out is what removes the layer, so an absent texture costs
/// nothing per frame.
@immutable
final class HalftoneScene {
  /// Creates a scene.
  const HalftoneScene({
    required this.ink,
    required this.ray,
    this.origin = RayOrigin.aboveTop,
    this.spokeDegrees = 5,
    this.pitchDegrees = 12,
    this.pitch = 15,
    this.dotRadius = 1.6,
  });

  /// The dot colour, **alpha already applied**, or `null` for no lattice.
  ///
  /// `SunburstColors.headerDots` carries it. Applying an opacity here would be
  /// the raw-value rule the token gates enforce, and a texture's strength is a
  /// design decision rather than something a painter should be free to tune.
  final Color? ink;

  /// The ray colour, alpha already applied, or `null` for no sweep.
  ///
  /// There is a slot per header, because the three headers deliberately differ:
  /// `.5` on Home, none on Stats, `.3` on Settings, `.55` on Results.
  final Color? ray;

  /// Where the sweep radiates from.
  final RayOrigin origin;

  /// How many degrees of each wedge are painted.
  ///
  /// `app.html`: `repeating-conic-gradient(... 0deg 5deg, transparent 5deg
  /// 12deg)` — a 5-degree spoke every 12.
  final double spokeDegrees;

  /// The angle between spoke starts.
  final double pitchDegrees;

  /// The lattice spacing. `app.html`: `background-size:15px 15px`.
  final double pitch;

  /// The dot radius. `app.html`: `radial-gradient(var(--ink) 1.6px, ...)`.
  final double dotRadius;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HalftoneScene &&
          other.ink == ink &&
          other.ray == ray &&
          other.origin == origin &&
          other.spokeDegrees == spokeDegrees &&
          other.pitchDegrees == pitchDegrees &&
          other.pitch == pitch &&
          other.dotRadius == dotRadius;

  @override
  int get hashCode => Object.hash(
    ink,
    ray,
    origin,
    spokeDegrees,
    pitchDegrees,
    pitch,
    dotRadius,
  );
}

/// Paints the ray sweep and the dot lattice behind a header.
///
/// **Neither mirrors.** The rays radiate from a fixed origin and the lattice is
/// a texture; both are properties of one imaginary light source for the whole
/// app, exactly like the hard offset shadow. Mirroring them would light the
/// Persian build from the other side for no reason a reader could name.
///
/// The `Paint`s are built once in the constructor and never inside `paint()`,
/// which is what `check_painter_hygiene.sh` exists to catch: this painter runs
/// behind a header that repaints on every scroll frame.
class HalftonePainter extends CustomPainter {
  /// Creates a painter for [scene].
  HalftonePainter(this.scene)
    : _dot = scene.ink == null ? null : (Paint()..color = scene.ink!),
      _ray = scene.ray == null ? null : (Paint()..color = scene.ray!);

  /// What to paint.
  final HalftoneScene scene;

  final Paint? _dot;
  final Paint? _ray;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..clipRect(Offset.zero & size);

    final ray = _ray;
    if (ray != null) {
      // The header origin sits `top:-330` inside a 720 box, so the sweep
      // centre is well above the strip and only its lower fan shows.
      final origin = switch (scene.origin) {
        RayOrigin.aboveTop => Offset(size.width / 2, -330 + 360),
        RayOrigin.centre => Offset(size.width / 2, size.height / 2),
      };
      final reach = size.width + size.height * 2;

      for (var start = 0.0; start < 360; start += scene.pitchDegrees) {
        final path = Path()
          ..moveTo(origin.dx, origin.dy)
          ..arcTo(
            Rect.fromCircle(center: origin, radius: reach),
            _radians(start),
            _radians(scene.spokeDegrees),
            false,
          )
          ..close();

        canvas.drawPath(path, ray);
      }
    }

    final dot = _dot;
    if (dot != null) {
      for (var y = 0.0; y < size.height; y += scene.pitch) {
        for (var x = 0.0; x < size.width; x += scene.pitch) {
          canvas.drawCircle(Offset(x, y), scene.dotRadius, dot);
        }
      }
    }

    canvas.restore();
  }

  static double _radians(double degrees) => degrees * 3.141592653589793 / 180;

  @override
  bool shouldRepaint(HalftonePainter old) => old.scene != scene;
}
