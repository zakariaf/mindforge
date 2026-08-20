import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

/// A square action carrying one drawn mark.
///
/// **[semanticLabel] is required.** A glyph excludes itself from semantics
/// precisely so the label belongs to the control around it; a mark with no
/// label is a button a screen reader announces as nothing at all.
class PopIconButton extends StatelessWidget {
  /// Creates a square action drawing [glyph].
  const PopIconButton({
    required this.glyph,
    required this.semanticLabel,
    required this.onPressed,
    this.fill,
    super.key,
  });

  /// The mark to draw. A directional one mirrors on its own.
  final SunburstGlyph glyph;

  /// The already-localized label a screen reader announces.
  final String semanticLabel;

  /// What a completed tap does. `null` disables the button.
  final VoidCallback? onPressed;

  /// The surface fill. Defaults to the raised surface.
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    return PopSurface(
      fill: fill ?? colours.surfaceRaised,
      radius: BorderRadiusDirectional.all(shape.radiusMd),
      elevation: PopElevation.e1,
      onTap: onPressed,
      enabled: onPressed != null,
      semanticLabel: semanticLabel,
      child: SizedBox.square(
        // The mark is 22; the surface's own 48pt floor is what makes the target
        // legal, so the glyph is not padded up to meet it.
        dimension: 22,
        child: SunburstGlyphIcon(
          glyph,
          colour: onPressed == null
              ? colours.textDisabled
              : colours.textPrimary,
        ),
      ),
    );
  }
}
