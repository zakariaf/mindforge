import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_badge.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

/// A game on the home hub.
///
/// **The accent arrives as an argument.** This widget reads no global and
/// contains no `switch (gameId)`: the engine is a registry, and a shell that
/// branched on a game's identity would have to be edited to add the next one.
///
/// Its title and subtitle are both `textPrimary`. That is not a default — on a
/// coral fill the secondary ink lands at 2.8:1, which is the trap this note
/// exists to keep someone from walking back into.
class GameCard extends StatelessWidget {
  /// Creates a card for a game.
  const GameCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.semanticLabel,
    this.bestLabel,
    this.bestValue,
    this.artwork,
    this.locked = false,
    this.onTap,
    super.key,
  });

  /// The already-localized game name.
  final String title;

  /// The already-localized tagline.
  final String subtitle;

  /// The game's own colour, from its definition.
  final Color accent;

  /// The already-localized label a screen reader announces.
  final String semanticLabel;

  /// The already-localized word beside the best score, if there is one.
  final String? bestLabel;

  /// The already-localized best score, if there is one.
  final String? bestValue;

  /// The game's artwork tile, at the end edge.
  final Widget? artwork;

  /// Whether the game is not yet available.
  final bool locked;

  /// What a completed tap does.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);
    final best = bestValue;
    final art = artwork;

    return PopSurface(
      fill: locked ? colours.surface : accent,
      radius: BorderRadiusDirectional.all(shape.radiusLg),
      // A locked card is not raised and is edged with a dashed line: it is a
      // placeholder for something that is not there yet, and it should not look
      // like a thing you failed to tap.
      elevation: locked ? PopElevation.flat : PopElevation.e2,
      borderStyle: locked ? PopBorderStyle.dashed : PopBorderStyle.solid,
      padding: const EdgeInsetsDirectional.all(SunburstShape.cardPadding),
      onTap: locked ? null : onTap,
      semanticLabel: semanticLabel,
      minTarget: 0,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: type.title.copyWith(color: colours.textPrimary),
                  textAlign: TextAlign.start,
                  maxLines: 2,
                ),
                const SizedBox(height: SunburstShape.space1),
                Text(
                  subtitle,
                  style: type.caption.copyWith(color: colours.textPrimary),
                  textAlign: TextAlign.start,
                  maxLines: 2,
                ),
                if (best != null) ...[
                  const SizedBox(height: SunburstShape.space3),
                  _BestPill(label: bestLabel ?? '', value: best),
                ],
                if (locked) ...[
                  const SizedBox(height: SunburstShape.space3),
                  PopBadge(label: subtitle, variant: PopBadgeVariant.locked),
                ],
              ],
            ),
          ),
          // The artwork sits at the END edge, which mirrors: a directional Row
          // puts it on the right in English and the left in Persian without a
          // second layout.
          if (art != null) ...[
            const SizedBox(width: SunburstShape.space4),
            art,
          ],
        ],
      ),
    );
  }
}

/// The small pill carrying a game's best score.
///
/// Its edge is [SunburstShape.borderWidthNested] rather than the full ink
/// width: it sits inside another surface, and two 3px borders a few pixels
/// apart read as one smudge.
class _BestPill extends StatelessWidget {
  const _BestPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colours.surface,
          borderRadius: BorderRadius.all(shape.radiusPill),
          border: Border.all(
            color: colours.border,
            width: shape.borderWidthNested,
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // BEST is textSecondary, which is legal here because the pill's
              // own fill is cream — not the card's coral.
              Text(
                label,
                style: type.label.copyWith(color: colours.textSecondary),
              ),
              const SizedBox(width: SunburstShape.space2),
              Text(
                value,
                style: type.numericHud.copyWith(color: colours.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
