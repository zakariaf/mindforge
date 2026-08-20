import 'package:flutter/material.dart';
import 'package:mindforge/theme/sunburst_colors.dart';

/// Which identity colour a game paints its chrome with.
///
/// A game contributes one of these and inherits every screen. Adding a game
/// adds a case here and a pair of slots in `SunburstColors`, and nothing else.
enum GameAccent {
  /// Stroop Rush.
  stroop,

  /// Schulte Grid.
  schulte,
}

/// Which half of an accent a surface wants.
///
/// The pair exists because the design language is a light face over a darker
/// edge: a raised surface takes [base] and its pressed or shadowed half takes
/// [deep]. A widget asking for "the accent" without saying which half is asking
/// an incomplete question.
enum GameColourRole {
  /// The lighter face.
  base,

  /// The darker edge, pressed face, or found-tile fill.
  deep,
}

/// Resolves a [GameAccent] against the palette.
///
/// An extension rather than a method on `SunburstColors`, so the colour layer
/// does not have to know the set of games — the accent vocabulary belongs to
/// the game surfaces, and the palette only supplies slots.
extension GameAccentTokens on SunburstColors {
  /// The colour for [accent] in [role].
  ///
  /// Exhaustive over both enums with no `default:`, so shipping a third game is
  /// a compile error here rather than a silently grey band.
  Color accentFor(GameAccent accent, GameColourRole role) => switch ((
    accent,
    role,
  )) {
    (GameAccent.stroop, GameColourRole.base) => gameStroop,
    (GameAccent.stroop, GameColourRole.deep) => gameStroopDeep,
    (GameAccent.schulte, GameColourRole.base) => gameSchulte,
    (GameAccent.schulte, GameColourRole.deep) => gameSchulteDeep,
  };

  /// The label colour to draw on [accent] in [role], or **`null` when that
  /// surface carries no compliant label at all**.
  ///
  /// Nullable on purpose, and it is not a hedge. Measured:
  ///
  /// | surface | ink | paper |
  /// |---|---|---|
  /// | `gameStroop` (coral) | **5.49:1** | 3.10:1 |
  /// | `gameStroopDeep` (coralDeep) | 3.90:1 | 3.94:1 |
  /// | `gameSchulte` (turquoise) | **7.27:1** | 2.34:1 |
  /// | `gameSchulteDeep` (turquoiseDeep) | **5.14:1** | 3.29:1 |
  ///
  /// `gameStroopDeep` clears 4.5:1 with **neither**. It is a pressed face, a
  /// shadow edge and the dark half of a stripe — never a text surface — so this
  /// returns `null` rather than handing back a colour that fails the floor. A
  /// caller that needs a label there is asking the wrong question and should
  /// draw on [GameColourRole.base].
  ///
  /// An earlier version returned `textPrimary` unconditionally and its doc
  /// claimed a `@contrast` declaration that did not exist, so the gate and the
  /// contrast test both passed over the one pair that fails.
  /// `game_accent_test.dart` now COMPUTES the ratio for every pair instead of
  /// trusting a declaration list, which is what makes an omission impossible
  /// rather than merely unlikely.
  Color? accentLabelFor(GameAccent accent, GameColourRole role) => switch ((
    accent,
    role,
  )) {
    (GameAccent.stroop, GameColourRole.base) => textPrimary,
    (GameAccent.stroop, GameColourRole.deep) => null,
    (GameAccent.schulte, GameColourRole.base) => textPrimary,
    (GameAccent.schulte, GameColourRole.deep) => textPrimary,
  };
}
