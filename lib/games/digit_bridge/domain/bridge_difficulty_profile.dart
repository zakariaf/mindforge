import 'package:meta/meta.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_distractor.dart';

/// How many chips a Digit Bridge board offers, at every difficulty.
///
/// **Fixed across all three on purpose.** Difficulty is carried by the length
/// of the numeral, which is what the reading task actually costs; changing the
/// chip count would change the board's geometry between difficulties and make
/// the 48px target floor a different calculation in each.
const int kBridgeCandidateCount = 6;

/// What one difficulty of Digit Bridge plays like, as numbers.
@immutable
final class BridgeDifficultyProfile {
  /// Creates a profile.
  const BridgeDifficultyProfile({
    required this.roundCount,
    required this.digitCount,
    required this.multiplierCap,
  });

  /// How many rounds a run holds.
  final int roundCount;

  /// How many digits the target and its near-misses carry.
  ///
  /// **This IS the difficulty of a cross-script matching task.** Every extra
  /// digit is another glyph to hold in the other script while scanning six
  /// candidates for it, and the working-memory cost is roughly linear in it.
  final int digitCount;

  /// The highest streak multiplier this difficulty pays.
  final int multiplierCap;
}

/// The profile for [difficulty].
///
/// Exhaustive with no `default:`, so a fourth difficulty does not compile until
/// someone decides what it plays like.
///
/// **Every number here is DERIVED.** No reference screen fixes a round count, a
/// digit count or a multiplier cap for this game; the reasoning is at each row.
///
/// Three digits is the floor, and not an arbitrary one: at two digits a
/// transposition and a reordering are the same operation, so the taxonomy in
/// [BridgeDistractor] collapses from four kinds to three and the board loses
/// its hardest rung.
BridgeDifficultyProfile profileFor(
  Difficulty difficulty,
) => switch (difficulty) {
  // DERIVED. Three digits is the shortest run that keeps all four distractor
  // kinds distinct, and twelve rounds is a minute or so — long enough to stop
  // guessing, short enough to retry immediately. Multiplier 2, because a chill
  // streak is an encouragement rather than a score to chase.
  Difficulty.chill => const BridgeDifficultyProfile(
    roundCount: 12,
    digitCount: 3,
    multiplierCap: 2,
  ),
  // DERIVED. The default. Four digits is where holding the target in the other
  // script stops being free and the chips have to be read rather than
  // recognised.
  Difficulty.classic => const BridgeDifficultyProfile(
    roundCount: 18,
    digitCount: 4,
    multiplierCap: 4,
  ),
  // DERIVED. Five digits is past most readers' comfortable span in a script
  // they learnt second, which is the point: on blitz the board rewards
  // chunking the numeral rather than memorising it whole.
  Difficulty.blitz => const BridgeDifficultyProfile(
    roundCount: 24,
    digitCount: 5,
    multiplierCap: 6,
  ),
};
