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
}

/// A small marker sitting on or beside something else.
///
/// It sits at [SunburstShape.eChip] — the half-step below the lowest raised
/// elevation — so it reads as lifted off the surface it annotates rather than
/// standing on the page in its own right.
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

    return MergeSemantics(
      child: PopSurface(
        fill: variant.fill(colours),
        radius: BorderRadiusDirectional.all(shape.radiusPill),
        elevation: PopElevation.chip,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        minTarget: 0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (glyph != null) ...[
              SunburstGlyphIcon(glyph, size: 14, colour: colours.textPrimary),
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
  }
}
