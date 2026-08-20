import 'package:flutter/material.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

/// The dashed slot standing in for a game that has not shipped.
///
/// **Its own widget, not a `GameCard` with a flag.** `app.html` draws them as
/// two different things and the differences are structural: a locked slot has
/// no shadow, a padlock chip LEADING rather than artwork trailing, a smaller
/// title, ink-2 throughout, and one status line instead of a tagline plus a
/// badge. A locked `GameCard` said the same thing twice — "Not yet unlocked" as
/// its tagline and "Coming soon" as a badge — which is the defect E05 fixed
/// once already, in a different shape.
///
/// It is deliberately **not tappable and not focusable**. It is a promise that
/// the engine grows, not a control that failed.
class LockedGameSlot extends StatelessWidget {
  /// Creates the slot for [title].
  const LockedGameSlot({required this.title, required this.status, super.key});

  /// The game's name.
  final String title;

  /// The one status line: "Coming soon".
  ///
  /// A status, not a disabled control's label — `app.html` says so on the rule
  /// — which is why it is `textSecondary` and never `textDisabled`.
  final String status;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    return MergeSemantics(
      child: PopSurface(
        fill: colours.surfaceSunk,
        radius: BorderRadiusDirectional.all(shape.radiusLg),
        // No shadow. A slot that looked raised would look pressable.
        elevation: PopElevation.flat,
        borderStyle: PopBorderStyle.dashed,
        minTarget: 0,
        padding: const EdgeInsetsDirectional.fromSTEB(15, 14, 15, 14),
        child: Row(
          children: <Widget>[
            ExcludeSemantics(
              child: Container(
                width: shape.lockedChip,
                height: shape.lockedChip,
                decoration: BoxDecoration(
                  color: colours.divider,
                  borderRadius: BorderRadius.all(shape.cardChipRadius),
                  border: Border.all(
                    color: colours.border,
                    width: shape.borderWidth,
                  ),
                ),
                alignment: Alignment.center,
                child: SunburstGlyphIcon(
                  SunburstGlyph.lock,
                  size: 20,
                  colour: colours.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: type.lockedTitle.copyWith(
                      color: colours.textSecondary,
                    ),
                  ),
                  Text(
                    status,
                    style: type.caption.copyWith(color: colours.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
