// TEMPLATE — a new Sunburst Pop component.
//
// Copy to lib/ui/components/<snake_name>.dart, rename PopThing, delete this
// banner. Before you start: the component must already exist in
// references/component-catalog.md. A surface that is not in the catalog is not a
// component — add the row (fill, radius, elevation, states, screens) first, or
// you are inventing a fourteenth contract.
//
// Then, in order:
//   1. Name the fill, radius and elevation as TOKEN slots. No literals.
//   2. Compose PopSurface. Never a second BoxDecoration carrying border+shadow.
//   3. Fill in the state matrix below — all five rows, or say why a row is n/a.
//   4. Give every state a non-colour channel (shadow, translate, glyph, word).
//   5. Wire the golden hook at the bottom.
//   6. Run scripts/check_component_hygiene.sh and check_raw_values.sh.

import 'package:flutter/material.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';

import 'pop_surface.dart';

/// <One sentence: what it is, and which screen it appears on.>
///
/// Anatomy: <ink glyph · gap · label · trailing value>.
/// Consumes: <fill slot>, <text slot>, radius<Sm|Md|Lg|Xl|Pill>, e<flat|1|2|3|4>.
class PopThing extends StatelessWidget {
  const PopThing({
    required this.label,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  /// Already localized and already formatted — a component does no domain work.
  final String label;

  /// Null disables the component. Do not add a second `enabled` flag that can
  /// disagree with this one.
  final VoidCallback? onTap;

  final bool selected;

  bool get _enabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    final colors = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);

    // Selected changes the FILL and gains a border/elevation; disabled is
    // resolved inside PopSurface (surfaceSunk + borderDisabled + a shallower
    // shadow), so never branch on `_enabled` for the fill here.
    final fill = selected ? colors.accent : colors.surfaceRaised;
    final ink = _enabled ? colors.textPrimary : colors.textDisabled;

    return PopSurface(
      fill: fill,
      onTap: onTap,
      enabled: _enabled,
      selected: selected,
      elevation: selected ? PopElevation.e2 : PopElevation.e1,
      radius: shape.radiusMd,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: SunburstShape.space3, // 12
        vertical: SunburstShape.space2, // 8
      ),
      semanticLabel: label,
      child: Text(label, style: type.button.copyWith(color: ink)),
    );
  }
}

// ── State matrix — fill every row before opening the PR ──────────────────────
//
//   rest     : <fill> · e<n> · <text slot>
//   pressed  : +pressTranslate(offset) · shadow pressedShadow (1,1) · ×<.97|.98>
//   disabled : surfaceSunk · borderDisabled edge · textDisabled label · e1 ink-3
//   selected : <fill> · border appears · <elevation change> · <translate>
//   focused  : rest shadow kept · 4px focusRing outside a 3px surface gap
//
//   reduced motion : transform dropped, pressed shadow + fill still applied
//   non-colour channel per state : <shadow depth | translate | glyph | word>
//   tap target : ≥48px on the fill box, or the enclosing row owns the gesture
//
// ── Golden hook ──────────────────────────────────────────────────────────────
//
//   test/ui/components/pop_thing_golden_test.dart
//     • one golden per row above, at textScaler 1.0 and 2.0
//     • one greyscale golden of the full matrix — if two states become the same
//       image, a state is carried by hue alone and the component is not done
//     • one a11y pass: tap-target size, Semantics(button/enabled/selected)
//
// The harness (pumpPopComponent, the ThemeData carrying the four Sunburst
// extensions, the greyscale filter) is owned by widget-golden-and-a11y-testing
// — do not write a per-component MaterialApp wrapper here.
