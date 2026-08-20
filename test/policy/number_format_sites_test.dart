import 'package:flutter_test/flutter_test.dart';

import 'support/source_text.dart';

/// The files allowed to construct a `NumberFormat`.
///
/// Exactly one. Every score, clock, tile, percentage and duration in the app is
/// formatted through `LocaleNumbers`, so the numbering system is pinned in one
/// place — and it has to be, because `intl` **throws** on `ckb` rather than
/// falling back.
const kNumberFormatSites = <String>{'lib/l10n/locale_numbers.dart'};

void main() {
  test('NumberFormat is constructed in exactly one file', () {
    // Generated localisations construct their own for ICU plurals; they are
    // not hand-written and their locale is already correct by construction —
    // dartFilesUnderLib excludes them along with every other generated file.
    final offenders = dartFilesUnderLib()
        .where((f) => !kNumberFormatSites.contains(f.path))
        .where(
          (f) => withoutDartComments(
            f.readAsStringSync(),
          ).contains('NumberFormat('),
        )
        .map((f) => f.path)
        .toList();

    expect(
      offenders,
      isEmpty,
      reason:
          'a second construction site is a second answer to "which '
          'numbering system", and under ckb the wrong answer THROWS: '
          '$offenders',
    );
  });

  test('and the intl import is confined to the l10n layer', () {
    final offenders = dartFilesUnderLib()
        .where((f) => !f.path.startsWith('lib/l10n/'))
        .where(
          (f) => withoutDartComments(
            f.readAsStringSync(),
          ).contains("import 'package:intl/"),
        )
        .map((f) => f.path)
        .toList();

    expect(offenders, isEmpty, reason: 'intl belongs to lib/l10n/: $offenders');
  });
}
