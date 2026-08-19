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
  'path_provider', // where the database file lives, E02
  'go_router', // the single router, E08
  'clock', // the injected Clock; DateTime.now() in domain code is a defect
  'intl', // LocaleNumbers' one NumberFormat construction site, E04
  'meta', // @immutable / @useResult on the lib/core value types, E02
  'path', // joining the application-support directory to the db file, E02
  // Direct: connection.dart names CommonDatabase to type the pragma setup
  // callback. It is drift's own runtime dependency, declared here because a
  // file under lib/ imports it directly.
  'sqlite3',
  'uuid', // UuidIdGenerator behind the IdGenerator seam, E02
  // dev
  'very_good_analysis', // the lint floor, T01.5
  'build_runner', // drift codegen, E02
  'drift_dev', // drift codegen, E02
  // lib/core/ is Flutter-free, so its tests are too. Declared explicitly rather
  // than resolved by accident through riverpod 3's dependency on package:test —
  // the same graph kExplainedTransitives documents as removable.
  'test',
};

/// Transitive packages whose presence in the lock is explained, measured and
/// accepted, mapped to the chain that drags them in.
///
/// An entry here is not an exemption from the offline promise — that promise is
/// enforced at the **import** level by `test/policy/banned_imports_test.dart`,
/// which is the check that actually decides whether a network code path can run.
/// This map exists so a name in the lock is either banned or explained, never
/// merely tolerated.
const kExplainedTransitives = <String, String>{
  'web_socket':
      'reached by web_socket_channel; see that entry. Listed '
      "separately so this file and audit_deps.py's ALLOW set agree — a direct "
      'dependency on it must not sail through one gate because only the other '
      'names it.',
  'web_socket_channel':
      'measured with `flutter pub deps --style=compact` on 2026-08-19: reached '
      'by riverpod 3.4.2 -> test 1.31.0 -> shelf_web_socket 3.0.0, and by '
      'the build_runner dev tool. Riverpod 3 declares package:test as a '
      'regular dependency because it ships test utilities in the main '
      'package. Nothing under lib/ imports it, so it tree-shakes out of the '
      'release binary; banned_imports_test.dart is what proves that.',
};

/// Packages that break a stated `CLAUDE.md` product constraint, mapped to the
/// constraint each one breaks. Checked against the **resolved lock**, not just
/// the direct set, because a transitive dependency ships in the binary too.
const kBannedPackages = <String, String>{
  'http': 'CLAUDE.md: fully offline — no network code at all',
  'dio': 'CLAUDE.md: fully offline — no network code at all',
  'web_socket': 'CLAUDE.md: fully offline — no network code at all',
  'web_socket_channel': 'CLAUDE.md: fully offline — no network code at all',
  'google_fonts':
      'CLAUDE.md: bundled fonts — runtime font fetching is a '
      'network call',
  'google_mobile_ads': 'CLAUDE.md: no ads, no IAP',
  'in_app_purchase': 'CLAUDE.md: no ads, no IAP',
  'posthog': 'CLAUDE.md: no analytics — zero telemetry packages',
  'mixpanel': 'CLAUDE.md: no analytics — zero telemetry packages',
  'amplitude': 'CLAUDE.md: no analytics — zero telemetry packages',
  'device_info_plus':
      'CLAUDE.md: no analytics — no user data leaves the device',
};

/// Banned package **families**, matched by prefix. Kept separate from
/// [kBannedPackages] because prefix-matching an ordinary name produces false
/// positives — `http_parser` and `http_multi_server` are not `package:http`,
/// and a gate that cries wolf gets an `// ignore:` instead of a fix.
const kBannedPackagePrefixes = <String, String>{
  'firebase_': 'CLAUDE.md: no analytics, no crash reporting, no accounts',
  'sentry': 'CLAUDE.md: no analytics, no crash reporting',
};

/// Every name declared under `dependencies:` or `dev_dependencies:` in
/// `pubspec.yaml`, mapped to its inline version constraint.
///
/// The value is `null` when the entry carries no inline constraint, which is
/// either an `sdk:` entry or a block form such as `foo:\n    version: 1.2.3`.
/// The caret-range test below does **not** treat `null` as "nothing to check" —
/// a block form is exactly how an exact pin would otherwise slip past the gate
/// that exists to catch it. Written once because the caret-range check and the
/// allow-set check had each grown their own copy of this fifteen-line walk.
Map<String, String?> _declaredDependencies(String pubspec) {
  final declared = <String, String?>{};
  var inDependencyBlock = false;

  for (final line in pubspec.split('\n')) {
    if (RegExp('^(dev_)?dependencies:').hasMatch(line)) {
      inDependencyBlock = true;
      continue;
    }
    if (line.isNotEmpty && !line.startsWith(' ') && !line.startsWith('#')) {
      inDependencyBlock = false;
      continue;
    }
    if (!inDependencyBlock) continue;

    final match = RegExp('^  ([a-z_0-9]+):(.*)').firstMatch(line);
    if (match == null) continue;

    final version = match.group(2)!.trim();
    declared[match.group(1)!] = version.isEmpty ? null : version;
  }
  return declared;
}

/// Every package name in the resolved `pubspec.lock`.
Set<String> _resolvedPackages(File lock) => RegExp(
  '^  ([a-z_0-9]+):',
  multiLine: true,
).allMatches(lock.readAsStringSync()).map((m) => m.group(1)!).toSet();

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final lock = File('pubspec.lock');
  final declaredDependencies = _declaredDependencies(pubspec);
  final resolvedPackages = _resolvedPackages(lock);

  group('dependency policy', () {
    test('every versioned direct dependency uses a caret range', () {
      final offenders = declaredDependencies.entries
          .where((e) => e.value != null && !e.value!.startsWith('^'))
          .map((e) => '${e.key}: ${e.value}')
          .toList();

      expect(
        offenders,
        isEmpty,
        reason:
            'dependency-hygiene rule 1: caret ranges in pubspec.yaml, exact '
            'pins only in the committed pubspec.lock. Offenders: $offenders',
      );
    });

    test('the direct dependency set is the reviewed allow-set', () {
      expect(
        declaredDependencies.keys.toSet().difference(
          kAllowedDirectDependencies,
        ),
        isEmpty,
        reason:
            'a dependency was added without extending the reviewed '
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
      final offenders = <String>[];
      for (final name in resolvedPackages) {
        if (kExplainedTransitives.containsKey(name)) continue;

        final exact = kBannedPackages[name];
        if (exact != null) offenders.add('$name — $exact');

        for (final family in kBannedPackagePrefixes.entries) {
          if (name.startsWith(family.key)) {
            offenders.add('$name — ${family.value}');
          }
        }
      }

      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('every explained transitive is still actually in the lock', () {
      final stale = kExplainedTransitives.keys.where(
        (k) => !resolvedPackages.contains(k),
      );
      expect(
        stale,
        isEmpty,
        reason:
            'these packages left the resolved graph, so their measured '
            'explanation is now a decoy that would silently re-admit them: '
            '$stale. Delete the entry.',
      );
    });

    test('cupertino_icons is absent', () {
      expect(
        pubspec.contains('cupertino_icons'),
        isFalse,
        reason:
            'MindForge draws inline stroke glyphs under lib/ui/glyphs/ '
            '(CLAUDE.md working agreement 6); an icon font is dead weight',
      );
    });
  });
}
