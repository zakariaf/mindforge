import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Import URI prefixes that break a stated `CLAUDE.md` product constraint,
/// mapped to the constraint each one breaks.
///
/// This is the **load-bearing** gate on the offline promise. The lock-level
/// check in `dependency_policy_test.dart` can only say a package is present in
/// the resolved graph; only this one says whether a network path is reachable
/// from an entrypoint.
const kBannedImportPrefixes = <String, String>{
  'package:http/': 'CLAUDE.md: fully offline — no network code at all',
  'package:dio/': 'CLAUDE.md: fully offline — no network code at all',
  'package:web_socket_channel/':
      'CLAUDE.md: fully offline — no network code at all',
  'package:web_socket/': 'CLAUDE.md: fully offline — no network code at all',
  'package:google_fonts/':
      'CLAUDE.md: bundled fonts — runtime font fetching is a network call',
  'package:firebase_':
      'CLAUDE.md: no analytics, no crash reporting, no accounts',
  'package:sentry': 'CLAUDE.md: no analytics, no crash reporting',
  'package:google_mobile_ads/': 'CLAUDE.md: no ads, no IAP',
  'package:in_app_purchase/': 'CLAUDE.md: no ads, no IAP',
};

/// Symbols that open a socket without needing a banned package, so a URI check
/// alone would miss them.
const kBannedSymbols = <String, String>{
  'HttpClient':
      "dart:io's HttpClient is a network path with no package to ban "
      '(CLAUDE.md: fully offline)',
};

void main() {
  test('no file under lib/ imports a banned URI or names a banned symbol', () {
    final offenders = <String>[];

    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in dartFiles) {
      // Strip line comments so a URI quoted in prose is not a false positive.
      final source = file
          .readAsLinesSync()
          .map((line) => line.replaceFirst(RegExp(r'\s*//.*$'), ''))
          .join('\n');

      final importUris = RegExp(
        r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
        multiLine: true,
      ).allMatches(source).map((m) => m.group(1)!);

      for (final uri in importUris) {
        for (final banned in kBannedImportPrefixes.entries) {
          if (uri.startsWith(banned.key)) {
            offenders.add('${file.path}: imports $uri — ${banned.value}');
          }
        }
      }

      for (final symbol in kBannedSymbols.entries) {
        if (RegExp('\\b${symbol.key}\\b').hasMatch(source)) {
          offenders.add('${file.path}: names ${symbol.key} — ${symbol.value}');
        }
      }
    }

    // Accumulate and fail once: a gate that reports one offender per run makes
    // a twenty-file cleanup twenty red builds.
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
