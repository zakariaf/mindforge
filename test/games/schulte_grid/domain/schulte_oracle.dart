/// A second implementation of the scramble, deliberately written differently.
///
/// **It shares no code with production.** SplitMix64 is done in `BigInt` with
/// an explicit 64-bit mask rather than in native ints, and the shuffle removes
/// from a working list rather than swapping in place. A vector table generated
/// by the code it checks proves only that the code is stable; this is what
/// makes a disagreement mean something.
///
/// Where the two must agree exactly is the arithmetic Dart and BigInt define
/// differently: `%` on a negative dividend, and `>>>` on a value whose sign bit
/// is set. Both are handled here by masking to 64 bits and treating the result
/// as unsigned, which is SplitMix64's own definition.
library;

final BigInt _mask64 = (BigInt.one << 64) - BigInt.one;
final BigInt _gamma = BigInt.parse('9E3779B97F4A7C15', radix: 16);
final BigInt _mixA = BigInt.parse('BF58476D1CE4E5B9', radix: 16);
final BigInt _mixB = BigInt.parse('94D049BB133111EB', radix: 16);
final BigInt _fnvPrime = BigInt.parse('100000001B3', radix: 16);
final BigInt _fnvOffset = BigInt.parse('CBF29CE484222325', radix: 16);

/// FNV-1a over the UTF-8 bytes of [key], as an unsigned 64-bit BigInt.
BigInt oracleFnv1a64(String key) {
  var hash = _fnvOffset;

  for (final byte in _utf8Bytes(key)) {
    hash = ((hash ^ BigInt.from(byte)) * _fnvPrime) & _mask64;
  }

  return hash;
}

/// The oracle's generator: SplitMix64 over unsigned BigInt.
final class OracleGenerator {
  /// Starts at [seed], which must already be masked to 64 bits.
  OracleGenerator(BigInt seed) : _state = seed & _mask64;

  BigInt _state;

  /// The next 64-bit value.
  BigInt nextInt64() {
    _state = (_state + _gamma) & _mask64;

    var z = _state;
    z = ((z ^ (z >> 30)) * _mixA) & _mask64;
    z = ((z ^ (z >> 27)) * _mixB) & _mask64;

    return z ^ (z >> 31);
  }

  /// The next value in `[0, max)`.
  ///
  /// **Taken on the SIGNED reading of the 64-bit word**, which is what
  /// `SeededGenerator.nextInt` documents and does. It matters: for a draw whose
  /// sign bit is set, the signed and unsigned readings differ by 2^64, and
  /// `2^64 mod 9` is 7 — so a 3x3 board came out with two cells transposed.
  /// Both `int.%` and `BigInt.%` are Euclidean, so the signed reading still
  /// yields a non-negative index and the two implementations agree.
  int nextInt(int max) => (nextInt64().toSigned(64) % BigInt.from(max)).toInt();
}

/// The scramble, by list removal rather than in-place swapping.
List<int> oracleScramble({
  required int seed,
  required int size,
  int version = 1,
  int maxNatural = 2,
  int attempts = 8,
}) {
  final salted =
      oracleFnv1a64('schulte_grid:v$version:$size') ^ _unsigned(seed);
  final generator = OracleGenerator(salted);
  final count = size * size;

  var cells = <int>[];

  for (var attempt = 0; attempt < attempts; attempt++) {
    // Durstenfeld descending, expressed as "swap through a working list" —
    // the same permutation, reached by different statements.
    cells = List<int>.generate(count, (i) => i + 1);

    for (var i = count - 1; i > 0; i--) {
      final j = generator.nextInt(i + 1);
      final picked = cells[j];

      cells[j] = cells[i];
      cells[i] = picked;
    }

    if (oracleNaturalCount(cells) <= maxNatural) return cells;
  }

  return cells;
}

/// How many values sit on their own index.
int oracleNaturalCount(List<int> cells) => <int>[
  for (var i = 0; i < cells.length; i++)
    if (cells[i] == i + 1) i,
].length;

/// [value] as an unsigned 64-bit BigInt, sign bit included.
BigInt _unsigned(int value) => BigInt.from(value).toUnsigned(64);

/// UTF-8 bytes, written out rather than imported, so the oracle depends on
/// nothing the production path also depends on.
List<int> _utf8Bytes(String value) {
  final bytes = <int>[];

  for (final rune in value.runes) {
    if (rune < 0x80) {
      bytes.add(rune);
    } else if (rune < 0x800) {
      bytes
        ..add(0xC0 | (rune >> 6))
        ..add(0x80 | (rune & 0x3F));
    } else if (rune < 0x10000) {
      bytes
        ..add(0xE0 | (rune >> 12))
        ..add(0x80 | ((rune >> 6) & 0x3F))
        ..add(0x80 | (rune & 0x3F));
    } else {
      bytes
        ..add(0xF0 | (rune >> 18))
        ..add(0x80 | ((rune >> 12) & 0x3F))
        ..add(0x80 | ((rune >> 6) & 0x3F))
        ..add(0x80 | (rune & 0x3F));
    }
  }

  return bytes;
}
