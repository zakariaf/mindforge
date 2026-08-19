import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The frozen set of direct dependencies. A package added without a review
/// fails this test rather than sliding in under a `pub get`.
///
/// Later epics **extend** this list; they never re-author it. E02 owns the
/// drift codegen additions, E11 owns anything the release needs.
const kAllowedDirectDependencies = <String>{
  // sdk entries — no version, no caret
  'flutter',
  'flutter_test',
  'flutter_localizations',
  // runtime
  'flutter_riverpod', // state and DI (CLAUDE.md); used from E02 on
  'drift', // on-device store, E02
  'sqlite3_flutter_libs', // the bundled SQLite the store runs on, E02
  'path_provider', // where the database file lives, E02
  'go_router', // the single router, E08
  'clock', // the injected Clock; DateTime.now() in domain code is a defect
  'intl', // LocaleNumbers' one NumberFormat construction site, E04
  // dev
  'very_good_analysis', // the lint floor, T01.5
  'build_runner', // drift codegen, E02
  'drift_dev', // drift codegen, E02
};

/// Packages that break a stated `CLAUDE.md` product constraint, mapped to the
/// constraint each one breaks. Checked against the **resolved lock**, not just
/// the direct set, because a transitive dependency ships in the binary too.
const kBannedPackages = <String, String>{
  'http': 'CLAUDE.md: fully offline — no network code at all',
  'dio': 'CLAUDE.md: fully offline — no network code at all',
  'web_socket_channel': 'CLAUDE.md: fully offline — no network code at all',
  'google_fonts': 'CLAUDE.md: bundled fonts — runtime font fetching is a '
      'network call',
  'firebase_': 'CLAUDE.md: no analytics, no crash reporting, no accounts',
  'sentry': 'CLAUDE.md: no analytics, no crash reporting',
  'google_mobile_ads': 'CLAUDE.md: no ads, no IAP',
  'in_app_purchase': 'CLAUDE.md: no ads, no IAP',
  'posthog': 'CLAUDE.md: no analytics — zero telemetry packages',
  'mixpanel': 'CLAUDE.md: no analytics — zero telemetry packages',
  'amplitude': 'CLAUDE.md: no analytics — zero telemetry packages',
  'device_info_plus': 'CLAUDE.md: no analytics — no user data leaves the device',
};

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final lock = File('pubspec.lock');

  group('dependency policy', () {
    test('every versioned direct dependency uses a caret range', () {
      final offenders = <String>[];
      var inDependencyBlock = false;

      for (final line in pubspec.split('\n')) {
        if (RegExp(r'^(dev_)?dependencies:').hasMatch(line)) {
          inDependencyBlock = true;
          continue;
        }
        if (line.isNotEmpty && !line.startsWith(' ') && !line.startsWith('#')) {
          inDependencyBlock = false;
          continue;
        }
        if (!inDependencyBlock) continue;

        final match = RegExp(r'^  ([a-z_0-9]+):\s*(\S.*)$').firstMatch(line);
        if (match == null) continue; // sdk: entries carry no inline version
        final version = match.group(2)!.trim();
        if (!version.startsWith('^')) {
          offenders.add('${match.group(1)}: $version');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'dependency-hygiene rule 1: caret ranges in pubspec.yaml, exact '
            'pins only in the committed pubspec.lock. Offenders: $offenders',
      );
    });

    test('the direct dependency set is the reviewed allow-set', () {
      final declared = <String>{};
      var inDependencyBlock = false;

      for (final line in pubspec.split('\n')) {
        if (RegExp(r'^(dev_)?dependencies:').hasMatch(line)) {
          inDependencyBlock = true;
          continue;
        }
        if (line.isNotEmpty && !line.startsWith(' ') && !line.startsWith('#')) {
          inDependencyBlock = false;
          continue;
        }
        if (!inDependencyBlock) continue;

        final match = RegExp(r'^  ([a-z_0-9]+):').firstMatch(line);
        if (match != null) declared.add(match.group(1)!);
      }

      expect(
        declared.difference(kAllowedDirectDependencies),
        isEmpty,
        reason: 'a dependency was added without extending the reviewed '
            'allow-set in this file. Audit its transitive tree first '
            '(dependency-hygiene rule 3), then add it here with the epic that '
            'first uses it.',
      );
    });

    test('pubspec.lock is committed and non-empty', () {
      expect(lock.existsSync(), isTrue);
      expect(lock.lengthSync(), greaterThan(0));
    });

    test('no banned package appears in the resolved lock', () {
      final resolved = RegExp(r'^  ([a-z_0-9]+):', multiLine: true)
          .allMatches(lock.readAsStringSync())
          .map((m) => m.group(1)!)
          .toSet();

      final offenders = <String>[];
      for (final entry in kBannedPackages.entries) {
        for (final name in resolved) {
          if (name == entry.key || name.startsWith(entry.key)) {
            offenders.add('$name — ${entry.value}');
          }
        }
      }

      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('cupertino_icons is absent', () {
      expect(
        pubspec.contains('cupertino_icons'),
        isFalse,
        reason: 'MindForge draws inline stroke glyphs under lib/ui/glyphs/ '
            '(CLAUDE.md working agreement 6); an icon font is dead weight',
      );
    });
  });
}
