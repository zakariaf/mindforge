import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/source_text.dart';

/// `lib/features/play/domain/` is the shell/game contract, and it renders
/// nothing.
///
/// Everything a game hands upward is a KEY and a CANONICAL INTEGER. The moment
/// a type in here can hold a `Color`, a `Widget` or a formatted string, a board
/// starts making decisions the shell owns — and a snapshot holding
/// `"۱۸٫۶ ثانیه"` goes stale the instant the player changes language, which no
/// English-only test suite would ever show.
void main() {
  List<File> domainFiles() => Directory('lib/features/play/domain')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  test('the domain has files to check', () {
    // A purity gate over an empty directory passes forever.
    expect(domainFiles(), isNotEmpty);
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

    final offenders = <String>[];

    for (final file in domainFiles()) {
      final code = withoutDartComments(file.readAsStringSync());

      for (final token in banned) {
        if (code.contains(token)) offenders.add('${file.path}: $token');
      }
    }

    expect(offenders, isEmpty);
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
