import 'dart:io';
import 'dart:typed_data';

/// Reads the design authority and the theme source as **text**, so a test can
/// compare what Dart says against what `system.html` says.
///
/// It parses the same shapes `check_palette_contrast.sh` parses, on purpose: if
/// this parser and that gate ever disagree about what a slot binds to, the gate
/// is silently passing.
abstract final class DesignSource {
  /// The path of [relative] from the package root.
  ///
  /// A helper so no test hardcodes a `../` and then breaks when it moves.
  static String pathToRepoFile(String relative) => relative;

  static final File _systemHtml = File(
    pathToRepoFile('design/sunburst-pop/system.html'),
  );

  static String get _rootBlock {
    final source = _systemHtml.readAsStringSync();
    final start = source.indexOf(':root{');
    // Checked BEFORE the second indexOf: passing -1 as its start throws a
    // RangeError, so the guard below would never run and a reformatted
    // system.html would fail every theme test with an opaque range message
    // instead of this one.
    if (start == -1) {
      throw StateError('system.html has no :root{ block to parse');
    }
    final end = source.indexOf('}', start);
    if (end == -1) {
      throw StateError('system.html :root{ block is not closed');
    }
    return source.substring(start, end);
  }

  /// Every hex-valued custom property in `system.html`'s `:root` block, keyed by
  /// its CSS name including the leading `--`, with the value uppercased and
  /// without the `#`.
  ///
  /// e.g. `{'--cream': 'FFF8EC', '--play-red': 'D81E2C', ...}`.
  static Map<String, String> cssRootHexes() {
    final hexes = <String, String>{};
    for (final match in RegExp(
      r'(--[a-z0-9-]+)\s*:\s*#([0-9A-Fa-f]{6})',
    ).allMatches(_rootBlock)) {
      hexes[match.group(1)!] = match.group(2)!.toUpperCase();
    }
    return hexes;
  }

  /// Every custom property in `:root` that aliases another one through
  /// `var(--other)`, keyed by name.
  ///
  /// e.g. `{'--surface': '--cream', '--danger': '--play-red', ...}`.
  static Map<String, String> cssRootAliases() {
    final aliases = <String, String>{};
    for (final match in RegExp(
      r'(--[a-z0-9-]+)\s*:\s*var\((--[a-z0-9-]+)\)',
    ).allMatches(_rootBlock)) {
      aliases[match.group(1)!] = match.group(2)!;
    }
    return aliases;
  }

  /// The raw value of one non-hex `:root` scalar, such as `--bw` or `--dur-tap`.
  static String? cssScalar(String name) => RegExp(
    '$name\\s*:\\s*([^;]+);',
  ).firstMatch(_rootBlock)?.group(1)?.trim();

  /// Every `static const <name> = Color(0xFF<HEX>);` in the primitives file,
  /// keyed by Dart name with the hex uppercased.
  static Map<String, String> dartPrimitiveHexes({
    String path = 'lib/theme/sunburst_primitives.dart',
  }) {
    final hexes = <String, String>{};
    for (final match in RegExp(
      // The full eight digits, not `0xFF` plus six: a composited primitive
      // like the header's ray sweep carries an alpha, and a parser that only
      // saw opaque colours reported it as "does not exist" — which reads as a
      // typo rather than as the parser's own blind spot.
      r'static const (\w+) = Color\(0x([0-9A-Fa-f]{8})\);',
    ).allMatches(File(pathToRepoFile(path)).readAsStringSync())) {
      hexes[match.group(1)!] = match.group(2)!.toUpperCase();
    }
    return hexes;
  }

  /// Every `<slot>: _P.<primitive>,` binding in the const palette instance,
  /// keyed by slot name.
  ///
  /// This is exactly what `check_palette_contrast.sh` reads, which is why it
  /// matches **line by line**: two slots on one line makes the second invisible
  /// to both the gate and this parser.
  static Map<String, String> dartSlotBindings({
    String path = 'lib/theme/sunburst_colors.dart',
  }) {
    final bindings = <String, String>{};
    for (final line in File(pathToRepoFile(path)).readAsLinesSync()) {
      final match = RegExp(r'^\s*(\w+):\s*_P\.(\w+),\s*$').firstMatch(line);
      if (match != null) bindings[match.group(1)!] = match.group(2)!;
    }
    return bindings;
  }

  /// The names declared as `final <Type> a, b, c;` inside [className], which
  /// may be a class or an enum.
  ///
  /// Used by the coverage tests so a field count is derived from the source
  /// rather than hardcoded — a hardcoded count is how a new slot gets forgotten
  /// in `copyWith` while the test still passes.
  static List<String> dartFieldNames(String path, String className) {
    final source = File(pathToRepoFile(path)).readAsStringSync();
    // A class or an enum: PlayAnswer is an enum and its field list is exactly
    // what one of the tests asserts on.
    final start = RegExp(
      '(class|enum) ${RegExp.escape(className)}\\b',
    ).firstMatch(source)?.start;
    if (start == null) throw StateError('$className not found in $path');

    // Bounded to this declaration's own braces. Scanning to end-of-file makes
    // an enum declared above a class inherit every one of that class's fields,
    // which is a test that passes for the wrong reason.
    final body = _bracedBody(source, start);

    final names = <String>[];
    for (final match in RegExp(
      r'^\s*final [\w<>?, ]+? ([\w, ]+);',
      multiLine: true,
    ).allMatches(body)) {
      names.addAll(match.group(1)!.split(',').map((n) => n.trim()));
    }
    return names;
  }

  /// The `{ ... }` body of the declaration starting at [start].
  static String _bracedBody(String source, int start) {
    final open = source.indexOf('{', start);
    if (open == -1) throw StateError('no body found');

    var depth = 0;
    for (var i = open; i < source.length; i++) {
      if (source[i] == '{') depth++;
      if (source[i] == '}') {
        depth--;
        if (depth == 0) return source.substring(open, i);
      }
    }
    throw StateError('unbalanced braces from offset $start');
  }

  /// The `flutter: fonts:` block of `pubspec.yaml`, as family name to the list
  /// of asset paths declared under it.
  static Map<String, List<String>> pubspecFontFamilies() {
    final families = <String, List<String>>{};
    String? current;

    for (final line in File(pathToRepoFile('pubspec.yaml')).readAsLinesSync()) {
      final family = RegExp(r'^\s*- family:\s*(\S+)').firstMatch(line);
      if (family != null) {
        current = family.group(1);
        families[current!] = <String>[];
        continue;
      }
      final asset = RegExp(r'^\s*- asset:\s*(\S+)').firstMatch(line);
      if (asset != null && current != null) {
        families[current]!.add(asset.group(1)!);
      }
    }
    return families;
  }
}

/// The eight reference screens, in the order they are numbered.
///
/// **One list.** It was written out in `reference_pixel_test.dart`,
/// `rtl_screens_test.dart` and `capture-screens.sh`; a ninth screen had to be
/// added in three places, and the two that were forgotten would still pass.
const kScreenBasenames = <String>[
  '01-home',
  '02-game-detail',
  '03-countdown',
  '04-stroop-rush',
  '05-schulte-grid',
  '06-results',
  '07-stats',
  '08-settings',
];

/// The pixel geometry every reference PNG is captured at: 390x844 at 2x, which
/// is exactly the canonical simulator.
const ({int width, int height}) kReferencePixelSize = (
  width: 780,
  height: 1688,
);

/// Reads a PNG's dimensions from its IHDR, without decoding the image.
///
/// Cheap enough to run over sixteen files in a synchronous test, and it needs
/// no Flutter binding — `ui.instantiateImageCodec` needs both.
({int width, int height}) pngSize(File file) {
  // 8-byte signature, then the IHDR chunk: 4 length, 4 type, then w/h.
  final header = ByteData.sublistView(file.readAsBytesSync());

  return (width: header.getUint32(16), height: header.getUint32(20));
}
