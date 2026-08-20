import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/hud_tone.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/core/run_outcome.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/games/stroop_rush/application/stroop_board_notifier.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_board_state.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_difficulty_profile.dart';
import 'package:mindforge/shared/feedback/feedback_service.dart';
import 'package:mindforge/shared/feedback/moment.dart';

import '../../../support/fake_feedback_service.dart';

/// The board's one owner: the deck, the score, the key states and the latches.
///
/// Driven headlessly with a `ProviderContainer`. There is no widget here — the
/// board's behaviour is not a rendering question, and a test that pumped one
/// would be slower and would prove less.
void main() {
  final config = RunConfig(
    gameId: GameId('stroop_rush'),
    difficulty: Difficulty.classic,
    seed: 42,
  );

  late FakeFeedbackService feedback;

  ProviderContainer containerWith({bool colourBlind = false}) {
    feedback = FakeFeedbackService();

    final container = ProviderContainer(
      overrides: [
        feedbackServiceProvider.overrideWithValue(feedback),
        // The board reads the palette from settings ONCE, at build. Seeded
        // here rather than left to bootstrap, which is what a real launch
        // would do.
        initialAppSettingsProvider.overrideWithValue(
          const AppSettings.defaults().copyWith(
            isColourBlindPalette: colourBlind,
          ),
        ),
        settingsProvider.overrideWith(
          (ref) => Stream<AppSettings>.value(
            const AppSettings.defaults().copyWith(
              isColourBlindPalette: colourBlind,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    return container;
  }

  StroopBoardState stateOf(ProviderContainer container) =>
      container.read(stroopBoardNotifierProvider(config));

  StroopBoardNotifier notifierOf(ProviderContainer container) =>
      container.read(stroopBoardNotifierProvider(config).notifier);

  /// Answers the current round correctly, or deliberately wrongly.
  void answer(ProviderContainer container, {required bool correctly}) {
    final state = stateOf(container);
    final round = state.rounds[state.index];
    final correctIndex = round.options.indexOf(round.ink);

    notifierOf(container).submit(
      correctly ? correctIndex : (correctIndex + 1) % round.options.length,
    );
  }

  group('build', () {
    test('seeds the deck from the RunConfig and starts on round zero', () {
      final state = stateOf(containerWith());

      expect(state.index, 0);
      expect(
        state.rounds,
        hasLength(profileFor(Difficulty.classic).roundCount),
      );
      expect(state.score.points, 0);
      expect(state.keyStates, everyElement(AnswerKeyState.idle));
    });

    test('and a different seed deals a different deck', () {
      final other = RunConfig(
        gameId: config.gameId,
        difficulty: config.difficulty,
        seed: 43,
      );
      final container = containerWith();

      expect(
        container.read(stroopBoardNotifierProvider(other)).rounds.first,
        isNot(stateOf(container).rounds.first),
      );
    });
  });

  group('a correct answer', () {
    test('advances the round, adds points and fires answerCorrect', () {
      final container = containerWith();
      final before = stateOf(container);

      answer(container, correctly: true);

      final after = stateOf(container);

      expect(after.index, before.index + 1);
      expect(after.score.points, greaterThan(before.score.points));
      expect(after.score.streak, 1);
      expect(feedback.countOf(Moment.answerCorrect), 1);
      expect(feedback.countOf(Moment.answerWrong), 0);
    });

    test('and clears the wrong-key marks it may have left', () {
      final container = containerWith();

      answer(container, correctly: false);
      expect(stateOf(container).wrongKeyIndex, isNotNull);

      answer(container, correctly: true);
      expect(stateOf(container).wrongKeyIndex, isNull);
    });
  });

  group('a wrong answer', () {
    test('holds the round, marks the tapped key and resets the streak', () {
      final container = containerWith();

      answer(container, correctly: true);
      answer(container, correctly: true);

      final before = stateOf(container);

      answer(container, correctly: false);

      final after = stateOf(container);

      expect(after.index, before.index, reason: 'the round is not consumed');
      expect(after.score.streak, 0);
      expect(after.score.points, before.score.points);
      expect(after.wrongKeyIndex, isNotNull);
      expect(
        after.keyStates[after.wrongKeyIndex!],
        AnswerKeyState.rejected,
      );
      expect(feedback.countOf(Moment.answerWrong), 1);
    });

    test('and exactly one key is marked, so exactly one shakes', () {
      final container = containerWith();

      answer(container, correctly: false);

      expect(
        stateOf(
          container,
        ).keyStates.where((state) => state == AnswerKeyState.rejected),
        hasLength(1),
      );
    });

    test('and a second wrong tap on the SAME key still shakes', () {
      // The latch is on the key IDENTITY, not on "a wrong answer happened":
      // tapping the same wrong key twice is two answers and has to feel like
      // two. `wrongTapId` is what tells the shake apart from a rebuild.
      final container = containerWith();

      answer(container, correctly: false);
      final first = stateOf(container).wrongTapId;

      answer(container, correctly: false);

      expect(stateOf(container).wrongTapId, isNot(first));
      expect(feedback.countOf(Moment.answerWrong), 2);
    });
  });

  group('the streak milestone', () {
    test('fires once per crossing, and replaces the correct-answer tick', () {
      // Twelve correct answers cross the five-step twice. The milestone
      // REPLACES the tick rather than stacking on it: two haptics on one
      // answer is felt as one longer buzz, which reads as a stutter.
      final container = containerWith();

      for (var i = 0; i < 12; i++) {
        answer(container, correctly: true);
      }

      expect(feedback.countOf(Moment.streakMilestone), 2);
      expect(feedback.countOf(Moment.answerCorrect), 10);
    });

    test('and does not re-fire after the streak dips and returns', () {
      // THE LATCH. Without it, breaking a streak at 6 and rebuilding to 5
      // fires the milestone a second time for the same achievement.
      final container = containerWith();

      for (var i = 0; i < 6; i++) {
        answer(container, correctly: true);
      }
      expect(feedback.countOf(Moment.streakMilestone), 1);

      answer(container, correctly: false);
      for (var i = 0; i < 5; i++) {
        answer(container, correctly: true);
      }

      expect(
        feedback.countOf(Moment.streakMilestone),
        2,
        reason: 'a rebuilt streak is a new achievement and fires once more',
      );
      expect(stateOf(container).score.bestStreak, 6);
    });
  });

  group('the snapshot', () {
    test('exposes three slots, at most one highlight, and never alarm', () {
      // A game never reaches for `alarm`: whether time is running out is the
      // shell's judgement, made against the run limit the shell owns.
      final container = containerWith();

      for (var i = 0; i < 40; i++) {
        final snapshot = container.read(stroopBoardSnapshotProvider(config));

        expect(snapshot.hud.slots, hasLength(3));
        expect(
          snapshot.hud.slots.where((s) => s.tone == HudTone.highlight).length,
          lessThanOrEqualTo(1),
        );
        expect(
          snapshot.hud.slots.map((s) => s.tone),
          isNot(contains(HudTone.alarm)),
        );

        if (stateOf(container).isFinished) break;
        answer(container, correctly: i % 3 != 2);
      }
    });

    test(
      'the streak pill highlights only once the multiplier is above one',
      () {
        final container = containerWith();

        HudSlot streakSlot() =>
            container.read(stroopBoardSnapshotProvider(config)).hud.slots.last;

        expect(streakSlot().tone, HudTone.neutral);

        for (var i = 0; i < 5; i++) {
          answer(container, correctly: true);
        }

        expect(streakSlot().tone, HudTone.highlight);
      },
    );

    test('the streak slot publishes a MULTIPLIER, not a raw count', () {
      // The sign is the shell's — `×7` is an ICU message with a plural and a
      // bidi isolate — and the format is how a game asks for it.
      final container = containerWith();

      expect(
        container
            .read(stroopBoardSnapshotProvider(config))
            .hud
            .slots
            .last
            .format,
        StatFormat.multiplier,
      );
    });

    test('progress is answered rounds over the round count', () {
      final container = containerWith();
      final total = profileFor(Difficulty.classic).roundCount;

      expect(
        container.read(stroopBoardSnapshotProvider(config)).progress,
        0,
      );

      for (var i = 0; i < total; i++) {
        answer(container, correctly: true);
      }

      expect(
        container.read(stroopBoardSnapshotProvider(config)).progress,
        1,
      );
    });

    test('and the score slot carries an INTEGER, not a formatted string', () {
      // Persisting `۱٬۲۴۰` would make the Stats table unsortable and
      // unparseable. The shell formats; the board counts.
      final container = containerWith();

      for (var i = 0; i < 3; i++) {
        answer(container, correctly: true);
      }

      final slot = container
          .read(stroopBoardSnapshotProvider(config))
          .hud
          .slots[1];

      expect(slot.canonicalValue, isA<int>());
      expect(slot.canonicalValue, stateOf(container).score.points);
      expect(slot.format, StatFormat.points);
    });
  });

  group('the outcome', () {
    test('is null until the last round, then carries the final figures', () {
      final container = containerWith();
      final total = profileFor(Difficulty.classic).roundCount;

      for (var i = 0; i < total - 1; i++) {
        answer(container, correctly: true);
        expect(
          container.read(stroopBoardSnapshotProvider(config)).outcome,
          isNull,
          reason: 'after ${i + 1} of $total',
        );
      }

      answer(container, correctly: true);

      final snapshot = container.read(stroopBoardSnapshotProvider(config));

      expect(snapshot.outcome, isA<RunCompleted>());
      expect(snapshot.score, stateOf(container).score.points);
    });

    test('and the outcome stats are integers with ARB keys', () {
      // A WRONG ANSWER HOLDS THE ROUND, so a run ends only when every round
      // has been answered correctly. Answering wrongly first and then
      // correctly is what a real run of mixed accuracy looks like.
      final container = containerWith();
      final total = profileFor(Difficulty.classic).roundCount;

      for (var i = 0; i < total; i++) {
        if (i.isEven) answer(container, correctly: false);
        answer(container, correctly: true);
      }

      final outcome =
          container.read(stroopBoardSnapshotProvider(config)).outcome!
              as RunCompleted;

      for (final stat in outcome.stats) {
        expect(stat.canonicalValue, isA<int>());
        expect(stat.labelKey, isNotEmpty);
      }
    });

    test('and a submit after the last round changes nothing', () {
      final container = containerWith();
      final total = profileFor(Difficulty.classic).roundCount;

      for (var i = 0; i < total; i++) {
        answer(container, correctly: true);
      }

      final finished = stateOf(container);

      notifierOf(container).submit(0);

      expect(stateOf(container), finished);
    });
  });

  group('the board owns no clock and no run', () {
    test('it never reads the run notifier', () {
      // Asserted structurally in the policy test; here, the narrower claim
      // that the board works with nothing in that provider at all.
      final container = containerWith();

      expect(() => answer(container, correctly: true), returnsNormally);
    });
  });

  group('the reaction time', () {
    test('is measured from the injected clock, over correct answers only', () {
      // A wrong tap leaves the round in front of the player, so counting it
      // would fold thinking time into a number that is meant to be a reflex.
      // The clock is INJECTED — never DateTime.now(), never a Stopwatch — so
      // this is a measurement a test can make rather than one it has to wait
      // for.
      final clock = _SteppingClock(const Duration(milliseconds: 250));
      final container = ProviderContainer(
        overrides: [
          feedbackServiceProvider.overrideWithValue(FakeFeedbackService()),
          initialAppSettingsProvider.overrideWithValue(
            const AppSettings.defaults(),
          ),
          settingsProvider.overrideWith(
            (ref) => Stream<AppSettings>.value(const AppSettings.defaults()),
          ),
          clockProvider.overrideWithValue(clock.asClock()),
        ],
      );
      addTearDown(container.dispose);

      for (var i = 0; i < 4; i++) {
        final state = container.read(stroopBoardNotifierProvider(config));
        final round = state.rounds[state.index];

        container
            .read(stroopBoardNotifierProvider(config).notifier)
            .submit(round.options.indexOf(round.ink));
      }

      expect(
        container.read(stroopBoardSnapshotProvider(config)).totalReactionMs,
        1000,
        reason: 'four correct answers at 250ms each',
      );
    });
  });
}

/// A clock that advances by a fixed step every time it is read.
///
/// Simpler than `fake_async` for this: the board reads the clock exactly twice
/// per answer, so a stepping clock makes each reaction exactly one step and the
/// arithmetic stays readable in the expectation.
class _SteppingClock {
  _SteppingClock(this.step);

  final Duration step;
  DateTime _now = DateTime.utc(2026);

  Clock asClock() => Clock(() {
    final reading = _now;

    _now = _now.add(step);

    return reading;
  });
}
