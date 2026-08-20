import 'package:flutter/material.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/components/tabular_text.dart';

/// The final score, set in white with a hard sunshine drop shadow.
///
/// **The text shadow does not mirror, and that is the same rule as the box
/// shadow.** One imaginary light for the whole app: a score whose shadow fell
/// to the start edge in Persian would be lit from the other side of the room
/// than every button on the screen below it.
///
/// It does not shrink at large text scales, and nothing in it scales text down
/// to fit its container. A score that gets SMALLER when the player asks for
/// larger text has inverted the setting they chose; the slab grows instead.
class ScoreSlab extends StatelessWidget {
  /// Creates the slab showing [value] under [label].
  const ScoreSlab({required this.label, required this.value, super.key});

  /// The already-localized caption.
  final String label;

  /// The already-localized score.
  final String value;

  /// The shadow the numerals cast. `app.html`: `text-shadow:5px 5px 0`.
  static const Offset shadowOffset = Offset(5, 5);

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    return MergeSemantics(
      child: PopSurface(
        fill: colours.surfaceRaised,
        radius: BorderRadiusDirectional.all(shape.radiusXl),
        elevation: PopElevation.e3,
        minTarget: 0,
        padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              textAlign: TextAlign.center,
              style: type.slabLabel.copyWith(color: colours.textSecondary),
            ),
            const SizedBox(height: 4),
            TabularText(
              value,
              style: type.scoreHero.copyWith(
                color: colours.textPrimary,
                shadows: <Shadow>[
                  // Zero blur is the whole look. A soft one reads as a print
                  // misregistration rather than a deliberate offset.
                  Shadow(color: colours.accent, offset: shadowOffset),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
