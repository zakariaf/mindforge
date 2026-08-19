// TEMPLATE — adding a semantic slot to SunburstColors.
//
// Copy the marked fragments into lib/theme/sunburst_colors.dart. Do NOT copy
// this file into lib/. It is a checklist with syntax, not a new theme file.
//
// Read references/adding-a-token.md FIRST and answer the six-step decision
// procedure. Most "I need a new colour" requests are answered by a slot that
// already exists, and a slot added for a value rather than a meaning is
// permanent clutter — nothing ever deletes one.
//
// Worked here: a `chartGrid` slot for Stats chart gridlines, mapped onto the
// existing `inkMuted` primitive (3.59:1 on paper — recessive, but above the 3.0
// non-text floor). Reusing a primitive under a NEW meaning is the common,
// correct case; adding a primitive is a change to system.html, not just to Dart.

import 'package:flutter/material.dart';

// ===========================================================================
// STEP 0 (only if no existing primitive expresses the hue)
// ===========================================================================
// In lib/theme/sunburst_primitives.dart, inside `abstract final class _P`,
// in family order, with its `-deep` partner if anything will ever stripe with
// it. Then add the same value to the :root block AND the token table in
// design/sunburst-pop/system.html in the SAME change — a primitive that exists
// only in Dart is a value that escaped design review.
//
//   static const TODO_name = Color(0xFFTODOHEX);

// ===========================================================================
// STEP 1 of 4 — field + constructor parameter
// ===========================================================================
// In the `const SunburstColors({...})` parameter list, in the group the slot
// belongs to (surfaces / text / structure / accents / game / play / cb):
//
//   required this.chartGrid,
//
// ...and in the matching `final Color ...;` group:
//
//   final Color border, borderDisabled, divider, dotPattern, chartGrid;
//                                                            ^^^^^^^^^

// ===========================================================================
// STEP 2 of 4 — copyWith
// ===========================================================================
// Parameter list:   Color? chartGrid,
// Body:             chartGrid: chartGrid ?? this.chartGrid,

// ===========================================================================
// STEP 3 of 4 — lerp   <-- THE ONE THAT ROTS
// ===========================================================================
// Body:             chartGrid: c(chartGrid, other.chartGrid),
//
// Nothing fails if you skip this. The slot simply never interpolates, forever,
// silently. The compiler cannot help here because `lerp` already exists and
// already compiles. This is the single most-skipped step in a design system.
//
// (SunburstMotion.lerp is a deliberate midpoint snap and needs no per-field
// line. Its comment says so — do not "restore" an interpolation there.)

// ===========================================================================
// STEP 4 of 4 — the const instance   <-- the only step the compiler catches
// ===========================================================================
// In `static const SunburstColors sunburstPop = SunburstColors(...)`:
//
//   chartGrid: _P.inkMuted,
//
// A missing required argument is a compile error, which is exactly why steps
// 1-3 need this checklist and this one does not.

// ===========================================================================
// AND THE GATE — a // @contrast declaration
// ===========================================================================
// Next to the other declarations inside the class, if the slot ever sits under
// text or is itself a UI boundary:
//
//   // @contrast textPrimary chartGrid 4.5  ink label on a gridline
//
// Floors: 4.5 body text, 3.0 large text and non-text UI (WCAG 2.2 SC 1.4.3 /
// 1.4.11). scripts/check_palette_contrast.sh resolves the names through the
// const instance down to primitive hexes and recomputes the ratio. Fix the hex
// or restate the pair — never lower the floor.
//
// A purely decorative slot legitimately has no line. Say so in the Role column
// of references/palette-and-slots.md, so the omission reads as a decision.
// Then check it really is never labelled: `gameStroopDeep` under ink is 3.90:1,
// which is precisely this trap.

// ===========================================================================
// DON'T FORGET
// ===========================================================================
// - Add the field to `_props`, or two different palettes compare equal and a
//   golden test silently stops detecting a palette change.
// - Add the row to references/palette-and-slots.md: name, hex, CSS var, Dart
//   field, role, where used.
// - Run BOTH gates:
//     bash .claude/skills/sunburst-tokens/scripts/check_raw_values.sh
//     bash .claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh

// ---------------------------------------------------------------------------
// Reference shape — what the finished fragments look like in context.
// ---------------------------------------------------------------------------

@immutable
class TemplateSlotExample extends ThemeExtension<TemplateSlotExample> {
  const TemplateSlotExample({
    required this.surfaceRaised,
    required this.chartGrid, // STEP 1
  });

  final Color surfaceRaised;
  final Color chartGrid; // STEP 1

  // @contrast chartGrid surfaceRaised 3.0  gridline against the card it sits on
  //                                          #8E80AE on #FFFFFF = 3.59:1

  static TemplateSlotExample of(BuildContext context) {
    final ext = Theme.of(context).extension<TemplateSlotExample>();
    assert(ext != null, 'TemplateSlotExample missing from ThemeData.extensions');
    return ext!;
  }

  List<Object?> get _props => [surfaceRaised, chartGrid]; // DON'T FORGET

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateSlotExample &&
          runtimeType == other.runtimeType &&
          surfaceRaised == other.surfaceRaised &&
          chartGrid == other.chartGrid;

  @override
  int get hashCode => Object.hashAll(_props);

  @override
  TemplateSlotExample copyWith({
    Color? surfaceRaised,
    Color? chartGrid, // STEP 2
  }) => TemplateSlotExample(
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    chartGrid: chartGrid ?? this.chartGrid, // STEP 2
  );

  @override
  TemplateSlotExample lerp(covariant TemplateSlotExample? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return TemplateSlotExample(
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      chartGrid: c(chartGrid, other.chartGrid), // STEP 3 — the one that rots
    );
  }

  // STEP 4 — the compiler enforces this one.
  static const TemplateSlotExample sunburstPop = TemplateSlotExample(
    surfaceRaised: Color(0xFFFFFFFF), // _P.paper
    chartGrid: Color(0xFF8E80AE), // _P.inkMuted
  );
}
