import 'package:flutter/widgets.dart';

/// The dot lattice and ray sweep behind a header, as one value.
///
/// A value type so the painter's `shouldRepaint` is one comparison rather than
/// five, and so a scene can be compared in a test without reaching into the
/// painter.
@immutable
final class HalftoneScene {
  /// Creates a scene.
  const HalftoneScene({
    required this.ink,
    required this.ray,
    this.pitch = 15,
    this.dotRadius = 1.6,
  });

  /// The dot colour, **alpha already applied**.
  ///
  /// `SunburstColors.headerDots` carries it. Applying an opacity here would be
  /// the raw-value rule the token gates enforce, and a texture's strength is a
  /// design decision rather than something a painter should be free to tune.
  final Color ink;

  /// The ray colour, alpha already applied. `SunburstColors.headerRay`.
  final Color ray;

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
          other.pitch == pitch &&
          other.dotRadius == dotRadius;

  @override
  int get hashCode => Object.hash(ink, ray, pitch, dotRadius);
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
    : _dot = Paint()..color = scene.ink,
      _ray = Paint()..color = scene.ray;

  /// What to paint.
  final HalftoneScene scene;

  final Paint _dot;
  final Paint _ray;

  /// How many degrees of each wedge are painted.
  ///
  /// `app.html`: `repeating-conic-gradient(... 0deg 5deg, transparent 5deg
  /// 12deg)` — a 5-degree spoke every 12.
  static const double _spokeDegrees = 5;

  /// The angle between spoke starts.
  static const double _pitchDegrees = 12;

  @override
  void paint(Canvas canvas, Size size) {
    // The origin: `left:50%; top:-330px` on a 720 box, so the sweep centre sits
    // well above the header and only its lower fan shows.
    final origin = Offset(size.width / 2, -330 + 360);
    final reach = size.width + size.height * 2;

    canvas
      ..save()
      ..clipRect(Offset.zero & size);

    for (var start = 0.0; start < 360; start += _pitchDegrees) {
      final path = Path()
        ..moveTo(origin.dx, origin.dy)
        ..arcTo(
          Rect.fromCircle(center: origin, radius: reach),
          _radians(start),
          _radians(_spokeDegrees),
          false,
        )
        ..close();

      canvas.drawPath(path, _ray);
    }

    for (var y = 0.0; y < size.height; y += scene.pitch) {
      for (var x = 0.0; x < size.width; x += scene.pitch) {
        canvas.drawCircle(Offset(x, y), scene.dotRadius, _dot);
      }
    }

    canvas.restore();
  }

  static double _radians(double degrees) => degrees * 3.141592653589793 / 180;

  @override
  bool shouldRepaint(HalftonePainter old) => old.scene != scene;
}
