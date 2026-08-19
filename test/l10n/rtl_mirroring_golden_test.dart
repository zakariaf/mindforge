@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/l10n/bidi_text.dart';
import 'package:mindforge/l10n/locale_numbers.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';

import '../support/harness.dart';
import '../support/load_app_fonts.dart';
import '../support/locale_cases.dart';

/// The narrow real-font lane: three primitives, per RTL locale, six files.
///
/// **An RTL golden rendered in Ahem proves nothing** — every glyph is the same
/// box, so broken cursive joining and a wrong digit block both pass. This suite
/// loads the real faces; the default lane stays on Ahem and stays fast.
///
/// **What six PNGs prove and do not.** They detect a *change* in shaping,
/// mirroring or digit block. They do not prove the shaping is *correct*, and
/// they prove nothing at all about translation. The correctness proof is the
/// human comparison against `design/sunburst-pop/screens/rtl/` and E11's
/// native-speaker review.
///
/// **Golden the primitives exhaustively and sample screens.** E08, E09 and E10
/// add at most one sampled screen each; that budget is stated here so this lane
/// cannot sprawl.
///
/// Re-blessing is local and reviewed: `flutter test --tags golden
/// --update-goldens`, in a commit whose title says so. There is no
/// `--update-goldens` step in CI.
void main() {
  setUpAll(loadAppFonts);

  for (final localeCase in LocaleCase.rightToLeft) {
    final tag = localeCase.tag;
    final numbers = LocaleNumbers(localeCase.locale);

    testWidgets('$tag numerals', (tester) async {
      useDevice(tester, Device.reference390);

      await tester.pumpLocalized(
        _topStart(
          _Specimen(
            children: [
              // Every digit, so a face missing one is visible rather than
              // averaged away by a sample.
              List<String>.generate(10, numbers.count).join(' '),
              numbers.count(1480),
              numbers.seconds(18600),
              numbers.clock(65000),
              numbers.percent(0.92),
            ],
          ),
        ),
        localeCase,
      );

      await expectLater(
        find.byKey(_kSpecimen),
        matchesGoldenFile('../goldens/rtl/numerals-$tag.png'),
      );
    });

    testWidgets('$tag mixed script', (tester) async {
      useDevice(tester, Device.reference390);

      // The wordmark is Latin and the sentence around it is not. Without the
      // isolate the trailing punctuation jumps to the wrong end of the line —
      // the classic bidi defect, and one a screenshot shows immediately.
      await tester.pumpLocalized(
        _topStart(
          _Specimen(
            children: [
              'MindForge',
              BidiText.isolate('MindForge'),
              'به ${BidiText.isolate('MindForge')} خوش آمدید!',
              _scoreLine(numbers),
            ],
          ),
        ),
        localeCase,
      );

      await expectLater(
        find.byKey(_kSpecimen),
        matchesGoldenFile('../goldens/rtl/mixed-script-$tag.png'),
      );
    });

    testWidgets('$tag mirroring', (tester) async {
      useDevice(tester, Device.reference390);

      await tester.pumpLocalized(
        _topStart(const _MirroringSpecimen()),
        localeCase,
      );

      await expectLater(
        find.byKey(_kSpecimen),
        matchesGoldenFile('../goldens/rtl/mirroring-$tag.png'),
      );
    });
  }
}

/// The key every golden is captured through.
const Key _kSpecimen = ValueKey<String>('specimen');

/// Loose constraints so a specimen sizes to its content, and a `RepaintBoundary`
/// so the capture is the specimen rather than the whole 390x844 viewport —
/// `matchesGoldenFile` walks UP to the nearest boundary, so without one every
/// golden is mostly cream.
Widget _topStart(Widget child) => Align(
  alignment: AlignmentDirectional.topStart,
  child: RepaintBoundary(key: _kSpecimen, child: child),
);

/// A game name beside its score: two Latin-ish runs in an RTL sentence, which
/// is where an unisolated number lands on the wrong side of the dash.
String _scoreLine(LocaleNumbers numbers) =>
    '${BidiText.isolate('Stroop Rush')} \u2014 ${numbers.count(1480)}';

/// A plain stack of lines at the numeric HUD step, on the app's own surface.
class _Specimen extends StatelessWidget {
  const _Specimen({required this.children});

  final List<String> children;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final type = SunburstType.of(context);

    return Material(
      // A Material ancestor, not a bare Container: without one every Text
      // paints Flutter's yellow "missing Material" underline, and six goldens
      // would freeze that artifact as if it were the design.
      color: colours.surface,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final line in children)
              Text(
                line,
                style: type.numericHud.copyWith(color: colours.textPrimary),
              ),
          ],
        ),
      ),
    );
  }
}

/// A flat square, so which side it is on is the only thing it says.
class _Marker extends StatelessWidget {
  const _Marker(this.colour);

  final Color colour;

  @override
  Widget build(BuildContext context) =>
      Container(width: 20, height: 20, color: colour);
}

/// Directional geometry, rendered. Every value here is logical, so the whole
/// thing mirrors — except the hard offset shadow, which does not.
class _MirroringSpecimen extends StatelessWidget {
  const _MirroringSpecimen();

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final type = SunburstType.of(context);
    final shape = SunburstShape.of(context);

    return Material(
      color: colours.surface,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Two flat markers rather than Icons.adaptive.arrow_back:
                // MindForge draws inline stroke glyphs and bundles no icon
                // font, so a Material icon here renders as tofu in the test
                // environment and would freeze a box into six goldens. Two
                // different colours make the swap unmistakable.
                _Marker(colours.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'سلام',
                    style: type.title.copyWith(color: colours.textPrimary),
                    textAlign: TextAlign.start,
                  ),
                ),
                _Marker(colours.success),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 8, 12),
              decoration: BoxDecoration(
                color: colours.accent,
                border: Border.all(color: colours.border, width: 3),
                borderRadius: const BorderRadiusDirectional.horizontal(
                  start: Radius.circular(20),
                  end: Radius.circular(4),
                ).resolve(Directionality.of(context)),
                // THE ONE THING THAT DOES NOT MIRROR. One imaginary light for
                // the whole app: a Persian build lit from the other side would
                // disagree with every English screenshot.
                boxShadow: shape.shadow(shape.e2, colours.border),
              ),
              child: Text(
                'شروع',
                style: type.button.copyWith(color: colours.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
