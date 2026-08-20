import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

/// How much a card wants to be noticed.
enum PopCardDensity {
  /// A row in a list.
  dense,

  /// The default.
  standard,

  /// The one card a screen is about.
  hero;

  /// The elevation step this density sits at.
  PopElevation get elevation => switch (this) {
    PopCardDensity.dense => PopElevation.e1,
    PopCardDensity.standard => PopElevation.e2,
    PopCardDensity.hero => PopElevation.e3,
  };

  /// The corner this density takes.
  Radius radius(SunburstShape shape) => switch (this) {
    PopCardDensity.dense || PopCardDensity.standard => shape.radiusLg,
    PopCardDensity.hero => shape.radiusXl,
  };
}

/// A surface that holds content.
///
/// Pressable only when given an [onTap]; without one it carries no button role,
/// no press response and no tap action, so a card that merely groups things is
/// not announced as a control.
class PopCard extends StatelessWidget {
  /// Creates a card around [child].
  const PopCard({
    required this.child,
    this.density = PopCardDensity.standard,
    this.fill,
    this.padding = const EdgeInsetsDirectional.all(SunburstShape.cardPadding),
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  /// What the card holds.
  final Widget child;

  /// How much the card wants to be noticed.
  final PopCardDensity density;

  /// The card's fill. Defaults to the raised surface.
  final Color? fill;

  /// The inset around [child].
  final EdgeInsetsDirectional padding;

  /// What a completed tap does. `null` makes the card inert.
  final VoidCallback? onTap;

  /// The label a screen reader announces, when the card is a control.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    return PopSurface(
      fill: fill ?? colours.surfaceRaised,
      radius: BorderRadiusDirectional.all(density.radius(shape)),
      elevation: density.elevation,
      padding: padding,
      onTap: onTap,
      semanticLabel: semanticLabel,
      // A card sizes to its content; the 48pt floor belongs to the controls
      // inside it, not to the grouping around them.
      minTarget: 0,
      child: child,
    );
  }
}

/// The rule between two rows of a card.
///
/// A 3px ink line, not `colours.divider`: inside a card the separation is part
/// of the same drawing as the card's own edge, and a lighter hairline reads as
/// a different construction.
class PopCardDivider extends StatelessWidget {
  /// Creates a divider.
  const PopCardDivider({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: SunburstShape.of(context).borderWidth,
    color: SunburstColors.of(context).border,
  );
}
