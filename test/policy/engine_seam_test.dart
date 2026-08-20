import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/games/game_registry.dart';

import 'support/source_text.dart';

/// The engine claim, as tests that fail loudly.
///
/// **A second game is what makes this provable.** Stroop Rush was built against
/// a shell designed alongside it, so nothing in E09 could disprove the seam —
/// the first game always fits. Schulte Grid is the opposite game on every axis
/// the seam touches, and these are the assertions that stop the claim from
/// being marketing.
void main() {
  /// Every Dart file under [directory].
  List<File> filesUnder(String directory) => Directory(directory)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  /// The names a shell file may not execute on.
  const gameNames = <String>['schulte', 'stroop', 'nback', 'n_back'];

  group('the shell knows no game by name', () {
    test('no file under lib/features NAMES one, outside a comment', () {
      // Comments are exempt on purpose: the shell may EXPLAIN itself with an
      // example — "Stroop Rush scores points, Schulte Grid a duration" is the
      // clearest way to say what a ScoreFormat is for. What it may not do is
      // branch on one.
      final offenders = <String>[];

      for (final file in filesUnder('lib/features')) {
        final code = withoutDartComments(file.readAsStringSync());

        for (final name in gameNames) {
          // WORD-BOUNDED. A bare substring match calls `onBackground` an
          // N-Back reference, which is the kind of false positive that gets a
          // policy test deleted rather than fixed.
          if (RegExp(
            '(?<![a-z])$name(?![a-z])',
            caseSensitive: false,
          ).hasMatch(code)) {
            offenders.add('${file.path}: $name');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'a shell screen that knows a game is not a shell screen',
      );
    });

    test('and no file under lib/features IMPORTS one', () {
      // The registry is the one legal way in, and it is not under features.
      final offenders = <String>[];

      for (final file in filesUnder('lib/features')) {
        for (final line in file.readAsLinesSync()) {
          if (!line.startsWith('import ') && !line.startsWith('export ')) {
            continue;
          }
          if (RegExp('games/(?!game_)[a-z_]+/').hasMatch(line)) {
            offenders.add('${file.path}: ${line.trim()}');
          }
        }
      }

      expect(offenders, isEmpty);
    });
  });

  group('the registry is the one place two games meet', () {
    test('and it is the only file naming more than one', () {
      final plural = <String>[];

      for (final file in filesUnder('lib')) {
        final imports = RegExp('games/([a-z_]+)/')
            .allMatches(file.readAsStringSync())
            .map((match) => match.group(1))
            .whereType<String>()
            .where((id) => !id.startsWith('game_'))
            .toSet();

        if (imports.length >= 2) plural.add(file.path);
      }

      expect(plural, <String>['lib/games/game_registry.dart']);
    });
  });

  group('every registered game', () {
    test('ships the same four artefacts', () {
      // A future game that fits the seam passes this for free; one that does
      // not has to explain itself here rather than in a shell screen.
      final container = ProviderContainer();

      addTearDown(container.dispose);

      for (final game in container.read(gameRegistryProvider)) {
        final root = 'lib/games/${game.id.value}';

        expect(
          File('$root/${game.id.value}_definition.dart').existsSync(),
          isTrue,
          reason: '$root has no definition file',
        );

        for (final layer in <String>['application', 'domain', 'ui']) {
          expect(
            Directory('$root/$layer').existsSync(),
            isTrue,
            reason: '$root/$layer is missing',
          );
        }
      }
    });
  });

  group('the ARB', () {
    test('names a game only under that game own key prefix', () {
      // The fifth place a shell could learn a game's name: a message written
      // for one board and reached from a shared screen.
      final source = File('lib/l10n/app_en.arb').readAsStringSync();
      final offenders = <String>[];

      for (final match in RegExp(r'"([A-Za-z]+)"\s*:').allMatches(source)) {
        final key = match.group(1)!;

        if (key.startsWith('@')) continue;

        for (final name in gameNames) {
          if (!key.toLowerCase().contains(name)) continue;
          // `game<Name>*` is the sanctioned prefix a definition declares, and
          // `schulteMissesLabel` / `schulteTilesLabel` are that game's own
          // results rows, reached only through the key it publishes.
          if (key.startsWith('game') || key.startsWith(name)) continue;

          offenders.add(key);
        }
      }

      expect(offenders, isEmpty);
    });
  });
}
