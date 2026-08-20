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
String _withoutAsserts(String code) {
  final buffer = StringBuffer();
  var index = 0;

  while (index < code.length) {
    final start = code.indexOf('assert(', index);
    if (start < 0) {
      buffer.write(code.substring(index));
      break;
    }

    buffer.write(code.substring(index, start));

    var depth = 0;
    var cursor = start + 'assert'.length;

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
