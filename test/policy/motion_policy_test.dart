@Tags(['tool'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The motion and feedback invariants that are textually decidable, silent when
/// broken, and one line to break.
///
/// Each assertion strips comment-only lines first, accumulates every hit, and
/// fails once with a message a stranger can act on. A gate that fails on the
/// first offender makes a ten-file regression into ten runs.
void main() {
  /// Every Dart file under [directory], excluding generated output.
  List<File> dartFilesUnder(String directory) {
    final root = Directory(directory);
    if (!root.existsSync()) return const <File>[];

    return root
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
  }

  /// [file]'s source with comment-only lines removed.
  ///
  /// The gates are about CODE. A sentence explaining why a thing is absent
  /// should not trip the gate that checks it is absent, and rewording accurate
  /// prose to satisfy a substring match makes the comment worse and the gate no
  /// stronger.
  String codeOf(File file) => file
      .readAsStringSync()
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  /// Every `lib/` file whose code contains [needle], as `path:line`.
  List<String> hitsFor(String needle, {Set<String> permitted = const {}}) {
    final hits = <String>[];

    for (final file in dartFilesUnder('lib')) {
      if (permitted.contains(file.path)) continue;

      final lines = codeOf(file).split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains(needle)) hits.add('${file.path}:${i + 1}');
      }
    }

    return hits;
  }

  group('nothing repeats', () {
    test('no controller in lib loops without an end', () {
      expect(
        hitsFor('.repeat('),
        isEmpty,
        reason:
            'every motion in the catalog has an explicit stop condition. A '
            'repeating controller ticks for as long as the app is alive and '
            'reads as a fault rather than as feedback',
      );
    });
  });

  group('no raw motion value outside the theme', () {
    const themeOnly = <String>{'lib/theme/sunburst_motion.dart'};

    test('durations, curves and cubics live in one file', () {
      final offenders = <String>[
        ...hitsFor('Duration(milliseconds:', permitted: themeOnly),
        ...hitsFor('Curves.', permitted: themeOnly),
        ...hitsFor('Cubic(', permitted: themeOnly),
      ];

      expect(
        offenders,
        isEmpty,
        reason:
            'a duration typed at a call site is a duration reduce motion '
            'cannot collapse. Duration.zero is exempt and does not match this '
            'needle, matching check_motion_tokens.sh',
      );
    });
  });

  group('the haptic vocabulary is small and spent carefully', () {
    test('heavyImpact appears in at most three places', () {
      // The verb, its one catalog row, and the gateway arm that plays it. A
      // fourth is a review stop: a heavy knock that fires often stops meaning
      // anything.
      final hits = hitsFor('heavyImpact');

      expect(
        hits,
        hasLength(lessThanOrEqualTo(3)),
        reason: 'found $hits',
      );
    });

    test('and no call site gates a haptic on a settings flag', () {
      // THE GATE LIVES ONCE, inside LiveFeedbackService. This bans the second
      // GATE, not the second mention: the Settings screen must be able to
      // render and write the toggle when E08 lands, and a test that banned the
      // word would go red that day and get deleted rather than fixed.
      final offenders = <String>[];

      for (final file in dartFilesUnder('lib')) {
        if (file.path.startsWith('lib/shared/feedback/')) continue;
        if (file.path.startsWith('lib/features/settings/')) continue;
        if (file.path.startsWith('lib/data/')) continue;
        if (file.path == 'lib/core/app_settings.dart') continue;

        final code = codeOf(file);
        if (code.contains('isHapticsEnabled') && code.contains('.fire(')) {
          offenders.add(file.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'these pair a haptics-setting read with a fire() call, which is a '
            'second gate. One gate, in LiveFeedbackService, or a player who '
            'turns haptics off still feels whichever call sites forgot',
      );
    });
  });

  group('one implementation each', () {
    /// The files whose code declares [className].
    List<String> declarationsOf(String className) => dartFilesUnder('lib')
        .where((file) => codeOf(file).contains('class $className'))
        .map((file) => file.path)
        .toList();

    test('ShakeOnWrong is declared once, in shared motion', () {
      expect(declarationsOf('ShakeOnWrong'), <String>[
        'lib/shared/motion/shake_on_wrong.dart',
      ]);
    });

    test('and PopCelebration is too', () {
      expect(declarationsOf('PopCelebration'), <String>[
        'lib/shared/motion/pop_celebration.dart',
      ]);
    });

    test('SlideTransition is constructed in exactly one file', () {
      // The assertion check_i18n_bans.sh structurally CANNOT make: a slide
      // offset is not physical-side geometry, so its grep never sees it, and a
      // second SlideTransition somewhere else would mirror or fail to mirror
      // entirely on its author's memory.
      expect(
        hitsFor(
          'SlideTransition(',
          permitted: {
            'lib/shared/motion/directional_slide.dart',
          },
        ),
        isEmpty,
      );
    });
  });

  group('non-directional motion never reads a direction', () {
    const fixedOrNone = <String>[
      'lib/shared/motion/press_physics.dart',
      'lib/shared/motion/pop_celebration.dart',
      'lib/shared/motion/shake_on_wrong.dart',
    ];

    test('the three that do not mirror read nothing that could make them', () {
      final offenders = <String>[];

      for (final path in fixedOrNone) {
        final code = codeOf(File(path));

        for (final needle in <String>['Directionality', 'TextDirection']) {
          if (code.contains(needle)) offenders.add('$path: $needle');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'the press travels toward the light source, the celebration is a '
            'scale, and the shake is symmetric. None of them has a reading '
            'direction to read',
      );
    });

    test('and nothing in lib negates a dx behind a direction check', () {
      final offenders = <String>[];
      final negation = RegExp(r'rtl.*-.*dx|dx.*\*.*-1|-\s*\w*[Dd]x\b');

      for (final file in dartFilesUnder('lib')) {
        final lines = codeOf(file).split('\n');
        for (var i = 0; i < lines.length; i++) {
          if (negation.hasMatch(lines[i])) {
            offenders.add('${file.path}:${i + 1}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'mirroring is SlideTransition.textDirection and the directional '
            'geometry types, never a hand-written sign. i18n-rtl-l10n names '
            'inverting a dx for RTL outright',
      );
    });
  });

  group('the sensory layer renders no strings', () {
    test('it imports no localization and no formatter', () {
      // A moment is a semantic token. Nothing about which language the app is
      // in changes what fires, how hard, or for how long.
      final offenders = <String>[];

      for (final directory in <String>[
        'lib/shared/feedback',
        'lib/shared/motion',
      ]) {
        for (final file in dartFilesUnder(directory)) {
          final code = codeOf(file);

          if (code.contains('app_localizations')) {
            offenders.add('${file.path}: AppLocalizations');
          }
          if (code.contains('package:intl')) {
            offenders.add('${file.path}: intl');
          }
        }
      }

      expect(offenders, isEmpty);
    });

    test('and residueNote is documentation, not a rendered string', () {
      // It exists so the catalog can be reviewed, and it is English prose. A
      // widget reading it would put untranslated English on a Persian screen.
      expect(
        hitsFor(
          'residueNote',
          permitted: {
            'lib/shared/feedback/moment_catalog.dart',
            'lib/shared/feedback/moment_spec.dart',
          },
        ),
        isEmpty,
      );
    });
  });

  group('shared motion is reachable from a game', () {
    /// Runs the shell/game fence over a synthetic tree and returns its exit
    /// code.
    ///
    /// The fence is what governs `lib/games/**`, and running it beats grepping
    /// it: the first version of this test looked for the word "shared" in
    /// `check_import_boundaries.sh` and failed, because that script enforces
    /// relative-import and pure-Dart rules and says nothing about layer edges.
    /// The edge a game actually has to cross is this one.
    int fenceOver(String boardSource) {
      final root = Directory.systemTemp.createTempSync('mindforge_fence');
      addTearDown(() => root.deleteSync(recursive: true));

      Directory('${root.path}/games/probe').createSync(recursive: true);
      File(
        '${root.path}/games/probe/board.dart',
      ).writeAsStringSync(boardSource);

      const fence =
          '.claude/skills/sunburst-shell-screens/scripts/'
          'check_shell_boundaries.sh';

      return Process.runSync('bash', <String>[fence, root.path]).exitCode;
    }

    test('a board may wrap ShakeOnWrong without a waiver', () {
      // Asserted BEFORE lib/games exists, because a boundary discovered
      // mid-epic becomes a waiver. E09's answer key and E10's tile both need
      // this widget; if the fence rejected the import, the first board would
      // reinvent the shake instead of raising it.
      expect(
        fenceOver('''
import 'package:flutter/widgets.dart';
import 'package:mindforge/shared/motion/pop_celebration.dart';
import 'package:mindforge/shared/motion/shake_on_wrong.dart';

Widget buildBoard(BuildContext context, {required bool wrong}) =>
    ShakeOnWrong(isWrong: wrong, child: const SizedBox.shrink());
'''),
        0,
        reason: 'lib/shared/motion is importable from lib/games',
      );
    });

    test('and the fence is still a fence', () {
      // The negative control. Without it the test above passes just as well
      // against a script that exits 0 unconditionally.
      expect(
        fenceOver('''
import 'package:flutter/material.dart';

void leave(BuildContext context) => Navigator.of(context).pop();
'''),
        isNot(0),
        reason: 'a game that navigates must still be rejected',
      );
    });
  });
}
