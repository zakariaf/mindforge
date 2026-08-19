import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

import '../support/design_source.dart';
import '../support/harness.dart';
import '../support/locale_cases.dart';

void main() {
  const shape = SunburstShape.sunburstPop;

  group('transcription from system.html', () {
    test('borderWidth is --bw', () {
      expect(DesignSource.cssScalar('--bw'), '3px');
      expect(shape.borderWidth, 3);
    });

    test('the radius scale matches --r-*', () {
      // Read from the design file, one property at a time. An earlier version
      // copied the CSS line into the test as a literal and justified it with a
      // claim that cssScalar could not split the shared line — measured, it
      // can. As written before, editing a radius in system.html left this test
      // green while the Dart silently diverged from the authority, which is
      // exactly the drift this whole apparatus exists to catch.
      final expected = <String, Radius>{
        '--r-sm': shape.radiusSm,
        '--r-md': shape.radiusMd,
        '--r-lg': shape.radiusLg,
        '--r-xl': shape.radiusXl,
        '--r-pill': shape.radiusPill,
      };

      for (final entry in expected.entries) {
        expect(
          DesignSource.cssScalar(entry.key),
          '${entry.value.x.toInt()}px',
          reason: '${entry.key} and its Dart radius disagree',
        );
      }
    });

    test('the four elevations are the hard offsets --sh-1..4', () {
      expect(shape.e1, const Offset(3, 3));
      expect(shape.e2, const Offset(5, 5));
      expect(shape.e3, const Offset(8, 8));
      expect(shape.e4, const Offset(10, 10));
    });
  });

  group('the hard shadow', () {
    test('never has blur or spread', () {
      for (final elevation in <Offset>[
        shape.e1,
        shape.e2,
        shape.e3,
        shape.e4,
      ]) {
        final shadows = shape.shadow(elevation, const Color(0xFF2B1B4D));

        expect(shadows, hasLength(1));
        expect(
          shadows.single.blurRadius,
          0,
          reason:
              'a blurred shadow reads as a floating panel; the whole '
              'system reads as die-cut card stock',
        );
        expect(shadows.single.spreadRadius, 0);
      }
    });

    test('shadow() is the only BoxShadow constructor in lib/', () {
      final files = Directory(DesignSource.pathToRepoFile('lib'))
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.endsWith('sunburst_shape.dart'))
          .where((f) => f.readAsStringSync().contains('BoxShadow('))
          .map((f) => f.path)
          .toList();

      expect(
        files,
        isEmpty,
        reason:
            'blurRadius is absent by CONSTRUCTION: there is one factory and '
            'it hardcodes zero. A second constructor is how a blur gets in',
      );
    });

    testWidgets('does NOT mirror under RTL', (tester) async {
      // The single question a reviewer will raise on the RTL PR, answered here
      // as well as in the source. Padding, alignment and icon direction mirror;
      // ILLUMINATION does not. One imaginary light for the whole app.
      final byDirection = <TextDirection, Offset>{};

      // Driven by LOCALE, not by a hardcoded Directionality: the question is
      // whether the shadow follows reading direction, and pinning the tree
      // upright is exactly what would hide the answer.
      for (final localeCase in <LocaleCase>[
        LocaleCase.all.first,
        LocaleCase.rightToLeft.first,
      ]) {
        await tester.pumpLocalized(
          Builder(
            builder: (context) {
              byDirection[Directionality.of(context)] =
                  SunburstShape.of(
                        context,
                      )
                      .shadow(shape.e2, SunburstColors.of(context).border)
                      .single
                      .offset;
              return const SizedBox.shrink();
            },
          ),
          localeCase,
          theme: ThemeData(
            extensions: const <ThemeExtension<dynamic>>[
              shape,
              SunburstColors.sunburstPop,
            ],
          ),
        );
      }

      expect(byDirection.keys, hasLength(2), reason: 'both directions ran');

      expect(
        byDirection[TextDirection.rtl],
        byDirection[TextDirection.ltr],
        reason:
            'a Persian build lit from the other side would disagree with '
            'every reference screenshot',
      );
      expect(byDirection[TextDirection.rtl], const Offset(5, 5));
    });
  });

  group('press physics', () {
    test('a pressed surface moves elevation - 1 on both axes', () {
      expect(shape.pressTranslate(shape.e2), const Offset(4, 4));
      expect(shape.pressTranslate(shape.e1), const Offset(2, 2));
    });

    test('a pressed surface keeps a 1px shadow rather than losing it', () {
      expect(
        SunburstShape.pressedShadow,
        const Offset(1, 1),
        reason:
            'dropping to zero would read as the surface vanishing, not as '
            'it being pushed into the page',
      );
    });

    test('the two press scales are distinct and both shrink', () {
      expect(shape.pressScale, 0.98);
      expect(shape.pressScaleSmall, 0.97);
      expect(shape.pressScaleSmall, lessThan(shape.pressScale));
    });
  });

  group('the spacing rhythm', () {
    test('is a static scale, not a themeable field', () {
      // Interpolating a gutter mid-animation is meaningless, and the rhythm is
      // identical in every conceivable variant.
      expect(
        DesignSource.dartFieldNames(
          'lib/theme/sunburst_shape.dart',
          'SunburstShape',
        ),
        isNot(contains('gutter')),
      );
    });

    test('the three layout constants are what app.html holds fixed', () {
      expect(SunburstShape.gutter, 20);
      expect(SunburstShape.cardGap, 16);
      expect(SunburstShape.cardPadding, 16);
    });
  });

  group('the slots the catalog needs', () {
    // Added by E05 T05.1. Every one is either DERIVED with its evidence or
    // transcribed from a system.html section, and each is pinned here so a
    // component can never justify typing the literal instead.
    test('eChip is the half-step below e1', () {
      expect(shape.eChip, const Offset(2, 2));
      expect(
        shape.eChip.dx,
        lessThan(shape.e1.dx),
        reason: 'a chip sits below the lowest raised step, not on it',
      );
    });

    test('nested border width is 2 and the primary edge is still 3', () {
      // Asserted TOGETHER, so a future edit cannot quietly collapse the two
      // into one number. The nested edge is the inner border of a surface
      // drawn inside another surface — a segment inside its track, a knob
      // inside its rail — and at 3px the pair reads as a smudge.
      expect(shape.borderWidthNested, 2);
      expect(shape.borderWidth, 3);
    });

    test('dash pitch is 9 on / 7 off', () {
      expect(shape.dashOn, 9);
      expect(shape.dashOff, 7);
    });

    test('glyph strokes are 2.6 at nav size and 3.0 below it', () {
      expect(shape.glyphStrokeNav, 2.6);
      expect(shape.glyphStrokeControl, 3);
      expect(
        shape.glyphStrokeControl,
        greaterThan(shape.glyphStrokeNav),
        reason:
            'the SMALLER glyph takes the HEAVIER stroke, which is why the '
            'resolver rule is "< 22 -> 3.0" and not "18-20 -> 3.0"',
      );
    });

    test('copyWith replaces each new slot independently', () {
      expect(
        shape.copyWith(eChip: const Offset(9, 9)).eChip,
        const Offset(9, 9),
      );
      expect(shape.copyWith(borderWidthNested: 9).borderWidthNested, 9);
      expect(shape.copyWith(dashOn: 9.5).dashOn, 9.5);
      expect(shape.copyWith(dashOff: 8.5).dashOff, 8.5);
      expect(shape.copyWith(glyphStrokeNav: 9).glyphStrokeNav, 9);
      expect(shape.copyWith(glyphStrokeControl: 9).glyphStrokeControl, 9);

      // And each leaves the others alone, which is the half that rots.
      final one = shape.copyWith(dashOn: 9.5);
      expect(one.dashOff, shape.dashOff);
      expect(one.eChip, shape.eChip);
    });

    test('lerp interpolates every new slot', () {
      final other = shape.copyWith(
        eChip: const Offset(12, 12),
        borderWidthNested: 4,
        dashOn: 19,
        dashOff: 17,
        glyphStrokeNav: 4.6,
        glyphStrokeControl: 5,
      );

      final halfway = shape.lerp(other, 0.5);

      // A field missing from lerp() returns a's value, so each midpoint is
      // asserted rather than the object compared.
      expect(halfway.eChip, const Offset(7, 7));
      expect(halfway.borderWidthNested, 3);
      expect(halfway.dashOn, 14);
      expect(halfway.dashOff, 12);
      // closeTo, not equals: 2.6 -> 4.6 lands on 3.5999999999999996, which is
      // the reason check_test_hygiene bans equals() on a double literal.
      expect(halfway.glyphStrokeNav, closeTo(3.6, 1e-9));
      expect(halfway.glyphStrokeControl, 4);
    });
  });

  group('the extension contract', () {
    testWidgets('of(context) asserts when the extension is missing', (
      tester,
    ) async {
      Object? error;

      await tester.pumpApp(
        Builder(
          builder: (context) {
            try {
              SunburstShape.of(context);
            } on Object catch (caught) {
              error = caught;
            }
            return const SizedBox.shrink();
          },
        ),
        theme: ThemeData(),
      );

      expect(error, isA<AssertionError>());
    });

    test('lerp moves every declared field', () {
      final other = shape.copyWith(
        borderWidth: 9,
        radiusSm: const Radius.circular(1),
        radiusMd: const Radius.circular(2),
        radiusLg: const Radius.circular(3),
        radiusXl: const Radius.circular(4),
        radiusPill: const Radius.circular(5),
        e1: const Offset(90, 90),
        e2: const Offset(91, 91),
        e3: const Offset(92, 92),
        e4: const Offset(93, 93),
        pressScale: 0.5,
        pressScaleSmall: 0.4,
        focusGap: 30,
        focusWidth: 40,
        stripePitch: 50,
        stripeAngle: 60,
        eChip: const Offset(94, 94),
        borderWidthNested: 8,
        dashOn: 70,
        dashOff: 80,
        glyphStrokeNav: 6.6,
        glyphStrokeControl: 7,
      );

      final halfway = shape.lerp(other, 0.5);

      expect(halfway, isNot(shape));
      expect(halfway.borderWidth, 6);
      expect(halfway.e2, const Offset(48, 48));
      expect(shape.lerp(other, 0), shape);
      expect(shape.lerp(other, 1), other);
      expect(shape.lerp(null, 0.5), shape);
    });
  });
}
