import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/source_text.dart';

/// The shell/game contract renders nothing, and neither does anything else in
/// `lib/core/`.
///
/// The contract types moved here from `lib/features/play/domain/` because
/// `lib/games/**` must speak them and `lib/games/**` is fenced: a board file
/// whose first line is `import 'package:mindforge/features/...'` sends exactly
/// the message the fence exists to prevent. `lib/core/` is the layer both
/// peers reach, which is the same argument that already put `HudTone` here.
///
/// Everything a game hands upward is a KEY and a CANONICAL INTEGER. The moment
/// a type in here can hold a `Color`, a `Widget` or a formatted string, a board
/// starts making decisions the shell owns — and a snapshot holding
/// `"۱۸٫۶ ثانیه"` goes stale the instant the player changes language, which no
/// English-only test suite would ever show.
void main() {
  /// The shell/game contract, named rather than globbed.
  ///
  /// Not all of `lib/core/`: that layer legitimately holds `SupportedLocale`
  /// and `AppSettings`, both of which name a `Locale` because naming the
  /// shipped locales is their job. What must never touch one is the contract a
  /// board speaks.
  List<File> contractFiles() => const <String>[
    'lib/core/board_snapshot.dart',
    'lib/core/result_stat.dart',
    'lib/core/run_outcome.dart',
    'lib/core/run_config.dart',
    'lib/core/game_id.dart',
    'lib/core/difficulty.dart',
    'lib/core/hud_tone.dart',
  ].map(File.new).toList();

  test('every contract file exists, so the list cannot rot', () {
    // A named list is only as good as its names. A gate over a deleted path
    // passes forever.
    for (final file in contractFiles()) {
      expect(file.existsSync(), isTrue, reason: file.path);
    }
  });

  test('nothing in it can render, format or localize', () {
    const banned = <String>[
      'Color',
      'Widget',
      'BuildContext',
      'Locale',
      'NumberFormat',
      'AppLocalizations',
      'package:flutter/material',
      'package:flutter/widgets',
      'package:intl',
    ];

    expect(bannedTokenHits(contractFiles(), banned), isEmpty);
  });

  test('and HudTone is imported, never declared twice', () {
    // It lives in lib/core because BOTH sides need it and neither may import
    // the other: E05's HudPill renders a tone and HudSlot carries one, and
    // lib/ui may not import lib/features. Declaring it here as well would
    // produce two enums with one name that never unify — a game would set
    // HudTone.highlight on the domain side, the pill would switch on the UI
    // side, and the code would not compile at the seam.
    final declarations = dartFilesUnderLib()
        .where(
          (file) => withoutDartComments(file.readAsStringSync()).contains(
            'enum HudTone',
          ),
        )
        .map((file) => file.path)
        .toList();

    expect(declarations, <String>['lib/core/hud_tone.dart']);
  });
}
