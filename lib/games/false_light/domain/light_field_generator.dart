import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/seeded_generator.dart';
import 'package:mindforge/games/false_light/domain/light_difficulty_profile.dart';
import 'package:mindforge/games/false_light/domain/light_field.dart';
import 'package:mindforge/games/false_light/domain/tile_depth.dart';

/// False Light's feature salt. **Frozen forever.**
///
/// Changing it re-deals every seed that has ever been played, which turns every
/// bug report carrying a seed into a story about a game nobody can reproduce.
const int kFalseLightFeatureSalt = 0x4C49474854; // 'LIGHT'

/// The generator's contract version.
///
/// Bumped only when the DRAW ORDER changes, which is the only change that can
/// alter what a seed means. Adding a field derived from existing draws does not
/// bump it; reordering the two draws below does.
const int kFalseLightGeneratorVersion = 1;

/// Deals a whole run.
///
/// A **total function** of exactly two inputs. It reads no clock, no locale and
/// no settings object, and it imports nothing from `lib/l10n/` — which is easy
/// to hold here, because a False Light board has nothing on it that could be
/// translated in the first place.
///
/// THE DRAW ORDER IS THE CONTRACT, in this order and no other:
///
/// 1. per field, how many tiles are pressed, drawn inside the profile's share
///    band and clamped so the field is playable;
/// 2. per field, WHICH tiles those are, by a partial Fisher-Yates over the
///    index list, walked downward.
///
/// Reordering these changes what every existing seed means, which is what
/// [kFalseLightGeneratorVersion] is for.
List<LightField> generateLightFields({
  required int seed,
  required Difficulty difficulty,
}) {
  final profile = profileFor(difficulty);
  // ASCII, and asserted so by `seedFrom`: a key built from a formatted number
  // or a translated label compiles, passes an English-only suite, and deals a
  // Persian player a different game.
  final generator = seedFrom(
    'false_light:$seed',
    featureSalt: kFalseLightFeatureSalt,
    // The difficulty is part of the SEED, not just of the grid. Without it
    // blitz would be chill on a bigger board dealt off the same stream — the
    // same opening pattern of targets, which a returning player would notice
    // before any test did.
    modeSalt: difficulty.index,
  );

  return <LightField>[
    for (var index = 0; index < profile.fieldCount; index++)
      _deal(index: index, generator: generator, profile: profile),
  ];
}

/// One field, drawn in the documented order.
LightField _deal({
  required int index,
  required SeededGenerator generator,
  required LightDifficultyProfile profile,
}) {
  final tileCount = profile.tileCount;
  final low = _bound(tileCount, profile.pressedShareLow);
  final high = _bound(tileCount, profile.pressedShareHigh);
  // Draw the COUNT first, then the positions. The other order — walk every
  // tile and press it with probability p — consumes one draw per TILE, so the
  // stream position after each field would be a function of the grid size
  // alone. This order consumes `1 + pressedCount`.
  //
  // **That does not make the stream grid-independent, and an earlier version of
  // this comment claimed it did.** `pressedCount` is drawn from a band computed
  // over `tileCount`, so a change to `columns` or `rows` still shifts every
  // later field on the same seed: measured, chill consumes 6-7 draws per field,
  // classic 6-8 and blitz 7-10. What the order actually buys is that the COUNT
  // draw itself is taken before the grid is consulted for anything but the
  // band, which keeps the first field of a run stable under a grid edit — and
  // that is a smaller claim than the one it replaces. A grid edit is a
  // [kFalseLightGeneratorVersion] bump.
  //
  // The band is inclusive at both ends, and `high >= low` is a property of the
  // PROFILE rather than a hope: `light_field_generator_test` asserts every
  // shipped profile's high share is at least its low one, so a profile that
  // would trip `nextInt`'s positive-bound assert fails as a profile.
  final pressedCount = low + generator.nextInt(high - low + 1);
  final pressed = _pressedPositions(generator, tileCount, pressedCount);

  return LightField(
    index: index,
    columns: profile.columns,
    rows: profile.rows,
    tiles: <TileDepth>[
      for (var i = 0; i < tileCount; i++)
        if (pressed.contains(i)) TileDepth.pressed else TileDepth.raised,
    ],
  );
}

/// Which [count] of [tileCount] positions are pressed.
///
/// A **partial** Fisher-Yates: it walks the index list downward for exactly
/// [count] steps and keeps what each step swaps into place, rather than
/// shuffling all thirty tiles to read six of them. Downward is the direction
/// every other generator in this repository walks, and the direction an oracle
/// transcribing the same definition would.
///
/// It cannot spin: [count] is clamped below [tileCount] by [_bound], so the
/// loop's last `i` is at least 1 and `nextInt` always has a positive bound.
Set<int> _pressedPositions(
  SeededGenerator generator,
  int tileCount,
  int count,
) {
  final indices = <int>[for (var i = 0; i < tileCount; i++) i];
  final pressed = <int>{};

  for (var i = indices.length - 1; i >= indices.length - count; i--) {
    final j = generator.nextInt(i + 1);
    final held = indices[i];

    indices[i] = indices[j];
    indices[j] = held;
    pressed.add(indices[i]);
  }

  return pressed;
}

/// One end of the pressed-count band, in tiles.
///
/// **Clamped into `[1, tileCount - 1]`, and that clamp is the invariant every
/// field depends on.** A field with no pressed tile can never be completed and
/// the run would stall on it forever, because completion is this game's only
/// end condition; a field with every tile pressed has no distractor, so there
/// is nothing to tell the target apart FROM and the board stops being a game.
/// Neither happens under the three shipped profiles — the tightest is blitz at
/// 6..9 of 30 — so the clamp is here for the profile edit that has not been
/// made yet, not for a case in production today.
///
/// The share reaches integer tiles through per-mille integers with a
/// round-half-up, not through `(tileCount * share).round()`. Both are
/// deterministic, but one `double` multiply that feeds a draw is one more thing
/// a future reader has to reason about before trusting a frozen vector, and the
/// per-mille form is exact arithmetic a reader can do in their head.
int _bound(int tileCount, double share) {
  final permille = (share * 1000).round();
  final tiles = (tileCount * permille + 500) ~/ 1000;

  if (tiles < 1) return 1;
  if (tiles > tileCount - 1) return tileCount - 1;

  return tiles;
}
