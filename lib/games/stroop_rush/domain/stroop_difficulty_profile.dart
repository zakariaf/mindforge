import 'package:meta/meta.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/theme/sunburst_colors.dart';

/// What one difficulty of Stroop Rush plays like, as numbers.
///
/// A value type rather than three constants scattered across the generator and
/// the scorer: "Blitz is harder" has to mean something a test can read, and
/// every number here is one a player feels.
@immutable
final class StroopDifficultyProfile {
  /// Creates a profile.
  const StroopDifficultyProfile({
    required this.roundCount,
    required this.pool,
    required this.incongruentShare,
    required this.multiplierCap,
  });

  /// How many rounds a run holds.
  final int roundCount;

  /// The answers this difficulty may offer, in a fixed order.
  ///
  /// Fixed because the generator draws from it by index: a pool that reordered
  /// itself would deal a different game from the same seed.
  final List<PlayAnswer> pool;

  /// What share of rounds print a word that lies about its ink.
  ///
  /// **This IS the difficulty of a Stroop task.** A congruent round asks you to
  /// read; an incongruent one asks you not to. Never 1.0 — with no congruent
  /// rounds at all the conflict stops meaning anything, because there is no
  /// baseline for it to be a conflict against.
  final double incongruentShare;

  /// The highest streak multiplier this difficulty pays.
  final int multiplierCap;
}

/// The four-answer pool chill and classic draw from.
///
/// Red, blue, green, yellow — the four `system.html` §03 draws, each already
/// bound to a distinct [PlayFill], so any four-of-four draw satisfies the
/// distinct-fill rule without filtering.
const List<PlayAnswer> _kBasePool = <PlayAnswer>[
  PlayAnswer.red,
  PlayAnswer.blue,
  PlayAnswer.green,
  PlayAnswer.yellow,
];

/// The six-answer pool blitz draws from.
///
/// Purple and orange are `PlayAnswer`'s two "blitz only" members. They collide
/// on fill with blue and red respectively, which is why the generator
/// rejection-samples for four distinct fills rather than taking any four.
const List<PlayAnswer> _kBlitzPool = <PlayAnswer>[
  ..._kBasePool,
  PlayAnswer.purple,
  PlayAnswer.orange,
];

/// The profile for [difficulty].
///
/// Exhaustive with no `default:`, so a fourth difficulty does not compile until
/// someone decides what it plays like.
///
/// **Every number here is DERIVED.** `app.html` shows one "Classic" chip and a
/// track at 57%; it fixes no round count, no incongruent share and no
/// multiplier cap. The reasoning is at each row, and screen 04's 57% track is
/// consistent with 17 of 30 answered — consistency, not derivation.
StroopDifficultyProfile profileFor(
  Difficulty difficulty,
) => switch (difficulty) {
  // DERIVED. 20 rounds at roughly a second each is a run someone tries while
  // the kettle boils, and 0.60 leaves enough congruent rounds that the trick
  // is still learnable rather than relentless. ×2 because a chill streak is
  // an encouragement, not a score to chase.
  Difficulty.chill => const StroopDifficultyProfile(
    roundCount: 20,
    pool: _kBasePool,
    incongruentShare: 0.6,
    multiplierCap: 2,
  ),
  // DERIVED. The default, and the one the reference screen shows: 30 rounds,
  // three in four of them lying, ×4 at the cap — which is what makes the
  // "×7" on screen 04 a Blitz number rather than a Classic one.
  Difficulty.classic => const StroopDifficultyProfile(
    roundCount: 30,
    pool: _kBasePool,
    incongruentShare: 0.75,
    multiplierCap: 4,
  ),
  // DERIVED. Six hues instead of four is the real step up — the extra two
  // collide on fill with two of the base four, so the board stops being
  // learnable by pattern alone — and 0.90 leaves just enough congruent
  // rounds to keep the reflex punishable.
  Difficulty.blitz => const StroopDifficultyProfile(
    roundCount: 40,
    pool: _kBlitzPool,
    incongruentShare: 0.9,
    multiplierCap: 6,
  ),
};
