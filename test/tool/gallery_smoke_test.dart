import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/ui/components/pop_button.dart';

import '../../tool/gallery_main.dart' as gallery;

/// The gallery is a shipped developer tool, and E06 made it possible to break
/// it from a distance.
///
/// Untagged, so it runs in the default lane. The `tool` tag would have read as
/// the right label and meant this never ran: the workflow's default lane
/// excludes it and the only `--tags tool` step names one file by path.
///
/// `hapticGatewayProvider` throws until it is overridden — deliberately, so a
/// missing override in `bootstrap()` is loud rather than silent. Every press in
/// the catalog now reads it through `FeedbackService`, so any entry point that
/// forgets the override has a gallery that renders perfectly and throws on the
/// first tap. Nothing else in the repository would have caught it: the app has
/// `bootstrap()`, and every widget test has the harness.
void main() {
  testWidgets('every tap in the gallery reaches a real gateway', (
    tester,
  ) async {
    // Verified red before the fix, on device and here: the first tap threw
    // twice over — once for the gateway and once for the settings seed, which
    // the feedback gates read through appSettingsProvider.
    await tester.pumpWidget(gallery.galleryRoot());
    await tester.pump();

    await tester.tap(find.byType(PopButton).first);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('and its motion switch reaches MediaQuery', (tester) async {
    // The gallery mounts MotionPreferenceScope the same way lib/app.dart does.
    // Without it the switch would flip a setting nothing below it reads, and
    // the on-device Reduce motion pass would be checking nothing.
    await tester.pumpWidget(
      gallery.galleryRoot(
        settings: const AppSettings.defaults().copyWith(
          isReduceMotionEnabled: true,
        ),
      ),
    );
    await tester.pump();

    expect(
      MediaQuery.disableAnimationsOf(
        tester.element(find.byType(PopButton).first),
      ),
      isTrue,
    );
  });
}
