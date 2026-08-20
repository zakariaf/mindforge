import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/seeded_generator.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_difficulty_profile.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_round.dart';
import 'package:mindforge/theme/sunburst_colors.dart';

/// Stroop Rush's feature salt. **Frozen forever.**
///
/// Changing it re-deals every seed that has ever been played, which turns every
/// bug report carrying a seed into a story about a game nobody can reproduce.
const int kStroopFeatureSalt = 0x5354524F4F50; // 'STROOP'

/// The generator's contract version.
///
/// Bumped only when the DRAW ORDER changes, which is the only change that can
/// alter what a seed means. A new field on `StroopRound` that is derived from
/// existing draws does not bump it; reordering the four draws below does.
const int kStroopGeneratorVersion = 1;

/// The colour-blind answer pool.
///
/// **Capped to the four the palette can re-point.** `SunburstColors` swaps
/// exactly red, green, blue and yellow to the CVD-safe set; purple and orange
/// have no swapped partner, so offering them would put two answers on the board
/// whose whole reason for existing is that they are distinguishable — and one
/// pair of them would not be.
const List<PlayAnswer> _kColourBlindPool = <PlayAnswer>[
  PlayAnswer.red,
  PlayAnswer.blue,
  PlayAnswer.green,
  PlayAnswer.yellow,
];

/// Deals a whole run.
///
/// A **total function** of exactly three inputs. It reads no clock, no locale
/// and no settings object, and it imports nothing from `lib/l10n/` — the
/// colour-blind flag arrives as a `bool` rather than as a settings snapshot for
/// that reason.
///
/// THE DRAW ORDER IS THE CONTRACT, in this order and no other:
///
/// 1. the four options, rejection-sampled until their fills are distinct;
/// 2. the ink, from those options;
/// 3. congruency, against the profile's share;
/// 4. the word — the ink itself when congruent, otherwise any OTHER answer.
///
/// Reordering these changes what every existing seed means, which is what
/// [kStroopGeneratorVersion] is for.
List<StroopRound> generateStroopRounds({
  required int seed,
  required Difficulty difficulty,
  required bool isColourBlindPalette,
}) {
  final profile = profileFor(difficulty);
  // ASCII, and asserted so by `seedFrom`: a key built from a formatted number
  // or a translated label compiles, passes an English-only suite, and deals a
  // Persian player a different game.
  final generator = seedFrom(
    'stroop_rush:$seed',
    featureSalt: kStroopFeatureSalt,
    // The difficulty is part of the SEED, not just of the length. Without it
    // Blitz would be Classic with extra innings — the same opening thirty
    // rounds, which a returning player would notice before any test did.
    modeSalt: difficulty.index,
  );
  final pool = isColourBlindPalette ? _kColourBlindPool : profile.pool;

  return <StroopRound>[
    for (var index = 0; index < profile.roundCount; index++)
      _deal(
        index: index,
        generator: generator,
        pool: pool,
        incongruentShare: profile.incongruentShare,
        isColourBlindPalette: isColourBlindPalette,
      ),
  ];
}

/// One round, drawn in the documented order.
StroopRound _deal({
  required int index,
  required SeededGenerator generator,
  required List<PlayAnswer> pool,
  required double incongruentShare,
  required bool isColourBlindPalette,
}) {
  final options = _drawOptions(generator, pool);
  final ink = options[generator.nextInt(options.length)];
  // A ratio compared against a draw in [0, 1000). Integer arithmetic on
  // purpose: a float comparison here would be one more thing that could differ
  // between this and the oracle that freezes the vectors.
  final isIncongruent = generator.nextInt(1000) < (incongruentShare * 1000);

  return StroopRound(
    index: index,
    word: isIncongruent ? _otherThan(generator, ink) : ink,
    ink: ink,
    options: options,
    isColourBlindPalette: isColourBlindPalette,
  );
}

/// Four distinct answers whose fills are also distinct.
///
/// A partial Fisher-Yates shuffle, retried until the fills differ. The retry is
/// what makes the six-answer blitz pool safe: `{blue, purple}` are both solid
/// and `{red, orange}` are both stripe, so an unfiltered draw can offer two
/// keys a colour-blind player cannot tell apart.
///
/// **It cannot loop forever**, and that is a property of the pools rather than
/// a hope: `stroop_difficulty_profile_test` asserts every pool can yield four
/// distinct fills, so a pool that would deadlock fails as a profile.
List<PlayAnswer> _drawOptions(
  SeededGenerator generator,
  List<PlayAnswer> pool,
) {
  while (true) {
    final shuffled = <PlayAnswer>[...pool];

    // Fisher-Yates, downward, which is the direction the oracle also walks.
    for (var i = shuffled.length - 1; i > 0; i--) {
      final j = generator.nextInt(i + 1);
      final held = shuffled[i];

      shuffled[i] = shuffled[j];
      shuffled[j] = held;
    }

    final drawn = shuffled.take(4).toList();

    if (drawn.map((answer) => answer.fill).toSet().length == 4) return drawn;
  }
}

/// Any answer that is not [ink].
///
/// Drawn from the WHOLE answer set rather than from the offered four: naming a
/// colour the player cannot tap is a legitimate Stroop trial, and it is the one
/// the reflex most wants to answer.
PlayAnswer _otherThan(SeededGenerator generator, PlayAnswer ink) {
  final others = PlayAnswer.values.where((answer) => answer != ink).toList();

  return others[generator.nextInt(others.length)];
}
