import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Names that always mean "I could not decide where this belongs".
const kGrabBagNames = <String>['utils', 'helpers', 'common', 'misc'];

/// Reads the fenced target-layout block out of `CLAUDE.md` and returns every
/// directory path it names under `lib/`, plus the ancestors those paths imply.
///
/// The list is parsed rather than restated so the document and the tree cannot
/// drift apart in either direction: a directory the block does not name is a
/// failure, and a directory the block names but the tree lacks is also one.
Set<String> _layoutDirectoriesFromClaudeMd() {
  final lines = File('CLAUDE.md').readAsLinesSync();
  final start = lines.indexWhere((l) => l.trimRight() == 'lib/');
  if (start == -1) {
    throw StateError('CLAUDE.md has no `lib/` layout block to parse');
  }

  final directories = <String>{};
  for (final line in lines.skip(start + 1)) {
    if (line.startsWith('```') || line.startsWith('test/')) break;
    final match = RegExp(
      r'^  ([a-z0-9_]+(?:/[a-z0-9_]+)*)/\s',
    ).firstMatch(line);
    if (match == null) continue; // a continuation line of a prose column

    final path = match.group(1)!;
    final segments = path.split('/');
    for (var i = 1; i <= segments.length; i++) {
      directories.add(segments.take(i).join('/'));
    }
  }
  return directories;
}

void main() {
  final expected = _layoutDirectoriesFromClaudeMd();

  // Walked once. Three of the tests below need the same list, and listSync
  // recursive over lib/ is the most expensive thing in this file.
  final actualLibDirectories = Directory('lib')
      .listSync(recursive: true)
      .whereType<Directory>()
      .map((d) => d.path.substring('lib/'.length))
      .toSet();

  group('project structure', () {
    test('CLAUDE.md names the foundation directories this plan depends on', () {
      // A guard on the parser as much as on the tree: if the block is
      // reformatted into something this test cannot read, it must fail loudly
      // rather than silently assert over an empty set.
      expect(
        expected,
        containsAll(<String>[
          'core',
          'theme',
          'l10n',
          'ui/components',
          'ui/glyphs',
          'features',
          'games',
          'data',
          'shared/feedback',
          'shared/motion',
          'routing',
        ]),
      );
    });

    test('every directory CLAUDE.md names exists under lib/', () {
      final missing =
          expected.where((d) => !Directory('lib/$d').existsSync()).toList()
            ..sort();

      expect(missing, isEmpty, reason: 'missing under lib/: $missing');
    });

    test('test/ mirrors every directory lib/ has', () {
      final missing =
          expected.where((d) => !Directory('test/$d').existsSync()).toList()
            ..sort();

      expect(
        missing,
        isEmpty,
        reason:
            'test/ mirrors lib/ 1:1 (project-structure-and-packages). '
            'Missing under test/: $missing',
      );
    });

    test('lib/ holds no directory CLAUDE.md does not name', () {
      final undocumented = actualLibDirectories.difference(expected).toList()
        ..sort();

      expect(
        undocumented,
        isEmpty,
        reason:
            'these exist under lib/ but the CLAUDE.md layout block does '
            'not name them. Either the layout block is out of date, or the '
            'directory is in the wrong place: $undocumented',
      );
    });

    test('no grab-bag directory exists anywhere under lib/', () {
      final offenders = actualLibDirectories
          .map((path) => path.split('/').last)
          .where(kGrabBagNames.contains)
          .toList();

      expect(
        offenders,
        isEmpty,
        reason:
            'utils/helpers/common/misc are names for "I could not decide". '
            'lib/shared/feedback/ is not one of these: it has a stated '
            'responsibility (HapticGateway + FeedbackService)',
      );
    });
  });
}
