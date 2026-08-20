import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/core/run_outcome.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/features/play/application/run_notifier.dart';
import 'package:mindforge/features/play/domain/run_phase.dart';

import '../../../policy/support/source_text.dart';
import '../../../support/engine_harness.dart';
import '../../../support/fake_save_run.dart';
import '../../../support/fixture_game.dart';
import '../../../support/locale_matrix.dart';

/// The run lifecycle, headless.
///
/// No widget is pumped anywhere in this file. The engine is the thing under
/// test and it renders nothing — that absence is part of the assertion.
void main() {
  const slot = HudSlot(
    labelKey: 'hudScore',
    canonicalValue: 0,
    format: StatFormat.points,
  );
  const finishedSnapshot = BoardSnapshot(
    hud: GameHud(leading: slot, middle: slot),
    // The SNAPSHOT carries the run's numbers, on every frame — not only at the
    // end. That is what lets a timed run that expires still write a real row.
    score: 1480,
    correctCount: 23,
    wrongCount: 2,
    longestCombo: 7,
    totalReactionMs: 14720,
    outcome: RunOutcome.completed(
      first: ResultStat(
        labelKey: 'accuracyLabel',
        canonicalValue: 923,
        format: StatFormat.percent,
      ),
      second: ResultStat(
        labelKey: 'longestStreakLabel',
        canonicalValue: 7,
        format: StatFormat.count,
      ),
      third: ResultStat(
        labelKey: 'avgReactionLabel',
        canonicalValue: 640,
        format: StatFormat.duration,
      ),
    ),
  );

  final config = fixtureConfig();

  ({ProviderContainer container, FakeSaveRun save}) harness({
    int? runLimitMs,
    bool isPersonalBest = false,
    DataFailure? failure,
    Clock? clock,
    AppSettings? settings,
  }) {
    final save = FakeSaveRun(isPersonalBest: isPersonalBest, failure: failure);

    final container = engineContainer(
      game: fixtureGame(
        isTimed: runLimitMs != null,
        runLimitFor: runLimitMs == null ? null : (_) => runLimitMs,
      ),
      save: save,
      clock: clock,
      settings: settings,
    );

    save.observePhase = () => container.read(runNotifierProvider(config)).phase;

    return (container: container, save: save);
  }

  RunNotifier notifierIn(ProviderContainer container) =>
      container.read(runNotifierProvider(config).notifier);

  RunPhase phaseIn(ProviderContainer container) =>
      container.read(runNotifierProvider(config)).phase;

  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  group('starting', () {
    test('start moves idle to countdown', () {
      final h = harness();

      expect(phaseIn(h.container), RunPhase.idle);
      notifierIn(h.container).start();
      expect(phaseIn(h.container), RunPhase.countdown);
    });

    test('and the countdown ends into playing', () {
      final h = harness();

      notifierIn(h.container)
        ..start()
        ..beginPlaying();

      expect(phaseIn(h.container), RunPhase.playing);
    });

    test('abandoning the countdown returns to idle and writes nothing', () {
      // A run that never started is not a run: no row, no streak.
      final h = harness();

      notifierIn(h.container)
        ..start()
        ..abandon();

      expect(phaseIn(h.container), RunPhase.idle);
      expect(h.save.saved, isEmpty);
    });
  });

  group('pausing', () {
    test('pause moves playing to paused', () {
      final h = harness();

      notifierIn(h.container)
        ..start()
        ..beginPlaying()
        ..pause();

      expect(phaseIn(h.container), RunPhase.paused);
    });

    test('keepPlaying goes back through a countdown, not straight in', () {
      final h = harness();

      notifierIn(h.container)
        ..start()
        ..beginPlaying()
        ..pause()
        ..keepPlaying();

      expect(phaseIn(h.container), RunPhase.countdown);
    });

    test('and leaving a paused run writes nothing', () {
      final h = harness();

      notifierIn(h.container)
        ..start()
        ..beginPlaying()
        ..pause()
        ..leaveRun();

      expect(phaseIn(h.container), RunPhase.over);
      expect(h.save.saved, isEmpty);
    });
  });

  group('finishing', () {
    test('a board outcome moves playing to over', () async {
      final h = harness();

      notifierIn(h.container)
        ..start()
        ..beginPlaying()
        ..onSnapshot(finishedSnapshot);

      await pumpEventQueue();

      expect(phaseIn(h.container), RunPhase.over);
      expect(h.save.saved, hasLength(1));
    });

    test('THE RUN IS PERSISTED BEFORE THE PHASE BECOMES OVER', () async {
      // The single most important ordering in the engine. A phase change first
      // would let the results screen celebrate a personal best whose row never
      // landed, and the player would find it gone on the next launch.
      final h = harness(isPersonalBest: true);

      notifierIn(h.container)
        ..start()
        ..beginPlaying()
        ..onSnapshot(finishedSnapshot);

      await pumpEventQueue();

      expect(
        h.save.phaseAtSave,
        <RunPhase>[RunPhase.playing],
        reason: 'the phase at the moment saveRun was called',
      );
    });

    test('a successful save carries the COMMITTED personal-best flag', () async {
      // From the committed row: E02 computes it inside the same transaction as
      // the insert. A post-commit read of watchPersonalBest would race this
      // notifier's own write.
      final h = harness(isPersonalBest: true);

      notifierIn(h.container)
        ..start()
        ..beginPlaying()
        ..onSnapshot(finishedSnapshot);

      await pumpEventQueue();

      expect(
        h.container.read(runNotifierProvider(config)).isPersonalBest,
        isTrue,
      );
    });

    test('a failed save still reaches over, carrying the failure', () async {
      // The player finished the run. Hiding that because a row did not land is
      // worse than telling them it did not.
      final h = harness(failure: const StoreUnavailable());

      notifierIn(h.container)
        ..start()
        ..beginPlaying()
        ..onSnapshot(finishedSnapshot);

      await pumpEventQueue();

      final state = h.container.read(runNotifierProvider(config));

      expect(state.phase, RunPhase.over);
      expect(state.saveFailure, isNotNull);
      expect(state.isPersonalBest, isFalse);
    });
  });

  group('the persisted draft', () {
    test(
      'is canonical: ASCII ids, a Gregorian day, integer milliseconds',
      () async {
        final h = harness();

        notifierIn(h.container)
          ..start()
          ..beginPlaying()
          ..onSnapshot(finishedSnapshot);

        await pumpEventQueue();

        final draft = h.save.saved.single;

        expect(draft.gameId, 'fixture_game');
        expect(draft.difficultyId, 'classic');
        expect(draft.metricValue, 1480);

        for (final value in <String>[
          draft.gameId,
          draft.difficultyId,
          draft.clientRunKey,
        ]) {
          for (final rune in value.runes) {
            expect(rune, lessThan(0x80), reason: value);
          }
        }
      },
    );
  });

  group('a run is saved exactly once', () {
    test(
      'a second terminal snapshot mid-save does not write a second row',
      () async {
        // THE CRASH THIS PREVENTS. The phase deliberately does not leave
        // `playing` until AFTER the write returns, so the phase cannot be the
        // guard: any board emission carrying an outcome during the await ran
        // _finish again. Measured before the latch — two rows with different
        // clientRunKeys, both counting toward stats and both able to claim a
        // personal best, then `over -> over is not a legal run transition`.
        //
        // A board keeps its terminal snapshot in its own provider state, so a
        // late tap or an end-of-round animation frame re-fires it.
        // THE SAVE IS HELD OPEN. That is the whole window: the phase stays
        // `playing` until the write returns, so only an emission arriving
        // DURING the save gets through. Three earlier versions of this test
        // were green against the bug — publishing the same value twice
        // (Riverpod skips an equal state), publishing twice synchronously
        // (listeners arrive on a microtask, so the two collapse into one), and
        // letting the save complete between them (which the phase check then
        // correctly blocks).
        final gate = Completer<void>();
        final h = harness()..save.gate = gate;
        final board = h.container.read(fixtureBoardProvider.notifier);

        notifierIn(h.container)
          ..start()
          ..beginPlaying();

        board.publish(finishedSnapshot);
        await pumpEventQueue();

        board.publish(
          BoardSnapshot(
            hud: finishedSnapshot.hud,
            score: 1490,
            outcome: finishedSnapshot.outcome,
          ),
        );
        await pumpEventQueue();

        gate.complete();
        await pumpEventQueue();

        expect(h.save.saved, hasLength(1));
        expect(phaseIn(h.container), RunPhase.over);
      },
    );

    test('and a late snapshot does not rewrite the results', () async {
      // The figures on the results screen are the ones that were persisted.
      final h = harness();
      final board = h.container.read(fixtureBoardProvider.notifier);

      notifierIn(h.container)
        ..start()
        ..beginPlaying();

      board.publish(finishedSnapshot);
      await pumpEventQueue();

      board.publish(
        const BoardSnapshot(
          hud: GameHud(leading: slot, middle: slot),
          score: 99999,
        ),
      );

      expect(
        h.container.read(runNotifierProvider(config)).snapshot.score,
        1480,
      );
    });
  });

  group('abandoning resets the run', () {
    test('it does not merely relabel it', () async {
      // playing -> paused -> countdown -> idle is a legal path, so a run can
      // reach idle after thirty seconds of play. Relabelling left elapsed, the
      // alarm latch, the snapshot and the ticker's banked time intact — and
      // the next run started at 0:00:31 with 29 seconds left of sixty.
      final h = harness(runLimitMs: 60000);

      notifierIn(h.container)
        ..start()
        ..beginPlaying()
        ..pause()
        ..keepPlaying()
        ..abandon();

      final state = h.container.read(runNotifierProvider(config));

      expect(state.phase, RunPhase.idle);
      expect(state.elapsed, Duration.zero);
      expect(state.hasFiredTimerAlarm, isFalse);
      expect(state.remainingMs, 60000);
    });
  });

  group('over is terminal', () {
    test('every intent from over is a no-op', () async {
      final h = harness();

      notifierIn(h.container)
        ..start()
        ..beginPlaying()
        ..onSnapshot(finishedSnapshot);

      await pumpEventQueue();
      expect(phaseIn(h.container), RunPhase.over);

      notifierIn(h.container)
        ..start()
        ..pause()
        ..keepPlaying()
        ..leaveRun()
        ..abandon()
        ..beginPlaying();

      expect(phaseIn(h.container), RunPhase.over);
    });
  });

  group('the clock ends a timed run', () {
    test('when remaining hits zero', () {
      fakeAsync((async) {
        withClock(async.getClock(DateTime.utc(2026)), () {
          final container = harness(
            runLimitMs: 60000,
            clock: clock,
          ).container;

          container.read(runNotifierProvider(config).notifier)
            ..start()
            ..beginPlaying();

          async
            ..elapse(const Duration(seconds: 60))
            ..flushMicrotasks();

          expect(
            container.read(runNotifierProvider(config)).phase,
            RunPhase.over,
          );
        });
      });
    });

    test('and an untimed run never ends on the clock', () {
      // Schulte Grid ends when the last tile is found. Ten minutes in, it is
      // still going — which is exactly why the limit lives on the game.
      fakeAsync((async) {
        withClock(async.getClock(DateTime.utc(2026)), () {
          final container = harness(clock: clock).container;

          container.read(runNotifierProvider(config).notifier)
            ..start()
            ..beginPlaying();

          async
            ..elapse(const Duration(minutes: 10))
            ..flushMicrotasks();

          expect(
            container.read(runNotifierProvider(config)).phase,
            RunPhase.playing,
          );
        });
      });
    });

    test('and the alarm latch flips exactly once', () {
      // The boundary is true on every frame after it happens: the clock is
      // still under five seconds a second later. Firing at 10 Hz for the last
      // fifty ticks is a rattle rather than a signal.
      fakeAsync((async) {
        withClock(async.getClock(DateTime.utc(2026)), () {
          final container = harness(
            runLimitMs: 60000,
            clock: clock,
          ).container;

          var flips = 0;
          final subscription = container.listen(
            runNotifierProvider(config),
            (previous, next) {
              if (previous?.hasFiredTimerAlarm == false &&
                  next.hasFiredTimerAlarm) {
                flips++;
              }
            },
          );
          addTearDown(subscription.close);

          container.read(runNotifierProvider(config).notifier)
            ..start()
            ..beginPlaying();

          async.elapse(const Duration(seconds: 59));

          expect(flips, 1);
        });
      });
    });
  });

  group('the app leaving the foreground', () {
    for (final lifecycle in <AppLifecycleState>[
      AppLifecycleState.inactive,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
    ]) {
      test('${lifecycle.name} pauses a live run', () {
        final h = harness();

        notifierIn(h.container)
          ..start()
          ..beginPlaying();

        // Driven through RESUMED first. AppLifecycleListener fires on
        // TRANSITIONS and synthesizes the intermediate states, so a jump into
        // `hidden` from whatever a fresh binding happens to hold is not a
        // transition it recognises. The hand-rolled observer this replaced
        // accepted any state at any time, which made these tests pass against
        // sequences iOS never produces.
        WidgetsBinding.instance
          ..handleAppLifecycleStateChanged(AppLifecycleState.resumed)
          ..handleAppLifecycleStateChanged(lifecycle);

        expect(phaseIn(h.container), RunPhase.paused);
      });
    }

    test('and RESUMING NEVER UN-PAUSES', () {
      // Coming back to the app is not the same as choosing to keep playing.
      // Dropping a player straight into a live Blitz board is how a run is lost
      // to the OS rather than to the game.
      final h = harness();

      notifierIn(h.container)
        ..start()
        ..beginPlaying();

      WidgetsBinding.instance
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed)
        ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      expect(phaseIn(h.container), RunPhase.paused);
    });

    test('and detached writes nothing', () {
      final h = harness();

      notifierIn(h.container)
        ..start()
        ..beginPlaying();

      WidgetsBinding.instance
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed)
        ..handleAppLifecycleStateChanged(AppLifecycleState.detached);

      expect(h.save.saved, isEmpty);
    });
  });

  group('the locale cannot reach the run', () {
    test('the same run in every language is the same RunState', () {
      // The engine's central locale property. Two containers, four locales, one
      // fixed clock and one seed: the states must be EQUAL, not merely similar,
      // because only the rendered string differs between languages and nothing
      // rendered lives in the state.
      //
      // Comparing one container to itself would be a tautology, which is what
      // the first version of this test was.
      final states = <String, Object>{};

      for (final tag in localeMatrix) {
        final settings = const AppSettings.defaults().withLocaleOverride(
          SupportedLocale.values.firstWhere((l) => l.tag == tag),
        );

        final container = harness(settings: settings).container;

        container.read(runNotifierProvider(config).notifier)
          ..start()
          ..beginPlaying();

        states[tag] = container.read(runNotifierProvider(config));
      }

      for (final entry in states.entries) {
        expect(
          entry.value,
          states['en'],
          reason: '${entry.key} produced a different run',
        );
      }
    });
  });

  group('the notifier renders nothing', () {
    test('it reads no formatter and no localizations', () {
      // Formatting is E08's, at render. A formatted value here would go stale
      // the moment the player changed language mid-run.
      final code = withoutDartComments(
        File(
          'lib/features/play/application/run_notifier.dart',
        ).readAsStringSync(),
      );

      for (final banned in <String>[
        'scoreFormatterProvider',
        'NumberFormat',
        'AppLocalizations',
        'LocaleNumbers',
      ]) {
        expect(code, isNot(contains(banned)), reason: banned);
      }
    });
  });
}
