import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import 'support/source_text.dart';

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
  // The golden lane runs, and it runs SEPARATELY: the default lane excludes it
  // so a shaping regression is legible on its own rather than buried among 500
  // geometry tests.
  'flutter test --tags golden',
  // The reference screenshots are tied to app.html and strings-fa.json by a
  // manifest of hashes, because CI cannot re-render them.
  'test/policy/reference_manifest_test.dart',
  // ONE --exclude-tags carrying a boolean selector. flutter_tools declares it
  // as a single addOption, so two flags last-wins and the first is dropped —
  // measured: the six golden tests ran inside the lane that excluded them.
  '--exclude-tags "tool || golden"',
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

  // The RUN LINES, with the comments stripped. Every ban below is a ban on
  // what CI executes, and a workflow that explains in a comment why it does not
  // bless a golden must not fail the ban on blessing goldens.
  final executed = withoutYamlComments(workflow);

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

    test('is valid YAML at all', () {
      // THE FIRST THING TO CHECK, and it was the one thing nothing checked.
      // Every run on every branch failed in 0s with "this run likely failed
      // because of a workflow file issue" — GitHub rejects the file before any
      // job starts, so no gate in it had ever executed, while eleven tests
      // asserted confidently about its contents as TEXT.
      //
      // The offending line was `run: "\$BASH5" tool/skill_gates.sh`: content
      // after a closing quote is a YAML parse error.
      late Map<dynamic, dynamic> parsed;

      expect(
        () => parsed = loadYaml(workflow) as Map<dynamic, dynamic>,
        returnsNormally,
      );
      expect(
        (parsed['jobs']! as Map<dynamic, dynamic>).keys,
        containsAll(<String>['verify', 'build-ios']),
      );
    });

    test('every step that runs a command has a runnable one', () {
      final jobs = (loadYaml(workflow) as Map)['jobs'] as Map;

      for (final job in jobs.values) {
        for (final step in (job as Map)['steps'] as List) {
          final run = (step as Map)['run'];
          if (run == null) continue;

          expect(
            run,
            isA<String>(),
            reason: '${step['name']} has a malformed run block',
          );
          expect(
            (run as String).trim(),
            isNotEmpty,
            reason: '${step['name']} runs nothing',
          );
        }
      }
    });

    test('every required gate step is present', () {
      // `executed`, not `workflow`. Reading the raw file meant the whole
      // skill-gate suite and the golden lane could be deleted from CI and the
      // test stayed green, as long as a `#` comment still carried the literal.
      final missing = kRequiredSteps
          .where((s) => !executed.contains(s))
          .toList();

      expect(missing, isEmpty, reason: 'missing steps: $missing');
    });

    test('no step repeats --exclude-tags, which silently drops one', () {
      // flutter_tools declares it as a single addOption: last wins. Two flags
      // read as "exclude both" and mean "exclude the second". Measured on
      // Flutter 3.44.6 — the golden lane ran inside the default lane.
      for (final line in executed.split('\n')) {
        expect(
          '--exclude-tags'.allMatches(line).length,
          lessThan(2),
          reason: 'use one --exclude-tags "a || b": $line',
        );
      }
    });

    test('no step can pass without passing, and no gate blesses', () {
      expect(
        executed.contains('continue-on-error'),
        isFalse,
        reason: 'a gate that cannot fail is not a gate',
      );
      expect(
        executed.contains('--update-goldens'),
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
