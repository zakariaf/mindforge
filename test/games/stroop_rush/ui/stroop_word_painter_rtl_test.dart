import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/games/stroop_rush/ui/board/play_fill.dart';
import 'package:mindforge/games/stroop_rush/ui/board/stroop_word_painter.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';

import '../../../support/load_app_fonts.dart';

/// The three-pass glyph on JOINED script, which is the riskiest thing in E09.
///
/// The passes were designed against Latin capitals: isolated, thick,
/// generously counter-spaced letterforms. Arabic script is cursive, and three
/// specific things can break — none of them visible in an English screenshot.
///
/// 1. The outline closes the counters, and fuses the dots of ب ت ث ن and the
///    Sorani marks on ڕ ڵ ۆ ێ into their letter bodies. A ڕ whose mark has
///    fused is a different letter.
/// 2. The pattern reads as texture on a blob instead of as a fill on a shape.
/// 3. The mask itself: a path-based clip cannot be built at all, because
///    Flutter exposes no glyph outline from a `TextPainter`.
///
/// Real fonts, never the test font. Ahem draws every glyph as a filled box, so
/// a counter-preservation measurement against it would pass for any stroke
/// width at all.
void main() {
  setUpAll(loadAppFonts);

  const colours = SunburstColors.sunburstPop;
  const shape = SunburstShape.sunburstPop;

  final arabicType = SunburstType.sunburstPop.forScript(SunburstScript.arabic);

  final geometry = PlayFillGeometry(
    stripePitch: shape.stripePitch,
    stripeAngle: shape.stripeAngle,
    dotPitch: shape.dotPitch,
    dotRadius: shape.dotRadius,
    ringPitch: shape.ringPitch,
    ringBandWidth: shape.ringBandWidth,
  );

  /// The four words the two RTL locales actually print, including the two with
  /// the most marks and counters.
  const arabicWords = <String>['قرمز', 'نارنجی', 'پەمەیی', 'سەوز'];

  StroopWordScene sceneOf(String word, {PlayFill fill = PlayFill.stripe}) =>
      StroopWordScene(
        word: word,
        textDirection: TextDirection.rtl,
        style: arabicType.stimulus,
        fill: fill,
        hue: colours.playRed,
        ink: colours.border,
        strokeWidth: shape.glyphStrokeWidth,
        geometry: geometry,
      );

  /// What fraction of a word's bounding box is inked, at [stroke].
  ///
  /// A stroke of zero measures the FILLED body, which is the baseline every
  /// outline is compared against. Rendered to a real image and counted pixel by
  /// pixel: there is no other way to ask "did the counters close".
  Future<double> inkCoverage(String word, double stroke) async {
    final style = arabicType.stimulus.copyWith(
      foreground: stroke == 0
          ? (Paint()..color = const Color(0xFF000000))
          : (Paint()
              ..color = const Color(0xFF000000)
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke
              ..strokeJoin = StrokeJoin.round
              ..strokeCap = StrokeCap.round),
    );
    final painter = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: TextDirection.rtl,
    )..layout();

    final recorder = PictureRecorder();

    painter.paint(Canvas(recorder), Offset.zero);

    final picture = recorder.endRecording();
    final width = painter.width.ceil() + 8;
    final height = painter.height.ceil() + 8;
    final image = await picture.toImage(width, height);
    final pixels = await image.toByteData();

    var inked = 0;

    for (var i = 3; i < pixels!.lengthInBytes; i += 4) {
      if (pixels.getUint8(i) > 128) inked++;
    }

    image.dispose();
    picture.dispose();
    painter.dispose();

    return inked / (width * height);
  }

  group('the outline does not close the counters', () {
    for (final word in arabicWords) {
      test('$word keeps its shape at the shipped stroke width', () async {
        // MEASURED, not guessed. At 78pt with the bundled Arabic face, a 6px
        // outline covers about the same area as the filled letterform — it
        // traces the contour rather than flooding it. A stroke that closed the
        // counters and fused the marks would cover far more.
        //
        // Recorded numbers, so the ceiling below is a measurement and not a
        // hope:
        //
        // | word | filled | stroke 6 | stroke 18 |
        // |---|---|---|---|
        // | قرمز | 22.8% | 23.0% | 53.3% |
        // | نارنجی | 20.9% | 22.8% | 52.6% |
        // | پەمەیی | 19.7% | 20.3% | 45.7% |
        // | سەوز | 20.0% | 19.9% | 46.3% |
        final filled = await inkCoverage(word, 0);
        final outlined = await inkCoverage(word, shape.glyphStrokeWidth);

        expect(
          outlined / filled,
          lessThan(1.25),
          reason:
              '$word: the outline covers ${(outlined * 100).toStringAsFixed(1)}% '
              'against a filled ${(filled * 100).toStringAsFixed(1)}% — the '
              'counters have closed or the marks have fused',
        );
      });
    }

    test('and a stroke three times wider demonstrably would', () async {
      // THE NEGATIVE HALF. Without it the ceiling above is a number that
      // happens to pass, and a later "make the outline bolder" would sail
      // through at 10px and fail a player instead of a test.
      final filled = await inkCoverage('نارنجی', 0);
      final tooBold = await inkCoverage('نارنجی', shape.glyphStrokeWidth * 3);

      expect(tooBold / filled, greaterThan(2));
    });
  });

  group('the layout is RTL and shared', () {
    test(
      'the direction reaches the painter and the word measures non-zero',
      () {
        for (final word in arabicWords) {
          final painter = TextPainter(
            text: TextSpan(text: word, style: arabicType.stimulus),
            textDirection: TextDirection.rtl,
          )..layout();

          expect(painter.width, greaterThan(0), reason: word);
          painter.dispose();
        }
      },
    );

    test('and direction changes the layout, not the advance', () {
      // Same glyphs, same width — only the order differs. A word that measured
      // differently under RTL would mean the direction had reached shaping,
      // which it must not: the SCRIPT decides shaping and the PARAGRAPH
      // decides order.
      for (final word in arabicWords) {
        final rtl = TextPainter(
          text: TextSpan(text: word, style: arabicType.stimulus),
          textDirection: TextDirection.rtl,
        )..layout();
        final ltr = TextPainter(
          text: TextSpan(text: word, style: arabicType.stimulus),
          textDirection: TextDirection.ltr,
        )..layout();

        expect(rtl.width, closeTo(ltr.width, 0.5), reason: word);
        rtl.dispose();
        ltr.dispose();
      }
    });
  });

  group('the mask survives joined script by construction', () {
    for (final fill in PlayFill.values) {
      test('${fill.name} composites with a layer and never clips a path', () {
        // The same guarantee the Latin test makes, asserted again on a word
        // whose letters JOIN — because "it works in English" is exactly the
        // evidence that would be missing if the implementation followed
        // contours.
        final canvas = _Recording();

        StroopWordPainter(
          sceneOf('نارنجی', fill: fill),
        ).paint(canvas, const Size(320, 120));

        expect(canvas.log, isNot(contains('clipPath')));

        if (fill == PlayFill.solid) return;

        expect(canvas.layerBlendModes, contains(BlendMode.srcIn));
      });
    }
  });
}

/// A canvas that draws nothing and remembers what it was asked for.
class _Recording implements Canvas {
  /// Every call, in order.
  final List<String> log = <String>[];

  /// The blend mode of each `saveLayer`'s paint.
  final List<BlendMode> layerBlendModes = <BlendMode>[];

  @override
  void saveLayer(Rect? bounds, Paint paint) {
    log.add('saveLayer');
    layerBlendModes.add(paint.blendMode);
  }

  @override
  void restore() => log.add('restore');

  @override
  void drawParagraph(Paragraph paragraph, Offset offset) =>
      log.add('drawParagraph');

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) => log.add('drawLine');

  @override
  void drawCircle(Offset c, double radius, Paint paint) =>
      log.add('drawCircle');

  @override
  void clipPath(Path path, {bool doAntiAlias = true}) => log.add('clipPath');

  /// Everything else is a no-op here.
  @override
  void noSuchMethod(Invocation invocation) {}
}
