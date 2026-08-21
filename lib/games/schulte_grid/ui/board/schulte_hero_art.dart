import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/l10n/l10n_providers.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';

/// The four chips under the tagline on Schulte Grid's detail screen.
///
/// **A DIFFERENT DRAWING from the Home-card tile, and that is the point.** The
/// tile is a 3x3 picture of a board that sizes itself to whatever frame it is
/// given; the hero lays its children out with a finite width and an unbounded
/// height, so reusing the tile there let it take the full column and stand
/// three hundred points tall, pushing the stats, the difficulty control and the
/// Play button below the fold. Stroop Rush hit exactly this and grew a hero row
/// of its own; a definition builds each drawing separately for this reason.
///
/// Where Stroop's row is the four ANSWER PATTERNS — its second channel, met
/// before the first round — this one is the four states a tile can be in:
/// found, next, idle, idle. Schulte's board carries no answer colours at all.
class SchulteHeroArt extends ConsumerWidget {
  /// Creates the row.
  const SchulteHeroArt({super.key});

  /// The values the chips show, and whether each is already found.
  static const List<(int value, bool isFound)> chips = <(int, bool)>[
    (1, true),
    (2, true),
    (3, false),
    (4, false),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numbers = ref.watch(localeNumbersProvider);

    return ExcludeSemantics(
      child: Row(
        // MIN, so the row is four chips wide and not the hero wide.
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final chip in chips) ...<Widget>[
            if (chip != chips.first)
              const SizedBox(width: SunburstShape.space2),
            _Chip(label: numbers.count(chip.$1), isFound: chip.$2),
          ],
        ],
      ),
    );
  }
}

/// One chip: a tile at rest, or a tile already found.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.isFound});

  final String label;
  final bool isFound;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    return Container(
      width: shape.heroSwatchSize,
      height: shape.heroSwatchSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isFound
            ? colours.accentFor(GameAccent.schulte, GameColourRole.deep)
            : colours.surface,
        borderRadius: BorderRadius.all(shape.heroSwatchRadius),
        border: Border.all(color: colours.border, width: shape.borderWidth),
        // The hard offset, through the theme's own helper: no blur, no spread,
        // and it does not mirror.
        boxShadow: shape.shadow(shape.heroSwatchShadow, colours.border),
      ),
      child: Text(
        label,
        style: SunburstType.of(context).button.copyWith(
          color: colours.textPrimary,
        ),
      ),
    );
  }
}
