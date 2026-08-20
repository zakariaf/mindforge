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
  test('no file under lib/features imports a specific game', () {
    // Matches on the ALLOWED TARGET rather than on the folder shape. The
    // shape version required a second slash to exempt the registry, which
    // meant a game shipped as a single file — `lib/games/schulte_grid.dart` —
    // could be imported by a screen without tripping the gate that exists to
    // stop exactly that.
    // The two ENGINE-level files under lib/games. Anything else there is a
    // specific game.
    const allowed = <String>{
      'games/game_definition.dart',
      'games/game_registry.dart',
    };
    final anyGameImport = RegExp("import '[^']*games/([^']+)'");

    final offenders = <String>[];

    for (final file in dartFilesUnder('lib/features')) {
      final code = withoutDartComments(file.readAsStringSync());

      for (final match in anyGameImport.allMatches(code)) {
        if (allowed.contains('games/${match.group(1)}')) continue;

        offenders.add('${file.path}: ${match.group(0)}');
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

    expect(bannedTokenHits(dartFilesUnder('lib/games'), banned), isEmpty);
  });

  test('and no file under lib/games reaches up into lib/features', () {
    // THE FENCE, made real. lib/games and lib/features were mutually dependent
    // — the registry imported the shell's domain folder while the notifier
    // imported the registry — and no gate said anything, because neither script
    // has a rule about lib/games at all. The contract types live in lib/core
    // now, which is the layer both peers reach, and this is what keeps them
    // there.
    final offenders = <String>[];

    for (final file in dartFilesUnder('lib/games')) {
      if (withoutDartComments(
        file.readAsStringSync(),
      ).contains('package:mindforge/features/')) {
        offenders.add(file.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'a game speaks the contract in lib/core. A board file whose first '
          'line imports lib/features sends the opposite of what the fence says',
    );
  });

  test('and the registry is the only file that DECLARES the list', () {
    // Reading the registry is the whole point of the engine: Home renders one
    // card per definition, and a screen that could not watch it would need a
    // hardcoded list instead. What must live in one place is the DECLARATION —
    // the line that says which games ship.
    //
    // The first version of this test banned the provider's NAME outside the
    // registry and bootstrap, which flagged Home's notifier for doing exactly
    // what the seam exists to allow.
    final declarations = dartFilesUnderLib()
        .where(
          (file) => withoutDartComments(
            file.readAsStringSync(),
          ).contains('gameRegistryProvider ='),
        )
        .map((file) => file.path)
        .toList();

    expect(declarations, <String>['lib/games/game_registry.dart']);
  });

  test('and nothing outside lib/games names a specific definition', () {
    // Reading the list is fine; naming a member of it is not. This is the
    // assertion that keeps `switch (gameId)` from arriving by another route.
    final offenders = dartFilesUnderLib()
        .where((file) => !file.path.startsWith('lib/games/'))
        .where(
          (file) => withoutDartComments(
            file.readAsStringSync(),
          ).contains('placeholderDefinitions'),
        )
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });
}
