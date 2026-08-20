import 'package:flutter/widgets.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

/// A three-item chooser whose selected item **lifts** instead of pressing.
///
/// The inversion is the point: everything else in Sunburst Pop goes down when
/// you touch it, so a segment that comes up reads unmistakably as *chosen*
/// rather than as *being touched*.
///
/// **The order mirrors.** The items are laid out in reading order, so the first
/// difficulty is at the left in English and at the right in Persian. That falls
/// out of a directional `Row` rather than a reversed list — reversing the list
/// would also reverse the semantics order, and a screen reader would read the
/// hardest option first.
class DifficultySegmented extends StatelessWidget {
  /// Creates a chooser over [labels], with [selectedIndex] chosen.
  const DifficultySegmented({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  /// The already-localized labels, in increasing difficulty.
  final List<String> labels;

  /// Which item is chosen.
  final int selectedIndex;

  /// Called with the index of a newly chosen item.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    return PopSurface(
      fill: colours.surfaceSunk,
      radius: BorderRadiusDirectional.all(shape.radiusPill),
      elevation: PopElevation.flat,
      padding: const EdgeInsetsDirectional.all(4),
      minTarget: 0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            PopSurface(
              fill: i == selectedIndex ? colours.accent : colours.surfaceSunk,
              radius: BorderRadiusDirectional.all(shape.radiusPill),
              // The chosen item is the only one that is raised. The others are
              // flat and draw no shadow at all.
              elevation: i == selectedIndex
                  ? PopElevation.e1
                  : PopElevation.flat,
              borderStyle: i == selectedIndex
                  ? PopBorderStyle.solid
                  : PopBorderStyle.none,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              selected: i == selectedIndex,
              commitMoment: Moment.difficultySelect,
              semanticLabel: labels[i],
              onTap: () => onSelected(i),
              child: Text(
                labels[i],
                style: type.label.copyWith(color: colours.textPrimary),
                maxLines: 1,
              ),
            ),
        ],
      ),
    );
  }
}
