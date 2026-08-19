import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('codegen hygiene', () {
    test('build.yaml fences drift_dev to lib/data', () {
      final buildYaml = File('build.yaml');
      expect(
        buildYaml.existsSync(),
        isTrue,
        reason:
            'without a generate_for: glob, one edit anywhere regenerates '
            'the whole tree (codegen-and-toolchain rule 2)',
      );

      final source = buildYaml.readAsStringSync();
      expect(source, contains('drift_dev'));
      expect(
        RegExp(r'generate_for:\s*\n\s*-\s*lib/data/\*\*').hasMatch(source),
        isTrue,
        reason:
            'drift_dev must be scoped to lib/data/**, the only directory '
            'allowed to hold a drift symbol',
      );
    });

    test('generated drift output is excluded from analysis', () {
      expect(
        File('analysis_options.yaml').readAsStringSync(),
        contains('"**/*.drift.dart"'),
      );
    });

    test('generated drift output is committed, not gitignored', () {
      // The repository's decision is that generated code is COMMITTED, and the
      // CI freshness diff is what makes that decision safe. Gitignoring it
      // instead would need a different gate, so the two must not drift apart.
      final result = Process.runSync('git', [
        'check-ignore',
        '-v',
        'lib/data/db/app_database.drift.dart',
      ]);

      expect(
        result.exitCode,
        isNot(0),
        reason: 'git check-ignore said: ${result.stdout}',
      );
    });

    test(
      'the CI workflow diffs the drift outputs and the schema snapshots',
      () {
        final workflow = File('.github/workflows/ci.yml').readAsStringSync();

        expect(
          workflow,
          contains("'*.drift.dart'"),
          reason:
              'a committed-generated-code policy without its freshness gate '
              'is not a policy',
        );
        expect(
          workflow,
          contains('drift_schemas/'),
          reason:
              'the committed v1 snapshot must match the live schema, or the '
              'migration harness is verifying against a stale record',
        );
      },
    );
  });
}
