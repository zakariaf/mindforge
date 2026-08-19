/// Helpers shared by the policy tests, which all assert over source text.
///
/// These live here rather than being copied into each test because the same
/// idiom had drifted into three slightly different regexes across four files —
/// which is how one of them ends up not stripping what it thinks it strips.
library;

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
