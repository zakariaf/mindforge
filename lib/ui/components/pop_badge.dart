import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

/// What a badge is announcing.
enum PopBadgeVariant {
  /// A new personal best.
  best,

  /// Something not yet unlocked.
  locked,

  /// A plain count or tag.
  neutral;

  /// The fill this variant paints.
  Color fill(SunburstColors colours) => switch (this) {
    PopBadgeVariant.best => colours.accent,
    PopBadgeVariant.locked => colours.surfaceSunk,
    PopBadgeVariant.neutral => colours.surfaceRaised,
  };

  /// The mark this variant carries, if any.
  SunburstGlyph? get glyph => switch (this) {
    PopBadgeVariant.best => SunburstGlyph.star,
    PopBadgeVariant.locked => SunburstGlyph.lock,
    PopBadgeVariant.neutral => null,
  };

  /// How far off the page this variant sits.
  ///
  /// `system.html` section 09, transcribed as one rule rather than as the half
  /// of it that was being edited:
  ///
  /// * `.badge` carries `--sh-1` (3px 3px) = [PopElevation.e1];
  /// * `.badge.new` overrides it with `--sh-2` (5px 5px) = [PopElevation.e2],
  ///   in the same declaration as the tilt — a personal best is lifted as well
  ///   as tilted, and taking only the rotation would have shipped a badge that
  ///   leans without rising;
  /// * `.badge.lock` sets `box-shadow:none` = [PopElevation.flat], because a
  ///   locked thing is not raised off the page at all.
  ///
  /// Every variant used to be `PopElevation.chip` (2px 2px), on the strength of
  /// a token doc claiming "the badges in section 09 are drawn with a 2px hard
  /// offset". They are not: the only 2px offset in the stylesheet belongs to a
  /// selected segment.
  PopElevation get elevation => switch (this) {
    PopBadgeVariant.best => PopElevation.e2,
    PopBadgeVariant.neutral => PopElevation.e1,
    PopBadgeVariant.locked => PopElevation.flat,
  };

  /// How this variant's edge is drawn.
  ///
  /// `.badge.lock` sets `border-style:dashed`: a not-yet-real thing gets a
  /// not-yet-solid edge, the same language the locked game card speaks.
  PopBorderStyle get borderStyle => switch (this) {
    PopBadgeVariant.locked => PopBorderStyle.dashed,
    PopBadgeVariant.best || PopBadgeVariant.neutral => PopBorderStyle.solid,
  };
}

/// A small marker sitting on or beside something else.
///
/// Each variant carries the elevation and edge `system.html` section 09 gives
/// it: a plain badge at `--sh-1`, a personal best lifted to `--sh-2` and tilted,
/// a locked one flat with a dashed edge.
class PopBadge extends StatelessWidget {
  /// Creates a badge labelled [label].
  const PopBadge({
    required this.label,
    this.variant = PopBadgeVariant.neutral,
    super.key,
  });

  /// The already-localized label.
  final String label;

  /// What the badge is announcing.
  final PopBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);
    final glyph = variant.glyph;

    final badge = MergeSemantics(
      child: PopSurface(
        fill: variant.fill(colours),
        radius: BorderRadiusDirectional.all(shape.radiusPill),
        elevation: variant.elevation,
        borderStyle: variant.borderStyle,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        minTarget: 0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (glyph != null) ...[
              // DECORATION, like the chip's: the badge's own label carries the
              // meaning and the star beside it is emphasis.
              ExcludeSemantics(
                child: SunburstGlyphIcon(
                  glyph,
                  size: 14,
                  colour: colours.textPrimary,
                ),
              ),
              const SizedBox(width: SunburstShape.space1),
            ],
            Text(
              label,
              style: type.label.copyWith(
                color: variant == PopBadgeVariant.locked
                    ? colours.textDisabled
                    : colours.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );

    // `.badge.new{transform:rotate(-2.5deg)}` in system.html. A RESTING
    // transform, applied here rather than by whatever animates the badge: it is
    // the badge's own geometry, it survives reduce motion, and it is still
    // there long after any celebration has finished.
    //
    // It does not mirror, for the same reason the hard offset shadow does not.
    // Tilting the Persian badge the other way would be a change nobody could
    // name a reason for.
    return variant == PopBadgeVariant.best
        ? Transform.rotate(
            angle: shape.badgeTiltDegrees * math.pi / 180,
            child: badge,
          )
        : badge;
  }
}
