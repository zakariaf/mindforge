@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/ui/app_icon_mark.dart';

import '../support/component_harness.dart';
import '../support/harness.dart';
import '../support/load_app_fonts.dart';

/// The app icon, rendered from the app's own tokens.
///
/// **Drawn by the app, not by a designer's export.** An icon exported by hand
/// drifts from the palette the moment a token moves, and nothing notices —
/// which is how a coral icon ends up beside a coral-that-is-not-quite app. This
/// renders `AppIconMark` and pins it, so a token change reds this test and the
/// icon is regenerated from the same source of truth the screens use.
///
/// To regenerate after a deliberate change:
///
/// ```sh
/// flutter test --update-goldens test/tool/app_icon_test.dart
/// tool/icon/resize_app_icon.sh
/// ```

/// The boundary the 1024 golden is captured from.
const iconBoundary = Key('app-icon');

void main() {
  setUpAll(loadAppFonts);

  testWidgets('is the wordmark tile at 1024, with no transparency', (
    tester,
  ) async {
    // NO ALPHA ANYWHERE. iOS rejects an app icon with transparency, and the
    // failure arrives at upload rather than at build — so the mark paints an
    // opaque ground rather than relying on whatever is behind it.
    // A 1024-POINT SURFACE AT DPR 1, so the golden is the 1024x1024 pixels
    // the App Store asks for and not a scaled crop of a phone screen.
    await tester.pumpPopComponent(
      const RepaintBoundary(key: iconBoundary, child: AppIconMark()),
      device: const Device('icon', logicalSize: Size(1024, 1024), dpr: 1),
    );

    await expectLater(
      find.byKey(iconBoundary),
      matchesGoldenFile('goldens/app_icon_1024.png'),
    );
  });

  testWidgets('and it paints an opaque ground', (tester) async {
    await tester.pumpPopComponent(
      const SizedBox.square(dimension: 128, child: AppIconMark()),
    );

    final ground = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(AppIconMark),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );

    expect(
      (ground.decoration as BoxDecoration).color!.a,
      1.0,
      reason: 'iOS rejects an app icon with an alpha channel',
    );
  });

  testWidgets('and it uses the palette, not a copy of it', (tester) async {
    await tester.pumpPopComponent(
      const SizedBox.square(dimension: 128, child: AppIconMark()),
    );

    const colours = SunburstColors.sunburstPop;
    final fills = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(AppIconMark),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => (box.decoration as BoxDecoration).color)
        .toList();

    expect(fills, contains(colours.accentWarm));
    expect(fills, contains(colours.surface));
  });
}
