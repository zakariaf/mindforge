import 'package:meta/meta.dart';
import 'package:mindforge/core/difficulty.dart';

/// What one difficulty of False Light plays like, as numbers.
///
/// A value type rather than constants scattered across the generator and the
/// scorer: "blitz is harder" has to mean something a test can read, and every
/// number here is one a player feels.
@immutable
final class LightDifficultyProfile {
  /// Creates a profile.
  const LightDifficultyProfile({
    required this.fieldCount,
    required this.columns,
    required this.rows,
    required this.pressedShareLow,
    required this.pressedShareHigh,
    required this.multiplierCap,
  });

  /// How many fields a run deals before it ends.
  ///
  /// **This is the run's length, and it is a count rather than a duration.**
  /// False Light has no clock: a run ends when the last field's last pressed
  /// tile is swept. A `runSeconds` here would be the shell's timer smuggled
  /// into the board.
  final int fieldCount;

  /// How many tiles across a field is.
  final int columns;

  /// How many tiles down a field is.
  final int rows;

  /// The low end of the share of tiles that are pressed, as a fraction.
  final double pressedShareLow;

  /// The high end of the same share.
  ///
  /// A band rather than a single number so two consecutive fields at the same
  /// difficulty do not look pre-counted. A player who learns that every classic
  /// field holds exactly six targets stops looking at the board and starts
  /// counting taps.
  final double pressedShareHigh;

  /// The highest streak multiplier this difficulty pays.
  final int multiplierCap;

  /// How many tiles a field of this profile holds.
  int get tileCount => columns * rows;
}

/// The profile for [difficulty].
///
/// Exhaustive with no `default:`, so a fourth difficulty does not compile until
/// someone decides what it plays like.
///
/// **Every number here is DERIVED.** No reference screen fixes a field count, a
/// grid or a pressed share for this game; the reasoning is at each row.
///
/// The shape of the ramp is the decision worth stating once: **the grid grows a
/// little and the pressed share falls, so targets get scarcer rather than tiles
/// getting smaller.** Sixteen tiles to thirty is a modest step, and five
/// columns is the cap because of the NARROW device rather than the reference
/// one. Measured against the shell's own gutter — `play_scaffold.dart` gives
/// the board `fromSTEB(20, 12, 20, 20)`, so the content is 350pt at 390 and
/// 280pt at 320 — five columns at the 12pt board gap is 60.4pt at 390 and
/// 46.4pt at 320, which the gap step down to 8pt lifts to 49.6pt. Six columns
/// is 48.3pt at 390, which clears the floor, and 36.7pt at 320, which does not.
/// **320 is the width the floor test is written against**, so six columns is
/// out and five is the cap — while the share falling
/// from 0.30-0.40 to 0.20-0.30 nearly halves how much of the field answers. A
/// difficulty ramp built the other way round, on ever-finer grids, would buy
/// the same difficulty by shrinking the target until blitz was unplayable for
/// anyone with imprecise aim, which is a different game for those players
/// rather than a harder one.
LightDifficultyProfile profileFor(
  Difficulty difficulty,
) => switch (difficulty) {
  // DERIVED. 4x4 is the smallest grid on which a sweep is a scan rather than a
  // glance, eight fields is a minute or so, and 0.30-0.40 means roughly a third
  // of the board answers — dense enough that the first field teaches the rule
  // without anyone explaining it. Multiplier 2, because a chill streak is an
  // encouragement rather than a score to chase.
  Difficulty.chill => const LightDifficultyProfile(
    fieldCount: 8,
    columns: 4,
    rows: 4,
    pressedShareLow: 0.3,
    pressedShareHigh: 0.4,
    multiplierCap: 2,
  ),
  // DERIVED. The default. One extra row rather than one extra column: the
  // board is taller than it is wide, so height is the axis with room to spend,
  // and the tile keeps its chill width. 0.25-0.35 is where the field stops
  // reading as "half of it" and has to be swept.
  Difficulty.classic => const LightDifficultyProfile(
    fieldCount: 12,
    columns: 4,
    rows: 5,
    pressedShareLow: 0.25,
    pressedShareHigh: 0.35,
    multiplierCap: 4,
  ),
  // DERIVED. Five columns is the CAP, not a step on the way to more: it is the
  // widest grid that keeps a tile above the 48px floor at 390px, so blitz buys
  // its difficulty from the share instead. 0.20-0.30 of thirty tiles is six to
  // nine targets in a field the eye cannot take in at once, which is the whole
  // step up.
  Difficulty.blitz => const LightDifficultyProfile(
    fieldCount: 16,
    columns: 5,
    rows: 6,
    pressedShareLow: 0.2,
    pressedShareHigh: 0.3,
    multiplierCap: 6,
  ),
};
