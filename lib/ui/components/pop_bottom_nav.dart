import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

/// One destination in the nav bar.
@immutable
final class PopNavItem {
  /// Describes a destination.
  const PopNavItem({required this.glyph, required this.label});

  /// The mark. A nav mark is a brand mark and does not mirror.
  final SunburstGlyph glyph;

  /// The already-localized label.
  final String label;
}

/// The three-destination bar at the bottom of the shell.
///
/// **The one partial border in the system.** It carries a 3px ink rule along
/// its top and no other edge — a top border has no handedness, so it is not a
/// directional property and does not mirror. The order of the destinations
/// does mirror, because that is reading order.
///
/// The active item sizes to its own **label**, not to a transcribed width. An
/// 88-point chip fits "Play" and "Stats"; it does not fit "Einstellungen", and a
/// bar whose active chip clips its word in German is a bar that has to be
/// rebuilt.
class PopBottomNav extends StatelessWidget {
  /// Creates a nav bar over [items].
  const PopBottomNav({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  /// The destinations, in reading order.
  final List<PopNavItem> items;

  /// Which destination is current.
  final int selectedIndex;

  /// Called with the index of a newly chosen destination.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colours.surfaceRaised,
        border: Border(
          top: BorderSide(color: colours.border, width: shape.borderWidth),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: SunburstShape.space3,
          vertical: SunburstShape.space2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < items.length; i++)
              _NavDestination(
                item: items[i],
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavDestination extends StatelessWidget {
  const _NavDestination({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final PopNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    return PopSurface(
      fill: selected ? colours.accent : colours.surfaceRaised,
      radius: BorderRadiusDirectional.all(shape.radiusMd),
      elevation: selected ? PopElevation.e1 : PopElevation.flat,
      // A transparent edge at rest rather than no edge at all, so selecting an
      // item adds no width and nothing in the bar shifts.
      borderStyle: selected ? PopBorderStyle.solid : PopBorderStyle.none,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: SunburstShape.space3,
        vertical: SunburstShape.space1,
      ),
      selected: selected,
      semanticLabel: item.label,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SunburstGlyphIcon(item.glyph, colour: colours.textPrimary),
          const SizedBox(height: SunburstShape.space1),
          Text(
            item.label,
            style: type.label.copyWith(color: colours.textPrimary),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
