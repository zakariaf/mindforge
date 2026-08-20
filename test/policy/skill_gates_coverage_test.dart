import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every `*.sh` under `.claude/skills/*/scripts/` must appear **exactly once**
/// in `tool/skill_gates.sh` — either in the run table or in the skip table with
/// a non-empty reason.
///
/// This is what makes the tables living rather than decorative. A later epic
/// that creates a script's target moves its row from skip to run in the same
/// PR, and "exactly once" is what forces the move to be deliberate instead of
/// leaving a duplicate behind.
void main() {
  final runner = File('tool/skill_gates.sh').readAsStringSync();

  /// The `"<script path>|<argument or reason>"` entries of one bash array in
  /// `tool/skill_gates.sh`, keyed by script path.
  Map<String, String> tableEntries(String arrayName) {
    final block = RegExp(
      '^$arrayName=\\(\$(.*?)^\\)\$',
      multiLine: true,
      dotAll: true,
    ).firstMatch(runner);
    if (block == null) {
      throw StateError('tool/skill_gates.sh has no $arrayName array to parse');
    }

    final entries = <String, String>{};
    for (final match in RegExp(
      r'^\s*"([^"|]+)\|(.*)"\s*$',
      multiLine: true,
    ).allMatches(block.group(1)!)) {
      entries[match.group(1)!] = match.group(2)!;
    }
    return entries;
  }

  final runRows = tableEntries('RUN_TABLE');
  final skipRows = tableEntries('SKIP_TABLE');

  final scripts =
      Directory('.claude/skills')
          .listSync()
          .whereType<Directory>()
          .map((skill) => Directory('${skill.path}/scripts'))
          .where((scripts) => scripts.existsSync())
          .expand((scripts) => scripts.listSync())
          .whereType<File>()
          .where((f) => f.path.endsWith('.sh'))
          .map((f) => f.path.replaceFirst('.claude/skills/', ''))
          .toList()
        ..sort();

  group('skill gate coverage', () {
    test('both tables parsed and there is something to cover', () {
      // Guards on the parser as much as on the tables: if the runner is
      // reformatted into something this test cannot read, it must fail loudly
      // rather than pass over an empty set.
      expect(scripts, isNotEmpty);
      expect(runRows, isNotEmpty);
      expect(skipRows, isNotEmpty);
    });

    test('every script appears exactly once, across both tables', () {
      final unlisted = <String>[];
      final duplicated = <String>[];

      for (final script in scripts) {
        final inRun = runRows.containsKey(script);
        final inSkip = skipRows.containsKey(script);

        if (!inRun && !inSkip) unlisted.add(script);
        if (inRun && inSkip) duplicated.add(script);
      }

      // Accumulate and fail once with the full list, never one at a time.
      expect(
        unlisted,
        isEmpty,
        reason:
            'these scripts are in neither table. Add each to RUN_TABLE '
            'with the argument it takes, or to SKIP_TABLE with a STRUCTURAL '
            'reason — never "it fails": $unlisted',
      );
      expect(
        duplicated,
        isEmpty,
        reason:
            'listed in both tables, so moving it was not deliberate: '
            '$duplicated',
      );
    });

    test('neither table lists a script that is not on disk', () {
      final phantom = <String>[
        ...runRows.keys,
        ...skipRows.keys,
      ].where((s) => !scripts.contains(s)).toList();

      expect(phantom, isEmpty, reason: 'listed but absent: $phantom');
    });

    test('every skip row carries a non-empty reason', () {
      final reasonless = skipRows.entries
          .where((e) => e.value.trim().isEmpty)
          .map((e) => e.key);

      expect(
        reasonless,
        isEmpty,
        reason: 'skipped with no reason: $reasonless',
      );
    });

    test('check_arb_parity.sh now runs, over the four-locale directory', () {
      const script = 'i18n-rtl-l10n/scripts/check_arb_parity.sh';

      // E01 measured it exiting 2 on a directory holding only the template and
      // parked it in the skip table naming E04 as its mover. This is that move,
      // and this assertion is what stops it drifting back.
      expect(skipRows, isNot(contains(script)));
      expect(runRows[script], 'lib/l10n');
    });
  });
}
