/// Helpers shared by the policy tests, which all assert over source text.
///
/// These live here rather than being copied into each test because the same
/// idiom had drifted into three slightly different regexes across four files —
/// which is how one of them ends up not stripping what it thinks it strips.
library;

import 'dart:io';

/// [source] with every `//` line comment removed.
///
/// Policy tests that ban a construct must strip comments first, because the
/// file being scanned usually explains in prose **why** the construct is
/// absent. A gate that fires on its own rationale gets deleted rather than
/// obeyed.
String withoutDartComments(String source) => _strip(source, '//');

/// [source] with every `#` line comment removed, for YAML and `.arb` scans.
String withoutYamlComments(String source) => _strip(source, '#');

/// Removes trailing [marker] comments, **without** cutting a marker that
/// appears inside a string literal.
///
/// A naive `indexOf(marker)` truncates any line holding a URL at the `//` in
/// `https://`, and any YAML line holding a `#` in a value. That is a
/// false-negative hole in a load-bearing gate: `banned_imports_test` scans the
/// stripped text, so a banned symbol sitting after a URL on the same line would
/// silently disappear before the scan ever saw it.
String _strip(String source, String marker) =>
    source.split('\n').map((line) => _stripLine(line, marker)).join('\n');

String _stripLine(String line, String marker) {
  var quote = '';

  for (var i = 0; i < line.length; i++) {
    final char = line[i];

    if (quote.isNotEmpty) {
      if (char == r'\') {
        i++; // skip the escaped character
      } else if (char == quote) {
        quote = '';
      }
      continue;
    }

    if (char == "'" || char == '"') {
      quote = char;
      continue;
    }

    if (line.startsWith(marker, i)) return line.substring(0, i);
  }

  return line;
}

/// Every **hand-written** `.dart` file under `lib/`.
///
/// The generated files are excluded here rather than in each caller: a policy
/// test that scans `app_localizations.dart` or a `.drift.dart` is asserting
/// over code nobody can edit, and the usual response is to weaken the rule
/// rather than the scan. Ten copies of this walk had accumulated, each with a
/// slightly different skip list — which is the same failure this file's
/// comment-stripping helpers were extracted to stop.
///
/// [skip] adds further path fragments to exclude, for a test that legitimately
/// exempts one file (usually the one that DEFINES the thing being banned).
Iterable<File> dartFilesUnderLib({Set<String> skip = const <String>{}}) =>
    dartFilesUnder('lib', skip: skip);

/// Every **hand-written** `.dart` file under [root].
///
/// The same walk as [dartFilesUnderLib], for a gate scanning one subtree. Four
/// policy tests had re-rolled it — and none of them inherited the generated-file
/// exclusion, so a future `.g.dart` under `lib/games/` would have been scanned
/// by two gates that would then have been weakened rather than fixed.
///
/// Returns nothing when [root] does not exist, so a gate written before the
/// directory it guards passes vacuously instead of throwing.
Iterable<File> dartFilesUnder(
  String root, {
  Set<String> skip = const <String>{},
}) {
  final directory = Directory(root);
  if (!directory.existsSync()) return const <File>[];

  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !_isGenerated(f.path))
      // Written with `every` rather than the negation of its Iterable
      // sibling, which check_test_hygiene.sh cannot distinguish from
      // mocktail's argument matcher of the same name — it greps test/ for
      // the bare call and fires on the collision. The gate is right to be
      // crude about it; this is the cheaper side to move.
      .where((f) => skip.every((fragment) => !f.path.contains(fragment)));
}

/// Every `path:token` in [files] whose CODE contains one of [tokens].
///
/// Comments are stripped first, so a sentence explaining why a construct is
/// absent does not trip the gate that checks it is absent. Six policy tests had
/// written this loop out.
List<String> bannedTokenHits(Iterable<File> files, List<String> tokens) {
  final hits = <String>[];

  for (final file in files) {
    final code = withoutDartComments(file.readAsStringSync());

    for (final token in tokens) {
      if (code.contains(token)) hits.add('${file.path}: $token');
    }
  }

  return hits;
}

bool _isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.drift.dart') ||
    path.contains('app_localizations');
