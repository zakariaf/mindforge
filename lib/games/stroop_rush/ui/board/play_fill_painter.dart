import 'package:flutter/widgets.dart';
import 'package:mindforge/games/stroop_rush/ui/board/play_fill.dart';
import 'package:mindforge/theme/sunburst_colors.dart';

/// One answer's pattern panel, as a value.
@immutable
final class PlayFillScene {
  /// Creates a scene.
  const PlayFillScene({
    required this.fill,
    required this.hue,
    required this.ink,
    required this.geometry,
  });

  /// Which pattern.
  final PlayFill fill;

  /// The panel's background.
  final Color hue;

  /// The pattern colour.
  final Color ink;

  /// The measured geometry.
  final PlayFillGeometry geometry;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayFillScene &&
          other.fill == fill &&
          other.hue == hue &&
          other.ink == ink &&
          other.geometry == geometry;

  @override
  int get hashCode => Object.hash(fill, hue, ink, geometry);
}

/// Paints an answer's pattern panel.
///
/// **The panel is the second channel made large.** The stimulus carries the
/// same pattern inside its letterforms, where it is thin; here it is a 56pt
/// block, which is what a player scans at arm's length. Red and green collapse
/// to the same olive under deuteranopia and to the same grey in a screenshot;
/// stripe and dot never do.
class PlayFillPainter extends CustomPainter {
  /// Creates a painter for [scene].
  PlayFillPainter(this.scene)
    : _hue = Paint()..color = scene.hue,
      _inkStroke = Paint()
        ..color = scene.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = scene.geometry.strokeWidthFor(scene.fill),
      _inkFill = Paint()..color = scene.ink;

  /// What to paint.
  final PlayFillScene scene;

  final Paint _hue;
  final Paint _inkStroke;
  final Paint _inkFill;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;

    canvas
      ..save()
      // Clipped to the panel, so a stripe that starts outside it does not run
      // across the label beside it. A clip rather than shorter primitives
      // because the stripe angle means "outside" is not a straight edge.
      ..clipRect(bounds)
      ..drawRect(bounds, _hue);

    paintPlayFill(
      canvas,
      bounds,
      scene.fill,
      inkStroke: _inkStroke,
      inkFill: _inkFill,
      geometry: scene.geometry,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(PlayFillPainter old) => old.scene != scene;
}
