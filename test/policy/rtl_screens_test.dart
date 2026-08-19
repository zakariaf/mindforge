import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/l10n/locale_numbers.dart';

import '../support/design_source.dart';

void main() {
  const ltr = 'design/sunburst-pop/screens';
  const rtl = 'design/sunburst-pop/screens/rtl';

  group('the RTL reference set', () {
    test('holds exactly the eight expected screens', () {
      final actual =
          Directory(rtl)
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.png'))
              .map((f) => f.uri.pathSegments.last.replaceAll('.png', ''))
              .toList()
            ..sort();

      expect(actual, kScreenBasenames);
    });

    test('every file is 780x1688, the same canvas as its LTR twin', () {
      // A capture that silently rendered at the wrong size is otherwise
      // invisible until someone lays it beside an implementation.
      for (final name in kScreenBasenames) {
        final rtlSize = pngSize(File('$rtl/$name.png'));
        final ltrSize = pngSize(File('$ltr/$name.png'));

        expect(
          rtlSize,
          kReferencePixelSize,
          reason: '$name is not 390x844 at 2x',
        );
        expect(
          rtlSize,
          ltrSize,
          reason: '$name: the two sets must be directly comparable',
        );
      }
    });
  });

  group('the string dump', () {
    final dump =
        jsonDecode(
              File(
                'design/sunburst-pop/rtl/strings-fa.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;

    test('covers every data-l10n key in app.html', () {
      final html = File(
        'design/sunburst-pop/app.html',
      ).readAsStringSync();
      final keys = RegExp(
        'data-l10n="([^"]+)"',
      ).allMatches(html).map((m) => m.group(1)!).toSet();
      final dumped = (dump['strings']! as Map<String, dynamic>).keys.toSet();

      expect(
        keys.difference(dumped),
        isEmpty,
        reason:
            'app.html marks a key the dump does not render, so the RTL '
            'screenshot would show the English string',
      );
    });

    test('covers every data-num node in app.html', () {
      final html = File(
        'design/sunburst-pop/app.html',
      ).readAsStringSync();
      final values = RegExp(
        'data-num="([^"]+)"',
      ).allMatches(html).map((m) => m.group(1)!).toSet();
      final dumped = (dump['numbers']! as Map<String, dynamic>).keys.toSet();

      expect(
        values.difference(dumped),
        isEmpty,
        reason:
            'a numeric node with no Persian rendering shows a LATIN digit '
            'in the RTL reference. On the Schulte board that is not a '
            'cosmetic slip — the tiles ARE the numbers',
      );
    });

    test('and every rendered digit is Eastern Arabic, not Arabic-Indic', () {
      final numbers = dump['numbers']! as Map<String, dynamic>;

      for (final entry in numbers.entries) {
        final rendered = entry.value! as String;

        expect(
          RegExp('[0-9]').hasMatch(rendered),
          isFalse,
          reason:
              '${entry.key} rendered "$rendered", which still holds an '
              'ASCII digit',
        );

        // The absence of ASCII is not the claim the name makes. A run of
        // Arabic-Indic U+0660-U+0669 — the block CLAUDE.md forbids, whose 4, 5
        // and 6 are different glyphs — has no ASCII digit either and would
        // have passed.
        expect(
          AsciiNumerals.hasNonAsciiDigits(rendered),
          RegExp(r'\d').hasMatch(AsciiNumerals.normalize(rendered)),
          reason: '${entry.key} rendered "$rendered" with no digit at all',
        );
        for (final rune in rendered.runes) {
          expect(
            rune >= 0x0660 && rune <= 0x0669,
            isFalse,
            reason:
                '${entry.key} rendered "$rendered", which holds an '
                'ARABIC-INDIC digit (U+0660-U+0669). MindForge renders the '
                'EASTERN ARABIC block U+06F0-U+06F9',
          );
        }
      }
    });
  });
}
