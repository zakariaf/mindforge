import 'package:flutter/widgets.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

/// Everything needed to draw one glyph.
///
/// A value, so [SunburstGlyphPainter.shouldRepaint] is a single comparison and
/// the painter holds no widget, no context and no direction.
@immutable
final class GlyphScene {
  /// Describes one drawn mark.
  const GlyphScene({
    required this.glyph,
    required this.colour,
    required this.strokeWidth,
  });

  /// Which mark.
  final SunburstGlyph glyph;

  /// The stroke, and the fill on the two filled marks.
  final Color colour;

  /// How thick the stroke is.
  final double strokeWidth;

  @override
  bool operator ==(Object other) =>
      other is GlyphScene &&
      other.glyph == glyph &&
      other.colour == colour &&
      other.strokeWidth == strokeWidth;

  @override
  int get hashCode => Object.hash(glyph, colour, strokeWidth);
}

/// Paints a [GlyphScene].
///
/// **The painter is direction-agnostic.** It never reads a `TextDirection` and
/// there is exactly one path per glyph; the RTL flip is a `Transform` applied
/// by `SunburstGlyphIcon`. Two paths per glyph would be two drawings to keep in
/// step, and a direction inside the scene would put it inside the repaint
/// comparison for no gain.
class SunburstGlyphPainter extends CustomPainter {
  /// Paints [scene].
  SunburstGlyphPainter(this.scene)
    : _stroke = Paint()
        ..color = scene.colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = scene.strokeWidth
        // Round caps and joins, per the SVG source in system.html §08. Square
        // terminals read as a different, harder icon family.
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
      _fill = Paint()
        ..color = scene.colour
        ..style = PaintingStyle.fill;

  /// What to draw.
  final GlyphScene scene;

  /// Built once in the constructor, never inside [paint].
  final Paint _stroke;
  final Paint _fill;

  /// The square every path below is authored in.
  ///
  /// Path coordinates are **artwork, not tokens**: they describe a drawing, not
  /// a design decision anyone would tune, so they live here rather than in
  /// `lib/theme/`.
  static const double _viewBox = 24;

  /// The two marks that are filled as well as stroked, per the source.
  static const Set<SunburstGlyph> _filled = <SunburstGlyph>{
    SunburstGlyph.go,
    SunburstGlyph.star,
  };

  /// Every glyph's path, in the 24x24 authoring box, built once at load.
  static final Map<SunburstGlyph, Path> _paths =
      <SunburstGlyph, Path>{
        SunburstGlyph.navPlay: _rounded(<Rect>[
          const Rect.fromLTWH(4, 4, 7, 7),
          const Rect.fromLTWH(13, 4, 7, 7),
          const Rect.fromLTWH(4, 13, 7, 7),
          const Rect.fromLTWH(13, 13, 7, 7),
        ]),
        SunburstGlyph.navStats: _bars(<double>[14, 8, 18, 11]),
        SunburstGlyph.navSettings: _settings(),
        SunburstGlyph.go: _polygon(<Offset>[
          const Offset(7, 4),
          const Offset(20, 12),
          const Offset(7, 20),
        ]),
        SunburstGlyph.back: _polyline(<Offset>[
          const Offset(15, 4),
          const Offset(7, 12),
          const Offset(15, 20),
        ]),
        SunburstGlyph.chevronForward: _polyline(<Offset>[
          const Offset(9, 4),
          const Offset(17, 12),
          const Offset(9, 20),
        ]),
        SunburstGlyph.pause: _rounded(<Rect>[
          const Rect.fromLTWH(7, 5, 3.5, 14),
          const Rect.fromLTWH(13.5, 5, 3.5, 14),
        ]),
        SunburstGlyph.close: _lines(<(Offset, Offset)>[
          (const Offset(6, 6), const Offset(18, 18)),
          (const Offset(18, 6), const Offset(6, 18)),
        ]),
        SunburstGlyph.sound: _sound(),
        SunburstGlyph.haptics: _haptics(),
        SunburstGlyph.motion: _clock(),
        SunburstGlyph.contrast: _contrast(),
        SunburstGlyph.language: _language(),
        SunburstGlyph.info: _info(),
        SunburstGlyph.lock: _lock(),
        SunburstGlyph.star: _star(),
        SunburstGlyph.flame: _flame(),
      }
      // Grown as an unmodifiable view, so nothing can add a path at runtime and
      // leave `SunburstGlyph.values` and this map disagreeing.
      .let(Map<SunburstGlyph, Path>.unmodifiable);

  /// The path for [glyph], in the authoring box.
  ///
  /// Public so a test can assert every enum value resolves to real artwork
  /// rather than to an empty path nobody would see fail.
  static Path pathFor(SunburstGlyph glyph) => _paths[glyph]!;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _viewBox;
    final path = _paths[scene.glyph]!;
    // Resolved before the canvas calls, and named. Written inline, the set
    // membership sat on the same line as the draw call, which
    // check_painter_hygiene cannot distinguish from the path hit test it bans
    // there — and it looked the same value up twice.
    final isFilled = _filled.contains(scene.glyph);

    canvas
      ..save()
      ..scale(scale)
      ..drawPath(path, isFilled ? _fill : _stroke);

    if (isFilled) {
      // Filled AND stroked, as in the source: the stroke is what gives the
      // filled marks the same weight as their outlined siblings.
      canvas.drawPath(path, _stroke);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(SunburstGlyphPainter old) => old.scene != scene;

  // --- artwork ---------------------------------------------------------------

  static Path _rounded(List<Rect> rects) {
    final path = Path();
    for (final rect in rects) {
      path.addRRect(RRect.fromRectXY(rect, 2, 2));
    }
    return path;
  }

  static Path _bars(List<double> heights) {
    final path = Path();
    for (var i = 0; i < heights.length; i++) {
      path.addRRect(
        RRect.fromRectXY(
          Rect.fromLTWH(4.5 + i * 4.5, 20 - heights[i], 3, heights[i]),
          1.5,
          1.5,
        ),
      );
    }
    return path;
  }

  static Path _polyline(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  static Path _polygon(List<Offset> points) => _polyline(points)..close();

  static Path _lines(List<(Offset, Offset)> segments) {
    final path = Path();
    for (final (from, to) in segments) {
      path
        ..moveTo(from.dx, from.dy)
        ..lineTo(to.dx, to.dy);
    }
    return path;
  }

  static Path _settings() => Path()
    ..moveTo(4, 8)
    ..lineTo(20, 8)
    ..moveTo(4, 16)
    ..lineTo(20, 16)
    ..addOval(Rect.fromCircle(center: const Offset(9, 8), radius: 2.6))
    ..addOval(Rect.fromCircle(center: const Offset(15, 16), radius: 2.6));

  /// A cone at the START edge with its waves at the END edge.
  ///
  /// Which is precisely why it mirrors: the drawing points along the reading
  /// direction, so in an RTL layout the cone belongs on the right.
  static Path _sound() => Path()
    ..moveTo(4, 9.5)
    ..lineTo(7.5, 9.5)
    ..lineTo(11.5, 5.5)
    ..lineTo(11.5, 18.5)
    ..lineTo(7.5, 14.5)
    ..lineTo(4, 14.5)
    ..close()
    ..addArc(
      Rect.fromCircle(center: const Offset(11.5, 12), radius: 5),
      -0.9,
      1.8,
    )
    ..addArc(
      Rect.fromCircle(center: const Offset(11.5, 12), radius: 8),
      -0.9,
      1.8,
    );

  static Path _haptics() => Path()
    ..addRRect(
      RRect.fromRectXY(const Rect.fromLTWH(8.5, 4, 7, 16), 1.8, 1.8),
    )
    ..moveTo(5, 9)
    ..lineTo(3.5, 12)
    ..lineTo(5, 15)
    ..moveTo(19, 9)
    ..lineTo(20.5, 12)
    ..lineTo(19, 15);

  /// A CLOCK — which is why this one never mirrors.
  static Path _clock() => Path()
    ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 8))
    ..moveTo(12, 7)
    ..lineTo(12, 12)
    ..lineTo(15.5, 14);

  static Path _contrast() => Path()
    ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 8))
    // The filled half is drawn with arcTo over a Rect rather than arcToPoint
    // with a Radius: check_raw_values reads `Radius.circular(n)` as a corner
    // token wherever it appears, and cannot tell a path's curvature from a
    // surface's corner. Same curve, no collision.
    ..moveTo(12, 4)
    ..arcTo(
      Rect.fromCircle(center: const Offset(12, 12), radius: 8),
      -1.5707963267948966,
      3.141592653589793,
      false,
    )
    ..close();

  static Path _language() => Path()
    ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 8))
    ..moveTo(4, 12)
    ..lineTo(20, 12)
    ..addOval(
      Rect.fromCenter(center: const Offset(12, 12), width: 8, height: 16),
    );

  static Path _info() => Path()
    ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 8))
    ..moveTo(12, 11)
    ..lineTo(12, 16.5)
    ..addOval(Rect.fromCircle(center: const Offset(12, 7.8), radius: 0.9));

  static Path _lock() => Path()
    ..addRRect(
      RRect.fromRectXY(const Rect.fromLTWH(5.5, 10.5, 13, 9.5), 2.2, 2.2),
    )
    ..moveTo(8.5, 10.5)
    ..lineTo(8.5, 8)
    ..arcTo(
      Rect.fromCircle(center: const Offset(12, 8), radius: 3.5),
      3.141592653589793,
      3.141592653589793,
      false,
    )
    ..lineTo(15.5, 10.5);

  static Path _star() {
    const centre = Offset(12, 12);
    const outer = 8.0;
    const inner = 3.6;
    final points = <Offset>[
      for (var i = 0; i < 10; i++)
        Offset(
          centre.dx + (i.isEven ? outer : inner) * _cos(i),
          centre.dy + (i.isEven ? outer : inner) * _sin(i),
        ),
    ];

    return _polygon(points);
  }

  static Path _flame() => Path()
    ..moveTo(12, 3.5)
    ..cubicTo(16.5, 8, 18.5, 10.5, 18.5, 14)
    ..arcTo(
      Rect.fromCircle(center: const Offset(12, 14), radius: 6.5),
      0,
      3.141592653589793,
      false,
    )
    ..cubicTo(5.5, 10.5, 7.5, 8, 12, 3.5)
    ..close();

  /// The star's vertex angles, stepping every 36 degrees from straight up.
  static double _cos(int i) => _unit(i).dx;
  static double _sin(int i) => _unit(i).dy;

  static Offset _unit(int i) {
    // -pi/2 puts vertex 0 at the top; 10 vertices, so pi/5 per step.
    const start = -1.5707963267948966;
    const step = 0.6283185307179586;
    final angle = start + step * i;

    return Offset.fromDirection(angle);
  }
}

/// Applies a transform to a value.
///
/// A one-line pipe so a map literal can be wrapped in `unmodifiable` without
/// naming an intermediate variable.
extension<T> on T {
  /// Returns `transform(this)`.
  R let<R>(R Function(T value) transform) => transform(this);
}
