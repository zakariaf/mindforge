import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The gate commands that must appear as steps in the workflow. Each one is a
/// named contract, and a contract deleted without a review is a red test.
const kRequiredSteps = <String>[
  'tool/check_toolchain.sh',
  'flutter gen-l10n',
  'dart format --output=none --set-exit-if-changed .',
  'build_runner build',
  // `git status --porcelain`, not `git diff --exit-code`: git diff compares
  // tracked files only, so a newly created generated file is invisible to it.
  'git status --porcelain',
  'flutter analyze --fatal-infos --fatal-warnings',
  '--test-randomize-ordering-seed random',
  'tool/skill_gates.sh',
  'check_i18n_bans.sh',
  'flutter build ios --no-codesign',
];

/// The five sections the delivery loop requires of every PR body.
const kRequiredPrSections = <String>[
  '## What changed',
  '## Why',
  '## How it was verified',
  '## Screens compared',
  '## Deliberately left out',
];

void main() {
  final workflow = File('.github/workflows/ci.yml').readAsStringSync();

  group('ci workflow', () {
    test('every runner is a pinned macOS label', () {
      final runners = RegExp(
        r'runs-on:\s*(\S+)',
      ).allMatches(workflow).map((m) => m.group(1)!).toSet();

      expect(runners, isNotEmpty);
      for (final runner in runners) {
        expect(
          runner.startsWith('macos-'),
          isTrue,
          reason:
              'the app ships on iOS only; a Linux job would go green over '
              'a platform nobody ships. Found: $runner',
        );
        expect(
          runner,
          isNot('macos-latest'),
          reason:
              'ci-pipeline-and-gates rule 2: image drift moves Xcode and '
              'the toolchain with no diff to review',
        );
      }
    });

    test('no ubuntu job exists', () {
      // Matched against the extracted runs-on values, not the whole file: a
      // whole-file substring search reds this test when someone lowercases the
      // word in a comment, which has nothing to do with the contract.
      final runners = RegExp(
        r'runs-on:\s*(\S+)',
      ).allMatches(workflow).map((m) => m.group(1)!);

      expect(runners.where((r) => r.startsWith('ubuntu-')), isEmpty);
    });

    test('the Flutter action is pinned to the same version as the record', () {
      expect(workflow, contains('subosito/flutter-action@v2'));
      expect(workflow, contains('channel: stable'));

      final pinned = RegExp(
        r"flutter-version:\s*'([^']+)'",
      ).firstMatch(workflow)?.group(1);
      final recorded = RegExp(
        r'"flutter":\s*"([^"]+)"',
      ).firstMatch(File('.toolchain.json').readAsStringSync())!.group(1);

      expect(
        pinned,
        recorded,
        reason:
            '.fvmrc is deliberately not used, so flutter-action cannot '
            'point at the record with flutter-version-file. The drift is '
            'caught by this test instead of by the action',
      );
    });

    test('every required gate step is present', () {
      final missing = kRequiredSteps
          .where((s) => !workflow.contains(s))
          .toList();

      expect(missing, isEmpty, reason: 'missing steps: $missing');
    });

    test('no step can pass without passing, and no gate blesses', () {
      expect(
        workflow.contains('continue-on-error'),
        isFalse,
        reason: 'a gate that cannot fail is not a gate',
      );
      expect(
        workflow.contains('--update-goldens'),
        isFalse,
        reason:
            'ci-pipeline-and-gates rule 9: a gate verifies, it never '
            'blesses. CI writing a golden makes every future run agree with '
            'whatever it wrote',
      );
    });

    test('codegen runs before analyze', () {
      expect(
        workflow.indexOf('build_runner build'),
        lessThan(workflow.indexOf('flutter analyze')),
        reason:
            'codegen-and-toolchain rule 1: analyzing before generating '
            'reports missing part files as real errors',
      );
    });
  });

  group('pull request template', () {
    final template = File(
      '.github/PULL_REQUEST_TEMPLATE.md',
    ).readAsStringSync();

    test('carries the five required sections', () {
      final missing = kRequiredPrSections
          .where((s) => !template.contains(s))
          .toList();

      expect(missing, isEmpty, reason: 'missing sections: $missing');
    });

    test('its verification checklist quotes the gate runner', () {
      expect(
        template,
        contains('tool/skill_gates.sh'),
        reason:
            'the runner is the only sanctioned way to run the skill gates, '
            'so the template must not invite a glob over the directory',
      );
    });
  });
}
