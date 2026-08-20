import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

/// What a button is for, which is what decides its fill.
enum PopButtonVariant {
  /// The one thing this screen wants you to do.
  primary,

  /// A confirming action.
  success,

  /// An action that is available but not the point.
  secondary,

  /// A quiet action, drawn with no surface at all.
  ghost;

  /// The fill this variant paints.
  Color fill(SunburstColors colours) => switch (this) {
    PopButtonVariant.primary => colours.accent,
    PopButtonVariant.success => colours.success,
    PopButtonVariant.secondary => colours.surfaceRaised,
    // A ghost is the page showing THROUGH, not a pale surface: a translucent
    // fill would pick up whatever is behind it and read differently on cream
    // than on a coloured card.
    PopButtonVariant.ghost => Colors.transparent,
  };

  /// How this variant's surface is edged.
  PopBorderStyle get borderStyle => this == PopButtonVariant.ghost
      ? PopBorderStyle.none
      : PopBorderStyle.solid;

  /// How far off the page this variant sits.
  ///
  /// A ghost is flat — it has no surface to raise — but it still travels on
  /// press, at the smallest step, so the acknowledgement survives.
  PopElevation get elevation =>
      this == PopButtonVariant.ghost ? PopElevation.flat : PopElevation.e2;
}

/// How large a button is.
enum PopButtonSize {
  /// The default.
  regular,

  /// A full-width primary action, at its own type step and corner.
  large;

  /// The type step this size labels itself at.
  TextStyle label(SunburstType type) =>
      this == PopButtonSize.large ? type.buttonLarge : type.button;

  /// The corner this size takes.
  Radius radius(SunburstShape shape) =>
      this == PopButtonSize.large ? shape.radiusXl : shape.radiusMd;

  /// The inset around the label.
  EdgeInsetsDirectional get padding => this == PopButtonSize.large
      ? const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 18)
      : const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 12);
}

/// A labelled action, on the one raised surface.
///
/// **There is no `enabled` parameter.** A `null` [onPressed] is what disables
/// it, so there is exactly one answer to "is this button live" and no way for
/// two flags to disagree — the mistake being avoided is a button that looks
/// enabled and does nothing.
///
/// The label never shrinks to fit. It wraps to two lines at its own type step,
/// with no overflow treatment and nothing scaling it down to the box: a label
/// that does not fit is a failure of the layout matrix, not something to hide
/// on a player's phone.
class PopButton extends StatelessWidget {
  /// Creates a button labelled [label].
  const PopButton({
    required this.label,
    required this.onPressed,
    this.variant = PopButtonVariant.primary,
    this.size = PopButtonSize.regular,
    this.leading,
    this.expand = false,
    super.key,
  });

  /// The already-localized label.
  ///
  /// **Already localized**: no component formats a string or a number. The
  /// shell owns `AppLocalizations` and `LocaleNumbers` and hands the result in.
  final String label;

  /// What a completed tap does. `null` disables the button.
  final VoidCallback? onPressed;

  /// What the button is for.
  final PopButtonVariant variant;

  /// How large it is.
  final PopButtonSize size;

  /// An optional mark at the start edge.
  final SunburstGlyph? leading;

  /// Whether the button fills the width it is given.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);
    final glyph = leading;
    final enabled = onPressed != null;

    return PopSurface(
      fill: variant.fill(colours),
      radius: BorderRadiusDirectional.all(size.radius(shape)),
      elevation: variant.elevation,
      borderStyle: variant.borderStyle,
      padding: size.padding,
      onTap: onPressed,
      enabled: enabled,
      semanticLabel: label,
      // A ghost has no surface to shrink, so it travels at the small step
      // rather than the one its flat elevation would choose.
      pressScaleOverride: variant == PopButtonVariant.ghost
          ? shape.pressScaleSmall
          : null,
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (glyph != null) ...[
            SunburstGlyphIcon(
              glyph,
              size: 20,
              colour: enabled ? colours.textPrimary : colours.textDisabled,
            ),
            const SizedBox(width: SunburstShape.space2),
          ],
          Flexible(
            child: Text(
              label,
              style: size
                  .label(type)
                  .copyWith(
                    color: enabled ? colours.textPrimary : colours.textDisabled,
                  ),
              textAlign: TextAlign.start,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
