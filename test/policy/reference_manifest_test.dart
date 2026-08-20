import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/design_source.dart';

/// Ties the committed reference screenshots to the sources they were rendered
/// from.
///
/// **This is not hypothetical.** `app.html` once carried `data-num="640"` while
/// the committed `screens/rtl/06-results.png` still showed a Latin `640`: the
/// source and the picture had diverged, every gate was green, and the only
/// thing that noticed was a human opening the PNG. The freshness gate on
/// `strings-fa.json` cannot see it either — its own escape hatch is that a dev
/// re-dumps the JSON, commits, and never re-runs the capture.
///
/// CI has no Chrome, so it cannot re-render. It can recompute hashes, and that
/// is exactly enough: if `app.html` changed since the capture, or a PNG was
/// replaced by hand, the manifest disagrees.
void main() {
  for (final set in <({String dir, bool rtl})>[
    (dir: 'design/sunburst-pop/screens', rtl: false),
    (dir: 'design/sunburst-pop/screens/rtl', rtl: true),
  ]) {
    group(set.dir, () {
      final manifest =
          jsonDecode(File('${set.dir}/manifest.json').readAsStringSync())
              as Map<String, dynamic>;
      final sources = manifest['sources']! as Map<String, dynamic>;
      final screens = manifest['screens']! as Map<String, dynamic>;

      String digestOf(String path) =>
          sha256.convert(File(path).readAsBytesSync()).toString();

      test('was captured from the committed app.html', () {
        expect(
          digestOf('design/sunburst-pop/app.html'),
          sources['app.html'],
          reason:
              'app.html has changed since these screens were captured. Run '
              './capture-screens.sh${set.rtl ? ' --rtl' : ''} and commit the '
              'result — the reference is what every screen is built against, '
              'and a stale one is worse than none',
        );
      });

      if (set.rtl) {
        test('and from the committed string dump', () {
          expect(
            digestOf('design/sunburst-pop/rtl/strings-fa.json'),
            sources['rtl/strings-fa.json'],
            reason:
                'an ARB was re-dumped without re-capturing the Persian '
                'screens, so the reference shows the previous translation',
          );
        });
      }

      test('holds the eight screens, unmodified since capture', () {
        expect(screens.keys.toList()..sort(), kScreenBasenames);

        for (final name in kScreenBasenames) {
          expect(
            digestOf('${set.dir}/$name.png'),
            screens[name],
            reason: '$name.png does not match the manifest',
          );
        }
      });
    });
  }
}
