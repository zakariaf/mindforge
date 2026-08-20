import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/sunburst_colors.dart';

/// The app's first frame, and the icon on the home screen.
///
/// **A launch screen is the first thing a player sees, and Flutter ships it
/// white.** The app paints cream, so the default opened on a white flash and
/// then repainted — a jolt that reads as a slow app rather than as a colour
/// choice. The storyboard now carries the same ground the first real frame
/// does, and this test keeps the two in step: a palette change that moved
/// `surface` and left the storyboard behind would reintroduce the flash and
/// nothing else would notice.
void main() {
  group('the launch screen', () {
    test('opens on the app own ground, not on white', () {
      final surface = SunburstColors.sunburstPop.surface;
      final storyboard = File(
        'ios/Runner/Base.lproj/LaunchScreen.storyboard',
      ).readAsStringSync();

      final match = RegExp(
        r'<color key="backgroundColor" red="([\d.]+)" green="([\d.]+)" '
        r'blue="([\d.]+)"',
      ).firstMatch(storyboard);

      expect(match, isNotNull, reason: 'no background colour is declared');

      /// A storyboard channel, as an 8-bit value.
      int channel(String? raw) => (double.parse(raw!) * 255).round();

      expect(channel(match!.group(1)), (surface.r * 255).round());
      expect(channel(match.group(2)), (surface.g * 255).round());
      expect(channel(match.group(3)), (surface.b * 255).round());
    });
  });

  group('the app icon', () {
    final appicon = Directory(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset',
    );

    test('is MindForge own mark, sampled from the pixels', () {
      // ASSERTED ON A PIXEL, not on a file size. The first version of this
      // test compared bytes against a threshold and had the numbers backwards:
      // the Flutter placeholder is 10,932 bytes and the real mark is 20,288,
      // so `lessThan(40000)` was GREEN on the exact artifact it was written to
      // reject. Reverting the appiconset would have passed it.
      //
      // The corner of the icon is the accent the wordmark's tile uses, and
      // nothing about a blue Flutter logo is.
      final master = File('${appicon.path}/Icon-App-1024x1024@1x.png');

      expect(master.existsSync(), isTrue);

      final corner = _pixelAt(master.readAsBytesSync(), 8, 0);
      final accent = SunburstColors.sunburstPop.accentWarm;

      expect(
        corner,
        <int>[
          (accent.r * 255).round(),
          (accent.g * 255).round(),
          (accent.b * 255).round(),
        ],
        reason:
            'the icon corner is not SunburstColors.accentWarm — is this still '
            "Flutter's placeholder, or has the palette moved without the icon "
            'being regenerated?',
      );
    });

    test('and every size Contents.json names is present', () {
      final contents = File('${appicon.path}/Contents.json').readAsStringSync();
      final named = RegExp(
        r'"filename"\s*:\s*"([^"]+)"',
      ).allMatches(contents).map((match) => match.group(1)!).toSet();

      expect(named, isNotEmpty);

      for (final filename in named) {
        expect(
          File('${appicon.path}/$filename').existsSync(),
          isTrue,
          reason: '$filename is named by Contents.json and missing',
        );
      }
    });

    test('and carries no alpha channel, which the store rejects', () {
      // ASSERTED FROM THE PNG HEADER, not from a tool's opinion. Byte 25 of a
      // PNG is the colour type: 2 is RGB and 6 is RGBA. App Store Connect
      // rejects an icon that HAS an alpha channel even when every pixel in it
      // is opaque, and the rejection arrives at upload — long after the build
      // looked fine.
      for (final file in appicon.listSync().whereType<File>().where(
        (file) => file.path.endsWith('.png'),
      )) {
        final bytes = file.readAsBytesSync();

        expect(
          bytes[25],
          isNot(anyOf(4, 6)),
          reason: '${file.path} still has an alpha channel',
        );
      }
    });
  });
}

/// The RGB triple at [x], [y] of an 8-bit RGB PNG.
///
/// A small decoder rather than a dependency: the icons this reads are written
/// by `tool/icon/resize_app_icon.sh` as non-interlaced 8-bit RGB, which is the
/// one shape it has to handle. It asserts that shape rather than assuming it,
/// so a re-encode that changed the format fails loudly instead of returning a
/// plausible wrong colour.
List<int> _pixelAt(Uint8List bytes, int x, int y) {
  expect(bytes[24], 8, reason: 'expected an 8-bit PNG');
  expect(bytes[25], 2, reason: 'expected truecolour RGB with no alpha');
  expect(bytes[28], 0, reason: 'expected a non-interlaced PNG');

  final width = ByteData.sublistView(bytes, 16, 20).getUint32(0);

  // Walk the chunks to collect IDAT, which may be split across several.
  final data = BytesBuilder();
  var offset = 8;

  while (offset < bytes.length) {
    final length = ByteData.sublistView(
      bytes,
      offset,
      offset + 4,
    ).getUint32(0);
    final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));

    if (type == 'IDAT') {
      data.add(bytes.sublist(offset + 8, offset + 8 + length));
    }

    offset += length + 12;
  }

  final raw = ZLibDecoder().convert(data.takeBytes());
  final stride = width * 3;
  // ROW 0 ONLY, which is all this needs and which makes the filters tractable:
  // every one of them references the PRIOR row, and for row 0 that row is
  // zeros — so Up collapses to the identity, and Average and Paeth both
  // collapse to Sub. ffmpeg writes Sub here, not None, which is what the first
  // version of this helper wrongly assumed.
  expect(y, 0, reason: 'this decoder reconstructs the first scanline only');

  final filter = raw[0];

  expect(
    filter,
    anyOf(0, 1, 2, 3, 4),
    reason: 'unknown PNG filter type $filter',
  );

  final row = List<int>.filled(stride, 0);

  for (var i = 0; i < stride; i++) {
    final left = i >= 3 ? row[i - 3] : 0;
    final value = raw[1 + i];

    row[i] = switch (filter) {
      0 || 2 => value,
      1 || 4 => (value + left) & 0xFF,
      _ => (value + (left ~/ 2)) & 0xFF,
    };
  }

  return <int>[row[x * 3], row[x * 3 + 1], row[x * 3 + 2]];
}
