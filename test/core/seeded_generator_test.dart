// Same reason as the generator itself: these are exact 64-bit seeds on the
// native target this app ships to, and the web is not one.
// ignore_for_file: avoid_js_rounded_ints

import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/seeded_generator.dart';

import 'seed_vectors.dart';

/// The one PRNG in this repository, frozen against an independent oracle.
///
/// A round is reproducible from `(gameId, difficulty, seed)` on any device, any
/// future SDK and — the property this epic keeps returning to — any locale.
void main() {
  group('fnv1a64', () {
    test('matches every frozen vector', () {
      for (final vector in kSeedVectors) {
        expect(
          fnv1a64(vector.key),
          vector.hash,
          reason:
              '${vector.key.isEmpty ? '<empty>' : vector.key}: '
              '${vector.why}',
        );
      }
    });

    test('hashes UTF-8 bytes, not code units', () {
      // The two non-ASCII rows exist for this and only this. A code-unit hash
      // agrees with a byte hash on all-ASCII input and disagrees here, so an
      // ASCII-only table would have frozen the wrong function without saying
      // so.
      final nonAscii = kSeedVectors.where((v) => !_isAscii(v));

      expect(nonAscii, hasLength(2));

      for (final vector in nonAscii) {
        expect(fnv1a64(vector.key), vector.hash, reason: vector.key);
      }
    });

    test('and distinguishes keys that differ by one byte', () {
      expect(fnv1a64('stroop_rush'), isNot(fnv1a64('stroop_rusi')));
    });
  });

  group('seedFrom', () {
    test('reproduces the frozen seed for every ASCII row', () {
      // ASCII rows only, and not because the others are awkward: seedFrom
      // ASSERTS against a non-ASCII key, which is the point of the row above.
      // Their hashes are still frozen and still checked, through fnv1a64
      // directly — which is exactly the split the epic asks for, the guard on
      // the app-facing helper and the byte path pinned underneath it.
      for (final vector in kSeedVectors.where(_isAscii)) {
        expect(
          seedFrom(
            vector.key,
            featureSalt: kVectorFeatureSalt,
            modeSalt: kVectorModeSalt,
          ).seed,
          vector.seed,
          reason: vector.why,
        );
      }
    });

    test('salts per feature, so two features never share a sequence', () {
      // A game and a daily challenge seeded off the same instant must not draw
      // the same round.
      final a = seedFrom('2026-01-01T00:00:00.000Z', featureSalt: 1);
      final b = seedFrom('2026-01-01T00:00:00.000Z', featureSalt: 2);

      expect(
        List<int>.generate(16, (_) => a.nextInt(1000)),
        isNot(List<int>.generate(16, (_) => b.nextInt(1000))),
      );
    });

    test('and salts per mode', () {
      final a = seedFrom('k', featureSalt: 1);
      final b = seedFrom('k', featureSalt: 1, modeSalt: 7);

      expect(a.nextInt64(), isNot(b.nextInt64()));
    });

    test('REJECTS a non-ASCII key', () {
      // The tripwire for the whole locale-independence property. If a refactor
      // ever seeds a run off a formatted score or a translated label, it trips
      // here in debug rather than silently dealing a Persian player a different
      // round.
      for (final key in <String>['run-۱۲۳', 'ڕەنگ', 'jeu privé']) {
        expect(
          () => seedFrom(key, featureSalt: 1),
          throwsA(isA<AssertionError>()),
          reason: key,
        );
      }
    });
  });

  group('the draw sequence', () {
    test('matches the frozen table for every ASCII row', () {
      for (final vector in kSeedVectors.where(_isAscii)) {
        final generator = seedFrom(
          vector.key,
          featureSalt: kVectorFeatureSalt,
          modeSalt: kVectorModeSalt,
        );

        expect(
          List<int>.generate(
            kVectorDrawCount,
            (_) => generator.nextInt(kVectorDrawBound),
          ),
          vector.draws,
          reason:
              '${vector.key.isEmpty ? '<empty>' : vector.key}: '
              '${vector.why}',
        );
      }
    });

    test('is identical for two generators from one seed', () {
      final a = SeededGenerator(0x1234567890ABCDEF);
      final b = SeededGenerator(0x1234567890ABCDEF);

      for (var i = 0; i < 1000; i++) {
        expect(a.nextInt64(), b.nextInt64(), reason: 'draw $i');
      }
    });

    test('stays in range for every bound from 1 to 1000', () {
      final generator = SeededGenerator(0xFEEDFACE);

      for (var i = 0; i < 5000; i++) {
        final bound = 1 + (i % 1000);
        final value = generator.nextInt(bound);

        expect(value, greaterThanOrEqualTo(0), reason: 'bound $bound');
        expect(value, lessThan(bound), reason: 'bound $bound');
      }
    });

    test('and consecutive keys do not correlate', () {
      // SplitMix64's avalanche: one bit of input changes about half the output
      // bits. Twenty of sixty-four is a floor well below the expected 32, and
      // well above what a weak mix would manage.
      for (var n = 0; n < 500; n++) {
        final a = seedFrom('key_$n', featureSalt: 1).nextInt64();
        final b = seedFrom('key_${n + 1}', featureSalt: 1).nextInt64();

        expect(
          _bitsDiffering(a, b),
          greaterThanOrEqualTo(20),
          reason: 'key_$n vs key_${n + 1}',
        );
      }
    });
  });
}

/// Whether [vector]'s key is one `seedFrom` will accept.
bool _isAscii(SeedVector vector) =>
    vector.key.runes.where((rune) => rune >= 0x80).isEmpty;

/// How many of the 64 bits differ between [a] and [b].
int _bitsDiffering(int a, int b) {
  final x = a ^ b;
  var count = 0;

  for (var i = 0; i < 64; i++) {
    count += (x >> i) & 1;
  }

  return count;
}
