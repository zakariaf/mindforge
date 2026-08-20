import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/core/run_outcome.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/features/play/application/run_notifier.dart';

import 'package:mindforge/features/play/domain/run_phase.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/game_registry.dart';

import '../policy/support/source_text.dart';
import '../support/fake_save_run.dart';
import '../support/fixture_game.dart';

/// The epic's whole claim, in one file.
///
/// A game the engine has never heard of plays a complete run, and it adds zero
/// lines to `lib/features/**`. If this file needs a shell change to pass,
/// Schulte Grid will need one too — and the engine is gone.
void main() {
  final config = RunConfig(
    gameId: GameId('fixture_game'),
    difficulty: Difficulty.classic,
    seed: 7,
  );

  HudSlot slotOf(String key, int value, StatFormat format) =>
      HudSlot(labelKey: key, canonicalValue: value, format: format);

  BoardSnapshot snapshotAt(
    int score, {
    double? progress,
    RunOutcome? outcome,
  }) => BoardSnapshot(
    hud: GameHud(
      leading: slotOf('hudScore', score, StatFormat.points),
      middle: slotOf('hudTime', 12300, StatFormat.duration),
      trailing: slotOf('hudStreak', 4, StatFormat.count),
    ),
    progress: progress,
    outcome: outcome,
    // The snapshot carries the run's numbers on every frame, which is what
    // lets a timed run that expires still write a real row.
    score: score,
    correctCount: 23,
    wrongCount: 2,
    longestCombo: 4,
    totalReactionMs: 14720,
  );

  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  group('a game the engine has never seen', () {
    test('plays a full run and its values come back unmodified', () async {
      final save = FakeSaveRun(isPersonalBest: true);
      final container = ProviderContainer(
        overrides: [
          // The ONE line a new game adds. Nothing else in this test knows
          // which game is running.
          gameRegistryProvider.overrideWithValue(<GameDefinition>[
            fixtureGame(),
          ]),
          saveRunProvider.overrideWithValue(save.call),
          clockProvider.overrideWithValue(Clock.fixed(DateTime.utc(2026))),
        ],
      );
      addTearDown(container.dispose);

      container.read(runNotifierProvider(config).notifier)
        ..start()
        ..beginPlaying();

      // PUBLISHED THROUGH THE BOARD'S OWN PROVIDER, not by calling the
      // notifier. That is how a real game reports a move, and it is the path
      // the first version of this test skipped: it called onSnapshot directly
      // against a fixture that returned a CONSTANT, so it never exercised what
      // a board update does to the run.
      final board = container.read(fixtureBoardProvider.notifier)
        ..publish(snapshotAt(100, progress: 0.25))
        ..publish(snapshotAt(700, progress: 0.5))
        ..publish(snapshotAt(1480, progress: 0.75));

      final mid = container.read(runNotifierProvider(config));

      expect(mid.phase, RunPhase.playing);
      expect(mid.progress, 0.75);
      expect(mid.hud.leading.canonicalValue, 1480);
      expect(mid.hud.trailing?.canonicalValue, 4);

      board.publish(
        snapshotAt(
          1480,
          progress: 1,
          outcome: const RunOutcome.completed(
            first: ResultStat(
              labelKey: 'statAccuracy',
              canonicalValue: 923,
              format: StatFormat.percent,
            ),
            second: ResultStat(
              labelKey: 'statBestCombo',
              canonicalValue: 7,
              format: StatFormat.count,
            ),
            third: ResultStat(
              labelKey: 'statAverageReaction',
              canonicalValue: 640,
              format: StatFormat.duration,
            ),
          ),
        ),
      );

      await pumpEventQueue();

      final end = container.read(runNotifierProvider(config));

      expect(end.phase, RunPhase.over);
      expect(end.isPersonalBest, isTrue);
      expect(end.progress, 1);
      expect(save.saved.single.metricValue, 1480);
      expect((end.outcome! as RunCompleted).stats, hasLength(3));
      expect(save.saved.single.longestCombo, 4);
    });

    test('and a board update does not end the run', () {
      // THE DEFECT THIS EXISTS FOR. bindBoard used to be a read, and a game
      // implements a read with ref.watch — the natural spelling — which made
      // every board update re-run the notifier's build and hand back a fresh
      // RunState.idle. Measured before the fix: the score updated to 99 and the
      // phase went from playing back to idle on the first tap.
      final container = ProviderContainer(
        overrides: [
          gameRegistryProvider.overrideWithValue(<GameDefinition>[
            fixtureGame(),
          ]),
          saveRunProvider.overrideWithValue(FakeSaveRun().call),
          clockProvider.overrideWithValue(Clock.fixed(DateTime.utc(2026))),
        ],
      );
      addTearDown(container.dispose);

      container.read(runNotifierProvider(config).notifier)
        ..start()
        ..beginPlaying();

      container.read(fixtureBoardProvider.notifier).publish(snapshotAt(99));

      final state = container.read(runNotifierProvider(config));

      expect(state.phase, RunPhase.playing, reason: 'the run survived');
      expect(state.hud.leading.canonicalValue, 99, reason: 'and it updated');
    });

    test('and its HUD carries keys and integers, never words', () {
      // The shell resolves the key at render. A slot holding a rendered value
      // would go stale the moment the player changed language.
      final container = ProviderContainer(
        overrides: [
          gameRegistryProvider.overrideWithValue(<GameDefinition>[
            fixtureGame(),
          ]),
          saveRunProvider.overrideWithValue(FakeSaveRun().call),
          clockProvider.overrideWithValue(Clock.fixed(DateTime.utc(2026))),
        ],
      );
      addTearDown(container.dispose);

      for (final slot
          in container.read(runNotifierProvider(config)).hud.slots) {
        expect(
          RegExp(r'^[a-z][a-zA-Z0-9]*$').hasMatch(slot.labelKey),
          isTrue,
          reason: slot.labelKey,
        );
        expect(slot.canonicalValue, isA<int>());
      }
    });
  });

  group('the fixture is invisible to the app', () {
    test('nothing under lib names it', () {
      // If it were reachable from lib/, this file would be testing a game the
      // engine ships rather than one it has never seen.
      final offenders = dartFilesUnderLib()
          .where((file) => file.readAsStringSync().contains('fixtureGame'))
          .map((file) => file.path)
          .toList();

      expect(offenders, isEmpty);
    });

    test('and it speaks only the contract, never the shell', () {
      // It DOES import lib/features/play/domain — BoardSnapshot, HudSlot and
      // ResultStat are the contract a game exists to speak, so importing them
      // is using the seam rather than crossing it. What it must not touch is
      // the shell's machinery: the notifier, the ticker, navigation, chrome.
      final code = withoutDartComments(
        File('test/support/fixture_game.dart').readAsStringSync(),
      );

      for (final banned in <String>[
        'features/play/application',
        'runNotifierProvider',
        'RunTicker',
        'go_router',
        'Navigator',
        'Scaffold(',
        'HudPill',
        'Stopwatch(',
        'Timer.periodic(',
      ]) {
        expect(code, isNot(contains(banned)), reason: banned);
      }
    });
  });
}
