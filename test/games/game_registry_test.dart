import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/game_registry.dart';

import '../policy/support/source_text.dart';
import '../support/fixture_game.dart';

void main() {
  ProviderContainer containerWith(List<GameDefinition> games) {
    final container = ProviderContainer(
      overrides: [gameRegistryProvider.overrideWithValue(games)],
    );
    addTearDown(container.dispose);

    return container;
  }

  group('the registry today', () {
    test('holds E08 three placeholders, in declaration order', () {
      // Asserted HERE, against the real provider, rather than inside a test
      // whose name is about something else. E07 asserted `isEmpty`; E09
      // replaces these ids with stroop_rush and nothing else in the file
      // changes.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(gameRegistryProvider).map((game) => game.id.value),
        <String>[
          'placeholder_coral',
          'placeholder_turquoise',
          'placeholder_locked',
        ],
      );
    });

    test('and exactly one of them is locked', () {
      // The home hub draws a locked game as a "coming soon" card rather than
      // hiding it, so the registry returning it unfiltered is the behaviour
      // E08 T08.5 renders against.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container
            .read(gameRegistryProvider)
            .where((game) => game.isLocked)
            .map((game) => game.id.value),
        <String>['placeholder_locked'],
      );
    });

    test('and they cover both score sources', () {
      // The turquoise one takes the pairing Schulte Grid will — untimed,
      // duration-scored, clocked by the shell — so the screens are exercised
      // against both sources before a real game uses either.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(gameRegistryProvider).map((game) => game.scoreSource),
        containsAll(<ScoreSource>[
          ScoreSource.board,
          ScoreSource.runClock,
        ]),
      );
    });
  });

  group('gameDefinitionProvider', () {
    test('resolves a registered id', () {
      final game = fixtureGame();
      final container = containerWith(<GameDefinition>[game]);

      expect(
        container.read(gameDefinitionProvider(GameId('fixture_game'))),
        game,
      );
    });

    test('throws a StateError for an unknown id, because that is a bug', () {
      // Not a Result: an unregistered id reaching this provider means the
      // CALLER built one out of nothing. The recoverable version — a saved row
      // or a deep link naming a game that no longer ships — is UnknownGame,
      // returned by the run notifier.
      final container = containerWith(<GameDefinition>[fixtureGame()]);

      expect(
        () => container.read(gameDefinitionProvider(GameId('nback'))),
        throwsA(
          isA<Object>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('nback'), contains('fixture_game')),
          ),
        ),
      );
    });
  });

  group('registry invariants', () {
    test('game ids are unique', () {
      final games = <GameDefinition>[
        fixtureGame(),
        fixtureGame(id: 'second_game'),
      ];

      expect(
        games.map((game) => game.id).toSet(),
        hasLength(games.length),
      );
    });

    test('and order is display order, unsorted and unfiltered', () {
      // A locked game still appears: the home hub renders it as a "coming
      // soon" card rather than hiding it, so filtering here would remove the
      // very thing E08 has to draw.
      final games = <GameDefinition>[
        fixtureGame(id: 'second_game', isLocked: true),
        fixtureGame(),
      ];

      expect(
        containerWith(games).read(gameRegistryProvider).map((g) => g.id.value),
        <String>['second_game', 'fixture_game'],
      );
    });
  });

  group('the repository accepts what the registry ships', () {
    test('bootstrap fills registeredGameIdsProvider from the registry', () {
      // RunRepository.saveRun REFUSES any id outside that set. While nothing
      // filled it, every finished run of every real game would have failed to
      // save the moment one was registered — and silently, because every
      // engine test overrides the write path with a fake. E02's doc said the
      // registry would fill it and nothing did until a review asked.
      //
      // Asserted by reading bootstrap, because the wiring IS the fix: the
      // provider's own default is deliberately still an empty set.
      final code = withoutDartComments(
        File('lib/bootstrap.dart').readAsStringSync(),
      );

      expect(code, contains('registeredGameIdsProvider.overrideWith'));
      expect(code, contains('gameRegistryProvider'));
    });

    test('and its default still refuses, which is the right polarity', () {
      // A run written against an unregistered game should fail loudly rather
      // than land in a player's history under an id nothing can render. The
      // DEFAULT is still empty even though the registry is not: bootstrap is
      // what connects them.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(registeredGameIdsProvider), isEmpty);
    });
  });

  group('nothing switches on a game id', () {
    test('the shell reads the registry instead', () {
      // The product's central claim: Schulte Grid ships without editing
      // lib/features. A switch on the id in a shell file is exactly how that
      // claim dies, so it is a test rather than a review note.
      expect(
        _sourceHits(<String>['switch (gameId)', 'switch (config.gameId)']),
        isEmpty,
      );
    });
  });
}

List<String> _sourceHits(List<String> needles) {
  final offenders = <String>[];

  for (final file in dartFilesUnderLib()) {
    final code = withoutDartComments(file.readAsStringSync());

    for (final needle in needles) {
      if (code.contains(needle)) offenders.add('${file.path}: $needle');
    }
  }

  return offenders;
}
