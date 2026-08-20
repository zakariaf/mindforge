import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_badge.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/components/tabular_text.dart';

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
    this.lockedLabel,
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

  /// The already-localized word on the locked badge.
  ///
  /// Its own string, not the subtitle: reusing the subtitle printed the same
  /// tagline twice on every locked card.
  final String? lockedLabel;

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
                if (locked && lockedLabel != null) ...[
                  const SizedBox(height: SunburstShape.space3),
                  PopBadge(
                    label: lockedLabel!,
                    variant: PopBadgeVariant.locked,
                  ),
                ],
              ],
            ),
          ),
          // The artwork sits at the END edge, which mirrors: a directional Row
          // puts it on the right in English and the left in Persian without a
          // second layout.
          if (art != null) ...[
            const SizedBox(width: SunburstShape.space4),
            // THE FRAME IS THE CARD'S AND THE ART INSIDE IT IS THE GAME'S.
            // app.html: `.gart` is a 64pt cream square with the standard 3px
            // ink edge and an e1 shadow, and a definition contributes only
            // what goes in the middle of it. Mounting a bare widget instead —
            // which is what shipped before the reference comparison — left
            // every game deciding its own frame, or having none.
            //
            // Decoration, and the SHELL says so rather than the game: whether
            // a preview is worth announcing is a card-level decision, and the
            // title and tagline beside it already name the game.
            ExcludeSemantics(
              // 64 is the frame's OUTER size and the 8pt padding is inside
              // it, not around it. Wrapping the other way makes it 80 — which
              // is what the first pass shipped, and what the reference
              // comparison caught.
              child: SizedBox.square(
                dimension: shape.gameArtFrame,
                child: PopSurface(
                  fill: colours.surface,
                  radius: BorderRadiusDirectional.all(shape.radiusMd),
                  elevation: PopElevation.e1,
                  nested: true,
                  minTarget: 0,
                  padding: const EdgeInsetsDirectional.all(8),
                  child: Center(child: art),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The small pill carrying a game's best score.
///
/// It composes [PopSurface] with `nested: true`, which is what gives it the
/// thinner edge: it sits inside another surface, and two 3px borders a few
/// pixels apart read as one smudge.
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
      child: PopSurface(
        fill: colours.surface,
        radius: BorderRadiusDirectional.all(shape.radiusPill),
        elevation: PopElevation.flat,
        nested: true,
        minTarget: 0,
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
            TabularText(
              value,
              style: type.numericHud.copyWith(color: colours.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
