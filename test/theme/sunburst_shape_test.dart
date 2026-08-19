import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

import '../support/design_source.dart';
import '../support/harness.dart';

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

      for (final direction in TextDirection.values) {
        await tester.pumpApp(
          Builder(
            builder: (context) {
              byDirection[direction] =
                  SunburstShape.of(
                        context,
                      )
                      .shadow(shape.e2, SunburstColors.of(context).border)
                      .single
                      .offset;
              return const SizedBox.shrink();
            },
          ),
          theme: ThemeData(
            extensions: const <ThemeExtension<dynamic>>[
              shape,
              SunburstColors.sunburstPop,
            ],
          ),
          textDirection: direction,
        );
      }

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
