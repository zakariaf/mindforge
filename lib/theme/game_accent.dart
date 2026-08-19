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

  /// The label colour to draw on [accent] in [role].
  ///
  /// Both accents are light enough to take ink, and the `@contrast`
  /// declarations in `sunburst_colors.dart` pin that at 4.5:1. Resolved here
  /// rather than picked at a call site, for the same reason `answerLabel` is.
  Color accentLabelFor(GameAccent accent, GameColourRole role) => textPrimary;
}
