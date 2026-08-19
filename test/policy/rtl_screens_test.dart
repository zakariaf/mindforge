import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// The eight screens, in both directions.
const kScreenBasenames = <String>[
  '01-home',
  '02-game-detail',
  '03-countdown',
  '04-stroop-rush',
  '05-schulte-grid',
  '06-results',
  '07-stats',
  '08-settings',
];

/// Reads a PNG's IHDR without decoding it.
({int width, int height}) pngSize(File file) {
  final bytes = file.readAsBytesSync();
  final header = ByteData.sublistView(Uint8List.fromList(bytes));

  // 8-byte signature, then the IHDR chunk: 4 length, 4 type, then w/h.
  return (width: header.getUint32(16), height: header.getUint32(20));
}

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
          <int>[rtlSize.width, rtlSize.height],
          <int>[780, 1688],
          reason: '$name is not 390x844 at 2x',
        );
        expect(
          <int>[rtlSize.width, rtlSize.height],
          <int>[
            ltrSize.width,
            ltrSize.height,
          ],
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

    test('and every rendered number is in the Eastern Arabic block', () {
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
      }
    });
  });
}
