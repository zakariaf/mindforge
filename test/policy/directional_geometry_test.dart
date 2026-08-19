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

void main() {
  test('no physical-side geometry appears under lib/', () {
    final offenders = <String>[];

    for (final file in dartFilesUnderLib()) {
      // Comments stripped: several files name these constructs in order to say
      // why they are absent, and a gate that fires on its own rationale gets
      // deleted rather than obeyed.
      final source = withoutDartComments(file.readAsStringSync());

      for (final banned in kPhysicalSideConstructs.entries) {
        if (source.contains(banned.key)) {
          offenders.add('${file.path}: ${banned.key} — ${banned.value}');
        }
      }
    }

    // Accumulate and fail once. This gate is turned on while lib/ui/ is EMPTY
    // precisely so it never has to report twenty offenders at once.
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('the hard offset shadow deliberately does not mirror', () {
    // Asserted rather than merely commented, because it is the one place the
    // rule above is knowingly not applied and it must stay knowing.
    final source = File(kNonMirroringShadowFile).readAsStringSync();

    expect(
      source,
      contains('does not mirror'),
      reason:
          'the exception must stay documented AT the exception. Padding, '
          'alignment and icon direction mirror; ILLUMINATION does not',
    );
    expect(
      source.contains('Directionality'),
      isFalse,
      reason:
          'the shadow must not consult direction at all. Reading it would '
          'be the first step towards mirroring it',
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
          ).contains('Directionality('),
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
