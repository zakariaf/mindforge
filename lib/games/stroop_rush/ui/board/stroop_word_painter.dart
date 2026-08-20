import 'package:flutter/widgets.dart';
import 'package:mindforge/games/stroop_rush/ui/board/play_fill.dart';
import 'package:mindforge/theme/sunburst_colors.dart';

/// Everything the stimulus glyph is drawn from, as one value.
///
/// **It carries a pre-formatted word and no locale.** `custom-canvas-and-gestures`
/// rule 9: a painter never formats or shapes text — the word arrives resolved
/// and the direction arrives resolved, so `shouldRepaint` is one value compare
/// and nothing inside `paint()` can pick up an ambient `Intl.defaultLocale`.
@immutable
final class StroopWordScene {
  /// Creates a scene.
  const StroopWordScene({
    required this.word,
    required this.textDirection,
    required this.style,
    required this.fill,
    required this.hue,
    required this.ink,
    required this.strokeWidth,
    required this.geometry,
  });

  /// The already-resolved word, in its display form.
  final String word;

  /// The direction it lays out in.
  ///
  /// Part of the scene, so a locale switch repaints. It was the field most
  /// likely to be left out of `shouldRepaint`, which is why the test names it.
  final TextDirection textDirection;

  /// The type step, already resolved for the script.
  final TextStyle style;

  /// Which pattern the ink pass draws.
  final PlayFill fill;

  /// The colour the word is PRINTED in — the answer.
  final Color hue;

  /// The outline and pattern colour.
  final Color ink;

  /// How wide the outline is grown.
  final double strokeWidth;

  /// The pattern geometry.
  final PlayFillGeometry geometry;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StroopWordScene &&
          other.word == word &&
          other.textDirection == textDirection &&
          other.style == style &&
          other.fill == fill &&
          other.hue == hue &&
          other.ink == ink &&
          other.strokeWidth == strokeWidth &&
          other.geometry == geometry;

  @override
  int get hashCode => Object.hash(
    word,
    textDirection,
    style,
    fill,
    hue,
    ink,
    strokeWidth,
    geometry,
  );
}

/// The stimulus word, in three passes.
///
/// 1. **Ink outline**, grown outward from every contour. This is what makes a
///    yellow word read at ink-on-cream contrast rather than yellow-on-white —
///    the reason `sunburst-tokens` rule 6 says the stimulus is never a bare
///    `Text`.
/// 2. **Hue fill**, the colour the answer is.
/// 3. **Ink pattern**, clipped to the glyph, so hue is never the only channel.
///
/// **Pass 3 is `saveLayer` + `BlendMode.srcIn`, never a path clip.** Flutter
/// exposes no glyph outline from a `TextPainter`, so a path-based mask cannot
/// be built at all — and the layer approach is script-independent by
/// construction, which is what makes it survive joined Arabic script where a
/// contour-following implementation would not.
class StroopWordPainter extends CustomPainter {
  /// Creates a painter for [scene].
  StroopWordPainter(this.scene)
    : // HOISTED, both of them. `paint()` runs on every frame of a shake, and
      // the plain layer paint was being allocated there while its sibling was
      // already a field — one invariant, half applied.
      _layer = Paint(),
      _maskToGlyph = Paint()..blendMode = BlendMode.srcIn,
      _inkStroke = Paint()
        ..color = scene.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = scene.geometry.stripePitch / 2,
      _inkFill = Paint()..color = scene.ink,
      _outline = TextPainter(
        text: TextSpan(
          text: scene.word,
          style: scene.style.copyWith(
            foreground: Paint()
              ..color = scene.ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = scene.strokeWidth
              // ROUND joins and caps. A mitre spike on a cursive join is a
              // sharp black dart hanging off the letter, and Arabic script is
              // nothing but joins.
              ..strokeJoin = StrokeJoin.round
              ..strokeCap = StrokeCap.round,
          ),
        ),
        textDirection: scene.textDirection,
        textAlign: TextAlign.center,
      ),
      _body = TextPainter(
        // PASS 2 IS THE BODY'S OWN COLOUR, not a rect composited over a mask.
        // The first draft drew a hue rect with `srcIn` and got there by
        // MUTATING the shared hue paint inside `paint()` — a change the next
        // frame would have inherited. A `TextPainter` already knows how to
        // fill a glyph.
        text: TextSpan(
          text: scene.word,
          style: scene.style.copyWith(color: scene.hue),
        ),
        textDirection: scene.textDirection,
        textAlign: TextAlign.center,
      );

  /// What to paint.
  final StroopWordScene scene;

  final Paint _inkStroke;
  final Paint _inkFill;
  final TextPainter _outline;
  final TextPainter _body;

  /// Composites a layer keeping only what the layer beneath already covers.
  ///
  /// **On the LAYER, not on each primitive.** `srcIn` per stripe would clear
  /// everything the current stripe does not cover, so the second stripe would
  /// have nothing left to intersect and the pattern would be one line. The
  /// whole pattern is drawn into its own layer and that layer is composited
  /// once.
  final Paint _layer;
  final Paint _maskToGlyph;

  @override
  void paint(Canvas canvas, Size size) {
    // ONE LAYOUT, THREE PASSES. The stroke, the fill and the pattern all read
    // the same metrics, so they cannot drift apart by a pixel — which on a
    // 6px outline is the difference between an outline and a shadow.
    _outline.layout(maxWidth: size.width);
    _body.layout(maxWidth: size.width);

    final origin = Offset(
      (size.width - _body.width) / 2,
      (size.height - _body.height) / 2,
    );
    final glyphBounds = origin & Size(_body.width, _body.height);

    // Pass 1, underneath.
    _outline.paint(
      canvas,
      Offset(
        (size.width - _outline.width) / 2,
        (size.height - _outline.height) / 2,
      ),
    );

    // Pass 2, the hue, in the body painter's own colour.
    _body.paint(canvas, origin);

    // A solid answer's second channel is the ABSENCE of a pattern, which is as
    // distinguishable as any of the other three.
    if (scene.fill == PlayFill.solid) return;

    // Pass 3: the pattern, masked to the glyph.
    canvas.saveLayer(glyphBounds, _layer);
    _body.paint(canvas, origin);
    canvas.saveLayer(glyphBounds, _maskToGlyph);
    paintPlayFill(
      canvas,
      glyphBounds,
      scene.fill,
      inkStroke: _inkStroke,
      inkFill: _inkFill,
      geometry: scene.geometry,
    );
    canvas
      ..restore()
      ..restore();
  }

  @override
  bool shouldRepaint(StroopWordPainter old) => old.scene != scene;
}
