import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/font_licences.dart';

/// Registers every bundled face with the test font system.
///
/// **Without this a widget test renders in Ahem**, whose every glyph is an
/// identical square one em wide. That is fine for a test asserting geometry —
/// it is deterministic and it is why the default lane uses it — and it is
/// useless for three things this epic cares about:
///
/// * An RTL golden rendered in Ahem proves nothing. Broken cursive joining and
///   a wrong digit block both come out as the same row of boxes.
/// * A text-fit matrix run in Ahem is a character-count test wearing a layout
///   test's clothes. Ahem's advance is 1.0 em for every glyph, roughly double a
///   real Latin face, so it fails on strings that fit comfortably and tells you
///   nothing about the ones that do not.
/// * A "longest string per type step" table measured in Ahem is just the string
///   with the most characters, which is not the same question.
///
/// The families come from [kBundledFonts], so a face added to `pubspec.yaml`
/// and forgotten here is impossible: there is one list.
///
/// Call it from `setUpAll` **in the suites that need it**, never from a global
/// `test/flutter_test_config.dart` hook — loading real fonts for every test in
/// the repository slows the default lane for the tests that assert geometry and
/// gain nothing from real glyphs.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final font in kBundledFonts) {
    final loader = FontLoader(font.family)
      ..addFont(rootBundle.load(font.asset));
    await loader.load();
  }
}
