import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/source_text.dart';

/// The four ways a layout cheats an accessibility setting, banned in `lib/`.
///
/// **Each of these makes a screen LOOK fine while doing the opposite of what
/// the player asked for.** Someone who turns text size up wants bigger text; a
/// `FittedBox` gives them the same text, scaled down, in a smaller box. That is
/// not a compromise, it is the setting inverted — and unlike an overflow it
/// leaves no yellow stripe for a reviewer to notice.
///
/// The fix for a label that stops fitting is a smaller BASE style, chosen once
/// and measured — the two-step pattern `stimulus`/`stimulusCompact` and
/// `button`/`buttonCompact` already use — or a layout that gives it more room.
/// Never a clamp.
void main() {
  /// What is banned, and the sentence a stranger needs to understand why.
  const bans = <String, String>{
    'withClampedTextScaling':
        'it caps the text size a player chose; fix the layout instead',
    'textScaleFactor':
        'the deprecated scaling knob, and every use of it is an override',
    'FittedBox': 'it scales text DOWN for the player who asked for it bigger',
    'TextOverflow.ellipsis':
        'a truncated VALUE turns a wrong number into a plausible one; only a '
        'title may ellipse, and it says so at the line',
    // A NUMERIC size, anywhere. Not anchored to `copyWith(`: `dart format`
    // reorders and wraps the arguments, so `copyWith(color: …, fontSize: 13)`
    // slipped past a version anchored that way — measured, by adding exactly
    // that to a chip. And the ban is about a WRITTEN number: `fontSize:
    // type.title.fontSize` is one step borrowing another's, which is a
    // composition of tokens and findable from either end.
    //
    // The scale itself is the one file that must write them, and it is on the
    // allow-list below for that reason.
    r'fontSize:\s*[\d.]':
        'a size WRITTEN outside the scale is a token nobody can find; add a '
        'step to SunburstType, or compose one from another step',
  };

  /// Files allowed one of these, each with the reason at the line.
  const sanctioned = <String, String>{
    'lib/features/shell/widgets/top_bar.dart':
        'the bar title ellipses so a long game name cannot push the '
        'difficulty chip off the end — a title, not a value',
    'lib/theme/sunburst_type.dart':
        'the scale itself, which is where every step is defined and therefore '
        'the one file that writes a size',
    'lib/games/stroop_rush/ui/stroop_board.dart':
        'the prompt is bounded to the two lines it is MEASURED at; a Text free '
        'to take a third made the whitespace budget a fiction',
  };

  test('none of them appears in lib/, outside a named file', () {
    final offenders = <String>[];

    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where((file) => !file.path.endsWith('.drift.dart'))) {
      if (sanctioned.containsKey(file.path)) continue;

      final code = withoutDartComments(file.readAsStringSync());

      for (final ban in bans.keys) {
        // Matched as a pattern rather than a substring, so a formatter's line
        // break cannot hide one. The plain tokens are regex-inert.
        if (RegExp(ban).hasMatch(code)) {
          offenders.add('${file.path}: $ban — ${bans[ban]}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'a clamp is the defect, never the fix',
    );
  });

  test('and every sanctioned file still needs its exemption', () {
    // AN ALLOW-LIST NOBODY CHECKS IS A HOLE, and the first version of this
    // test only asserted the file was non-empty — so an entry kept after its
    // FittedBox was removed, or a second unjustified ban added to an already
    // listed file, both passed.
    for (final entry in sanctioned.entries) {
      final file = File(entry.key);

      expect(file.existsSync(), isTrue, reason: '${entry.key} was moved');

      final code = withoutDartComments(file.readAsStringSync());
      final present = bans.keys.where((ban) => RegExp(ban).hasMatch(code));

      expect(
        present,
        isNotEmpty,
        reason:
            '${entry.key} no longer uses any banned construct — drop it from '
            'the allow-list rather than leaving a standing exemption',
      );
      expect(
        present,
        hasLength(1),
        reason:
            '${entry.key} is exempt for ONE reason (${entry.value}) and now '
            'carries ${present.length}: $present',
      );
    }
  });
}
