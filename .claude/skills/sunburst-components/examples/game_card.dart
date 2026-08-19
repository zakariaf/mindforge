// GameCard — the home hub's per-game block (app.html screen 01).
//
// The engine's promise, rendered: a new game supplies a title, a one-line rule,
// its accent and a scrap of artwork, and inherits the card, the press physics,
// the best-score pill and the locked variant. Nothing else changes.
//
// The card is domain-blind: it takes strings the feature already localized and a
// Color the caller already resolved from GameAccent (sunburst-game-surfaces owns
// that mapping). It never imports a game module and never reads a provider.

import 'package:flutter/material.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';

import 'pop_surface.dart';

class GameCard extends StatelessWidget {
  const GameCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.artwork,
    required this.onTap,
    this.bestLabel,
    this.bestValue,
    super.key,
  }) : isLocked = false,
       lockedLabel = null;

  /// The "coming soon" slot. Dashed edge, no shadow, no press — it advertises
  /// that the engine grows without pretending to be a control.
  const GameCard.locked({
    required this.title,
    required this.subtitle,
    required this.artwork,
    required this.lockedLabel,
    super.key,
  }) : isLocked = true,
       accent = null,
       onTap = null,
       bestLabel = null,
       bestValue = null;

  final String title;

  /// The game's rule in one line — "Tap the colour, not the word".
  final String subtitle;

  /// The game's identity colour, resolved from tokens by the caller
  /// (`gameStroop` coral, `gameSchulte` turquoise). Null only when locked.
  final Color? accent;

  /// A drawn scrap of the board: the four-swatch quad, the mini 3×3 grid.
  final Widget artwork;

  final VoidCallback? onTap;

  /// Both already formatted by the ViewModel — no NumberFormat in a build().
  final String? bestLabel;
  final String? bestValue;

  final String? lockedLabel;
  final bool isLocked;

  String get _semanticLabel {
    final best = bestValue == null ? '' : ' $bestLabel $bestValue.';
    final locked = isLocked ? ' $lockedLabel.' : '';
    return '$title. $subtitle.$best$locked';
  }

  @override
  Widget build(BuildContext context) {
    final colors = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    // On a saturated accent the copy is FULL ink: textSecondary drops to 2.8:1
    // on coral. A locked card sits on cream-2, where ink-2 is legal — and
    // "Coming soon" is a status line, so it is never textDisabled.
    final copy = isLocked ? colors.textSecondary : colors.textPrimary;

    return PopSurface(
      fill: isLocked ? colors.surfaceSunk : accent!,
      onTap: onTap,
      elevation: isLocked ? PopElevation.flat : PopElevation.e2,
      borderStyle: isLocked ? PopBorderStyle.dashed : PopBorderStyle.solid,
      radius: shape.radiusLg,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: SunburstShape.space4, // 16
        vertical: 15,
      ),
      semanticLabel: _semanticLabel,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: type.title.copyWith(color: copy)),
                const SizedBox(height: 2),
                Text(subtitle, style: type.caption.copyWith(color: copy)),
                if (bestValue != null) ...[
                  const SizedBox(height: 9),
                  _BestPill(label: bestLabel!, value: bestValue!),
                ],
                if (isLocked) ...[
                  const SizedBox(height: 9),
                  _LockedBadge(label: lockedLabel!),
                ],
              ],
            ),
          ),
          const SizedBox(width: SunburstShape.space3), // 12
          ExcludeSemantics(child: _Artwork(child: artwork)),
        ],
      ),
    );
  }
}

/// BEST · 1,480. A nested chip inside an already-bordered surface, so it takes
/// `borderWidthNested` (2) rather than 3 — the nesting is what makes it read as
/// a sticker on the card instead of a second card. It is not a PopSurface: it
/// has no shadow, no press and no target, so the primitive would only add a
/// gesture nobody wants.
class _BestPill extends StatelessWidget {
  const _BestPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.all(shape.radiusPill),
        border: Border.all(
          color: colors.border,
          width: shape.borderWidthNested,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // textSecondary is legal here: the pill's own fill is cream (7.3:1).
          Text(label, style: type.label.copyWith(color: colors.textSecondary)),
          const SizedBox(width: 6),
          Text(value, style: type.chip), // derived slot — see SKILL.md
        ],
      ),
    );
  }
}

/// Dashed pill, no shadow, ink-2 label — the locked card's status marker.
class _LockedBadge extends StatelessWidget {
  const _LockedBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    return PopSurface(
      fill: colors.surfaceSunk,
      elevation: PopElevation.flat,
      borderStyle: PopBorderStyle.dashed,
      radius: shape.radiusPill,
      minTarget: 0, // not a control: the card around it is not tappable either
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 6),
      child: Text(label, style: type.chip.copyWith(color: colors.textSecondary)),
    );
  }
}

/// 64×64 cream tile, 3px ink, radiusMd, e1 — the artwork's frame, so every game
/// hands in loose art and still lands in the same box.
class _Artwork extends StatelessWidget {
  const _Artwork({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    return SizedBox(
      width: 64,
      height: 64,
      child: PopSurface(
        fill: colors.surface,
        elevation: PopElevation.e1,
        radius: shape.radiusMd,
        minTarget: 0,
        padding: const EdgeInsetsDirectional.all(SunburstShape.space2), // 8
        child: child,
      ),
    );
  }
}

// ── States ───────────────────────────────────────────────────────────────────
//
//   rest     : accent fill, 3px ink, e2 (5,5)
//   pressed  : +(4,4), shadow (1,1), scale 0.98 — durTap 120ms, easePop
//   focused  : e2 kept, plus the 4px focusRing outside a 3px cream gap
//   locked   : surfaceSunk, DASHED 3px ink, no shadow, no press, ink-2 copy
//
// There is no disabled GameCard: a game the player cannot start is `locked`,
// which is a different sentence ("not yet"), not a greyed-out control.
