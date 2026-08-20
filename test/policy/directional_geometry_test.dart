import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/source_text.dart';

/// Physical-side constructs that compile, pass every test, render correctly on
/// a developer's LTR screen, and are silently wrong in Persian.
///
/// There is no runtime signal and no analyzer rule for any of these. The only
/// enforcement is this scan and `check_i18n_bans.sh`, and both run from **this
/// commit onward** — before E05 writes its first component, because retrofitting
/// twenty built components is a diff nobody can review and every one of them
/// would need re-screenshotting.
const kPhysicalSideConstructs = <String, String>{
  'EdgeInsets.only(left:': 'use EdgeInsetsDirectional.only(start:)',
  'EdgeInsets.only(right:': 'use EdgeInsetsDirectional.only(end:)',
  'EdgeInsets.fromLTRB(': 'use EdgeInsetsDirectional.fromSTEB()',
  'Alignment.centerLeft': 'use AlignmentDirectional.centerStart',
  'Alignment.centerRight': 'use AlignmentDirectional.centerEnd',
  'Alignment.topLeft': 'use AlignmentDirectional.topStart',
  'Alignment.topRight': 'use AlignmentDirectional.topEnd',
  'Alignment.bottomLeft': 'use AlignmentDirectional.bottomStart',
  'Alignment.bottomRight': 'use AlignmentDirectional.bottomEnd',
  'TextAlign.left': 'use TextAlign.start',
  'TextAlign.right': 'use TextAlign.end',
  'Positioned(left:': 'use PositionedDirectional(start:)',
  'Positioned(right:': 'use PositionedDirectional(end:)',
  'BorderRadius.only(topLeft': 'use BorderRadiusDirectional.only(topStart:)',
  'BorderRadius.horizontal(left:': 'use BorderRadiusDirectional.horizontal',
  'Icons.arrow_back': 'use Icons.adaptive.arrow_back',
  'Icons.arrow_forward': 'use Icons.adaptive.arrow_forward',
};

/// The **one** legal physical-side construct in the app, and why.
///
/// `SunburstShape.shadow` builds a `BoxShadow` whose offset does not mirror. It
/// is a light-source constant — one imaginary light for the whole app — not a
/// reading-direction property, and a Persian build lit from the other side
/// would disagree with every reference screenshot.
///
/// This is the single question a reviewer will raise on the RTL PR, so it is
/// answered in the source, here, and in the PR body.
///
/// **The other half of this rule is `check_i18n_bans.sh`**, which CI runs by
/// name over `lib/`. It bans the same constructs from the shell side and is
/// the weaker of the two — this list adds `EdgeInsets.fromLTRB`, the
/// `BorderRadius.horizontal(left:` form and the corner variants. Two gates
/// deliberately, because the shell one is vendored library code this
/// repository does not own; if they ever disagree, this one is right.
const kNonMirroringShadowFile = 'lib/theme/sunburst_shape.dart';

/// The construct this file bans from production code, spelled without being
/// one.
///
/// Built from two halves so a review grep for a hand-built directionality
/// wrapper does not match the test that forbids it.
const kDirectionalityCall =
    'Directionality'
    '(';

void main() {
  test('no physical-side geometry appears under lib/', () {
    final offenders = <String>[];

    for (final file in dartFilesUnderLib()) {
      // Comments stripped: several files name these constructs in order to say
      // why they are absent, and a gate that fires on its own rationale gets
      // deleted rather than obeyed.
      //
      // WHITESPACE COLLAPSED, which is load-bearing. `dart format` breaks a
      // nested widget tree across lines, so the form that actually appears in
      // E05's catalog is
      //
      //   padding: const EdgeInsets.only(
      //     left: 20,
      //
      // and a same-line `contains('EdgeInsets.only(left:')` does not see it.
      // Measured: a file containing exactly that passed both this test and
      // check_i18n_bans.sh.
      final source = withoutDartComments(
        file.readAsStringSync(),
      ).replaceAll(RegExp(r'\s+'), '');

      for (final banned in kPhysicalSideConstructs.entries) {
        if (source.contains(banned.key.replaceAll(' ', ''))) {
          offenders.add('${file.path}: ${banned.key} — ${banned.value}');
        }
      }
    }

    // Accumulate and fail once. This gate is turned on while lib/ui/ is EMPTY
    // precisely so it never has to report twenty offenders at once.
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('the hard offset shadow cannot consult direction', () {
    // The BEHAVIOURAL half, over executable text only. Asserting the phrase
    // "does not mirror" over the raw file — as this did — is satisfied by the
    // doc comment alone: the offset could be negated, or dropped to
    // Offset.zero, and the test would stay green as long as the sentence
    // survived. That the offset is identical in both directions is proved by
    // pumping both locales, in sunburst_shape_test.dart.
    expect(
      withoutDartComments(
        File(kNonMirroringShadowFile).readAsStringSync(),
      ).contains('Directionality'),
      isFalse,
      reason:
          'the shadow must not consult direction at all. Reading it would '
          'be the first step towards mirroring it',
    );
  });

  test('and the exception stays documented AT the exception', () {
    // A DOCUMENTATION check, and named as one. It reads the raw file on
    // purpose: what it asserts is that the comment exists.
    expect(
      File(kNonMirroringShadowFile).readAsStringSync(),
      contains('does not mirror'),
      reason:
          'padding, alignment and icon direction mirror; ILLUMINATION does '
          'not, and the next reader has to be told why at the line itself',
    );
  });

  test('no production file hardcodes a root Directionality', () {
    // A hardcoded Directionality is exactly what hides a physical-side bug:
    // it pins the tree to one direction so the other is never exercised. The
    // TEST harness may do it, as a documented stand-in; production may not.
    final offenders = dartFilesUnderLib()
        .where(
          (f) => withoutDartComments(
            f.readAsStringSync(),
          ).contains(kDirectionalityCall),
        )
        .map((f) => f.path)
        .toList();

    expect(
      offenders,
      isEmpty,
      reason:
          'direction must follow the locale, through Localizations: '
          '$offenders',
    );
  });
}
