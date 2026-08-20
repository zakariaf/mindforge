import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph_painter.dart';

import '../../support/component_harness.dart';
import '../../support/locale_cases.dart';

void main() {
  const shape = SunburstShape.sunburstPop;
  const colours = SunburstColors.sunburstPop;

  GlyphScene sceneFor(SunburstGlyph glyph, {double stroke = 2.6}) => GlyphScene(
    glyph: glyph,
    colour: colours.textPrimary,
    strokeWidth: stroke,
  );

  group('the set', () {
    test('every value resolves to real artwork', () {
      // A value added to the enum without a path fails here immediately,
      // rather than rendering as nothing on whichever screen first uses it.
      for (final glyph in SunburstGlyph.values) {
        final path = SunburstGlyphPainter.pathFor(glyph);

        expect(
          path.computeMetrics().isNotEmpty || !path.getBounds().isEmpty,
          isTrue,
          reason: '$glyph has no artwork',
        );
        expect(path.getBounds().isEmpty, isFalse, reason: '$glyph is empty');
      }
    });

    test('is the seventeen marks the design draws', () {
      expect(SunburstGlyph.values, hasLength(17));
    });
  });

  group('the mirror table', () {
    // THE TABLE, as a literal. The enum's own switch is exhaustive with no
    // default clause, so an eighteenth glyph does not compile until someone
    // decides — and this asserts the decision they made is the one the design
    // calls for.
    const expected = <SunburstGlyph, bool>{
      // Directional: these point along the reading direction.
      SunburstGlyph.back: true,
      SunburstGlyph.chevronForward: true,
      SunburstGlyph.sound: true,
      // Brand marks. Mirroring changes recognition and adds no meaning.
      SunburstGlyph.navPlay: false,
      SunburstGlyph.navStats: false,
      SunburstGlyph.navSettings: false,
      // A media play triangle has a fixed meaning in both directions.
      SunburstGlyph.go: false,
      // A CLOCK. Its hands would run backwards.
      SunburstGlyph.motion: false,
      // Symmetric or representational.
      SunburstGlyph.pause: false,
      SunburstGlyph.close: false,
      SunburstGlyph.haptics: false,
      SunburstGlyph.contrast: false,
      SunburstGlyph.language: false,
      SunburstGlyph.info: false,
      SunburstGlyph.lock: false,
      SunburstGlyph.star: false,
      SunburstGlyph.flame: false,
    };

    test('covers every glyph, with no glyph left undecided', () {
      expect(expected.keys.toSet(), SunburstGlyph.values.toSet());
    });

    test('and each glyph answers the way the design says', () {
      for (final entry in expected.entries) {
        expect(entry.key.mirrorsInRtl, entry.value, reason: '${entry.key}');
      }
    });

    test('exactly three marks move', () {
      expect(
        SunburstGlyph.values.where((glyph) => glyph.mirrorsInRtl).length,
        3,
      );
    });
  });

  group('the stroke resolver', () {
    testWidgets('takes the nav weight at 22 and above', (tester) async {
      for (final size in <double>[22, 24, 32]) {
        expect(
          await _strokeAt(tester, size),
          shape.glyphStrokeNav,
          reason: 'at ${size}pt',
        );
      }
    });

    testWidgets('and the heavier control weight below it', (tester) async {
      // 16 IS THE CASE THAT MATTERS: the settings disclosure chevron is 16pt at
      // stroke 3 in app.html. A resolver written as "18-20 -> 3.0" gives it 2.6
      // and it renders visibly thinner than the row it sits in.
      for (final size in <double>[16, 18, 20, 21.9]) {
        expect(
          await _strokeAt(tester, size),
          shape.glyphStrokeControl,
          reason: 'at ${size}pt',
        );
      }
    });
  });

  group('the painter', () {
    test('holds no direction, so there is one path per glyph', () {
      // custom-canvas-and-gestures rule 11: geometry is direction-agnostic and
      // only chrome mirrors. The flip is a Transform applied by the widget,
      // which keeps shouldRepaint a pure value compare.
      expect(
        GlyphScene(
          glyph: SunburstGlyph.back,
          colour: colours.textPrimary,
          strokeWidth: 3,
        ),
        sceneFor(SunburstGlyph.back, stroke: 3),
      );
    });

    test('shouldRepaint is a single value compare', () {
      final painter = SunburstGlyphPainter(sceneFor(SunburstGlyph.back));

      expect(
        painter.shouldRepaint(
          SunburstGlyphPainter(sceneFor(SunburstGlyph.back)),
        ),
        isFalse,
      );
      expect(
        painter.shouldRepaint(
          SunburstGlyphPainter(sceneFor(SunburstGlyph.close)),
        ),
        isTrue,
      );
      expect(
        painter.shouldRepaint(
          SunburstGlyphPainter(sceneFor(SunburstGlyph.back, stroke: 3)),
        ),
        isTrue,
      );
    });
  });

  group('the widget', () {
    testWidgets('flips a directional mark under fa and leaves the rest', (
      tester,
    ) async {
      Future<bool> isFlipped(SunburstGlyph glyph, LocaleCase localeCase) async {
        await tester.pumpPopComponent(
          SunburstGlyphIcon(glyph),
          localeCase: localeCase,
        );

        return find
            .descendant(
              of: find.byType(SunburstGlyphIcon),
              matching: find.byType(Transform),
            )
            .evaluate()
            .isNotEmpty;
      }

      final en = LocaleCase.all.first;
      final fa = LocaleCase.rightToLeft.first;

      expect(await isFlipped(SunburstGlyph.back, en), isFalse);
      expect(await isFlipped(SunburstGlyph.back, fa), isTrue);
      expect(await isFlipped(SunburstGlyph.motion, fa), isFalse);
      expect(await isFlipped(SunburstGlyph.navPlay, fa), isFalse);
    });

    testWidgets('renders no semantics of its own', (tester) async {
      // The label belongs to the enclosing component: a screen reader should
      // hear "Back", not "Back, image".
      final handle = tester.ensureSemantics();

      await tester.pumpPopComponent(
        const SunburstGlyphIcon(SunburstGlyph.back),
      );

      expect(
        find.descendant(
          of: find.byType(SunburstGlyphIcon),
          matching: find.byType(Semantics),
        ),
        findsNothing,
      );

      handle.dispose();
    });
  });
}

Future<double> _strokeAt(WidgetTester tester, double size) async {
  await tester.pumpPopComponent(
    SunburstGlyphIcon(SunburstGlyph.close, size: size),
  );

  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(SunburstGlyphIcon),
      matching: find.byType(CustomPaint),
    ),
  );

  return (paint.painter! as SunburstGlyphPainter).scene.strokeWidth;
}
