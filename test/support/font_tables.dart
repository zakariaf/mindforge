import 'dart:typed_data';

/// Reads a TrueType font's `cmap` table.
///
/// Glyph coverage is asserted from the **font's own tables**, never from a
/// foundry page or a specimen image. A face that claims a script and cannot
/// draw five of its letters renders tofu on a device nobody checked, and that
/// is exactly what happened when Lalezar was measured for this project.
abstract final class FontTables {
  /// Every Unicode codepoint [fontBytes] maps to a glyph.
  ///
  /// Reads the format-4 subtable of a Unicode-platform or
  /// Windows-Unicode-platform `cmap` record, which is the one every shipped
  /// TrueType face carries.
  static Set<int> mappedCodepoints(Uint8List fontBytes) {
    final data = ByteData.sublistView(fontBytes);
    final tableCount = data.getUint16(4);

    int? cmapOffset;
    for (var i = 0; i < tableCount; i++) {
      final record = 12 + i * 16;
      final tag = String.fromCharCodes(fontBytes.sublist(record, record + 4));
      if (tag == 'cmap') cmapOffset = data.getUint32(record + 8);
    }
    if (cmapOffset == null) return <int>{};

    int? best;
    final subtableCount = data.getUint16(cmapOffset + 2);
    for (var i = 0; i < subtableCount; i++) {
      final record = cmapOffset + 4 + i * 8;
      final platform = data.getUint16(record);
      final encoding = data.getUint16(record + 2);
      final offset = cmapOffset + data.getUint32(record + 4);

      final isUnicode =
          (platform == 3 && (encoding == 1 || encoding == 10)) ||
          (platform == 0);
      if (isUnicode && data.getUint16(offset) == 4) best = offset;
    }
    if (best == null) return <int>{};

    return _readFormat4(data, best);
  }

  static Set<int> _readFormat4(ByteData data, int offset) {
    final segCountX2 = data.getUint16(offset + 6);
    final segCount = segCountX2 ~/ 2;

    final endsAt = offset + 14;
    final startsAt = endsAt + segCountX2 + 2;
    final deltasAt = startsAt + segCountX2;
    final rangesAt = deltasAt + segCountX2;

    final mapped = <int>{};
    for (var segment = 0; segment < segCount; segment++) {
      final end = data.getUint16(endsAt + segment * 2);
      final start = data.getUint16(startsAt + segment * 2);
      final delta = data.getInt16(deltasAt + segment * 2);
      final rangeOffset = data.getUint16(rangesAt + segment * 2);

      for (var code = start; code <= end && code != 0xFFFF; code++) {
        int glyph;
        if (rangeOffset == 0) {
          glyph = (code + delta) & 0xFFFF;
        } else {
          final index =
              rangesAt + segment * 2 + rangeOffset + (code - start) * 2;
          if (index + 2 > data.lengthInBytes) continue;
          glyph = data.getUint16(index);
          if (glyph != 0) glyph = (glyph + delta) & 0xFFFF;
        }
        if (glyph != 0) mapped.add(code);
      }
    }
    return mapped;
  }
}

/// The five Sorani letters that are not in the Persian alphabet, plus the two
/// Kurdish-specific forms.
///
/// A face that draws Persian is **not** thereby a face that draws Sorani, and
/// this set is the difference.
const kSoraniLetters = <String, int>{
  'ڕ': 0x0695,
  'ڵ': 0x06B5,
  'ۆ': 0x06C6,
  'ێ': 0x06CE,
  'ھ': 0x06BE,
  'ە': 0x06D5,
  'ڤ': 0x06A4,
};

/// The Eastern Arabic digits `۰۱۲۳۴۵۶۷۸۹`, U+06F0–U+06F9.
///
/// **Not** the Arabic-Indic block U+0660–U+0669, whose 4, 5 and 6 are different
/// glyphs. `fa` and `ckb` render these, and the Schulte Grid tiles *are* the
/// numbers, so a face that cannot draw them cannot ship that game.
const kEasternArabicDigits = <int>[
  0x06F0,
  0x06F1,
  0x06F2,
  0x06F3,
  0x06F4,
  0x06F5,
  0x06F6,
  0x06F7,
  0x06F8,
  0x06F9,
];

/// The Arabic decimal separator U+066B and group separator U+066C, which
/// `LocaleNumbers` pins for `fa` and `ckb` in E04.
const kArabicSeparators = <int>[0x066B, 0x066C];
