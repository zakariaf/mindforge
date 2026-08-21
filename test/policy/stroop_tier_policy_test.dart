import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/source_text.dart';

/// The rules a game module obeys, asserted over its source.
///
/// **It duplicates the shell and i18n shell scripts on purpose.** Those run in
/// CI and in `tool/skill_gates.sh`; this runs in `flutter test`, which is what
/// a contributor runs before pushing. A rule that only fails in CI is a rule
/// found an hour late.
void main() {
  Iterable<File> filesUnder(String path) => Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));

  String codeOf(File file) => withoutDartComments(file.readAsStringSync());

  group('the gameplay tier stays inside the board', () {
    test('only a board file names the gameplay palette', () {
      // A gameplay colour that becomes chrome is a hint — and the colour-blind
      // swap re-points exactly those slots, so the hint would change colour
      // for the players who need it most.
      final offenders = <String>[];

      for (final file in filesUnder('lib/games/stroop_rush')) {
        final isBoard =
            file.path.endsWith('_board.dart') || file.path.contains('/board/');

        if (isBoard) continue;

        final code = codeOf(file);

        for (final name in <String>[
          'answerColour',
          'answerLabel(',
          'playRed',
          'playBlue',
          'playGreen',
          'playYellow',
          'cbPink',
          'cbOrange',
        ]) {
          if (code.contains(name)) offenders.add('${file.path}: $name');
        }
      }

      expect(offenders, isEmpty);
    });

    test('and no game file declares a colour of its own', () {
      // `(?<![A-Za-z])` because `SunburstColors.of(context)` ENDS IN
      // "Colors." — a plain substring flagged every file that reads the
      // palette correctly, which is the opposite of the rule.
      final material = RegExp(r'(?<![A-Za-z])Colors\.');
      final offenders = <String>[];

      for (final file in filesUnder('lib/games')) {
        final code = codeOf(file);

        if (code.contains('Color(0x') || material.hasMatch(code)) {
          offenders.add(file.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'a raw colour in a game is a colour nobody reviewed',
      );
    });
  });

  group('the game builds no chrome and owns no run', () {
    test('no navigation, no scaffold, no HUD, no clock, no run read', () {
      final offenders = <String>[];

      for (final file in filesUnder('lib/games')) {
        final code = codeOf(file);

        for (final name in <String>[
          'go_router',
          'Navigator.',
          'Scaffold(',
          'AppBar(',
          'HudPill',
          'Stopwatch(',
          'Timer.periodic(',
          'runNotifierProvider',
        ]) {
          if (code.contains(name)) offenders.add('${file.path}: $name');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'a board that could navigate could end the run, and a board with '
            'its own timer is the second clock rule 3 forbids',
      );
    });

    test('and no shell file imports the game', () {
      // THE CENTRAL CLAIM, as a grep. Schulte Grid ships without editing
      // lib/features, and this is what fails the day someone reaches the
      // other way.
      final offenders = <String>[];

      for (final file in filesUnder('lib/features')) {
        if (codeOf(file).contains('games/stroop_rush')) {
          offenders.add(file.path);
        }
      }

      expect(offenders, isEmpty);
    });
  });

  group('localisation cannot reach the domain', () {
    test('the domain imports no intl and no l10n', () {
      // A generator that could read a locale would deal a Persian player a
      // different game — the one thing the frozen vectors exist to prevent.
      final offenders = <String>[];

      for (final file in filesUnder('lib/games/stroop_rush/domain')) {
        final code = codeOf(file);

        if (code.contains('package:intl') || code.contains('mindforge/l10n')) {
          offenders.add(file.path);
        }
      }

      expect(offenders, isEmpty);
    });

    test('and the game formats no number and cases no string', () {
      final offenders = <String>[];

      for (final file in filesUnder('lib/games')) {
        final code = codeOf(file);

        for (final name in <String>[
          'NumberFormat(',
          'toUpperCase(',
          'toLowerCase(',
        ]) {
          if (code.contains(name)) offenders.add('${file.path}: $name');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'LocaleNumbers is the one NumberFormat site, and casing is a '
            'language property that belongs in the ARB',
      );
    });

    test('and it hardcodes no direction', () {
      // Direction is a consequence of the locale. A board that pinned one
      // would look right in the language it was written in and wrong in the
      // other three — and a test that pinned one would prove nothing at all.
      final offenders = <String>[];

      for (final file in filesUnder('lib/games')) {
        final code = codeOf(file);

        if (code.contains('Directionality(')) {
          offenders.add('${file.path}: Directionality(');
        }
      }

      expect(offenders, isEmpty);
    });
  });
}
