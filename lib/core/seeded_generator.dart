/// The one seeded generator in this repository.
///
/// A round is reproducible from `(gameId, difficulty, seed)` on any device and
/// any future SDK, which is what makes "the Blitz round gave me two orange
/// keys" a bug report someone can replay rather than a story.
///
/// **And on any locale.** Seeds are computed from ASCII keys and produce
/// integers; nothing here reads a locale, formats a number or touches a clock.
/// [seedFrom] asserts its key is ASCII precisely so a formatted score or a
/// translated label can never reach a generator — that mistake compiles, passes
/// an English-only suite, and deals a Persian player a different game.
///
/// **There is no second generator.** No `SeededRng`, no `lib/core/random/`, no
/// `lib/shared/determinism/`. E09 and E10 import these three names. A game epic
/// that adds its own has destroyed the frozen-vector guarantee this file
/// exists to create.
///
/// **64-bit integer arithmetic assumes a native target.** Dart's `int` is a
/// true 64-bit signed integer on iOS and Android and a double on the web, where
/// every value here would be silently wrong. The app ships iOS only; building
/// for web requires reimplementing this in 32-bit halves, not enabling it.
// The lint is correct and the platform is out of scope: these constants are
// exact 64-bit integers on a native target and silently wrong on the web, which
// is what the paragraph above says. Suppressed here rather than repository-wide
// so the warning still fires anywhere else someone writes one.
// ignore_for_file: avoid_js_rounded_ints
library;

/// The FNV-1a 64-bit offset basis, from the published definition.
const int _kFnvOffsetBasis = 0xCBF29CE484222325;

/// The FNV-1a 64-bit prime.
const int _kFnvPrime = 0x100000001B3;

/// SplitMix64's golden-ratio increment.
const int _kGoldenGamma = 0x9E3779B97F4A7C15;

/// Hashes [key]'s **UTF-8 bytes** with FNV-1a-64.
///
/// Bytes, not code units: the two differ for every non-ASCII character, and a
/// code-unit hash would agree with this one on all-ASCII input and disagree
/// everywhere else — passing an ASCII-only vector table while freezing the
/// wrong function. `test/core/seed_vectors.dart` carries a Persian row and a
/// Sorani row for exactly that reason.
///
/// It accepts any string. The ASCII guard lives on [seedFrom], the app-facing
/// helper, where the mistake would actually be made.
int fnv1a64(String key) {
  var hash = _kFnvOffsetBasis;

  for (final byte in _utf8Bytes(key)) {
    hash = (hash ^ byte) * _kFnvPrime;
  }

  return hash;
}

/// A deterministic sequence of 64-bit values from one seed.
///
/// SplitMix64, transcribed from its published definition. Chosen over
/// `dart:math`'s `Random`, whose algorithm the SDK does not freeze — a future
/// Dart release could change it and silently invalidate every golden vector and
/// every bug report.
final class SeededGenerator {
  /// Creates a generator starting at [seed].
  SeededGenerator(this.seed) : _state = seed;

  /// The seed this generator started from, so a run can report it.
  final int seed;

  int _state;

  /// The next 64-bit value.
  int nextInt64() {
    _state += _kGoldenGamma;

    var z = _state;
    z = (z ^ (z >>> 30)) * 0xBF58476D1CE4E5B9;
    z = (z ^ (z >>> 27)) * 0x94D049BB133111EB;

    return z ^ (z >>> 31);
  }

  /// The next value in `[0, max)`.
  ///
  /// The modulo is taken on the signed value directly — no `abs()`, no `>>>`.
  /// Dart's `%` is Euclidean, so a negative dividend with a positive divisor
  /// still yields a non-negative result, and Python's agrees; that is what lets
  /// the oracle express the same definition. `abs()` would be wrong anyway:
  /// `(-9223372036854775808).abs()` is itself in two's complement, so it
  /// returns a negative index roughly once in every 2^63 draws.
  int nextInt(int max) {
    assert(max > 0, 'nextInt needs a positive bound, got $max');

    return nextInt64() % max;
  }
}

/// A generator for [key], salted per feature and per mode.
///
/// [featureSalt] keeps two features seeded off the same instant from dealing
/// the same round; [modeSalt] does the same for two modes of one feature. Both
/// are frozen constants at their call sites, never computed.
///
/// **[key] must be ASCII.** This assert is the tripwire for the engine's
/// locale independence: a generator seeded off a formatted number or a
/// translated string compiles, passes an English-only suite, and produces a
/// different game for a Persian player. It fails loudly in debug instead.
SeededGenerator seedFrom(
  String key, {
  required int featureSalt,
  int modeSalt = 0,
}) {
  assert(
    key.runes.every((rune) => rune < 0x80),
    'seed keys are ASCII; a localized string must never reach a generator. '
    'Got "$key". If this is a timestamp, use toUtc().toIso8601String().',
  );

  return SeededGenerator(
    fnv1a64(key) ^ (featureSalt * _kGoldenGamma) ^ modeSalt,
  );
}

/// [text] as UTF-8 bytes.
///
/// Hand-rolled rather than `utf8.encode`, so this file imports nothing at all —
/// `lib/core/` is the Flutter-free foundation, and a `dart:convert` import here
/// is one more thing to keep out of it.
Iterable<int> _utf8Bytes(String text) sync* {
  for (final rune in text.runes) {
    if (rune < 0x80) {
      yield rune;
    } else if (rune < 0x800) {
      yield 0xC0 | (rune >> 6);
      yield 0x80 | (rune & 0x3F);
    } else if (rune < 0x10000) {
      yield 0xE0 | (rune >> 12);
      yield 0x80 | ((rune >> 6) & 0x3F);
      yield 0x80 | (rune & 0x3F);
    } else {
      yield 0xF0 | (rune >> 18);
      yield 0x80 | ((rune >> 12) & 0x3F);
      yield 0x80 | ((rune >> 6) & 0x3F);
      yield 0x80 | (rune & 0x3F);
    }
  }
}
