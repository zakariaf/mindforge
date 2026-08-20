import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/id_generator.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/game_registry.dart';

import 'fake_id_generator.dart';
import 'fake_save_run.dart';
import 'fixture_game.dart';

/// A container wired the way a run needs one.
///
/// The registry / save / clock override triple was written out eight times
/// across three files. Adding one required engine provider — E08 will — meant
/// editing eight places, and a miss surfaces as a Riverpod throw in whichever
/// unrelated test happens to run next.
///
/// [clock] takes a `Clock` rather than an instant so the three `fakeAsync`
/// tests can pass `async.getClock(...)`; those three hand-rolled their own
/// fifteen-line container precisely because the file-local helper could not.
///
/// The extras are named parameters rather than a list of overrides because
/// `flutter_riverpod` does not export `Override`, so such a list cannot be
/// given a type.
ProviderContainer engineContainer({
  GameDefinition? game,
  FakeSaveRun? save,
  Clock? clock,
  IdGenerator? idGenerator,
  AppSettings? settings,
}) {
  final resolved = settings ?? const AppSettings.defaults();

  final container = ProviderContainer(
    overrides: [
      gameRegistryProvider.overrideWithValue(<GameDefinition>[
        game ?? fixtureGame(),
      ]),
      saveRunProvider.overrideWithValue((save ?? FakeSaveRun()).call),
      clockProvider.overrideWithValue(clock ?? Clock.fixed(DateTime.utc(2026))),
      idGeneratorProvider.overrideWithValue(idGenerator ?? FakeIdGenerator()),
      initialAppSettingsProvider.overrideWithValue(resolved),
      settingsProvider.overrideWith(
        (ref) => Stream<AppSettings>.value(resolved),
      ),
    ],
  );
  addTearDown(container.dispose);

  return container;
}

/// The run every engine test drives, matching [fixtureGame]'s default id.
///
/// Retyped in four files, three of which also retyped the `'fixture_game'`
/// string — which has to agree with the fixture or the registry lookup throws.
RunConfig fixtureConfig({int seed = 7, Difficulty? difficulty}) => RunConfig(
  gameId: GameId('fixture_game'),
  difficulty: difficulty ?? Difficulty.classic,
  seed: seed,
);
