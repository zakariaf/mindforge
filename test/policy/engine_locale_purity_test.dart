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
    ...Directory('lib/core')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart')),
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

    final offenders = <String>[];

    for (final file in generationPath()) {
      final code = withoutDartComments(file.readAsStringSync());

      for (final token in banned) {
        if (code.contains(token)) offenders.add('${file.path}: $token');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'a generator seeded off a formatted string, or a domain value holding '
          'one, produces a different game per language and no English-only test '
          'would show it',
    );
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
