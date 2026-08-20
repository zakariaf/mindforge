import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/sunburst_colors.dart';

import '../support/design_source.dart';

/// Samples the shipped reference PNGs and asserts the sampled hexes are the
/// slots the theme declares.
///
/// This is the pin in the other direction. `token_parity_test` proves Dart
/// agrees with `system.html`; this proves Dart agrees with the images the
/// screens are actually built against. If the two design sources ever disagree,
/// one of these fails rather than both passing over a quiet divergence.
///
/// It is **not** a screenshot comparison and cannot become one: it reads the
/// reference, never a render.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const colours = SunburstColors.sunburstPop;
  const screens = 'design/sunburst-pop/screens';

  /// The colour at ([x], [y]) in [path], in device pixels.
  Future<Color> pixelAt(String path, int x, int y) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData();

    final offset = (y * frame.image.width + x) * 4;
    final rgba = Uint8List.sublistView(
      data!.buffer.asUint8List(),
      offset,
      offset + 4,
    );

    frame.image.dispose();
    codec.dispose();

    return Color.fromARGB(rgba[3], rgba[0], rgba[1], rgba[2]);
  }

  group('the reference PNGs', () {
    // BOTH sets. The RTL captures are laid directly beside these, so a set
    // rendered at another size is not comparable and the human comparison step
    // silently stops meaning anything.
    for (final dir in <String>[screens, '$screens/rtl']) {
      test('$dir holds the eight screens at 780x1688 — 390x844 at 2x', () {
        final files = Directory(dir)
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.png'))
            .toList();

        expect(
          files
              .map((f) => f.uri.pathSegments.last.replaceAll('.png', ''))
              .toList()
            ..sort(),
          kScreenBasenames,
        );

        for (final file in files) {
          expect(
            pngSize(file),
            kReferencePixelSize,
            reason:
                '${file.path} is not the geometry the canonical simulator '
                'renders at',
          );
        }
      });
    }
  });

  group('sampled hexes are the shipped slots', () {
    test('the page background on 01-home.png is surface', () async {
      // A point in the top gutter, clear of the wordmark and the streak chip.
      final sampled = await pixelAt('$screens/01-home.png', 12, 12);

      expect(
        sampled,
        colours.surface,
        reason:
            'the reference and the theme disagree about the page '
            'background. If the reference is genuinely wrong, that is a '
            'deliberate design change: edit app.html, re-run '
            'capture-screens.sh, and commit the regenerated PNGs with the '
            'reason',
      );
    });

    test('every screen sits on the background its design gives it', () async {
      // Seven screens sit on cream. The countdown is the exception and it is a
      // deliberate one: app.html:476 declares
      //   .count{position:absolute;inset:0;background:var(--grape)}
      // — a full-bleed takeover, not a page. Pinning the exception here is what
      // stops someone "fixing" it to cream later, and what would catch it if
      // the takeover were ever dropped.
      final expected = <String, Color>{
        '01-home': colours.surface,
        '02-game-detail': colours.surface,
        '03-countdown': colours.accentAlt,
        '04-stroop-rush': colours.surface,
        '05-schulte-grid': colours.surface,
        '06-results': colours.surface,
        '07-stats': colours.surface,
        '08-settings': colours.surface,
      };

      final divergent = <String>[];
      for (final entry in expected.entries) {
        final sampled = await pixelAt('$screens/${entry.key}.png', 6, 6);
        if (sampled != entry.value) {
          divergent.add(
            '${entry.key} sampled ${sampled.toARGB32().toRadixString(16)}, '
            'expected ${entry.value.toARGB32().toRadixString(16)}',
          );
        }
      }

      expect(
        divergent,
        isEmpty,
        reason:
            'the reference and the theme disagree. If the reference is '
            'genuinely wrong, that is a deliberate design change: edit '
            'app.html, re-run capture-screens.sh, and commit the regenerated '
            'PNGs with the reason. Divergent: $divergent',
      );
    });
  });
}
