import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The store answer cannot drift from the tree.
///
/// `docs/review/app-review-4-3-a.md` is what a human sends to App Review. Every
/// differentiator it names points at a file, a test or a setting — and a
/// document that claims a capability the code does not have is worse than no
/// document, because it is the one artifact a reviewer might actually check.
///
/// **This is a grep, and it earns its place on the three criteria
/// `ci-pipeline-and-gates` rule 7 sets**: the claim is textually decidable, it
/// fails silently otherwise (nothing breaks when a doc goes stale), and it is
/// one rename away from being wrong.
void main() {
  final answer = File('docs/review/app-review-4-3-a.md');

  test('the answer exists and names the rejected build', () {
    expect(answer.existsSync(), isTrue);

    final text = answer.readAsStringSync();

    expect(text, contains('4.3(a)'));
    expect(
      text,
      contains('6803829952'),
      reason: 'the app id it was rejected under',
    );
    expect(text, contains('1.0.0'));
  });

  test('and every path it points at exists', () {
    // The backticked paths in its evidence tables. A claim naming a file that
    // was renamed or deleted is a claim a reviewer would find broken.
    const paths = <String>[
      'lib/games/digit_bridge/',
      'lib/games/game_registry.dart',
      'lib/games/digit_bridge/domain/bridge_distractor.dart',
      'lib/l10n/locale_numbers.dart',
      'lib/l10n/ckb_localizations.dart',
      'lib/games/stroop_rush/ui/board/play_fill.dart',
      'ios/Runner/Info.plist',
      'lib/l10n/app_en.arb',
      'lib/l10n/app_de.arb',
      'lib/l10n/app_fa.arb',
      'lib/l10n/app_ckb.arb',
      'test/policy/engine_locale_purity_test.dart',
      'test/policy/permissions_test.dart',
      'test/policy/dependency_policy_test.dart',
      'test/l10n/material_delegate_support_test.dart',
      'test/games/digit_bridge/domain/bridge_round_generator_test.dart',
      'test/games/digit_bridge/domain/bridge_round_locale_test.dart',
      'test/games/false_light/ui/light_tile_states_test.dart',
    ];

    final text = answer.readAsStringSync();

    for (final path in paths) {
      expect(
        text,
        contains(path),
        reason: '$path is in the evidence list but not cited in the document',
      );
      expect(
        FileSystemEntity.typeSync(path),
        isNot(FileSystemEntityType.notFound),
        reason: 'the document cites $path, which does not exist',
      );
    }
  });

  test('and every test it names as evidence actually asserts it', () {
    // A named test file is only evidence if the assertion is in it. Checked by
    // the test DESCRIPTION the document quotes, so renaming a test away from
    // the claim fails here rather than silently.
    const quoted = <String, String>{
      'test/policy/engine_locale_purity_test.dart':
          'False Light DRAWS nothing a locale could translate',
      'test/games/false_light/ui/light_tile_states_test.dart':
          'changes nothing on this board',
    };

    for (final entry in quoted.entries) {
      expect(
        File(entry.key).readAsStringSync(),
        contains(entry.value),
        reason:
            'the document quotes "${entry.value}" from ${entry.key}, and it '
            'is not there',
      );
    }
  });

  test('and the symbols it names still exist', () {
    // The API-level claims. `digitsInScript` is the whole cross-script
    // mechanic; the three tile-state keys are False Light's only non-visual
    // channel. Both are named in the document as things a reviewer can check.
    expect(
      File('lib/l10n/locale_numbers.dart').readAsStringSync(),
      contains('digitsInScript'),
    );

    final board = File(
      'lib/games/false_light/ui/false_light_board.dart',
    ).readAsStringSync();

    for (final key in <String>[
      'lightTileRaised',
      'lightTilePressed',
      'lightTileSwept',
    ]) {
      expect(board, contains(key));
    }
  });

  test('and it makes no promise about the outcome', () {
    // The one thing a document like this is most tempted to do. 4.3(a) is a
    // reviewer judgement; claiming it is settled would be the same kind of
    // overstatement the app's privacy copy is gated against.
    final text = answer.readAsStringSync();

    expect(
      text,
      contains('does not claim the rejection will be overturned'),
      reason: 'the honest limit has to be stated in the document itself',
    );
  });
}
