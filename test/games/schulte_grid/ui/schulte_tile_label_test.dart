import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/games/schulte_grid/ui/schulte_tile_label.dart';
import 'package:mindforge/l10n/locale_numbers.dart';

/// The tiles ARE the numbers, so this is where the numeral pipeline is proven.
void main() {
  const values = <int>[1, 7, 25];

  group('a tile label', () {
    const expected = <SupportedLocale, List<String>>{
      SupportedLocale.en: <String>['1', '7', '25'],
      SupportedLocale.de: <String>['1', '7', '25'],
      SupportedLocale.fa: <String>['۱', '۷', '۲۵'],
      SupportedLocale.ckb: <String>['۱', '۷', '۲۵'],
    };

    for (final entry in expected.entries) {
      test('renders ${entry.value} in ${entry.key.tag}', () {
        expect(
          schulteTileLabels(values, LocaleNumbers(entry.key)),
          entry.value,
        );
      });
    }

    test('and fa and ckb emit the PERSIAN block, never the Arabic one', () {
      // THE NAMED DIGIT-BLOCK TEST. U+0660-0669 is also "Eastern Arabic" and
      // is the wrong SHAPE for a Persian or Sorani reader — four and six
      // differ outright. `intl` ships no ckb symbols, so ckb is asserted
      // separately rather than inherited from fa: an unpinned formatter falls
      // back to Latin there while fa still looks correct.
      for (final locale in <SupportedLocale>[
        SupportedLocale.fa,
        SupportedLocale.ckb,
      ]) {
        final labels = schulteTileLabels(
          List<int>.generate(25, (i) => i + 1),
          LocaleNumbers(locale),
        );

        for (final label in labels) {
          for (final rune in label.runes) {
            expect(
              rune,
              inInclusiveRange(0x06F0, 0x06F9),
              reason:
                  '${locale.tag} "$label" carries '
                  'U+${rune.toRadixString(16).padLeft(4, '0')}',
            );
          }
        }
      }
    });

    test('and no label carries a grouping separator', () {
      // The values are 1..25 so no separator could appear today. What is
      // pinned is the FORMATTER'S CONFIGURATION: a board that grew to 10x10
      // must not start printing `1,00` — or, in de, `1.00`.
      for (final locale in SupportedLocale.values) {
        final labels = schulteTileLabels(
          List<int>.generate(25, (i) => i + 1),
          LocaleNumbers(locale),
        );

        for (final label in labels) {
          expect(label, isNot(contains(',')), reason: locale.tag);
          expect(label, isNot(contains('.')), reason: locale.tag);
          expect(label, isNot(contains('٬')), reason: locale.tag);
        }
      }
    });

    test('and every label round-trips to its integer', () {
      for (final locale in SupportedLocale.values) {
        final cells = List<int>.generate(25, (i) => i + 1);
        final labels = schulteTileLabels(cells, LocaleNumbers(locale));

        for (var i = 0; i < cells.length; i++) {
          expect(
            int.parse(AsciiNumerals.normalize(labels[i])),
            cells[i],
            reason: '${locale.tag} at ${cells[i]}',
          );
        }
      }
    });

    test('and the list is in cell order, not sorted', () {
      // The scramble's order is the screen's order. A helper that sorted would
      // put 1 top-left in every locale, which is the one board this game may
      // not draw.
      expect(
        schulteTileLabels(const <int>[
          7,
          1,
          4,
        ], const LocaleNumbers(SupportedLocale.en)),
        <String>['7', '1', '4'],
      );
    });
  });
}
