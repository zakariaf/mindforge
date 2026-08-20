import 'package:mindforge/core/difficulty.dart';

/// How big the grid is at each difficulty.
///
/// **Two difficulties ship, not three.** Blitz would be 6x6, and
/// `schulte_rules_test` records the arithmetic rather than a comment: on a
/// 320pt device the cell lands at 40pt, under the 48pt tap floor, and the
/// shell's only remaining lever — narrowing its gutter — reaches 41.33pt and
/// still misses. On the narrowest iPhone actually sold, 375pt, the cell is
/// 49.17pt and the tap-target argument no longer withholds anything; what
/// withholds it there is the glyph fit, measured on the board itself, because
/// a two-digit Eastern Arabic numeral does not fit a 39.17pt inner box at an
/// accessible text scale.
///
/// `forDifficulty` still answers for `blitz`. A table with a hole in it is a
/// crash waiting for a hand-edited deep link, and `Routes.configFrom` accepts
/// any difficulty the enum has.
final class SchulteRules {
  /// Creates the rules for a [gridSize] x [gridSize] board.
  const SchulteRules({required this.gridSize});

  /// The rules [difficulty] plays under.
  factory SchulteRules.forDifficulty(Difficulty difficulty) => SchulteRules(
    gridSize: switch (difficulty) {
      Difficulty.chill => 4,
      Difficulty.classic => 5,
      Difficulty.blitz => 6,
    },
  );

  /// Cells per side.
  final int gridSize;

  /// How many tiles the board holds.
  int get cellCount => gridSize * gridSize;
}

/// The difficulties Schulte Grid offers.
///
/// The definition reads this; the detail screen renders whatever it finds. A
/// game offering two of three is exactly the case that would have been a
/// `switch (gameId)` in the shell if the list were not data.
const List<Difficulty> schulteDifficulties = <Difficulty>[
  Difficulty.chill,
  Difficulty.classic,
];
