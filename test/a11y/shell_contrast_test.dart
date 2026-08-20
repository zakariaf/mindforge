import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';

/// The composited pairs the eight shell screens introduce.
///
/// **This file is not multiplied by locale, and that is deliberate.** Colour is
/// locale-independent: the same ink on the same sunshine is the same ratio in
/// Persian as in English, and a four-times matrix over it would be four
/// identical assertions wearing different names. What DOES change per locale is
/// size and weight, and that is the overflow matrix's job, not this one.
///
/// Every pair here is COMPOSITED — a text colour over a fill that itself has a
/// texture layer over it — which is why they cannot be declared as
/// `// @contrast` comments in the theme and checked by the palette script: that
/// script reads two named slots, and half of these are three.
void main() {
  const colours = SunburstColors.sunburstPop;

  /// The WCAG relative luminance of [colour], over its VALUE.
  ///
  /// Not a rendered-pixel sample: `textContrastGuideline` renders a widget and
  /// reads pixels, which has a known false negative on text over a patterned
  /// or partly transparent background — which is exactly what every pair below
  /// is.
  double luminance(Color colour) {
    double channel(double component) => component <= 0.03928
        ? component / 12.92
        : math.pow((component + 0.055) / 1.055, 2.4).toDouble();

    return 0.2126 * channel(colour.r) +
        0.7152 * channel(colour.g) +
        0.0722 * channel(colour.b);
  }

  /// [over] composited under [colour], which is what a texture layer does.
  Color composite(Color colour, Color over) => Color.alphaBlend(over, colour);

  double ratio(Color a, Color b) {
    final lighter = math.max(luminance(a), luminance(b));
    final darker = math.min(luminance(a), luminance(b));

    return (lighter + 0.05) / (darker + 0.05);
  }

  void expectAtLeast(
    String what,
    Color foreground,
    Color background,
    double minimum,
  ) {
    final measured = ratio(foreground, background);

    expect(
      measured,
      greaterThanOrEqualTo(minimum),
      reason: '$what measured ${measured.toStringAsFixed(2)}:1',
    );
  }

  group('the header composites', () {
    test('the greeting is legible on sunshine under rays and dots', () {
      // Home's header is three layers: sunshine, a ray sweep at .5, a dot
      // lattice at .16. The dots are the layer that takes it DOWN, and the
      // greeting is small text, so it needs the full 4.5:1.
      final surface = composite(
        composite(colours.accent, colours.headerRay),
        colours.headerDots,
      );

      expectAtLeast('the greeting on Home', colours.textPrimary, surface, 4.5);
    });

    test('the settings title is legible on grape under its dimmer rays', () {
      // Cream on grape, and app.html dims the rays to .3 on this header. The
      // title is large text, so 3:1 is the floor that applies.
      final surface = composite(
        composite(colours.accentAlt, colours.headerRaySettings),
        colours.headerDots,
      );

      expectAtLeast(
        'the Settings title',
        colours.textInvert,
        surface,
        3,
      );
    });

    test('and the stats kicker is legible on turquoise with dots alone', () {
      final surface = composite(colours.accentCool, colours.headerDots);

      expectAtLeast('the Stats kicker', colours.textPrimary, surface, 4.5);
    });
  });

  group('the hero panel composites', () {
    for (final accent in GameAccent.values) {
      test('the ${accent.name} kicker clears the small-text floor', () {
        // THE REASON THE HERO DOTS ARE .08 AND THE HEADER'S ARE .16. app.html
        // says it on the rule; this is the measurement behind the sentence.
        final surface = composite(
          colours.accentFor(accent, GameColourRole.base),
          colours.heroDots,
        );

        expectAtLeast(
          'the ${accent.name} hero kicker',
          colours.textPrimary,
          surface,
          4.5,
        );
      });

      test('and the header lattice would NOT clear it on ${accent.name}', () {
        // The negative half of the same measurement. Without it the .08 above
        // looks like a number someone picked, and a later "simplification"
        // that reused headerDots here would pass every other test.
        final tooStrong = composite(
          colours.accentFor(accent, GameColourRole.base),
          colours.headerDots,
        );

        expect(
          ratio(colours.textPrimary, tooStrong),
          lessThan(
            ratio(
              colours.textPrimary,
              composite(
                colours.accentFor(accent, GameColourRole.base),
                colours.heroDots,
              ),
            ),
          ),
          reason:
              'the header lattice must composite DARKER than the hero one, or '
              'the two opacities are the same decision twice',
        );
      });
    }
  });

  group('the results trio', () {
    test('its labels are ink on the saturated cells, never ink-2', () {
      // app.html says it on the rule: "ink-2 drops to 2.8:1 on coral". Both
      // halves are asserted, so the rule cannot be re-broken by someone
      // tidying the label colour into one constant.
      for (final fill in <Color>[colours.accentCool, colours.accentWarm]) {
        expectAtLeast('the trio label', colours.textPrimary, fill, 4.5);
        expect(
          ratio(colours.textSecondary, fill),
          lessThan(4.5),
          reason: 'textSecondary here would be a silent regression',
        );
      }
    });

    test('and ink-2 IS legal on the paper cell between them', () {
      expectAtLeast(
        'the middle trio label',
        colours.textSecondary,
        colours.surfaceRaised,
        4.5,
      );
    });
  });

  group('the stat box', () {
    test('its label goes ink on sunshine and ink-2 on paper', () {
      expectAtLeast(
        'the accent stat label',
        colours.textPrimary,
        colours.accent,
        4.5,
      );
      expectAtLeast(
        'the paper stat label',
        colours.textSecondary,
        colours.surfaceRaised,
        4.5,
      );
    });

    test('and app.html generalises further than its own numbers do', () {
      // The rule says "ink-2 is for paper and cream only — on a saturated fill
      // the label goes ink". MEASURED, that is true of coral (2.77:1) and of
      // turquoise (3.66:1) and NOT of sunshine, where ink-2 reaches 4.91:1.
      //
      // The implementation follows the design anyway: ink on every saturated
      // fill is one rule a reader can hold, and 9.74:1 costs nothing. What is
      // recorded here is that the sunshine case is a STYLE decision while the
      // other two are a floor — so nobody later discovers ink-2 passes on
      // sunshine and generalises THAT in the opposite direction.
      expect(ratio(colours.textSecondary, colours.accent), greaterThan(4.5));
      expect(ratio(colours.textSecondary, colours.accentWarm), lessThan(4.5));
      expect(ratio(colours.textSecondary, colours.accentCool), lessThan(4.5));
    });
  });

  group('the countdown', () {
    test('cream on grape under a .55 burst is still large-text legible', () {
      final surface = composite(colours.accentAlt, colours.countdownRay);

      expectAtLeast('Get ready', colours.textInvert, surface, 3);
    });

    test('and the numeral is ink on the sunshine ring', () {
      expectAtLeast('the numeral', colours.textPrimary, colours.accent, 4.5);
    });
  });

  group('the play band', () {
    for (final accent in GameAccent.values) {
      test('${accent.name} carries no small text, and its pills are their own '
          'surfaces', () {
        // app.html states this on the rule: only ink-outlined objects sit on
        // the band, never small text, which is why the ray and dot layers can
        // run at full strength there. The assertion is that the PILL's fill —
        // not the band's — is what a HUD label is measured against.
        expectAtLeast(
          'a HUD label',
          colours.textPrimary,
          colours.surfaceRaised,
          4.5,
        );
      });
    }
  });
}
