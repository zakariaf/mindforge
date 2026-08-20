import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

/// A small pill carrying a word, and sometimes a mark.
///
/// A label, not a control: a chip has no `onTap` and no press. The streak
/// indicator on Home is one of these, and so is a game's tag.
class PopChip extends StatelessWidget {
  /// Creates a chip labelled [label].
  const PopChip({required this.label, this.glyph, this.fill, super.key});

  /// The already-localized label.
  final String label;

  /// An optional mark at the start edge.
  final SunburstGlyph? glyph;

  /// The chip's fill. Defaults to the raised surface.
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);
    final mark = glyph;

    return PopSurface(
      fill: fill ?? colours.surfaceRaised,
      radius: BorderRadiusDirectional.all(shape.radiusPill),
      elevation: PopElevation.e1,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 14,
        vertical: 7,
      ),
      // A chip is not a target, so it does not claim the 48pt floor and push
      // the row it sits in taller than the design.
      minTarget: 0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mark != null) ...[
            SunburstGlyphIcon(mark, size: 16, colour: colours.textPrimary),
            const SizedBox(width: SunburstShape.space2),
          ],
          Text(
            label,
            style: type.chip.copyWith(color: colours.textPrimary),
            textAlign: TextAlign.start,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
