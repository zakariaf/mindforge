/// Helpers shared by the policy tests, which all assert over source text.
///
/// These live here rather than being copied into each test because the same
/// three-line idiom had drifted into three slightly different regexes across
/// four files — which is how one of them ends up not stripping what it thinks
/// it strips.
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

String _strip(String source, String marker) => source
    .split('\n')
    .map(
      (line) => line.replaceFirst(RegExp('\\s*${RegExp.escape(marker)}.*'), ''),
    )
    .join('\n');
