import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/source_text.dart';

/// Directories that must stay canonical: integers, UTC epoch milliseconds,
/// local serial days and ASCII tokens.
const kCanonicalDirectories = <String>['lib/data', 'lib/core'];

/// Symbols that turn a canonical value into a rendered one.
///
/// `LocaleNumbers` — the per-locale formatter with a pinned numbering system,
/// `fa` and `ckb` both borrowing `fa`'s symbols because `intl` ships none for
/// `ckb` — is **E04's** file, `lib/l10n/locale_numbers.dart`. This gate's job
/// is to prove it can never be called from here. Stating the boundary in both
/// directions is what stops a later task from "helpfully" formatting a score at
/// the repository.
const kBannedRenderSymbols = <String, String>{
  'package:intl': 'the store is locale-independent; formatting is E04 job',
  'package:flutter_localizations': 'same',
  'AppLocalizations': 'a translated string must never reach a column',
  'NumberFormat':
      '1480 renders as 1,480 in en and 1.480 in de. The store '
      'holds 1480',
  'DateFormat':
      'instants are stored as UTC epoch ms; a calendar label is a '
      'projection',
  'toStringAsFixed': 'a rounded double is a rendered value',
};

void main() {
  /// Every `.dart` file under the canonical directories, with comments removed.
  Map<String, String> canonicalSources() {
    final sources = <String, String>{};
    for (final directory in kCanonicalDirectories) {
      final dir = Directory(directory);
      if (!dir.existsSync()) continue;

      for (final file
          in dir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        // Generated drift output is not hand-written and is not held to this.
        if (file.path.endsWith('.drift.dart')) continue;
        sources[file.path] = withoutDartComments(file.readAsStringSync());
      }
    }
    return sources;
  }

  test('no render symbol appears in the canonical layers', () {
    final offenders = <String>[];

    canonicalSources().forEach((path, source) {
      for (final banned in kBannedRenderSymbols.entries) {
        if (source.contains(banned.key)) {
          offenders.add('$path: ${banned.key} — ${banned.value}');
        }
      }
      // `Intl.` as a qualified call, not the bare word, so a comment-stripped
      // mention of the package name in a string does not fire.
      if (RegExp(r'\bIntl\.').hasMatch(source)) {
        offenders.add(
          '$path: Intl. — the ambient locale must not be read here',
        );
      }
    });

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('no Eastern Arabic or Arabic-Indic digit appears in the source', () {
    final offenders = <String>[];

    canonicalSources().forEach((path, source) {
      for (final rune in source.runes) {
        // U+0660-U+0669 Arabic-Indic, U+06F0-U+06F9 Eastern Arabic.
        final isArabicIndic = rune >= 0x0660 && rune <= 0x0669;
        final isEasternArabic = rune >= 0x06F0 && rune <= 0x06F9;
        if (isArabicIndic || isEasternArabic) {
          offenders.add(
            '$path: U+${rune.toRadixString(16).toUpperCase().padLeft(4, '0')}',
          );
          break;
        }
      }
    });

    expect(
      offenders,
      isEmpty,
      reason:
          'a localized numeral in the store layer is a value no other '
          'locale can read back: $offenders',
    );
  });

  test('no grouped number literal appears in the canonical layers', () {
    final offenders = <String>[];

    canonicalSources().forEach((path, source) {
      // A quoted `1,480` or `1.480` is a formatted value that escaped.
      final match = RegExp("'[0-9]{1,3}([,.][0-9]{3})+'").firstMatch(source);
      if (match != null) offenders.add('$path: ${match.group(0)}');
    });

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
