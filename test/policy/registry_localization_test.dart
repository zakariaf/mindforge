import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';

import '../support/fixture_game.dart';
import 'support/source_text.dart';

/// [code] with every `assert(...)` removed, parentheses matched.
///
/// An assert message is a developer string that is stripped in release and can
/// never reach a screen — and the messages in `game_definition.dart` are long,
/// deliberately, because they are what a contributor reads when they pair a
/// mechanic board with an accent background. Scanning them as though they were
/// labels would force those explanations to be deleted to satisfy a gate about
/// something else.
String _withoutAsserts(String code) => _withoutCallsTo(
  _withoutCallsTo(code, 'assert('),
  'StateError(',
);

/// [code] with every `name(...)` call and its arguments removed.
///
/// Used for `assert(` and `StateError(`, both of which carry DEVELOPER-facing
/// messages: an assert explains an invariant to whoever broke it, and a
/// StateError thrown by a registry switch explains which file to extend. The
/// rule this scan enforces is about strings a PLAYER can read, and neither of
/// those ever reaches one — a StateError here means the app is already
/// crashing.
///
/// Both are stripped by the same walker rather than by a regex, because the
/// message spans lines and a line-based skip would drop only the first of them.
String _withoutCallsTo(String code, String opening) {
  final buffer = StringBuffer();
  var index = 0;

  while (index < code.length) {
    final start = code.indexOf(opening, index);
    if (start < 0) {
      buffer.write(code.substring(index));
      break;
    }

    buffer.write(code.substring(index, start));

    var depth = 0;
    var cursor = start + opening.length - 1;

    for (; cursor < code.length; cursor++) {
      if (code[cursor] == '(') depth++;
      if (code[cursor] == ')') {
        depth--;
        if (depth == 0) break;
      }
    }

    index = cursor + 1;
  }

  return buffer.toString();
}

/// The registry declares ARB keys; this is what makes them earn their place.
///
/// A key held as a string and a getter called by E08 can drift apart silently:
/// nothing compiles against a key. These three assertions are the bridge.
void main() {
  /// Every hand-written `.dart` under `lib/games/`.
  Iterable<File> registryFiles() => dartFilesUnder('lib/games');

  group('no user-facing literal lives in the registry', () {
    test('every string literal is an id or an ARB key', () {
      // Snake-case ids and lowerCamelCase keys pass. Anything with a space, a
      // capital first letter, punctuation or a non-ASCII rune is a display
      // string, and a display string here is a string four locales cannot
      // change.
      //
      // Passes over the definition and registry files themselves; it is the
      // tripwire for E08, E09 and E10, which is why it exists before they do.
      final offenders = <String>[];
      final identifier = RegExp(r'^[a-z][a-zA-Z0-9_]*$');
      // A PURE SEPARATOR is not a display string. A canonical serializer joins
      // fields with `:` and `,` — E09's `StroopRound.canonical()` is the first
      // — and those are machine-readable punctuation, not words.
      //
      // Deliberately these five characters and no more: a string a player can
      // read always contains a letter or a space, and both are still refused.
      // "Anything short" or "anything without a capital" would have let `", "`
      // and `"— "` through, which are display strings.
      final separator = RegExp(r'^[:,;|/]+$');

      for (final file in registryFiles()) {
        final code = _withoutAsserts(
          withoutDartComments(file.readAsStringSync()),
        );

        for (final line in code.split('\n')) {
          // An import URI is a path, not a display string.
          if (line.trimLeft().startsWith('import ')) continue;

          for (final match in RegExp(r"'([^'$]*)'").allMatches(line)) {
            final value = match.group(1)!;
            if (value.isEmpty) continue;
            if (identifier.hasMatch(value)) continue;
            if (separator.hasMatch(value)) continue;

            offenders.add('${file.path}: "$value"');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'these read as display strings rather than keys',
      );
    });
  });

  group('the separator exemption is narrow', () {
    test('a display string is still refused, however short', () {
      // The exemption above is the kind that rots into "anything short". These
      // are the strings it must keep out — each one a thing a player could
      // read — asserted against the same pattern the scan uses.
      final separator = RegExp(r'^[:,;|/]+$');

      for (final display in <String>[', ', '— ', 'Red', 'x', '0:23', '·']) {
        expect(
          separator.hasMatch(display),
          isFalse,
          reason: '"$display" would have been exempted',
        );
      }
    });

    test('and a real separator is accepted', () {
      final separator = RegExp(r'^[:,;|/]+$');

      for (final punctuation in <String>[':', ',', '|', ';', '/']) {
        expect(separator.hasMatch(punctuation), isTrue);
      }
    });
  });

  group('every declared key is real', () {
    /// The keys a definition and the difficulties promise.
    List<String> declaredKeys() => <String>[
      ...fixtureGame().strings.keys,
      ...Difficulty.values.map((difficulty) => difficulty.labelKey),
    ];

    test('and exists in all four locales', () {
      // check_arb_parity.sh proves the four ARBs agree with each other. This is
      // the narrower claim: the keys the ENGINE names are among them.
      for (final tag in <String>['en', 'de', 'fa', 'ckb']) {
        final arb =
            jsonDecode(File('lib/l10n/app_$tag.arb').readAsStringSync())
                as Map<String, dynamic>;

        for (final key in declaredKeys()) {
          expect(
            arb.containsKey(key),
            isTrue,
            reason: '$key is missing from app_$tag.arb',
          );
        }
      }
    });

    test('and has a generated getter of exactly that name', () {
      // This is what closes the drift between a key held as a string and a
      // getter called by E08. It works only because E04's keys are
      // lowerCamelCase — the same spelling a Dart getter takes.
      final generated = File(
        'lib/l10n/app_localizations.dart',
      ).readAsStringSync();

      for (final key in declaredKeys()) {
        expect(
          generated,
          contains('get $key'),
          reason: '$key has no generated getter',
        );
      }
    });
  });
}
