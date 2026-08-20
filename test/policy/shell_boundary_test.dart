import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/source_text.dart';

/// The shell/game seam, asserted from `flutter test` as well as from the shell
/// script.
///
/// `check_shell_boundaries.sh` already enforces this and runs in CI. Mirroring
/// it here means a contributor running `flutter test` locally sees the same
/// failure without knowing the gate exists — and the two agree because they use
/// the same token list.
///
/// Both halves pass vacuously today: `lib/features/` holds only domain and
/// application code and `lib/games/` holds only the definition and the empty
/// registry. That is exactly when a tripwire should be written, because after
/// E08, E09 and E10 it is a tripwire someone would have to write around.
void main() {
  List<File> dartFilesUnder(String directory) {
    final root = Directory(directory);
    if (!root.existsSync()) return const <File>[];

    return root
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
  }

  test('no file under lib/features imports a specific game', () {
    // `games/game_registry.dart` is the one allowed target: the pattern needs a
    // SECOND slash, so `games/stroop_rush/...` fails while the registry passes.
    final offenders = <String>[];
    final specificGame = RegExp(r"import\s+'[^']*games/[a-z0-9_]+/");

    for (final file in dartFilesUnder('lib/features')) {
      if (specificGame.hasMatch(withoutDartComments(file.readAsStringSync()))) {
        offenders.add(file.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'the shell reads GameDefinition. A screen that imports one game is '
          'the moment Schulte Grid stops being addable without editing it',
    );
  });

  test('and no file under lib/games builds shell chrome', () {
    // The same token set check_shell_boundaries.sh uses.
    const banned = <String>[
      'package:go_router',
      'Navigator.',
      'Scaffold(',
      'AppBar(',
      'SafeArea(',
      'HudPill',
      'PopBottomNav',
      'Stopwatch(',
      'Timer.periodic(',
      'runNotifierProvider',
    ];

    final offenders = <String>[];

    for (final file in dartFilesUnder('lib/games')) {
      final code = withoutDartComments(file.readAsStringSync());

      for (final token in banned) {
        if (code.contains(token)) offenders.add('${file.path}: $token');
      }
    }

    expect(offenders, isEmpty);
  });

  test('and the registry is the only file in lib that enumerates games', () {
    final offenders = dartFilesUnderLib()
        .where((file) => file.path != 'lib/games/game_registry.dart')
        .where(
          (file) => withoutDartComments(
            file.readAsStringSync(),
          ).contains('gameRegistryProvider'),
        )
        .map((file) => file.path)
        .toList();

    expect(
      offenders,
      isEmpty,
      reason:
          'reading the registry is fine through gameDefinitionProvider; '
          'enumerating it is the registry own job',
    );
  });
}
