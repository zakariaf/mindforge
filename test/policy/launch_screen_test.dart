import 'dart:io';

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

    test('is not Flutter own placeholder any more', () {
      // The default ships a blue Flutter logo, and it is the kind of thing
      // that survives to a store listing because it looks like SOMETHING.
      // Compared by bytes against the known placeholder's size rather than by
      // eye: the real mark is a flat two-colour square and compresses far
      // smaller than the gradient logo.
      final master = File('${appicon.path}/Icon-App-1024x1024@1x.png');

      expect(master.existsSync(), isTrue);
      expect(
        master.readAsBytesSync().length,
        lessThan(40000),
        reason:
            'the flat mark compresses to a few KB; the Flutter placeholder is '
            'a gradient and does not',
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
