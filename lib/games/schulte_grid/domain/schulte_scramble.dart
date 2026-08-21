import 'package:mindforge/core/seeded_generator.dart';

/// Bumped when the draw order changes. A new version is a new set of boards.
const int kSchulteGeneratorVersion = 1;

/// How many numbers may sit on their own square.
///
/// **A ceiling, not a ban.** A full derangement is itself a pattern a regular
/// player learns — "1 is never top-left" is information they can use — so some
/// boards leave one or two numbers in place on purpose. What is excluded is the
/// board that reads as barely shuffled.
const int kMaxNaturalPositions = 2;

/// How many times to redraw before repairing by hand.
const int kScrambleAttempts = 8;

/// The tiles of an [size] x [size] Schulte board, in reading order.
///
/// **Integers in, integers out. No locale reaches this function.** The tiles
/// are localized at render, by `LocaleNumbers`, and a formatter in here would
/// mean a Persian player got a different board from a German one — which is
/// what `schulte_scramble_locale_test` exists to prevent, and what would
/// silently void the frozen vector table.
///
/// The draw order is part of the contract: seed derivation, then a Durstenfeld
/// Fisher-Yates walking DOWN, then rejection-resampling from the same stream.
/// Changing any of the three changes every board, which is what
/// [kSchulteGeneratorVersion] is for.
List<int> schulteScramble({required int seed, required int size}) {
  // Salted by size as well as by feature: without it a 4x4 and a 5x5 from the
  // same seed would start from the same stream, and the first sixteen draws of
  // the 5x5 would be recognisably the 4x4's.
  final base = fnv1a64('schulte_grid:v$kSchulteGeneratorVersion:$size') ^ seed;
  final generator = SeededGenerator(base);
  final count = size * size;

  var cells = <int>[];

  // REJECTION FROM THE SAME STREAM, never a fresh generator per attempt: a new
  // generator seeded the same way would draw the same board forever.
  for (var attempt = 0; attempt < kScrambleAttempts; attempt++) {
    cells = List<int>.generate(count, (i) => i + 1);

    for (var i = count - 1; i > 0; i--) {
      final j = generator.nextInt(i + 1);
      final swap = cells[i];

      cells[i] = cells[j];
      cells[j] = swap;
    }

    if (naturalPositionCount(cells) <= kMaxNaturalPositions) return cells;
  }

  // TOTAL, always. Eight rejections in a row is astronomically unlikely and
  // "unlikely" is not a contract: the repair makes the function answer for
  // every seed rather than looping or throwing on the one that got there.
  return repairNaturalPositions(cells);
}

/// How many numbers in [cells] sit on their own square.
int naturalPositionCount(List<int> cells) {
  var count = 0;

  for (var i = 0; i < cells.length; i++) {
    if (cells[i] == i + 1) count++;
  }

  return count;
}

/// [cells] with enough numbers moved off their own square to clear the ceiling.
///
/// **Sound, total and idempotent**, which is why it is exhaustively tested over
/// every permutation of length 5 and 7 rather than sampled: the search for a
/// swap partner is the one place this can run out of candidates, and a sampled
/// test would miss exactly the permutation that has nowhere left to go.
///
/// Each offending index swaps with the first later index whose swap introduces
/// no new natural position, wrapping to the start; the wrap is what makes the
/// last offending index solvable.
List<int> repairNaturalPositions(List<int> cells) {
  final repaired = List<int>.of(cells);
  final length = repaired.length;

  for (var i = 0; i < length; i++) {
    if (naturalPositionCount(repaired) <= kMaxNaturalPositions) break;
    if (repaired[i] != i + 1) continue;

    for (var step = 1; step < length; step++) {
      final j = (i + step) % length;

      // The ONLY two disqualifiers, and they are exactly the two ways a swap
      // can create a natural position: the value arriving at `i` is `i + 1`,
      // or the value arriving at `j` is `j + 1`.
      //
      // A partner already sitting on its own square is emphatically NOT
      // disqualified — it is the best partner there is, because one swap
      // clears both. Excluding it made the identity permutation unrepairable:
      // every index was natural, so every candidate was skipped and the
      // function returned its input unchanged.
      if (repaired[j] == i + 1) continue;
      if (repaired[i] == j + 1) continue;

      final swap = repaired[i];

      repaired[i] = repaired[j];
      repaired[j] = swap;
      break;
    }
  }

  return repaired;
}
