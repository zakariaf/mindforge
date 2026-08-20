import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph_painter.dart';

/// The size at and above which a glyph takes the lighter stroke.
///
/// Transcribed from `system.html` §08, which separates its examples into
/// "22px · stroke 2.6" and "18–20px · stroke 3".
const double kGlyphNavSize = 22;

/// Every mark the app draws.
///
/// **Drawn, never typed.** No emoji, no icon font, no `IconData`: a Material
/// icon on a hand-drawn cream surface is visible from across the room, and an
/// emoji is a different typeface, a different colour model and a different
/// meaning on every platform.
///
/// The set is `system.html` §08 plus the four settings-row marks `app.html`
/// draws and the disclosure chevron. The status-bar wifi and battery marks are
/// deliberately absent: those are mockup device chrome, drawn by the OS on a
/// real device.
enum SunburstGlyph {
  /// The play tab.
  navPlay,

  /// The stats tab.
  navStats,

  /// The settings tab.
  navSettings,

  /// A filled play triangle.
  go,

  /// The chevron that returns to the previous screen.
  back,

  /// Two bars.
  pause,

  /// A cross.
  close,

  /// A speaker cone with a wave.
  sound,

  /// A phone with motion marks.
  haptics,

  /// A clock.
  motion,

  /// A half-filled circle.
  contrast,

  /// A globe.
  language,

  /// An i in a circle.
  info,

  /// The chevron that opens a row.
  ///
  /// **`chevronForward`, not `chevronRight`.** A name carrying a physical side
  /// is wrong in half the shipped locales, and it invites exactly the physical
  /// geometry the i18n gate bans.
  chevronForward,

  /// A padlock.
  lock,

  /// A filled five-pointed star.
  star,

  /// A flame.
  flame;

  /// Whether this mark flips when the reading direction does.
  ///
  /// **Exhaustive, with no `default:` clause.** An eighteenth glyph does not
  /// compile until someone decides — which is the point. The rule is
  /// *mirror the directional, never the absolute*:
  ///
  /// * `back` and `chevronForward` point along the reading direction, so they
  ///   follow it.
  /// * `sound` has a cone at the start and its waves at the end, so it follows
  ///   too.
  /// * the three nav marks are **brand marks**. Mirroring them changes
  ///   recognition and adds no meaning.
  /// * `motion` is a **clock**, and a clock never mirrors — its hands would run
  ///   backwards.
  /// * `go` is a media play triangle, which has a fixed meaning across
  ///   platforms in both directions.
  /// * the rest are symmetric or representational, and flipping them would
  ///   just be a different drawing of the same thing.
  bool get mirrorsInRtl => switch (this) {
    SunburstGlyph.back ||
    SunburstGlyph.chevronForward ||
    SunburstGlyph.sound => true,
    SunburstGlyph.navPlay ||
    SunburstGlyph.navStats ||
    SunburstGlyph.navSettings ||
    SunburstGlyph.go ||
    SunburstGlyph.pause ||
    SunburstGlyph.close ||
    SunburstGlyph.haptics ||
    SunburstGlyph.motion ||
    SunburstGlyph.contrast ||
    SunburstGlyph.language ||
    SunburstGlyph.info ||
    SunburstGlyph.lock ||
    SunburstGlyph.star ||
    SunburstGlyph.flame => false,
  };
}

/// Draws a [SunburstGlyph].
///
/// The stroke weight follows the size, not the call site: at or above
/// [kGlyphNavSize] a glyph takes the lighter nav stroke, below it the heavier
/// control stroke. The **smaller** mark takes the **heavier** line, because a
/// thin stroke at 16pt disappears against a saturated fill — which is why the
/// rule is `< 22` rather than a band around 18–20.
class SunburstGlyphIcon extends StatelessWidget {
  /// Draws [glyph] at [size].
  const SunburstGlyphIcon(this.glyph, {this.size = 22, this.colour, super.key});

  /// The mark to draw.
  final SunburstGlyph glyph;

  /// The square the mark is drawn in.
  final double size;

  /// The stroke colour. Defaults to the primary text ink.
  final Color? colour;

  @override
  Widget build(BuildContext context) {
    final shape = SunburstShape.of(context);
    // RepaintBoundary: a glyph's colour changes with its component's state —
    // a pressed nav tab, an alarming HUD pill — and without a boundary each of
    // those repaints the surface it sits on.
    final painted = RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: SunburstGlyphPainter(
          GlyphScene(
            glyph: glyph,
            colour: colour ?? SunburstColors.of(context).textPrimary,
            strokeWidth: size >= kGlyphNavSize
                ? shape.glyphStrokeNav
                : shape.glyphStrokeControl,
          ),
        ),
      ),
    );

    // The FLIP LIVES HERE, not in the painter. Geometry is direction-agnostic
    // and only chrome mirrors, so there is one path per glyph rather than two,
    // and shouldRepaint stays a pure value compare with no direction in it.
    final mirrored =
        glyph.mirrorsInRtl && Directionality.of(context) == TextDirection.rtl;

    return ExcludeSemantics(
      child: mirrored
          ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(math.pi),
              child: painted,
            )
          : painted,
    );
  }
}
