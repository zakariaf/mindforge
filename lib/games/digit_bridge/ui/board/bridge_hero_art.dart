import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/numeral_script.dart';
import 'package:mindforge/games/digit_bridge/ui/board/bridge_numeral.dart';
import 'package:mindforge/l10n/l10n_providers.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';

/// The four chips under the tagline on Digit Bridge's detail screen.
///
/// **A DIFFERENT DRAWING from the Home-card tile**, for the reason
/// `SchulteHeroArt` records: the tile sizes itself to whatever frame it is
/// given, and reusing it in a column with an unbounded height let it stand
/// three hundred points tall and push the Play button below the fold.
///
/// Where Stroop's row is the four answer patterns and Schulte's is the four
/// tile states, this one is **the legend for the two numbering systems** — the
/// same two values in both scripts, met on a screen with no clock running,
/// rather than worked out mid-round. It is the closest thing this game has to a
/// tutorial, and it costs nothing because the detail screen is already there.
class BridgeHeroArt extends ConsumerWidget {
  /// Creates the row.
  const BridgeHeroArt({super.key});

  /// The values the chips show. Two of them, each drawn in both systems.
  static const List<int> values = <int>[4, 7];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numbers = ref.watch(localeNumbersProvider);

    return ExcludeSemantics(
      child: Row(
        // MIN, so the row is four chips wide and not the hero wide.
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final value in values) ...<Widget>[
            if (value != values.first)
              const SizedBox(width: SunburstShape.space2),
            _Chip(label: numbers.digitsInScript(value, NumeralScript.latin)),
            const SizedBox(width: SunburstShape.space2),
            _Chip(
              label: numbers.digitsInScript(
                value,
                NumeralScript.easternArabic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One chip: a numeral at rest.
class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    return Container(
      width: shape.heroSwatchSize,
      height: shape.heroSwatchSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colours.surfaceRaised,
        borderRadius: BorderRadius.all(shape.heroSwatchRadius),
        border: Border.all(color: colours.border, width: shape.borderWidth),
        // The hero swatch's own offset, which is smaller than e1 on purpose:
        // a 38pt chip carrying the full 3px edge takes e1 as a slab rather
        // than a lift. Every other hero row in the app draws it.
        boxShadow: shape.shadow(shape.heroSwatchShadow, colours.border),
      ),
      child: BridgeNumeral(
        label: label,
        style: SunburstType.of(
          context,
        ).miniTile.copyWith(color: colours.textPrimary),
      ),
    );
  }
}
