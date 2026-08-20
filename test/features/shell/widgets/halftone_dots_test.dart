import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/features/shell/widgets/halftone_dots.dart';
import 'package:mindforge/theme/sunburst_colors.dart';

/// The painter behind every header.
///
/// It repaints on every scroll frame under a header, so both of its costs are
/// asserted here rather than reviewed: what makes it repaint, and what it
/// allocates while it does.
void main() {
  const colours = SunburstColors.sunburstPop;
  final dotInk = colours.headerDots;
  final rayInk = colours.headerRay;

  final scene = HalftoneScene(ink: dotInk, ray: rayInk);

  group('the scene is a value', () {
    test('two scenes with the same parts are equal', () {
      final other = HalftoneScene(
        ink: dotInk,
        ray: rayInk,
      );

      expect(other, scene);
      expect(other.hashCode, scene.hashCode);
    });

    test('and every field takes part in that equality', () {
      // A field left out of == is a field a repaint cannot notice. Each one is
      // flipped in turn rather than trusting the list.
      expect(
        HalftoneScene(ink: colours.border, ray: rayInk),
        isNot(scene),
      );
      expect(
        HalftoneScene(ink: dotInk, ray: colours.border),
        isNot(scene),
      );
      expect(
        HalftoneScene(
          ink: dotInk,
          ray: rayInk,
          pitch: 16,
        ),
        isNot(scene),
      );
      expect(
        HalftoneScene(
          ink: dotInk,
          ray: rayInk,
          dotRadius: 2,
        ),
        isNot(scene),
      );
      expect(
        HalftoneScene(
          ink: dotInk,
          ray: rayInk,
          spokeDegrees: 6,
        ),
        isNot(scene),
      );
      expect(
        HalftoneScene(
          ink: dotInk,
          ray: rayInk,
          pitchDegrees: 14,
        ),
        isNot(scene),
      );
      expect(
        HalftoneScene(
          ink: dotInk,
          ray: rayInk,
          origin: RayOrigin.centre,
        ),
        isNot(scene),
      );
    });
  });

  group('shouldRepaint', () {
    test('is false for an equal scene', () {
      final equal = HalftoneScene(
        ink: dotInk,
        ray: rayInk,
      );

      expect(
        HalftonePainter(scene).shouldRepaint(HalftonePainter(equal)),
        isFalse,
      );
    });

    test('and true when the ray opacity changes', () {
      // The three headers differ ONLY in ray strength — .5 on home, none on
      // stats, .3 on settings. A painter that could not tell them apart would
      // paint whichever one rendered first.
      final dimmer = HalftoneScene(
        ink: dotInk,
        ray: colours.headerRaySettings,
      );

      expect(
        HalftonePainter(scene).shouldRepaint(HalftonePainter(dimmer)),
        isTrue,
      );
    });
  });

  group('a layer that is absent is not painted', () {
    test('a null ray paints no wedge, and a null ink paints no dot', () {
      // Stats has a dot lattice and NO rays; the countdown has a burst and no
      // dots. Both are expressed by leaving the colour out, so there is no
      // "paint it at zero alpha" path that still costs a frame.
      final dotsOnly = HalftoneScene(ink: dotInk, ray: null);
      final raysOnly = HalftoneScene(ink: null, ray: colours.countdownRay);

      expect(_run(dotsOnly).wedges, 0);
      expect(_run(dotsOnly).dots, greaterThan(0));
      expect(_run(raysOnly).dots, 0);
      expect(_run(raysOnly).wedges, greaterThan(0));
    });

    test('and the spoke pitch decides how many wedges there are', () {
      // 360/12 = 30 spokes for a header, 360/14 for the countdown burst.
      expect(_run(scene).wedges, 30);
      expect(
        _run(
          HalftoneScene(
            ink: null,
            ray: colours.countdownRay,
            spokeDegrees: 6,
            pitchDegrees: 14,
          ),
        ).wedges,
        26,
      );
    });
  });

  group('paint allocates nothing', () {
    test('the same Paint objects are used on every pass', () {
      // A Paint built inside paint() is one allocation per frame per header,
      // and this painter sits under a scrolling list.
      final painter = HalftonePainter(scene);

      final first = _run(scene, painter: painter).paints;
      final second = _run(scene, painter: painter).paints;

      expect(first, isNotEmpty);
      expect(
        second.difference(first),
        isEmpty,
        reason: 'paint() allocated a new Paint on the second pass',
      );
    });
  });
}

/// A canvas that draws nothing and remembers what it was asked for.
///
/// It does NOT forward to a real canvas. `Canvas` is a native class and
/// `noSuchMethod` cannot be delegated to one, so the probe records instead —
/// which is all these assertions need, and it keeps `save`/`clipRect`/`restore`
/// as the no-ops they are here.
class _ProbeCanvas implements Canvas {
  /// How many ray wedges were drawn.
  int wedges = 0;

  /// How many lattice dots were drawn.
  int dots = 0;

  /// Every `Paint` handed over, by IDENTITY.
  ///
  /// A `Set.identity`, not a list and not a value set: two equal-but-distinct
  /// `Paint`s are exactly the per-frame allocation this asserts against, and
  /// `==` would collapse them into one and let the defect through.
  final Set<Paint> paints = Set<Paint>.identity();

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    dots++;
    _remember(paint);
  }

  @override
  void drawPath(Path path, Paint paint) {
    wedges++;
    _remember(paint);
  }

  void _remember(Paint paint) => paints.add(paint);

  /// Everything else — save, clipRect, restore — is a no-op here.
  @override
  void noSuchMethod(Invocation invocation) {}
}

/// Runs [scene] through a probe canvas.
_ProbeCanvas _run(HalftoneScene scene, {HalftonePainter? painter}) {
  final canvas = _ProbeCanvas();

  (painter ?? HalftonePainter(scene)).paint(canvas, const Size(390, 120));

  return canvas;
}
