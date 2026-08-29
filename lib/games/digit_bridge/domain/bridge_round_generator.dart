import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/seeded_generator.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_difficulty_profile.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_distractor.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_round.dart';

/// Digit Bridge's feature salt. **Frozen forever.**
///
/// Changing it re-deals every seed that has ever been played, which turns every
/// bug report carrying a seed into a story about a game nobody can reproduce.
const int kBridgeFeatureSalt = 0x4252494447; // 'BRIDG'

/// The generator's contract version.
///
/// Bumped only when the DRAW ORDER changes, which is the only change that can
/// alter what a seed means. Adding a field derived from existing draws does
/// not bump it; reordering the draws below does.
const int kBridgeGeneratorVersion = 1;

/// Deals a whole run.
///
/// A **total function** of exactly two inputs. It reads no clock, no locale and
/// no settings object, and it imports nothing from `lib/l10n/` — which is what
/// makes the golden vectors byte-identical across all four locales for a game
/// whose entire content is numerals.
///
/// THE DRAW ORDER IS THE CONTRACT, in this order and no other:
///
/// 1. the target, from the digit-count band, rejecting all-identical digits;
/// 2. one distractor from each non-empty kind, in [BridgeDistractor] order;
/// 3. the remaining chips, from the union of every kind's pool;
/// 4. the shuffle that lays the six chips out;
/// 5. which side of the bridge the reader's own script sits on.
///
/// Reordering these changes what every existing seed means, which is what
/// [kBridgeGeneratorVersion] is for.
List<BridgeRound> generateBridgeRounds({
  required int seed,
  required Difficulty difficulty,
}) {
  final profile = profileFor(difficulty);
  // ASCII, and asserted so by `seedFrom`: a key built from a formatted number
  // would compile, pass an English-only suite, and deal a Persian player a
  // different game — which for this game would be a different question.
  final generator = seedFrom(
    'digit_bridge:$seed',
    featureSalt: kBridgeFeatureSalt,
    // The difficulty is part of the SEED, not just of the length. Without it
    // blitz would be classic with longer numbers drawn from the same stream.
    modeSalt: difficulty.index,
  );

  return <BridgeRound>[
    for (var index = 0; index < profile.roundCount; index++)
      _deal(index: index, generator: generator, profile: profile),
  ];
}

/// One round, drawn in the documented order.
BridgeRound _deal({
  required int index,
  required SeededGenerator generator,
  required BridgeDifficultyProfile profile,
}) {
  final target = _drawTarget(generator, profile.digitCount);
  final digits = _digitsOf(target);

  final pools = <BridgeDistractor, List<int>>{
    for (final kind in BridgeDistractor.values)
      kind: _poolFor(kind, digits, target),
  };

  final drawn = <int>[];
  final drawnKinds = <BridgeDistractor>[];

  // One from each kind that HAS one, in enum order. A round is only guaranteed
  // all four when the target's digits allow all four: `100` has no valid
  // transposition (the swap that changes it leads with a zero) and no valid
  // reordering, which is a property of the number and not a bug to design out.
  for (final kind in BridgeDistractor.values) {
    final pool = pools[kind]!.where((value) => !drawn.contains(value)).toList();

    if (pool.isEmpty) continue;

    drawn.add(pool[generator.nextInt(pool.length)]);
    drawnKinds.add(kind);
  }

  // Then fill from the union, which is never short: substitution alone offers
  // at least 8 + 9 * (digits - 1) values for any target, and the smallest
  // shipped digit count is three.
  while (drawn.length < kBridgeCandidateCount - 1) {
    final union = <int>[
      for (final kind in BridgeDistractor.values)
        for (final value in pools[kind]!)
          if (!drawn.contains(value)) value,
    ];
    final pick = generator.nextInt(union.length);

    drawn.add(union[pick]);
    drawnKinds.add(_kindOf(union[pick], pools));
  }

  return _layOut(
    index: index,
    generator: generator,
    target: target,
    distractors: drawn,
    kinds: drawnKinds,
  );
}

/// Shuffles the target in among its distractors and records where it landed.
BridgeRound _layOut({
  required int index,
  required SeededGenerator generator,
  required int target,
  required List<int> distractors,
  required List<BridgeDistractor> kinds,
}) {
  final values = <int>[target, ...distractors];
  final tags = <BridgeDistractor?>[null, ...kinds];

  // Fisher-Yates, downward, over both lists at once so a chip and its kind
  // cannot come apart. Two separate shuffles off one generator would produce
  // exactly that, silently, and only the `kinds` assertions would ever see it.
  for (var i = values.length - 1; i > 0; i--) {
    final j = generator.nextInt(i + 1);
    final heldValue = values[i];
    final heldTag = tags[i];

    values[i] = values[j];
    values[j] = heldValue;
    tags[i] = tags[j];
    tags[j] = heldTag;
  }

  return BridgeRound(
    index: index,
    target: target,
    candidates: values,
    correctIndex: values.indexOf(target),
    kinds: tags,
    targetOnReaderScript: generator.nextInt(2) == 0,
  );
}

/// A [digitCount]-digit number with no leading zero and at least two distinct
/// digits.
///
/// The distinctness requirement is what keeps the taxonomy meaningful: `111`
/// has no transposition and no reordering that differs from itself, so a
/// repdigit target would silently drop two of the four kinds from every board
/// that drew one.
int _drawTarget(SeededGenerator generator, int digitCount) {
  final low = _pow10(digitCount - 1);
  final span = _pow10(digitCount) - low;

  while (true) {
    final candidate = low + generator.nextInt(span);

    if (_digitsOf(candidate).toSet().length > 1) return candidate;
  }
}

/// Every valid distractor of [kind] for [target], in a stable order.
///
/// Enumerated rather than rejection-sampled. Both are deterministic, but an
/// enumeration cannot spin: a pool that turns out to be empty is visible here
/// as an empty list rather than as a generator that never returns.
List<int> _poolFor(BridgeDistractor kind, List<int> digits, int target) =>
    switch (kind) {
      BridgeDistractor.transposition => _transpositions(digits, target),
      BridgeDistractor.substitution => _substitutions(digits, target),
      BridgeDistractor.reordering => _reorderings(digits, target),
      BridgeDistractor.lengthChange => _lengthChanges(digits, target),
    };

/// Adjacent swaps, left to right.
List<int> _transpositions(List<int> digits, int target) {
  final out = <int>[];

  for (var i = 0; i < digits.length - 1; i++) {
    final swapped = <int>[...digits];

    swapped[i] = digits[i + 1];
    swapped[i + 1] = digits[i];
    _addIfValid(out, swapped, target);
  }

  return out;
}

/// One digit replaced, position by position, replacement ascending.
List<int> _substitutions(List<int> digits, int target) {
  final out = <int>[];

  for (var i = 0; i < digits.length; i++) {
    for (var d = 0; d <= 9; d++) {
      if (d == digits[i]) continue;

      final swapped = <int>[...digits]..[i] = d;

      _addIfValid(out, swapped, target);
    }
  }

  return out;
}

/// Permutations of the same digits that are NOT a single adjacent swap.
///
/// Subtracting the transpositions is what keeps the two kinds from collapsing:
/// every transposition is a permutation, so an unfiltered permutation pool
/// would let `kinds` report a reordering for a chip that is one adjacent swap
/// away — which is a different question for the player.
List<int> _reorderings(List<int> digits, int target) {
  final swaps = _transpositions(digits, target).toSet();
  final out = <int>[];

  for (final permuted in _permutations(digits)) {
    if (swaps.contains(_valueOf(permuted))) continue;

    _addIfValid(out, permuted, target);
  }

  return out;
}

/// One digit dropped, then one digit appended, in that order.
List<int> _lengthChanges(List<int> digits, int target) {
  final out = <int>[];

  for (var i = 0; i < digits.length; i++) {
    final shorter = <int>[...digits]..removeAt(i);

    _addIfValid(out, shorter, target);
  }

  for (var d = 0; d <= 9; d++) {
    _addIfValid(out, <int>[...digits, d], target);
  }

  return out;
}

/// Appends [digits] to [out] if it is a legal, non-duplicate distractor.
///
/// A leading zero is rejected because the board renders a bare numeral with no
/// padding: `047` and `47` would paint identically in both scripts, so one of
/// them is a chip the player cannot distinguish from another chip.
void _addIfValid(List<int> out, List<int> digits, int target) {
  if (digits.isEmpty || digits.first == 0) return;

  final value = _valueOf(digits);

  if (value == target || out.contains(value)) return;

  out.add(value);
}

/// Every ordering of [digits], in a stable order.
///
/// Heap's algorithm would be shorter and is NOT used: its output order depends
/// on its recursion, which makes the frozen vectors depend on an implementation
/// detail nobody reading the table could reconstruct. This is
/// insert-into-every-position, which walks lexicographically over positions and
/// is what the oracle also walks.
List<List<int>> _permutations(List<int> digits) {
  if (digits.length <= 1) {
    return <List<int>>[
      <int>[...digits],
    ];
  }

  final out = <List<int>>[];

  for (final tail in _permutations(digits.sublist(1))) {
    for (var i = 0; i <= tail.length; i++) {
      out.add(<int>[...tail.sublist(0, i), digits.first, ...tail.sublist(i)]);
    }
  }

  return out;
}

/// Which kind [value] came from, preferring the earliest in enum order.
///
/// A value can legitimately sit in two pools — a substitution can also be a
/// length change of a different target — so "the first kind that claims it" is
/// the rule, and it is stable because [BridgeDistractor.values] is.
BridgeDistractor _kindOf(int value, Map<BridgeDistractor, List<int>> pools) {
  for (final kind in BridgeDistractor.values) {
    if (pools[kind]!.contains(value)) {
      return kind;
    }
  }

  // Unreachable: every drawn value came out of one of the pools. Stated as a
  // fallback rather than a `!` so a future pool change degrades to a wrong
  // label instead of a crash mid-run.
  return BridgeDistractor.substitution;
}

/// [value]'s digits, most significant first.
List<int> _digitsOf(int value) {
  final out = <int>[];

  for (var rest = value; rest > 0; rest ~/= 10) {
    out.insert(0, rest % 10);
  }

  return out.isEmpty ? <int>[0] : out;
}

/// [digits] read back as a number.
int _valueOf(List<int> digits) =>
    digits.fold<int>(0, (value, digit) => value * 10 + digit);

/// Ten to the [exponent], as an integer.
///
/// `math.pow` returns a `num` and goes through doubles; at five digits that is
/// still exact, but a digit count is a loop bound and a loop is both clearer
/// and immune to the question.
int _pow10(int exponent) {
  var value = 1;

  for (var i = 0; i < exponent; i++) {
    value *= 10;
  }

  return value;
}
