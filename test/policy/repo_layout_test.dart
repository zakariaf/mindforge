import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Asserts the physical shape of the repository: the package name, the one
/// platform directory that ships, and the platform directories that are absent
/// by decision rather than by oversight.
void main() {
  group('repo layout', () {
    test('pubspec.yaml declares the package name mindforge', () {
      final pubspec = File('pubspec.yaml');
      expect(pubspec.existsSync(), isTrue, reason: 'the package must exist');
      expect(
        pubspec.readAsLinesSync().first.trim(),
        'name: mindforge',
        reason:
            'the working directory is E04, which is not a legal Dart '
            'package name, so --project-name was mandatory',
      );
    });

    test('ios is the only platform directory', () {
      expect(
        Directory('ios').existsSync(),
        isTrue,
        reason: 'iOS is the only shipping target (E01 T01.2)',
      );

      const absentPlatforms = <String, String>{
        'android':
            'deferred by decision, not unsupported. Nothing in lib/ may assume '
            'iOS; re-adding it is flutter create --platforms=android plus '
            'one PR for the build job',
        'macos':
            'superseded by the canonical simulator. macOS earned its place only '
            'as somewhere to eyeball the app, and MindForge iPhone 14 does '
            'that better because it is exactly 390x844 while a macOS window '
            'is whatever the developer dragged it to',
        'web': 'never in scope',
        'linux': 'never in scope',
        'windows': 'never in scope',
      };

      for (final entry in absentPlatforms.entries) {
        expect(
          Directory(entry.key).existsSync(),
          isFalse,
          reason: '${entry.key}/ must not exist: ${entry.value}',
        );
      }
    });

    test('lib/main.dart exists', () {
      expect(File('lib/main.dart').existsSync(), isTrue);
    });

    test('pubspec.lock is tracked, not gitignored', () {
      expect(File('.gitignore').existsSync(), isTrue);

      final result = Process.runSync('git', [
        'check-ignore',
        '-v',
        'pubspec.lock',
      ]);
      expect(
        result.exitCode,
        isNot(0),
        reason:
            'the Dart template gitignores pubspec.lock; an application must '
            'commit it so a fresh clone resolves the graph that was tested '
            '(dependency-hygiene rule 2). git check-ignore said: '
            '${result.stdout}',
      );
    });
  });
}
