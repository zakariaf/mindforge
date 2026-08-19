import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The bug classes promoted to `error` because each one otherwise fails
/// **silently**: the operation never happens, the failure is swallowed, or the
/// hole is at a boundary nothing else watches.
const kPromotedToError = <String>[
  'unawaited_futures',
  'discarded_futures',
  'empty_catches',
  'avoid_catches_without_on_clauses',
  'only_throw_errors',
  'throw_in_finally',
  'use_build_context_synchronously',
  'cancel_subscriptions',
  'close_sinks',
  'avoid_dynamic_calls',
  'always_declare_return_types',
  'cast_nullable_to_non_nullable',
  'exhaustive_cases',
  'avoid_print',
  'avoid_slow_async_io',
];

/// Generated output that is committed source but must never be analyzed as
/// hand-written code. Mirrored into coverage filtering, or the number lies
/// upward.
const kRequiredExcludeGlobs = <String>[
  '**/*.g.dart',
  '**/*.freezed.dart',
  '**/*.drift.dart',
  '**/l10n/app_localizations*.dart',
];

void main() {
  final options = File('analysis_options.yaml').readAsStringSync();

  group('lint config', () {
    test('the very_good_analysis include is version-pinned', () {
      expect(
        RegExp(
          r'^include: package:very_good_analysis/analysis_options\.'
          r'\d+\.\d+\.\d+\.yaml$',
          multiLine: true,
        ).hasMatch(options),
        isTrue,
        reason:
            'a bare analysis_options.yaml lets a pub upgrade silently '
            'change what counts as an error (dependency-hygiene rule 5)',
      );
    });

    test('the pinned include filename exists in the resolved package', () {
      final pinned = RegExp(
        r'^include: package:very_good_analysis/(analysis_options\.'
        r'\d+\.\d+\.\d+\.yaml)$',
        multiLine: true,
      ).firstMatch(options)!.group(1)!;

      final resolvedVersion = RegExp(
        r'^  very_good_analysis:\n(?:.*\n)*?    version: "([^"]+)"',
        multiLine: true,
      ).firstMatch(File('pubspec.lock').readAsStringSync())!.group(1)!;

      expect(
        pinned,
        'analysis_options.$resolvedVersion.yaml',
        reason:
            'a filename that does not exist in the resolved package yields '
            'one include_file_not_found warning and a ruleset of zero added '
            'rules — a green build that checks nothing',
      );
    });

    test('every silence-producing bug class is promoted to error', () {
      final missing = kPromotedToError
          .where(
            (rule) => !RegExp(
              '^\\s+$rule: error\$',
              multiLine: true,
            ).hasMatch(options),
          )
          .toList();

      expect(missing, isEmpty, reason: 'not mapped to error: $missing');
    });

    test('no language block restates what VGA already sets', () {
      expect(
        RegExp('^language:', multiLine: true).hasMatch(options),
        isFalse,
        reason:
            'VGA already sets strict-casts, strict-inference and '
            'strict-raw-types; restating them is config that drifts and then '
            'contradicts',
      );
    });

    test('generated output is excluded from analysis', () {
      final missing = kRequiredExcludeGlobs
          .where((glob) => !options.contains('"$glob"'))
          .toList();

      expect(missing, isEmpty, reason: 'not excluded: $missing');
    });

    test('no linter rules block mixes list form and map form', () {
      final block = RegExp(
        r'^linter:\s*\n\s+rules:\s*\n((?:\s+.*\n)*)',
        multiLine: true,
      ).firstMatch(options);

      if (block == null) return; // no block at all is the default and is fine

      final lines = block
          .group(1)!
          .split('\n')
          .where((l) => l.trim().isNotEmpty && !l.trim().startsWith('#'));

      final hasListForm = lines.any((l) => l.trim().startsWith('- '));
      final hasMapForm = lines.any(
        (l) => RegExp(r':\s*(true|false)\s*$').hasMatch(l),
      );

      expect(
        hasListForm && hasMapForm,
        isFalse,
        reason:
            'mixing the two forms is a parse error, which silently '
            'disables the analyzer',
      );
    });
  });
}
