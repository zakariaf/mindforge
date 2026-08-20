import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/games/stroop_rush/ui/board/play_fill.dart';
import 'package:mindforge/games/stroop_rush/ui/board/stroop_word_painter.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';

/// The three-pass stimulus glyph.
///
/// Ink stroke, hue fill, ink pattern clipped to the glyph — which is what makes
/// a yellow word read at ink-on-cream contrast instead of yellow-on-white, and
/// what keeps hue from being the only channel.
void main() {
  const colours = SunburstColors.sunburstPop;
  const shape = SunburstShape.sunburstPop;
  const type = SunburstType.sunburstPop;

  final geometry = PlayFillGeometry(
    stripePitch: shape.stripePitch,
    stripeAngle: shape.stripeAngle,
    dotPitch: shape.dotPitch,
    dotRadius: shape.dotRadius,
    ringPitch: shape.ringPitch,
    ringBandWidth: shape.ringBandWidth,
  );

  StroopWordScene sceneOf({
    String word = 'BLUE',
    TextDirection direction = TextDirection.ltr,
    PlayFill fill = PlayFill.stripe,
    Color? hue,
    double? strokeWidth,
    TextStyle? style,
  }) => StroopWordScene(
    word: word,
    textDirection: direction,
    style: style ?? type.stimulus,
    fill: fill,
    hue: hue ?? colours.playRed,
    ink: colours.border,
    strokeWidth: strokeWidth ?? shape.glyphStrokeWidth,
    geometry: geometry,
  );

  _Recording render(StroopWordScene scene) {
    final canvas = _Recording();

    StroopWordPainter(scene).paint(canvas, const Size(320, 120));

    return canvas;
  }

  group('the scene is a value', () {
    test('an identical scene does not repaint', () {
      expect(
        StroopWordPainter(sceneOf()).shouldRepaint(
          StroopWordPainter(sceneOf()),
        ),
        isFalse,
      );
    });

    test('and every field changes it — including textDirection', () {
      // The direction was the field most likely to be left out, and leaving it
      // out means a locale switch mid-run repaints nothing and the word keeps
      // laying out the old way.
      final variants = <String, StroopWordScene>{
        'word': sceneOf(word: 'RED'),
        'textDirection': sceneOf(direction: TextDirection.rtl),
        'fill': sceneOf(fill: PlayFill.dot),
        'hue': sceneOf(hue: colours.playBlue),
        'strokeWidth': sceneOf(strokeWidth: 99),
        'style': sceneOf(style: type.stimulusCompact),
      };

      for (final entry in variants.entries) {
        expect(
          StroopWordPainter(sceneOf()).shouldRepaint(
            StroopWordPainter(entry.value),
          ),
          isTrue,
          reason: '${entry.key} is missing from the scene comparison',
        );
      }
    });
  });

  group('the pass order', () {
    test('the outline is drawn before the fill', () {
      // Underneath, not over: an outline drawn last would ink over the very
      // hue it exists to make legible.
      final canvas = render(sceneOf(fill: PlayFill.solid));

      expect(canvas.paragraphs, greaterThanOrEqualTo(2));
      expect(
        canvas.log.indexOf('drawParagraph'),
        lessThan(canvas.log.lastIndexOf('drawParagraph')),
      );
    });

    test('and a solid fill draws no pattern and opens no mask layer', () {
      final canvas = render(sceneOf(fill: PlayFill.solid));

      expect(canvas.log, isNot(contains('saveLayer')));
      expect(canvas.log, isNot(contains('drawLine')));
      expect(canvas.log, isNot(contains('drawCircle')));
    });
  });

  group('the pattern is masked with a LAYER, never a path clip', () {
    test('the sequence is saveLayer, glyph, saveLayer, pattern, restore', () {
      // THE STRUCTURAL GUARANTEE THAT JOINED SCRIPT CANNOT BREAK. Flutter
      // exposes no glyph outline from a TextPainter, so a path-based mask
      // cannot be built at all — and a layer composite is script-independent
      // by construction. This test exists so nobody "optimizes" it into a
      // clipPath that happens to look right in English.
      final canvas = render(sceneOf(fill: PlayFill.stripe));

      expect(canvas.log, isNot(contains('clipPath')));
      expect(canvas.log, isNot(contains('clipRect')));

      final firstLayer = canvas.log.indexOf('saveLayer');
      final maskLayer = canvas.log.indexOf('saveLayer', firstLayer + 1);
      final pattern = canvas.log.indexOf('drawLine');

      expect(firstLayer, isNonNegative);
      expect(maskLayer, greaterThan(firstLayer));
      expect(pattern, greaterThan(maskLayer));
      expect(canvas.log.lastIndexOf('restore'), greaterThan(pattern));
    });

    test('and the mask layer composites with srcIn', () {
      final canvas = render(sceneOf(fill: PlayFill.dot));

      expect(
        canvas.layerBlendModes,
        contains(BlendMode.srcIn),
        reason: 'the pattern layer must keep only what the glyph covers',
      );
    });

    test('and srcIn is on the LAYER, not on each primitive', () {
      // Per-primitive srcIn clears everything the current stripe does not
      // cover, so the second stripe has nothing to intersect and the pattern
      // is one line. Measured by counting: many primitives, one masked layer.
      final canvas = render(sceneOf(fill: PlayFill.stripe));

      expect(canvas.primitiveBlendModes, isNot(contains(BlendMode.srcIn)));
      expect(
        canvas.log.where((call) => call == 'drawLine').length,
        greaterThan(1),
      );
    });
  });

  group('the three patterns each draw something different', () {
    test('stripe strokes lines, dot fills circles, ring strokes circles', () {
      expect(render(sceneOf(fill: PlayFill.stripe)).log, contains('drawLine'));
      expect(render(sceneOf(fill: PlayFill.dot)).log, contains('drawCircle'));
      expect(render(sceneOf(fill: PlayFill.ring)).log, contains('drawCircle'));

      // And the two circle patterns are not the same drawing: a ring is a
      // stroke and a dot is a fill, which is what keeps them apart in
      // greyscale.
      expect(
        render(sceneOf(fill: PlayFill.dot)).circlePaintStyles,
        contains(PaintingStyle.fill),
      );
      expect(
        render(sceneOf(fill: PlayFill.ring)).circlePaintStyles,
        contains(PaintingStyle.stroke),
      );
    });
  });

  group('paint allocates nothing', () {
    test('the same Paint objects are used on every pass', () {
      // This painter runs on every frame of a shake.
      final painter = StroopWordPainter(sceneOf(fill: PlayFill.dot));

      final first = _Recording();
      final second = _Recording();

      painter
        ..paint(first, const Size(320, 120))
        ..paint(second, const Size(320, 120));

      expect(first.paints, isNotEmpty);
      expect(
        second.paints.difference(first.paints),
        isEmpty,
        reason: 'paint() allocated a new Paint on the second pass',
      );
    });
  });
}

/// A canvas that draws nothing and remembers what it was asked for.
///
/// It does not forward to a real canvas: `Canvas` is a native class and
/// `noSuchMethod` cannot be delegated to one, so the probe records instead —
/// which is all these assertions need.
class _Recording implements Canvas {
  /// Every call, in order.
  final List<String> log = <String>[];

  /// Every `Paint` handed over, by IDENTITY.
  final Set<Paint> paints = Set<Paint>.identity();

  /// The blend mode of each `saveLayer`'s paint.
  final List<BlendMode> layerBlendModes = <BlendMode>[];

  /// The blend mode of each drawing primitive's paint.
  final List<BlendMode> primitiveBlendModes = <BlendMode>[];

  /// The style of each circle drawn.
  final List<PaintingStyle> circlePaintStyles = <PaintingStyle>[];

  /// How many paragraphs were drawn.
  int paragraphs = 0;

  @override
  void saveLayer(Rect? bounds, Paint paint) {
    log.add('saveLayer');
    layerBlendModes.add(paint.blendMode);
  }

  @override
  void save() => log.add('save');

  @override
  void restore() => log.add('restore');

  @override
  void drawParagraph(Paragraph paragraph, Offset offset) {
    log.add('drawParagraph');
    paragraphs++;
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    log.add('drawLine');
    _remember(paint);
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    log.add('drawCircle');
    circlePaintStyles.add(paint.style);
    _remember(paint);
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    log.add('drawRect');
    _remember(paint);
  }

  @override
  void clipPath(Path path, {bool doAntiAlias = true}) => log.add('clipPath');

  @override
  void clipRect(
    Rect rect, {
    ClipOp clipOp = ClipOp.intersect,
    bool doAntiAlias = true,
  }) => log.add('clipRect');

  void _remember(Paint paint) {
    paints.add(paint);
    primitiveBlendModes.add(paint.blendMode);
  }

  /// Everything else is a no-op here.
  @override
  void noSuchMethod(Invocation invocation) {}
}
