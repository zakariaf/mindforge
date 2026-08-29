import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/source_text.dart';

/// Nothing on the generation path can reach a locale.
///
/// Textually decidable, silent when broken, and one line to break — the three
/// criteria a policy grep has to meet to earn its place. The failure it guards
/// against compiles, passes an English-only suite, and deals a Persian player a
/// different game.
void main() {
  /// Every file that computes something a run depends on.
  List<File> generationPath() => <File>[
    File('lib/core/seeded_generator.dart'),
    File('lib/features/play/application/seeded_random_provider.dart'),
    // The whole contract layer, through the shared walk — which skips
    // generated files, unlike the copy this replaced.
    ...dartFilesUnder('lib/core'),
    // E12. Every game's DOMAIN is on the generation path too: it is where the
    // seed becomes a round, and a formatter reaching it would deal a different
    // game per language. Four directories rather than a `lib/games` walk,
    // because `application/` and `ui/` legitimately localize.
    ...dartFilesUnder('lib/games/stroop_rush/domain'),
    ...dartFilesUnder('lib/games/schulte_grid/domain'),
    ...dartFilesUnder('lib/games/digit_bridge/domain'),
    ...dartFilesUnder('lib/games/false_light/domain'),
  ];

  test('the path has files on it', () {
    // A purity gate over an empty list passes forever.
    expect(generationPath(), hasLength(greaterThan(5)));

    for (final file in generationPath()) {
      expect(file.existsSync(), isTrue, reason: file.path);
    }
  });

  test('and none of them imports a formatter or a localization', () {
    const banned = <String>[
      'package:intl',
      'app_localizations',
      'AppLocalizations',
      'LocaleNumbers',
      'NumberFormat',
      'DateFormat',
      'Intl.',
    ];

    expect(
      bannedTokenHits(generationPath(), banned),
      isEmpty,
      reason:
          'a generator seeded off a formatted string, or a domain value holding '
          'one, produces a different game per language and no English-only test '
          'would show it',
    );
  });

  test('and False Light DRAWS nothing a locale could translate', () {
    // The differentiation claim, as a gate rather than a habit, and stated
    // exactly. False Light's board has no numeral, no word and no glyph: depth
    // is its only visual channel.
    //
    // **It still localizes — and that is the accessibility half of the same
    // fact.** `lightTileRaised`, `lightTilePressed` and `lightTileSwept` are
    // announced and never drawn, because a screen-reader user cannot see a
    // shadow and would otherwise be handed a board with no channel at all. So
    // the banned token is not `AppLocalizations`, which would forbid the thing
    // that makes the game playable; it is `Text(`, the widget that would put a
    // string on the screen.
    //
    // Scoped to False Light alone. The other three games DO draw localized
    // content, which is correct for them.
    const banned = <String>['Text('];

    final files = <File>[
      ...dartFilesUnder('lib/games/false_light/domain'),
      ...dartFilesUnder('lib/games/false_light/ui'),
    ];

    expect(files, hasLength(greaterThan(3)));
    expect(
      bannedTokenHits(files, banned),
      isEmpty,
      reason:
          'a drawn string on the False Light board would be the one thing that '
          'makes its en and fa renders differ in content, which is the claim '
          'the game exists to make',
    );
  });

  test('and False Light still SAYS which depth a tile is', () {
    // The counterpart, and it has to be asserted or the test above could be
    // satisfied by a board that told a screen-reader user nothing either. The
    // three tile-state keys are the game's only non-visual channel.
    final board = File(
      'lib/games/false_light/ui/false_light_board.dart',
    ).readAsStringSync();

    for (final key in <String>[
      'lightTileRaised',
      'lightTilePressed',
      'lightTileSwept',
    ]) {
      expect(
        board,
        contains(key),
        reason:
            'depth is the only channel on this board, so a reader who cannot '
            'see a shadow needs it in words or the game is unplayable',
      );
    }
  });

  test('and check_arb_parity.sh is in the run table, not the skip table', () {
    // E01 skipped it with a measured reason: one locale shipped, nothing to
    // compare. E04 shipped four, which makes that reason stale — and a stale
    // skip row is a gate that silently checks nothing.
    final runner = File('tool/skill_gates.sh').readAsStringSync();

    final runTable = runner.substring(
      runner.indexOf('RUN_TABLE'),
      runner.indexOf('SKIP_TABLE'),
    );

    expect(runTable, contains('check_arb_parity.sh'));
  });
}
