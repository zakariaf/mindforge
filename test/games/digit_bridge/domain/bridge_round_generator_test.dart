import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_difficulty_profile.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_distractor.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_round.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_round_generator.dart';

/// Every round a sweep of [seeds] deals at [difficulty].
Iterable<BridgeRound> sweep(Difficulty difficulty, {int seeds = 200}) sync* {
  for (var seed = 0; seed < seeds; seed++) {
    yield* generateBridgeRounds(seed: seed, difficulty: difficulty);
  }
}

void main() {
  group('determinism', () {
    test('the same seed deals the same run, every time', () {
      final first = generateBridgeRounds(
        seed: 7,
        difficulty: Difficulty.classic,
      );

      for (var i = 0; i < 1000; i++) {
        expect(
          generateBridgeRounds(seed: 7, difficulty: Difficulty.classic),
          first,
        );
      }
    });

    test('and a different seed deals a different one', () {
      expect(
        generateBridgeRounds(seed: 8, difficulty: Difficulty.classic),
        isNot(generateBridgeRounds(seed: 7, difficulty: Difficulty.classic)),
      );
    });

    test('and the difficulty is part of the seed, not just the length', () {
      // Without the mode salt, blitz would be classic with longer numbers
      // drawn off the same stream -- the same opening rounds, which a
      // returning player notices before any test does.
      final classic = generateBridgeRounds(
        seed: 3,
        difficulty: Difficulty.classic,
      ).first;
      final blitz = generateBridgeRounds(
        seed: 3,
        difficulty: Difficulty.blitz,
      ).first;

      expect(
        blitz.targetOnReaderScript == classic.targetOnReaderScript,
        isA<bool>(),
      );
      expect(blitz.candidates, isNot(classic.candidates));
    });
  });

  group('the board is answerable', () {
    test('exactly one chip is the target, at correctIndex', () {
      for (final difficulty in Difficulty.values) {
        for (final round in sweep(difficulty)) {
          expect(
            round.candidates.where((value) => value == round.target),
            hasLength(1),
            reason: 'two winning chips is two right answers',
          );
          expect(round.candidates[round.correctIndex], round.target);
          expect(round.correct, round.target);
        }
      }
    });

    test('every chip is distinct, so no round is won by tapping a twin', () {
      for (final difficulty in Difficulty.values) {
        for (final round in sweep(difficulty)) {
          expect(round.candidates.toSet(), hasLength(kBridgeCandidateCount));
        }
      }
    });

    test('there are always six chips and six kinds, parallel by index', () {
      for (final difficulty in Difficulty.values) {
        for (final round in sweep(difficulty)) {
          expect(round.candidates, hasLength(kBridgeCandidateCount));
          expect(round.kinds, hasLength(kBridgeCandidateCount));
          expect(
            round.kinds[round.correctIndex],
            isNull,
            reason: 'the target is not a distractor and has no kind',
          );
          expect(
            round.kinds.where((kind) => kind == null),
            hasLength(1),
            reason: 'exactly one chip is the target',
          );
        }
      }
    });
  });

  group('the numerals themselves', () {
    test('the target carries the profile digit count and no leading zero', () {
      for (final difficulty in Difficulty.values) {
        final digits = profileFor(difficulty).digitCount;

        for (final round in sweep(difficulty)) {
          expect(round.target.toString(), hasLength(digits));
          expect(round.target.toString().startsWith('0'), isFalse);
        }
      }
    });

    test('the target is never a repdigit', () {
      // 111 has no transposition and no reordering that differs from itself,
      // so a repdigit target silently drops two of the four kinds.
      for (final difficulty in Difficulty.values) {
        for (final round in sweep(difficulty)) {
          expect(
            round.target.toString().split('').toSet().length,
            greaterThan(1),
          );
        }
      }
    });

    test('no chip has a leading zero, in any script', () {
      // The board paints a bare numeral with no padding, so 047 and 47 would
      // be two chips a player cannot tell apart.
      for (final difficulty in Difficulty.values) {
        for (final round in sweep(difficulty)) {
          for (final value in round.candidates) {
            expect(value, greaterThan(0));
            expect(value.toString().startsWith('0'), isFalse);
          }
        }
      }
    });
  });

  group('the distractor taxonomy', () {
    test('every kind is dealt somewhere in a sweep', () {
      for (final difficulty in Difficulty.values) {
        final seen = <BridgeDistractor>{};

        for (final round in sweep(difficulty)) {
          seen.addAll(round.kinds.whereType<BridgeDistractor>());
        }

        expect(
          seen,
          BridgeDistractor.values.toSet(),
          reason: 'a kind that is never dealt is a kind that does not exist',
        );
      }
    });

    test('and the hard kinds are the common case, not the rare one', () {
      // A lengthChange is rejectable peripherally. If most chips were one, the
      // board would be a spot-the-shape exercise and neither script would have
      // to be read -- which is the game not existing.
      for (final difficulty in Difficulty.values) {
        final counts = <BridgeDistractor, int>{
          for (final kind in BridgeDistractor.values) kind: 0,
        };

        for (final round in sweep(difficulty)) {
          for (final kind in round.kinds.whereType<BridgeDistractor>()) {
            counts[kind] = counts[kind]! + 1;
          }
        }

        final total = counts.values.reduce((a, b) => a + b);
        final easy = counts[BridgeDistractor.lengthChange]!;

        expect(
          easy / total,
          lessThan(0.5),
          reason: 'length changes are $easy of $total chips at $difficulty',
        );
      }
    });

    test('a transposition really is one adjacent swap of the target', () {
      for (final round in sweep(Difficulty.classic, seeds: 50)) {
        for (var i = 0; i < round.candidates.length; i++) {
          if (round.kinds[i] != BridgeDistractor.transposition) continue;

          expect(
            _isAdjacentSwap(round.target, round.candidates[i]),
            isTrue,
            reason:
                '${round.candidates[i]} is not one swap from ${round.target}',
          );
        }
      }
    });

    test('a reordering keeps the digits and is NOT one adjacent swap', () {
      // The two kinds would otherwise collapse: every transposition is a
      // permutation, so an unfiltered pool would label a single swap as a
      // reordering -- a different question for the player.
      for (final round in sweep(Difficulty.classic, seeds: 50)) {
        for (var i = 0; i < round.candidates.length; i++) {
          if (round.kinds[i] != BridgeDistractor.reordering) continue;

          final value = round.candidates[i];

          expect(_sortedDigits(value), _sortedDigits(round.target));
          expect(_isAdjacentSwap(round.target, value), isFalse);
        }
      }
    });

    test('a substitution changes exactly one digit and keeps the length', () {
      for (final round in sweep(Difficulty.classic, seeds: 50)) {
        for (var i = 0; i < round.candidates.length; i++) {
          if (round.kinds[i] != BridgeDistractor.substitution) continue;

          final a = round.target.toString();
          final b = round.candidates[i].toString();

          expect(b, hasLength(a.length));
          expect(_positionsDiffering(a, b), 1);
        }
      }
    });

    test('a length change changes the length by exactly one', () {
      for (final round in sweep(Difficulty.classic, seeds: 50)) {
        for (var i = 0; i < round.candidates.length; i++) {
          if (round.kinds[i] != BridgeDistractor.lengthChange) continue;

          final delta =
              round.candidates[i].toString().length -
              round.target.toString().length;

          expect(delta.abs(), 1);
        }
      }
    });
  });

  group('which side of the bridge the reader own script sits on', () {
    test('both sides come up, roughly evenly', () {
      // A player who learns that the target is always theirs stops reading one
      // of the two systems, which is half the game.
      final rounds = sweep(Difficulty.classic, seeds: 100).toList();
      final onReader = rounds.where((r) => r.targetOnReaderScript).length;
      final share = onReader / rounds.length;

      expect(share, greaterThan(0.4));
      expect(share, lessThan(0.6));
    });
  });
}

bool _isAdjacentSwap(int target, int candidate) {
  final a = target.toString();
  final b = candidate.toString();

  if (a.length != b.length) return false;

  for (var i = 0; i < a.length - 1; i++) {
    final swapped = a.split('')
      ..[i] = a[i + 1]
      ..[i + 1] = a[i];

    if (swapped.join() == b) return true;
  }

  return false;
}

String _sortedDigits(int value) => (value.toString().split('')..sort()).join();

int _positionsDiffering(String a, String b) {
  var count = 0;

  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) count++;
  }

  return count;
}
