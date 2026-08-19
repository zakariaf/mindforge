// PopButton — the Sunburst button variants, every state, on PopSurface.
//
// There is no ElevatedButton/FilledButton/TextButton anywhere in MindForge:
//
//   // WRONG — Material's ink splash, ambient elevation and its own shape.
//   ElevatedButton(
//     style: ElevatedButton.styleFrom(elevation: 4, backgroundColor: colors.accent),
//     onPressed: onPressed,
//     child: Text(label),
//   );
//
// The variants: primary (accent), success (leaf — "Play" / "Play again"),
// secondary (paper), ghost (no border, no shadow — ONE dismissive action per
// screen, the only sanctioned break in the outline rule).

import 'package:flutter/material.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';

import 'pop_surface.dart';

enum PopButtonVariant { primary, success, secondary, ghost }

/// `large` is the full-width Play / Play again button: 18/20 padding,
/// `buttonLarge` 21 (derived), `radiusXl`. Everything else is `regular`.
enum PopButtonSize { regular, large }

class PopButton extends StatelessWidget {
  const PopButton({
    required this.label,
    required this.onPressed,
    this.variant = PopButtonVariant.primary,
    this.size = PopButtonSize.regular,
    this.leading,
    this.expand = false,
    super.key,
  });

  /// Already localized by the caller — a component never touches AppLocalizations.
  final String label;

  /// Null disables the button; there is no separate `enabled` flag to disagree
  /// with it.
  final VoidCallback? onPressed;

  final PopButtonVariant variant;
  final PopButtonSize size;

  /// A drawn glyph from `lib/ui/icons/` (one ink path, stroke 2.6 or 3). Never an
  /// emoji and never a platform IconData — system.html §08.
  final Widget? leading;

  final bool expand;

  bool get _enabled => onPressed != null;
  bool get _isGhost => variant == PopButtonVariant.ghost;

  Color _fill(SunburstColors colors) => switch (variant) {
    PopButtonVariant.primary => colors.accent,
    PopButtonVariant.success => colors.success,
    PopButtonVariant.secondary => colors.surfaceRaised,
    // Allowed by check_raw_values.sh, which exempts Colors.transparent: there is
    // no "no fill" slot, and inventing one would be a token that paints nothing.
    PopButtonVariant.ghost => Colors.transparent,
  };

  @override
  Widget build(BuildContext context) {
    final colors = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    // Ink is the label colour on every fill in this system — sunshine 9.6:1,
    // leaf 7.1:1, paper 15.2:1. Only the disabled state moves off it.
    final ink = _enabled ? colors.textPrimary : colors.textDisabled;

    final textStyle =
        (size == PopButtonSize.large
                ? type.buttonLarge // derived slot — see SKILL.md
                : type.button)
            .copyWith(color: ink);

    final Widget content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[
          ExcludeSemantics(child: leading!),
          const SizedBox(width: SunburstShape.space2),
        ],
        Flexible(child: Text(label, style: textStyle, textAlign: TextAlign.center)),
      ],
    );

    return PopSurface(
      fill: _fill(colors),
      enabled: _enabled,
      onTap: onPressed,
      // Ghost has no shadow, but it still borrows e1's 2px travel so the press
      // lands somewhere. `borderStyle: none` is what suppresses the shadow.
      elevation: _isGhost ? PopElevation.e1 : PopElevation.e2,
      borderStyle: _isGhost ? PopBorderStyle.none : PopBorderStyle.solid,
      pressScaleOverride: _isGhost ? shape.pressScale : null,
      radius: size == PopButtonSize.large ? shape.radiusXl : shape.radiusLg,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: SunburstShape.space5, // 20
        vertical: size == PopButtonSize.large ? 18 : 15,
      ),
      semanticLabel: label,
      child: _isGhost ? _GhostUnderline(ink: ink, child: content) : content,
    );
  }
}

/// The ghost button's 3px ink rule. Flutter's `decorationThickness` is a
/// multiplier of the font's own underline, not a pixel width, so the rule is a
/// bottom `BorderSide` at `borderWidth` instead. The mockup's 5px underline
/// offset snaps to `space1` (4).
class _GhostUnderline extends StatelessWidget {
  const _GhostUnderline({required this.ink, required this.child});

  final Color ink;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shape = SunburstShape.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ink, width: shape.borderWidth)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(bottom: SunburstShape.space1),
        child: child,
      ),
    );
  }
}

// ── How each state renders, for the golden matrix ────────────────────────────
//
//   rest      primary : accent fill, 3px ink, e2 (5,5)
//   pressed           : +(4,4), shadow (1,1), scale 0.98, over durTap on easePop
//   disabled          : surfaceSunk fill, borderDisabled edge, textDisabled
//                       label, e1 shadow in borderDisabled
//   focused           : the rest shadow PLUS a 4px focusRing outside a 3px gap
//   reduced motion    : no translate, no scale — the shadow still drops to (1,1)
//
// The same five rows exist for success, secondary and ghost; ghost's disabled
// row is text only — no fill, no border, no shadow, nothing to shrink.
//
// A golden test pumps this widget inside the harness's MaterialApp carrying the
// four Sunburst extensions, at textScaler 1.0 and 2.0, in colour and greyscale.
// Harness: widget-golden-and-a11y-testing.
