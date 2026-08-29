import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/hud_tone.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/core/run_outcome.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_board_state.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_difficulty_profile.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_round_generator.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_scoring.dart';
import 'package:mindforge/shared/feedback/feedback_service.dart';
import 'package:mindforge/shared/feedback/moment.dart';

/// The board's one owner.
///
/// **It owns no clock and never reads the run.** The elapsed time, the run
/// limit, the phase machine and the decision to navigate are all the shell's;
/// this publishes what the board knows and nothing else.
///
/// Family-keyed by `RunConfig` and auto-disposed, so "play again" with a fresh
/// seed is a fresh notifier and a fresh run rather than a reset.
final class BridgeBoardNotifier extends Notifier<BridgeBoardState> {
  /// Creates the notifier for [config].
  ///
  /// Riverpod 3 hands a family's argument to the CONSTRUCTOR — `build()` takes
  /// none — so the config is a field.
  BridgeBoardNotifier(this.config);

  /// Which run is being played.
  final RunConfig config;

  /// When the current round was put in front of the player.
  ///
  /// **From the injected `Clock`, never an ambient wall-clock read and never a
  /// stopwatch.** A board may measure its own reaction times — that is what
  /// `BoardSnapshot.totalReactionMs` is for — and doing it through the injected
  /// clock is what keeps the measurement testable and the rule against a second
  /// RUN timer intact.
  ///
  /// `late` rather than an epoch placeholder: `build()` always assigns before
  /// anything can read it, so a genuine misuse throws instead of banking a
  /// fifty-six-year reaction time.
  late DateTime _shownAt;

  @override
  BridgeBoardState build() {
    final rounds = generateBridgeRounds(
      seed: config.seed,
      difficulty: config.difficulty,
    );

    _shownAt = ref.read(clockProvider).now();

    return BridgeBoardState(
      rounds: rounds,
      index: 0,
      score: const BridgeScore.zero(),
      chipStates: List<BridgeChipState>.filled(
        rounds.first.candidates.length,
        BridgeChipState.idle,
      ),
    );
  }

  /// The board is on screen and the round in front of the player starts now.
  ///
  /// **Not the run phase, which this notifier is fenced from.** The board is
  /// BUILT at `start()` — the run notifier subscribes to it inside its own
  /// build — which is before the 3-2-1, so anchoring the reaction clock there
  /// would bank the whole countdown into the first answer. Resuming from a
  /// pause routes back through the countdown while the board stays alive
  /// underneath it, so it would bank the pause too.
  void markShown() => _shownAt = ref.read(clockProvider).now();

  /// The player tapped the chip at [chipIndex].
  ///
  /// The one intent method. Everything else on this notifier is derived.
  void submit(int chipIndex) {
    final round = state.current;

    // A tap after the last round changes nothing. The board freezes when the
    // run ends and the shell decides what happens next.
    if (round == null) return;

    final profile = profileFor(config.difficulty);
    // Compared as INTEGERS, never as rendered numerals. The two sides of this
    // board are drawn in different numbering systems on purpose, so a string
    // comparison here would be comparing a Persian glyph against a Latin one
    // and would never match — working agreement 12's "normalise before any
    // comparison", reached by never leaving canonical form in the first place.
    final isCorrect = round.candidates[chipIndex] == round.target;
    final now = ref.read(clockProvider).now();
    // Floored at zero. A clock that goes backwards — a manual time change, a
    // fake clock rewound in a test — would otherwise bank a negative reaction
    // and make the average meaningless.
    final reactionMs = now.difference(_shownAt).inMilliseconds.clamp(0, 60000);
    final score = applyAnswer(
      state.score,
      isCorrect: isCorrect,
      profile: profile,
    );

    if (!isCorrect) {
      _fire(Moment.answerWrong);

      state = state.copyWith(
        score: score,
        // THE LATCH RESETS WITH THE STREAK. It exists to stop ONE crossing
        // firing on every frame after it happens — not to stop a rebuilt
        // streak celebrating.
        lastMilestone: 0,
        // A NEW IDENTITY on every wrong tap, so tapping the same wrong chip
        // twice shakes twice.
        wrongTapId: state.wrongTapId + 1,
        chipStates: _chipStatesWith(chipIndex, BridgeChipState.rejected),
      );

      return;
    }

    // Only a CORRECT answer records a reaction: a wrong tap leaves the round in
    // front of the player, and counting the false start as a measurement would
    // report an average nobody achieved.
    _reactionMs += reactionMs;
    _shownAt = now;

    final milestone = _milestoneCrossed(score.streak, profile);

    // THE MILESTONE REPLACES THE TICK rather than stacking on it. Two haptics
    // on one answer are felt as one longer buzz, which reads as a stutter.
    _fire(milestone == null ? Moment.answerCorrect : Moment.streakMilestone);

    final nextIndex = state.index + 1;
    final isFinished = nextIndex >= state.rounds.length;

    state = state.copyWith(
      index: nextIndex,
      score: score,
      lastMilestone: milestone ?? state.lastMilestone,
      chipStates: isFinished
          ? List<BridgeChipState>.filled(
              state.chipStates.length,
              BridgeChipState.locked,
            )
          : List<BridgeChipState>.filled(
              state.rounds[nextIndex].candidates.length,
              BridgeChipState.idle,
            ),
    );
  }

  /// Reaction time banked across every correct answer, in milliseconds.
  int _reactionMs = 0;

  /// The streak this answer just crossed, or `null` if it crossed none.
  ///
  /// Latched on the highest milestone already reached, because a boundary
  /// condition is true on every frame after it happens.
  int? _milestoneCrossed(int streak, BridgeDifficultyProfile profile) {
    if (streak == 0 || streak % kBridgeStreakStep != 0) return null;
    if (streak <= state.lastMilestone) return null;

    // Past the cap the multiplier stops moving, so there is nothing to
    // celebrate: a milestone that fires every four answers forever stops
    // meaning anything.
    final cap = profile.multiplierCap;
    final moved =
        streakMultiplier(streak, cap: cap) >
        streakMultiplier(streak - kBridgeStreakStep, cap: cap);

    return moved ? streak : null;
  }

  List<BridgeChipState> _chipStatesWith(int index, BridgeChipState value) {
    final states = List<BridgeChipState>.filled(
      state.chipStates.length,
      BridgeChipState.idle,
    );

    states[index] = value;

    return states;
  }

  /// Reaction time banked across every correct answer.
  int get totalReactionMs => _reactionMs;

  /// One moment, on the commit frame, once.
  void _fire(Moment moment) => ref.read(feedbackServiceProvider).fire(moment);
}

/// The board's state, per run.
// The lint wants the family's own type spelled out and Riverpod 3 exports no
// name for it — the same reason the run family is declared this way.
// ignore: specify_nonobvious_property_types
final bridgeBoardNotifierProvider = NotifierProvider.autoDispose
    .family<BridgeBoardNotifier, BridgeBoardState, RunConfig>(
      BridgeBoardNotifier.new,
    );

/// What the shell reads: three HUD slots, a progress value and an outcome.
///
/// **Derived, never stored.** A snapshot field on the state would be a second
/// copy of the score that can disagree with it.
///
/// Every value is a canonical INTEGER. The shell formats — and for this game
/// that separation is load-bearing rather than tidy: the board deliberately
/// draws one of its two numeral runs in a script the locale did not choose, and
/// a HUD that inherited that choice would print the score in a system the
/// player never asked for.
// ignore: specify_nonobvious_property_types
final bridgeBoardSnapshotProvider = Provider.autoDispose
    .family<BoardSnapshot, RunConfig>((ref, config) {
      final state = ref.watch(bridgeBoardNotifierProvider(config));
      final profile = profileFor(config.difficulty);
      final multiplier = streakMultiplier(
        state.score.streak,
        cap: profile.multiplierCap,
      );
      final notifier = ref.watch(bridgeBoardNotifierProvider(config).notifier);

      return BoardSnapshot(
        hud: GameHud(
          // TIME is the SHELL's clock, and the slot SAYS SO. The board does not
          // know how long the run has been going and must not.
          leading: const HudSlot(
            labelKey: 'hudTime',
            canonicalValue: 0,
            format: StatFormat.duration,
            source: HudSource.runClock,
          ),
          middle: HudSlot(
            labelKey: 'hudScore',
            canonicalValue: state.score.points,
            format: StatFormat.points,
          ),
          trailing: HudSlot(
            labelKey: 'hudStreak',
            canonicalValue: multiplier,
            format: StatFormat.multiplier,
            tone: multiplier > 1 ? HudTone.highlight : HudTone.neutral,
          ),
        ),
        progress: state.progress,
        score: state.score.points,
        correctCount: state.score.correct,
        wrongCount: state.score.wrong,
        longestCombo: state.score.bestStreak,
        totalReactionMs: notifier.totalReactionMs,
        outcome: state.isFinished
            ? _outcomeOf(state.score, notifier.totalReactionMs)
            : null,
      );
    });

/// The three cells the results screen shows.
///
/// Accuracy, average reaction and longest streak — the three `06-results.png`
/// draws, and the three the shell has ARB rows for.
RunOutcome _outcomeOf(BridgeScore score, int totalReactionMs) {
  final answered = score.correct + score.wrong;

  return RunOutcome.completed(
    // PER MILLE, which is StatFormat.percent's canonical unit: a rounded
    // percentage is a display decision and making it here would freeze one
    // locale's idea of precision.
    first: ResultStat(
      labelKey: 'accuracyLabel',
      format: StatFormat.percent,
      canonicalValue: answered == 0 ? 0 : (score.correct * 1000) ~/ answered,
    ),
    // AVERAGED OVER CORRECT ANSWERS ONLY. A wrong tap leaves the round in front
    // of the player, so counting it would fold thinking time into a number that
    // is supposed to be a reflex.
    second: ResultStat(
      labelKey: 'avgReactionLabel',
      format: StatFormat.duration,
      canonicalValue: score.correct == 0 ? 0 : totalReactionMs ~/ score.correct,
    ),
    third: ResultStat(
      labelKey: 'longestStreakLabel',
      format: StatFormat.multiplier,
      canonicalValue: score.bestStreak,
    ),
  );
}
